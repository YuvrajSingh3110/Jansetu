import { NextRequest, NextResponse } from 'next/server'
import { getServerSession } from 'next-auth'
import { authOptions } from '@/lib/auth'
import { generateDifferentialDiagnosis } from '@/lib/ollama'

export async function POST(req: NextRequest) {
  const session = await getServerSession(authOptions)
  if (!session) return NextResponse.json({ error: 'unauthorized' }, { status: 401 })

  const { symptoms, caseCount, villages, windowHrs } = await req.json()
  if (!symptoms?.length) return NextResponse.json({ error: 'symptoms required' }, { status: 400 })

  try {
    const result = await generateDifferentialDiagnosis(symptoms, caseCount || 0, villages || [], windowHrs || 72)
    return NextResponse.json(result)
  } catch (err) {
    console.error('[/api/ai/differential] Gemma failed:', err)
    return NextResponse.json({ error: 'Gemma unavailable', detail: String(err) }, { status: 503 })
  }
}
