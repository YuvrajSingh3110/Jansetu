import { NextRequest, NextResponse } from 'next/server'
import { verifyAndroidToken } from '@/lib/android-auth'
import { prisma } from '@/lib/prisma'
import { enqueueOutbreakDetection } from '@/lib/queue'

/**
 * POST /api/android/sync
 * Authorization: Bearer jansetu-internal-2026
 *
 * Unified sync endpoint — combines report ingestion + CHW heartbeat
 * in a single round-trip to minimise data usage on 2G connections.
 *
 * Body:
 * {
 *   "chwId": "VR-2841",           // CHW employee ID (null for village users)
 *   "sourceType": "chw",          // "chw" | "village_user"
 *   "deviceId": "uuid",           // optional, for dedup
 *   "reports": [{
 *     "villageId": "clv001rampur",
 *     "ageGroup": "adult",        // "child" | "adult" | "elderly"
 *     "gender": "F",              // "M" | "F" | "unknown"
 *     "symptoms": ["fever","cough"],
 *     "duration": 3,              // days (optional)
 *     "severity": "mild",         // "mild" | "moderate" | "severe"
 *     "hasPhoto": false,
 *     "referral": false,
 *     "reportedAt": "2026-04-26T09:30:00Z"
 *   }]
 * }
 *
 * Response:
 * {
 *   "received": 3,
 *   "queued": true,
 *   "chwReportsCount": 47,        // updated total for CHW
 *   "alerts": [...]               // any NEW alerts since lastSyncAt
 * }
 */

const VALID_SYMPTOMS = new Set([
  'fever', 'cough', 'breathlessness', 'diarrhoea', 'vomiting', 'rash',
  'headache', 'bodyache', 'sore_throat', 'runny_nose', 'malnutrition',
  'jaundice', 'conjunctivitis', 'seizure', 'unconscious', 'bleeding',
])

export async function POST(req: NextRequest) {
  if (!verifyAndroidToken(req)) {
    return NextResponse.json({ error: 'unauthorized' }, { status: 401 })
  }

  let body: any
  try { body = await req.json() } catch {
    return NextResponse.json({ error: 'invalid JSON' }, { status: 400 })
  }

  const { reports = [], chwId, sourceType = 'village_user' } = body

  // Resolve CHW and update heartbeat
  let chwDbId: string | null = null
  let chw: any = null
  if (chwId) {
    chw = await prisma.cHW.findUnique({ where: { employeeId: chwId } })
    if (chw) {
      chwDbId = chw.id
      await prisma.cHW.update({
        where: { id: chw.id },
        data: { lastSyncAt: new Date(), reportsCount: { increment: reports.length } },
      })
    }
  }

  // Ingest reports
  const created: string[] = []
  const districtIds = new Set<string>()
  const prevSyncAt = chw?.lastSyncAt || new Date(0)

  for (const r of reports) {
    if (!r.villageId || !r.ageGroup || !r.gender || !r.severity || !r.reportedAt) continue

    const village = await prisma.village.findUnique({
      where: { id: r.villageId },
      include: { block: true },
    })
    if (!village) continue

    districtIds.add(village.block.districtId)

    const symptoms = (r.symptoms || []).filter((s: string) => VALID_SYMPTOMS.has(s))

    const report = await prisma.report.create({
      data: {
        sourceType: sourceType || 'village_user',
        villageId: r.villageId,
        chwId: chwDbId,
        ageGroup: r.ageGroup,
        gender: r.gender,
        symptoms,
        duration: r.duration || null,
        severity: r.severity,
        hasPhoto: r.hasPhoto || false,
        referral: r.referral || false,
        reportedAt: new Date(r.reportedAt),
      },
    })
    created.push(report.id)
  }

  // Queue outbreak detection for affected districts
  for (const districtId of Array.from(districtIds)) {
    enqueueOutbreakDetection(districtId).catch(() => {})
  }

  // Return any new alerts since CHW's last sync (so app shows them)
  const newAlerts = districtIds.size > 0
    ? await prisma.alert.findMany({
        where: {
          districtId: { in: Array.from(districtIds) },
          status: 'active',
          createdAt: { gt: prevSyncAt },
        },
        select: {
          id: true, type: true, title: true, confidence: true,
          affectedVillages: true, caseCount: true, createdAt: true,
        },
        orderBy: { createdAt: 'desc' },
        take: 5,
      })
    : []

  return NextResponse.json({
    received: created.length,
    queued: districtIds.size > 0,
    chwReportsCount: chw ? chw.reportsCount + reports.length : null,
    newAlerts: newAlerts.map((a) => ({ ...a, createdAt: a.createdAt.toISOString() })),
    syncedAt: new Date().toISOString(),
  })
}
