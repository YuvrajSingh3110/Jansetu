import { NextRequest, NextResponse } from 'next/server'
import { getServerSession } from 'next-auth'
import { authOptions } from '@/lib/auth'
import { prisma } from '@/lib/prisma'
import { draftBroadcastMessage } from '@/lib/ollama'

export async function POST(req: NextRequest) {
  const session = await getServerSession(authOptions)
  if (!session) return NextResponse.json({ error: 'unauthorized' }, { status: 401 })

  const { alertId, village } = await req.json()

  let description = ''
  let villages: string[] = []

  if (alertId) {
    const alert = await prisma.alert.findUnique({ where: { id: alertId } })
    if (!alert) return NextResponse.json({ error: 'alert not found' }, { status: 404 })
    description = alert.description
    villages = alert.affectedVillages
  } else if (village) {
    description = `Health advisory for ${village} village`
    villages = [village]
  } else {
    return NextResponse.json({ error: 'alertId or village required' }, { status: 400 })
  }

  try {
    const draft = await draftBroadcastMessage(description, villages)
    return NextResponse.json({ hindi: draft.hindi, english: draft.english })
  } catch (err) {
    // Fallback if Ollama is down
    return NextResponse.json({
      hindi: `${villages.join(', ')} और आसपास के गाँवों में स्वास्थ्य सतर्कता जारी की गई है। कृपया सावधान रहें और किसी भी बीमारी के लक्षण दिखने पर तुरंत CHW से संपर्क करें।`,
      english: `A health advisory has been issued for ${villages.join(', ')} and nearby villages. Please remain cautious and contact your CHW immediately if you notice any illness symptoms.`,
    })
  }
}
