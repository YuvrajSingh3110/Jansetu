import { NextResponse } from 'next/server'
import { prisma } from '@/lib/prisma'

/**
 * GET /api/android/health
 * No auth required.
 *
 * Android app pings this on startup to check server reachability
 * before attempting a full sync. Also returns server time so the
 * app can detect large clock drift on field devices.
 */
export async function GET() {
  try {
    await prisma.$queryRaw`SELECT 1`
    return NextResponse.json({
      status: 'ok',
      db: 'connected',
      serverTime: new Date().toISOString(),
      version: '1.0.0',
    })
  } catch {
    return NextResponse.json({ status: 'error', db: 'unreachable' }, { status: 503 })
  }
}
