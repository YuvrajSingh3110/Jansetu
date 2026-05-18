import { NextRequest, NextResponse } from 'next/server'
import { prisma } from '@/lib/prisma'

export async function GET(req: NextRequest) {
  const districtId = new URL(req.url).searchParams.get('districtId') || 'dist001varanasi'

  const villages = await prisma.village.findMany({
    where: { block: { districtId } },
    include: { block: { select: { name: true } } },
    orderBy: { name: 'asc' },
  })

  return NextResponse.json({
    villages: villages.map((v) => ({
      id: v.id,
      name: v.name,
      block: v.block.name,
      lat: v.lat,
      lng: v.lng,
    })),
  })
}
