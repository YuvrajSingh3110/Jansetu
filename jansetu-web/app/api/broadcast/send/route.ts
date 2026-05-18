import { NextRequest, NextResponse } from 'next/server'
import { getServerSession } from 'next-auth'
import { authOptions } from '@/lib/auth'
import { prisma } from '@/lib/prisma'

export async function POST(req: NextRequest) {
  const session = await getServerSession(authOptions)
  if (!session) return NextResponse.json({ error: 'unauthorized' }, { status: 401 })

  const { alertId, targetType, targetIds, channel, messageHi, messageEn } = await req.json()
  if (!targetType || !targetIds || !messageHi || !messageEn) {
    return NextResponse.json({ error: 'missing required fields' }, { status: 400 })
  }

  if (Array.isArray(channel) && channel.includes('sms')) {
    console.log('[SMS MOCK] Broadcasting to', targetIds, ':', messageEn)
  }

  const broadcast = await prisma.broadcast.create({
    data: {
      alertId: alertId || null,
      targetType,
      targetIds: Array.isArray(targetIds) ? targetIds : [targetIds],
      messageHi,
      messageEn,
      channel: Array.isArray(channel) ? channel : [channel],
      status: 'sent',
      sentAt: new Date(),
    },
  })

  return NextResponse.json({ broadcast, sent: true })
}
