import { NextRequest, NextResponse } from 'next/server'
import { verifyAndroidToken } from '@/lib/android-auth'
import { prisma } from '@/lib/prisma'

/**
 * GET /api/android/alerts?districtId=dist001varanasi&since=2026-04-20T00:00:00Z
 * Authorization: Bearer jansetu-internal-2026
 *
 * Returns active alerts for a district, optionally filtered by
 * a timestamp so the app only fetches new alerts since last check.
 * The app displays these to CHWs so they know where outbreaks are.
 */
export async function GET(req: NextRequest) {
  if (!verifyAndroidToken(req)) {
    return NextResponse.json({ error: 'unauthorized' }, { status: 401 })
  }

  const { searchParams } = new URL(req.url)
  const districtId = searchParams.get('districtId') || 'dist001varanasi'
  const since = searchParams.get('since') ? new Date(searchParams.get('since')!) : undefined

  const alerts = await prisma.alert.findMany({
    where: {
      districtId,
      status: 'active',
      ...(since ? { createdAt: { gt: since } } : {}),
    },
    select: {
      id: true,
      type: true,
      confidence: true,
      title: true,
      description: true,
      affectedVillages: true,
      symptomCluster: true,
      caseCount: true,
      timeWindowHrs: true,
      status: true,
      createdAt: true,
    },
    orderBy: { createdAt: 'desc' },
    take: 20,
  })

  return NextResponse.json({
    alerts: alerts.map((a) => ({
      ...a,
      createdAt: a.createdAt.toISOString(),
    })),
    fetchedAt: new Date().toISOString(),
  })
}
