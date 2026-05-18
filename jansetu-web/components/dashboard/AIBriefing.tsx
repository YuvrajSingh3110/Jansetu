'use client'
import { useState } from 'react'

type Briefing = {
  headline: string
  situation: string
  watchPoints: string[]
  recommendedFocus: string
  positives: string
}

export function AIBriefing() {
  const [briefing, setBriefing] = useState<Briefing | null>(null)
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState('')

  async function generate() {
    setLoading(true)
    setError('')
    try {
      const res = await fetch('/api/ai/briefing', { method: 'POST' })
      if (!res.ok) throw new Error('Ollama unavailable')
      setBriefing(await res.json())
    } catch {
      setError('Gemma unavailable — check Ollama connection in Settings')
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="rounded-[10px] p-[12px_14px] mb-[10px]" style={{ background: '#fff', border: '1px solid #E5E5E5' }}>
      <div className="flex items-center justify-between mb-[8px]">
        <div>
          <div className="text-[12px] font-medium text-[#333]">AI district briefing</div>
          <div className="text-[10px]" style={{ color: '#aaa' }}>Gemma 4 31B · generated on demand</div>
        </div>
        <button
          onClick={generate}
          disabled={loading}
          className="text-[11px] px-3 py-1.5 rounded-[6px] font-medium text-white disabled:opacity-60"
          style={{ background: '#185FA5' }}
        >
          {loading ? 'Analysing…' : briefing ? 'Regenerate' : 'Generate briefing'}
        </button>
      </div>

      {error && (
        <div className="text-[10px] px-3 py-2 rounded-[6px]" style={{ background: '#FAEEDA', color: '#633806' }}>
          {error}
        </div>
      )}

      {loading && (
        <div className="space-y-2 mt-2">
          {[80, 60, 90, 50].map((w, i) => (
            <div key={i} className="h-[10px] rounded-[4px] animate-pulse" style={{ background: '#f0f0f0', width: `${w}%` }} />
          ))}
        </div>
      )}

      {briefing && !loading && (
        <div className="space-y-[10px]">
          <div className="rounded-[7px] p-[10px]" style={{ background: '#E6F1FB' }}>
            <div className="text-[11px] font-medium" style={{ color: '#0C447C' }}>{briefing.headline}</div>
          </div>

          <div className="text-[11px] leading-[1.6]" style={{ color: '#444' }}>{briefing.situation}</div>

          {briefing.watchPoints?.length > 0 && (
            <div>
              <div className="text-[10px] font-medium text-[#888] mb-1">Watch points</div>
              <div className="space-y-1">
                {briefing.watchPoints.map((w, i) => (
                  <div key={i} className="flex gap-2 text-[11px]" style={{ color: '#444' }}>
                    <span style={{ color: '#EF9F27', flexShrink: 0 }}>⚠</span>
                    <span>{w}</span>
                  </div>
                ))}
              </div>
            </div>
          )}

          <div className="rounded-[7px] p-[8px]" style={{ background: '#FCEBEB' }}>
            <div className="text-[10px] font-medium mb-[2px]" style={{ color: '#A32D2D' }}>Recommended focus today</div>
            <div className="text-[11px]" style={{ color: '#791F1F' }}>{briefing.recommendedFocus}</div>
          </div>

          <div className="rounded-[7px] p-[8px]" style={{ background: '#E1F5EE' }}>
            <div className="text-[10px] font-medium mb-[2px]" style={{ color: '#085041' }}>Positive signal</div>
            <div className="text-[11px]" style={{ color: '#085041' }}>{briefing.positives}</div>
          </div>
        </div>
      )}

      {!briefing && !loading && !error && (
        <div className="text-[11px] text-center py-4" style={{ color: '#bbb' }}>
          Click to generate your morning health briefing
        </div>
      )}
    </div>
  )
}
