import { NextRequest, NextResponse } from 'next/server'
import { prisma } from '@/lib/prisma'

export async function GET(req: NextRequest) {
  const { searchParams } = new URL(req.url)
  const days = parseInt(searchParams.get('days') || '7')
  const districtId = searchParams.get('districtId') || 'dist001varanasi'

  const since = new Date(Date.now() - days * 24 * 60 * 60 * 1000)

  const reports = await prisma.report.findMany({
    where: { syncedAt: { gte: since }, village: { block: { districtId } } },
    select: { symptoms: true },
  })

  const counts: Record<string, number> = {}
  for (const r of reports) {
    for (const s of r.symptoms) {
      counts[s] = (counts[s] || 0) + 1
    }
  }

  const sorted = Object.entries(counts)
    .sort((a, b) => b[1] - a[1])
    .map(([name, count]) => ({ name, count }))

  return NextResponse.json({ symptoms: sorted, days, total: reports.length })
}
