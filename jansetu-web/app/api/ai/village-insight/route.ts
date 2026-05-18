import { NextRequest, NextResponse } from 'next/server'
import { getServerSession } from 'next-auth'
import { authOptions } from '@/lib/auth'
import { generateVillageInsight } from '@/lib/ollama'

export async function POST(req: NextRequest) {
  const session = await getServerSession(authOptions)
  if (!session) return NextResponse.json({ error: 'unauthorized' }, { status: 401 })

  const { villageName, blockName, symptomCounts, totalCases, days } = await req.json()
  if (!villageName) return NextResponse.json({ error: 'villageName required' }, { status: 400 })

  try {
    const insight = await generateVillageInsight(
      villageName,
      blockName || 'Unknown block',
      symptomCounts || {},
      totalCases || 0,
      days || 7
    )
    return NextResponse.json(insight)
  } catch (err) {
    console.error('[/api/ai/village-insight] Gemma failed:', err)
    return NextResponse.json({ error: 'Gemma unavailable', detail: String(err) }, { status: 503 })
  }
}
