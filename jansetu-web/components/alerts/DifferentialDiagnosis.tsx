'use client'
import { useState } from 'react'

type Differential = {
  disease: string
  likelihood: number
  reasoning: string
  keyDistinguisher: string
}

type Result = {
  differentials: Differential[]
  urgentFlag: string | null
  suggestedTests: string[]
}

export function DifferentialDiagnosis({
  symptoms, caseCount, villages, windowHrs,
}: {
  symptoms: string[]
  caseCount: number
  villages: string[]
  windowHrs: number
}) {
  const [result, setResult] = useState<Result | null>(null)
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState('')

  async function run() {
    setLoading(true)
    setError('')
    try {
      const res = await fetch('/api/ai/differential', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ symptoms, caseCount, villages, windowHrs }),
      })
      if (!res.ok) throw new Error()
      setResult(await res.json())
    } catch {
      setError('Gemma unavailable')
    } finally {
      setLoading(false)
    }
  }

  const likelihoodColor = (pct: number) =>
    pct >= 60 ? '#E24B4A' : pct >= 35 ? '#EF9F27' : '#1D9E75'

  return (
    <div className="rounded-[10px] p-[12px_14px]" style={{ background: '#fff', border: '1px solid #E5E5E5' }}>
      <div className="flex items-center justify-between mb-[8px]">
        <div>
          <div className="text-[12px] font-medium text-[#333]">Differential diagnosis</div>
          <div className="text-[10px]" style={{ color: '#aaa' }}>Gemma 4 31B · clinical pattern analysis</div>
        </div>
        <button
          onClick={run}
          disabled={loading}
          className="text-[11px] px-3 py-1.5 rounded-[6px] font-medium text-white disabled:opacity-60"
          style={{ background: '#185FA5' }}
        >
          {loading ? 'Analysing…' : result ? 'Re-analyse' : 'Run analysis'}
        </button>
      </div>

      {error && (
        <div className="text-[10px] px-3 py-2 rounded-[6px]" style={{ background: '#FAEEDA', color: '#633806' }}>{error}</div>
      )}

      {loading && (
        <div className="space-y-2">
          {[70, 50, 40].map((w, i) => (
            <div key={i} className="h-[32px] rounded-[6px] animate-pulse" style={{ background: '#f5f5f5', width: `${w}%` }} />
          ))}
        </div>
      )}

      {result && !loading && (
        <div className="space-y-[8px]">
          {result.urgentFlag && (
            <div className="rounded-[6px] p-[8px] flex gap-2" style={{ background: '#FCEBEB' }}>
              <span className="text-[13px]">🚨</span>
              <div className="text-[11px] font-medium" style={{ color: '#A32D2D' }}>{result.urgentFlag}</div>
            </div>
          )}

          {result.differentials.map((d, i) => (
            <div key={i} className="rounded-[7px] p-[10px]" style={{ background: '#fafafa', border: '1px solid #f0f0f0' }}>
              <div className="flex items-center justify-between mb-[4px]">
                <div className="text-[12px] font-medium" style={{ color: '#222' }}>{d.disease}</div>
                <div className="text-[12px] font-medium" style={{ color: likelihoodColor(d.likelihood) }}>
                  {d.likelihood}%
                </div>
              </div>
              <div className="w-full h-[3px] rounded-[2px] mb-[6px]" style={{ background: '#eee' }}>
                <div className="h-full rounded-[2px]"
                  style={{ width: `${d.likelihood}%`, background: likelihoodColor(d.likelihood) }} />
              </div>
              <div className="text-[10px] mb-[3px]" style={{ color: '#555' }}>{d.reasoning}</div>
              <div className="text-[10px]" style={{ color: '#888' }}>
                <span className="font-medium">Key distinguisher: </span>{d.keyDistinguisher}
              </div>
            </div>
          ))}

          {result.suggestedTests?.length > 0 && (
            <div className="rounded-[7px] p-[8px]" style={{ background: '#E6F1FB' }}>
              <div className="text-[10px] font-medium mb-[4px]" style={{ color: '#0C447C' }}>Suggested rapid tests</div>
              <div className="flex flex-wrap gap-1">
                {result.suggestedTests.map((t) => (
                  <span key={t} className="text-[9px] px-[7px] py-[2px] rounded-[8px] font-medium"
                    style={{ background: '#fff', color: '#0C447C', border: '1px solid #B5D4F4' }}>{t}</span>
                ))}
              </div>
            </div>
          )}
        </div>
      )}

      {!result && !loading && !error && (
        <div className="text-[11px] text-center py-3" style={{ color: '#bbb' }}>
          Analyse the symptom cluster for differential diagnoses
        </div>
      )}
    </div>
  )
}
