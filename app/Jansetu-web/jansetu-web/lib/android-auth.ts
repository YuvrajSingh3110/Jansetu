import { NextRequest } from 'next/server'

export function verifyAndroidToken(req: NextRequest): boolean {
  const auth = req.headers.get('authorization')
  return auth === `Bearer ${process.env.INTERNAL_API_SECRET}`
}
