import { NextRequest, NextResponse } from 'next/server'
import { getServerSession } from 'next-auth'
import { authOptions } from '@/lib/auth'
import { prisma } from '@/lib/prisma'

export async function GET(req: NextRequest) {
  const session = await getServerSession(authOptions)
  if (!session) return NextResponse.json({ error: 'unauthorized' }, { status: 401 })

  const { searchParams } = new URL(req.url)
  const status = searchParams.get('status') || undefined
  const districtId = searchParams.get('districtId') || (session.user as any).districtId

  const alerts = await prisma.alert.findMany({
    where: { districtId, ...(status && status !== 'all' ? { status } : {}) },
    include: { actions: { orderBy: { step: 'asc' } } },
    orderBy: { createdAt: 'desc' },
  })

  return NextResponse.json({ alerts })
}
