import { NextResponse } from 'next/server'
import { prisma } from '@/lib/prisma'

export async function GET(_: Request, { params }: { params: { id: string } }) {
  const days: { date: string; count: number }[] = []

  for (let i = 6; i >= 0; i--) {
    const d = new Date()
    d.setUTCDate(d.getUTCDate() - i)
    d.setUTCHours(0, 0, 0, 0)
    const end = new Date(d)
    end.setUTCHours(23, 59, 59, 999)

    const count = await prisma.report.count({
      where: { chwId: params.id, reportedAt: { gte: d, lte: end } },
    })
    days.push({ date: d.toISOString().slice(0, 10), count })
  }

  return NextResponse.json({ days })
}
