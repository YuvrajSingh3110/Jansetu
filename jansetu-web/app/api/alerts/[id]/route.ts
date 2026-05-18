import { NextRequest, NextResponse } from 'next/server'
import { getServerSession } from 'next-auth'
import { authOptions } from '@/lib/auth'
import { prisma } from '@/lib/prisma'

export async function GET(_req: NextRequest, { params }: { params: { id: string } }) {
  const session = await getServerSession(authOptions)
  if (!session) return NextResponse.json({ error: 'unauthorized' }, { status: 401 })

  const alert = await prisma.alert.findUnique({
    where: { id: params.id },
    include: {
      actions: { orderBy: { step: 'asc' } },
      broadcasts: { orderBy: { createdAt: 'desc' }, take: 5 },
    },
  })

  if (!alert) return NextResponse.json({ error: 'not found' }, { status: 404 })
  return NextResponse.json({ alert })
}

export async function PATCH(req: NextRequest, { params }: { params: { id: string } }) {
  const session = await getServerSession(authOptions)
  if (!session) return NextResponse.json({ error: 'unauthorized' }, { status: 401 })

  const body = await req.json()
  const alert = await prisma.alert.update({
    where: { id: params.id },
    data: { status: body.status },
  })

  return NextResponse.json({ alert })
}
