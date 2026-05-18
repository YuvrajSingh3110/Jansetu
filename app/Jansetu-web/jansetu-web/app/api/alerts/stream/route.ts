import { NextRequest } from 'next/server'
import { prisma } from '@/lib/prisma'

export async function GET(req: NextRequest) {
  const districtId = new URL(req.url).searchParams.get('districtId') || 'dist001varanasi'
  let lastChecked = new Date()

  const stream = new ReadableStream({
    start(controller) {
      const enc = new TextEncoder()

      const heartbeat = setInterval(() => {
        try {
          controller.enqueue(enc.encode(': heartbeat\n\n'))
        } catch {}
      }, 30000)

      const poll = setInterval(async () => {
        try {
          const alerts = await prisma.alert.findMany({
            where: { districtId, createdAt: { gt: lastChecked } },
          })
          if (alerts.length > 0) {
            lastChecked = new Date()
            for (const a of alerts) {
              controller.enqueue(enc.encode(`data: ${JSON.stringify(a)}\n\n`))
            }
          }
        } catch {}
      }, 5000)

      req.signal.addEventListener('abort', () => {
        clearInterval(heartbeat)
        clearInterval(poll)
        try { controller.close() } catch {}
      })
    },
  })

  return new Response(stream, {
    headers: {
      'Content-Type': 'text/event-stream',
      'Cache-Control': 'no-cache',
      Connection: 'keep-alive',
    },
  })
}
