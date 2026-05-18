import { NextRequest, NextResponse } from 'next/server'
import { verifyAndroidToken } from '@/lib/android-auth'
import { prisma } from '@/lib/prisma'

/**
 * GET /api/android/bootstrap?districtId=dist001varanasi
 * Authorization: Bearer jansetu-internal-2026
 *
 * Called once on app first launch or after a factory reset.
 * Returns everything the Android app needs to operate offline:
 * villages (with coordinates), blocks, and district info.
 */
export async function GET(req: NextRequest) {
  if (!verifyAndroidToken(req)) {
    return NextResponse.json({ error: 'unauthorized' }, { status: 401 })
  }

  const districtId = new URL(req.url).searchParams.get('districtId') || 'dist001varanasi'

  const [district, blocks, villages] = await Promise.all([
    prisma.district.findUnique({ where: { id: districtId } }),
    prisma.block.findMany({ where: { districtId }, select: { id: true, name: true } }),
    prisma.village.findMany({
      where: { block: { districtId } },
      include: { block: { select: { id: true, name: true } } },
      orderBy: { name: 'asc' },
    }),
  ])

  if (!district) {
    return NextResponse.json({ error: 'district not found' }, { status: 404 })
  }

  return NextResponse.json({
    district: { id: district.id, name: district.name, state: district.state },
    blocks: blocks.map((b) => ({ id: b.id, name: b.name })),
    villages: villages.map((v) => ({
      id: v.id,
      name: v.name,
      lat: v.lat,
      lng: v.lng,
      blockId: v.blockId,
      block: v.block.name,
    })),
    symptomCodes: [
      'fever', 'cough', 'breathlessness', 'diarrhoea', 'vomiting', 'rash',
      'headache', 'bodyache', 'sore_throat', 'runny_nose', 'malnutrition',
      'jaundice', 'conjunctivitis', 'seizure', 'unconscious', 'bleeding',
    ],
    syncedAt: new Date().toISOString(),
  })
}
