import { NextRequest, NextResponse } from 'next/server'
import { prisma } from '@/lib/prisma'
import { format, subDays } from 'date-fns'

export async function GET(req: NextRequest) {
  const { searchParams } = new URL(req.url)
  const villageId = searchParams.get('villageId')
  const days = parseInt(searchParams.get('days') || '14')

  if (!villageId) return NextResponse.json({ error: 'villageId required' }, { status: 400 })

  const points: { date: string; count: number }[] = []

  for (let i = days - 1; i >= 0; i--) {
    const start = subDays(new Date(), i + 1)
    const end = subDays(new Date(), i)
    start.setHours(0, 0, 0, 0)
    end.setHours(23, 59, 59, 999)

    const count = await prisma.report.count({
      where: { villageId, syncedAt: { gte: start, lte: end } },
    })

    points.push({ date: format(end, 'MMM d'), count })
  }

  return NextResponse.json({ timeline: points })
}
