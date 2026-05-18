import { NextRequest, NextResponse } from 'next/server'
import { prisma } from '@/lib/prisma'
import { startOfDay } from 'date-fns'

export async function GET(req: NextRequest) {
  const { searchParams } = new URL(req.url)
  const districtId = searchParams.get('districtId') || 'dist001varanasi'

  const today = startOfDay(new Date())
  const since24h = new Date(Date.now() - 86400000)

  const [reportsToday, activeAlerts, activeCHWs, villages] = await Promise.all([
    prisma.report.count({ where: { syncedAt: { gte: today }, village: { block: { districtId } } } }),
    prisma.alert.count({ where: { districtId, status: 'active' } }),
    prisma.cHW.count({ where: { block: { districtId }, lastSyncAt: { gte: since24h } } }),
    prisma.village.count({ where: { block: { districtId } } }),
  ])

  return NextResponse.json({ reportsToday, activeAlerts, activeCHWs, villages })
}
