import { NextRequest, NextResponse } from 'next/server'
import { prisma } from '@/lib/prisma'
import { getServerSession } from 'next-auth'
import { authOptions } from '@/lib/auth'

export async function GET() {
  const settings = await prisma.setting.findMany({ orderBy: { key: 'asc' } })
  return NextResponse.json(settings)
}

export async function PATCH(req: NextRequest) {
  const session = await getServerSession(authOptions)
  if (!session) return NextResponse.json({ error: 'unauthorized' }, { status: 401 })

  const body: Record<string, string> = await req.json()

  const updates = await Promise.all(
    Object.entries(body)
      .filter(([, v]) => v !== undefined && v !== '')
      .map(([key, value]) =>
        prisma.setting.update({ where: { key }, data: { value } }).catch(() => null)
      )
  )

  return NextResponse.json({ updated: updates.filter(Boolean).length })
}
