import { NextRequest, NextResponse } from 'next/server'
import { verifyAndroidToken } from '@/lib/android-auth'
import { prisma } from '@/lib/prisma'

/**
 * GET /api/android/chw/profile?employeeId=VR-2841
 * Authorization: Bearer jansetu-internal-2026
 *
 * Called on CHW login. Returns the CHW's profile, block, and
 * the villages they are responsible for.
 * The app stores this locally to show the CHW their own info.
 */
export async function GET(req: NextRequest) {
  if (!verifyAndroidToken(req)) {
    return NextResponse.json({ error: 'unauthorized' }, { status: 401 })
  }

  const employeeId = new URL(req.url).searchParams.get('employeeId')
  if (!employeeId) {
    return NextResponse.json({ error: 'employeeId required' }, { status: 400 })
  }

  const chw = await prisma.cHW.findUnique({
    where: { employeeId },
    include: {
      block: {
        include: {
          villages: { select: { id: true, name: true, lat: true, lng: true } },
        },
      },
    },
  })

  if (!chw) {
    return NextResponse.json({ error: 'CHW not found' }, { status: 404 })
  }

  // Update last sync timestamp
  await prisma.cHW.update({
    where: { id: chw.id },
    data: { lastSyncAt: new Date() },
  })

  return NextResponse.json({
    chw: {
      id: chw.id,
      employeeId: chw.employeeId,
      name: chw.name,
      phone: chw.phone,
      isActive: chw.isActive,
      reportsCount: chw.reportsCount,
      lastSyncAt: new Date().toISOString(),
      block: {
        id: chw.block.id,
        name: chw.block.name,
        villages: chw.block.villages.map((v) => ({
          id: v.id, name: v.name, lat: v.lat, lng: v.lng,
        })),
      },
    },
  })
}
