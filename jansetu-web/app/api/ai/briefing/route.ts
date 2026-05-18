import { NextRequest, NextResponse } from 'next/server'
import { getServerSession } from 'next-auth'
import { authOptions } from '@/lib/auth'
import { prisma } from '@/lib/prisma'
import { generateDailyBriefing } from '@/lib/ollama'
import { startOfDay } from 'date-fns'

export async function POST(req: NextRequest) {
  const session = await getServerSession(authOptions)
  if (!session) return NextResponse.json({ error: 'unauthorized' }, { status: 401 })

  const districtId = (session.user as any).districtId || 'dist001varanasi'

  const today = startOfDay(new Date())
  const since24h = new Date(Date.now() - 86400000)
  const since7d = new Date(Date.now() - 7 * 86400000)

  const [reportsToday, activeAlerts, activeCHWs, totalCHWs, symptomReports, district] =
    await Promise.all([
      prisma.report.count({ where: { syncedAt: { gte: today }, village: { block: { districtId } } } }),
      prisma.alert.count({ where: { districtId, status: 'active' } }),
      prisma.cHW.count({ where: { block: { districtId }, lastSyncAt: { gte: since24h } } }),
      prisma.cHW.count({ where: { block: { districtId } } }),
      prisma.report.findMany({ where: { syncedAt: { gte: since7d }, village: { block: { districtId } } }, select: { symptoms: true } }),
      prisma.district.findUnique({ where: { id: districtId } }),
    ])

  const alerts = await prisma.alert.findMany({
    where: { districtId, status: 'active' },
    orderBy: { createdAt: 'desc' },
    take: 5,
  })

  const symCounts: Record<string, number> = {}
  for (const r of symptomReports) {
    for (const s of r.symptoms) symCounts[s] = (symCounts[s] || 0) + 1
  }
  const topSymptoms = Object.entries(symCounts)
    .sort((a, b) => b[1] - a[1])
    .slice(0, 5)
    .map(([name, count]) => ({ name, count }))

  try {
    const briefing = await generateDailyBriefing(
      district?.name || districtId,
      { reportsToday, activeAlerts, activeCHWs, totalCHWs },
      alerts.map((a) => ({
        title: a.title, type: a.type, confidence: a.confidence,
        caseCount: a.caseCount, villages: a.affectedVillages,
      })),
      topSymptoms
    )
    return NextResponse.json(briefing)
  } catch (err) {
    console.error('[/api/ai/briefing] Gemma failed:', err)
    return NextResponse.json({ error: 'Gemma unavailable', detail: String(err) }, { status: 503 })
  }
}
