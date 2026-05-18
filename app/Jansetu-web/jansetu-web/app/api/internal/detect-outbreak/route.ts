import { NextRequest, NextResponse } from 'next/server'
import { runOutbreakDetection } from '@/lib/outbreak-detector'
import { checkOllamaHealth } from '@/lib/ollama'

export async function GET(_req: NextRequest) {
  // Health check endpoint for settings page
  const healthy = await checkOllamaHealth()
  return NextResponse.json({ ollama: healthy ? 'connected' : 'unreachable' })
}

export async function POST(req: NextRequest) {
  const secret = req.headers.get('x-internal-secret')
  if (secret !== process.env.INTERNAL_API_SECRET) {
    return NextResponse.json({ error: 'unauthorized' }, { status: 401 })
  }

  const { districtId, windowHrs = 72 } = await req.json()
  if (!districtId) return NextResponse.json({ error: 'districtId required' }, { status: 400 })

  const alert = await runOutbreakDetection(districtId, windowHrs)
  return NextResponse.json({ alert: alert ? { id: alert.id, title: alert.title } : null })
}
