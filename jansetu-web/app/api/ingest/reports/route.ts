import { NextRequest, NextResponse } from 'next/server'
import { prisma } from '@/lib/prisma'
import { enqueueOutbreakDetection } from '@/lib/queue'

const VALID_SYMPTOMS = new Set([
  'fever', 'cough', 'breathlessness', 'diarrhoea', 'vomiting', 'rash',
  'headache', 'bodyache', 'sore_throat', 'runny_nose', 'malnutrition',
  'jaundice', 'conjunctivitis', 'seizure', 'unconscious', 'bleeding',
])

export async function POST(req: NextRequest) {
  const auth = req.headers.get('authorization')
  if (auth !== `Bearer ${process.env.INTERNAL_API_SECRET}`) {
    return NextResponse.json({ error: 'unauthorized' }, { status: 401 })
  }

  let body: any
  try { body = await req.json() } catch {
    return NextResponse.json({ error: 'invalid JSON' }, { status: 400 })
  }

  const { reports, chwId, sourceType } = body
  if (!Array.isArray(reports) || reports.length === 0) {
    return NextResponse.json({ error: 'missing required field: reports' }, { status: 400 })
  }

  let chwDbId: string | null = null
  if (chwId) {
    const chw = await prisma.cHW.findUnique({ where: { employeeId: chwId } })
    if (chw) {
      chwDbId = chw.id
      await prisma.cHW.update({
        where: { id: chw.id },
        data: { lastSyncAt: new Date(), reportsCount: { increment: reports.length } },
      })
    }
  }

  const created: string[] = []
  const districtIds: string[] = []

  for (const r of reports) {
    if (!r.villageId || !r.ageGroup || !r.gender || !r.severity || !r.reportedAt) continue

    const village = await prisma.village.findUnique({
      where: { id: r.villageId },
      include: { block: true },
    })
    if (!village) continue

    if (!districtIds.includes(village.block.districtId)) {
      districtIds.push(village.block.districtId)
    }

    const symptoms = (r.symptoms || []).filter((s: string) => VALID_SYMPTOMS.has(s))

    const report = await prisma.report.create({
      data: {
        sourceType: sourceType || r.sourceType || 'village_user',
        villageId: r.villageId,
        chwId: chwDbId,
        ageGroup: r.ageGroup,
        gender: r.gender,
        symptoms: symptoms,
        duration: r.duration || null,
        severity: r.severity,
        hasPhoto: r.hasPhoto || false,
        referral: r.referral || false,
        reportedAt: new Date(r.reportedAt),
      },
    })
    created.push(report.id)
  }

  for (const districtId of districtIds) {
    enqueueOutbreakDetection(districtId).catch(() => {})
  }

  return NextResponse.json({ received: created.length, queued: true })
}
