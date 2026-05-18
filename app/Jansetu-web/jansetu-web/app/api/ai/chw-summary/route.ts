import { NextRequest, NextResponse } from 'next/server'
import { getServerSession } from 'next-auth'
import { authOptions } from '@/lib/auth'
import { prisma } from '@/lib/prisma'
import { generateCHWSummary } from '@/lib/ollama'

export async function POST(req: NextRequest) {
  const session = await getServerSession(authOptions)
  if (!session) return NextResponse.json({ error: 'unauthorized' }, { status: 401 })

  const { chwId } = await req.json()
  if (!chwId) return NextResponse.json({ error: 'chwId required' }, { status: 400 })

  const since7d = new Date(Date.now() - 7 * 86400000)

  const chw = await prisma.cHW.findUnique({
    where: { id: chwId },
    include: {
      block: { select: { name: true } },
      reports: {
        where: { syncedAt: { gte: since7d } },
        select: { symptoms: true, villageId: true },
      },
    },
  })

  if (!chw) return NextResponse.json({ error: 'CHW not found' }, { status: 404 })

  const symCounts: Record<string, number> = {}
  const villageSet = new Set<string>()
  for (const r of chw.reports) {
    villageSet.add(r.villageId)
    for (const s of r.symptoms) symCounts[s] = (symCounts[s] || 0) + 1
  }

  const lastSyncHoursAgo = chw.lastSyncAt
    ? Math.floor((Date.now() - chw.lastSyncAt.getTime()) / 3600000)
    : null

  try {
    const summary = await generateCHWSummary(
      chw.name,
      chw.block.name,
      chw.reportsCount,
      symCounts,
      lastSyncHoursAgo,
      villageSet.size
    )
    return NextResponse.json({ chw: { id: chw.id, name: chw.name, employeeId: chw.employeeId }, ...summary })
  } catch (err) {
    console.error('[/api/ai/chw-summary] Gemma failed:', err)
    return NextResponse.json({ error: 'Gemma unavailable', detail: String(err) }, { status: 503 })
  }
}
