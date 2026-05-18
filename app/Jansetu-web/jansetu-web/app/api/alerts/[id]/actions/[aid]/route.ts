import { NextRequest, NextResponse } from 'next/server'
import { getServerSession } from 'next-auth'
import { authOptions } from '@/lib/auth'
import { prisma } from '@/lib/prisma'

export async function PATCH(
  req: NextRequest,
  { params }: { params: { id: string; aid: string } }
) {
  const session = await getServerSession(authOptions)
  if (!session) return NextResponse.json({ error: 'unauthorized' }, { status: 401 })

  const body = await req.json()
  const validStatuses = ['pending', 'in_progress', 'done']
  if (!validStatuses.includes(body.status)) {
    return NextResponse.json({ error: 'invalid status' }, { status: 400 })
  }

  const action = await prisma.responseAction.update({
    where: { id: params.aid },
    data: {
      status: body.status,
      ...(body.status === 'done' ? { completedAt: new Date() } : {}),
    },
  })

  return NextResponse.json({ action })
}
