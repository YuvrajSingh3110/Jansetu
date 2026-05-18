import { NextRequest, NextResponse } from 'next/server'
import { getServerSession } from 'next-auth'
import { authOptions } from '@/lib/auth'
import { prisma } from '@/lib/prisma'

export async function GET(req: NextRequest) {
  const session = await getServerSession(authOptions)
  if (!session) return NextResponse.json({ error: 'unauthorized' }, { status: 401 })

  const districtId = new URL(req.url).searchParams.get('districtId') || (session.user as any).districtId

  const chws = await prisma.cHW.findMany({
    where: { block: { districtId } },
    include: { block: { select: { name: true } } },
    orderBy: { reportsCount: 'desc' },
  })

  return NextResponse.json({ chws })
}
