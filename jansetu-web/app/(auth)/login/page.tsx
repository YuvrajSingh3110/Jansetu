'use client'
import { signIn } from 'next-auth/react'
import { useRouter } from 'next/navigation'
import { useState } from 'react'

export default function LoginPage() {
  const router = useRouter()
  const [email, setEmail] = useState('demo@jansetu.in')
  const [password, setPassword] = useState('jansetu2026')
  const [error, setError] = useState('')
  const [loading, setLoading] = useState(false)

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    setLoading(true)
    setError('')

    const result = await signIn('credentials', { email, password, redirect: false })

    if (result?.error) {
      setError('Invalid email or password')
      setLoading(false)
    } else {
      router.push('/dashboard')
    }
  }

  return (
    <div className="min-h-screen flex items-center justify-center" style={{ background: '#F5F5F5' }}>
      <div className="w-full max-w-sm">
        {/* Logo */}
        <div className="text-center mb-8">
          <div
            className="inline-flex items-center justify-center w-12 h-12 rounded-xl mb-3"
            style={{ background: '#185FA5' }}
          >
            <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="white" strokeWidth="2">
              <path d="M3 9l9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z" />
              <polyline points="9 22 9 12 15 12 15 22" />
            </svg>
          </div>
          <h1 className="text-xl font-medium text-gray-900">Jansetu</h1>
          <p className="text-sm text-gray-500 mt-1">District Health Intelligence</p>
        </div>

        {/* Card */}
        <div className="bg-white rounded-xl border border-[#E5E5E5] p-6">
          <h2 className="text-sm font-medium text-gray-700 mb-5">Sign in to your account</h2>

          <form onSubmit={handleSubmit} className="space-y-4">
            <div>
              <label className="block text-[11px] text-gray-500 mb-1.5">Email</label>
              <input
                type="email"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                className="w-full text-sm border border-[#E5E5E5] rounded-lg px-3 py-2.5 outline-none focus:border-[#185FA5] transition-colors"
                placeholder="officer@jansetu.in"
                required
              />
            </div>
            <div>
              <label className="block text-[11px] text-gray-500 mb-1.5">Password</label>
              <input
                type="password"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                className="w-full text-sm border border-[#E5E5E5] rounded-lg px-3 py-2.5 outline-none focus:border-[#185FA5] transition-colors"
                placeholder="••••••••"
                required
              />
            </div>

            {error && (
              <div className="text-[11px] text-[#A32D2D] bg-[#FCEBEB] rounded-lg px-3 py-2">
                {error}
              </div>
            )}

            <button
              type="submit"
              disabled={loading}
              className="w-full py-2.5 rounded-lg text-sm font-medium text-white transition-opacity disabled:opacity-60"
              style={{ background: '#185FA5' }}
            >
              {loading ? 'Signing in…' : 'Sign in'}
            </button>
          </form>

          <div className="mt-4 text-center text-[10px] text-gray-400">
            Demo: demo@jansetu.in / jansetu2026
          </div>
        </div>

        <p className="text-center text-[10px] text-gray-400 mt-4">
          Jansetu · Varanasi District Health · 2026
        </p>
      </div>
    </div>
  )
}
