import { NextRequest, NextResponse } from 'next/server'
import { prisma } from '@/lib/prisma'
import { getRiskLevel } from '@/lib/utils'

export async function GET(req: NextRequest) {
  const { searchParams } = new URL(req.url)
  const days = parseInt(searchParams.get('days') || '7')
  const districtId = searchParams.get('districtId') || 'dist001varanasi'
  const symptomFilter = searchParams.get('symptom') || ''

  const since = new Date(Date.now() - days * 24 * 60 * 60 * 1000)

  const villages = await prisma.village.findMany({
    where: { block: { districtId } },
    include: {
      reports: {
        where: {
          syncedAt: { gte: since },
          ...(symptomFilter ? { symptoms: { has: symptomFilter } } : {}),
        },
        select: { symptoms: true },
      },
      block: { select: { name: true } },
    },
  })

  return NextResponse.json({
    villages: villages.map((v) => {
      const counts: Record<string, number> = {}
      v.reports.forEach((r) => {
        r.symptoms.forEach((s) => { counts[s] = (counts[s] || 0) + 1 })
      })

      const caseCount = v.reports.length
      const topEntry = Object.entries(counts).sort((a, b) => b[1] - a[1])[0]

      return {
        id: v.id,
        name: v.name,
        block: v.block.name,
        lat: v.lat,
        lng: v.lng,
        caseCount,
        topSymptom: topEntry?.[0] || null,
        symptomCounts: counts,
        riskLevel: getRiskLevel(caseCount, days),
      }
    }),
  })
}
