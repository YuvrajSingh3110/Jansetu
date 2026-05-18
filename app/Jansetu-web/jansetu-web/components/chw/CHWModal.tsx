'use client'
import { useState, useEffect } from 'react'

type Summary = {
  performanceSummary: string
  symptomPattern: string
  syncAlert: string
  recommendation: string
}

type DayData = { date: string; count: number }

type CHW = {
  id: string
  name: string
  employeeId: string
  phone: string | null
  reportsCount: number
  lastSyncAt: string | null
  blockName: string
  active: boolean
}

function Sparkline({ days }: { days: DayData[] }) {
  const W = 280
  const H = 48
  const PAD = 4
  const counts = days.map((d) => d.count)
  const max = Math.max(...counts, 1)
  const step = (W - PAD * 2) / (days.length - 1)

  const pts = counts.map((c, i) => {
    const x = PAD + i * step
    const y = H - PAD - ((c / max) * (H - PAD * 2))
    return `${x},${y}`
  })

  const dayLabels = days.map((d) => {
    const dt = new Date(d.date + 'T00:00:00Z')
    return dt.toLocaleDateString('en-IN', { weekday: 'short' }).slice(0, 2)
  })

  return (
    <div>
      <svg width={W} height={H} className="overflow-visible">
        {/* Area fill */}
        <polyline
          points={[`${PAD},${H - PAD}`, ...pts, `${PAD + (days.length - 1) * step},${H - PAD}`].join(' ')}
          fill="#B5D4F4"
          fillOpacity="0.4"
          stroke="none"
        />
        {/* Line */}
        <polyline
          points={pts.join(' ')}
          fill="none"
          stroke="#0C447C"
          strokeWidth="1.5"
          strokeLinejoin="round"
          strokeLinecap="round"
        />
        {/* Dots */}
        {pts.map((pt, i) => {
          const [x, y] = pt.split(',').map(Number)
          return (
            <circle
              key={i}
              cx={x}
              cy={y}
              r={counts[i] > 0 ? 2.5 : 1.5}
              fill={counts[i] > 0 ? '#0C447C' : '#ccc'}
            />
          )
        })}
      </svg>
      {/* Day labels */}
      <div className="flex justify-between mt-[2px]" style={{ width: W, paddingLeft: PAD, paddingRight: PAD }}>
        {dayLabels.map((l, i) => (
          <span key={i} className="text-[9px]" style={{ color: '#aaa', width: 20, textAlign: 'center', marginLeft: i === 0 ? 0 : -10 }}>
            {l}
          </span>
        ))}
      </div>
    </div>
  )
}

export function CHWModal({ chw, onClose }: { chw: CHW; onClose: () => void }) {
  const [summary, setSummary] = useState<Summary | null>(null)
  const [loadingAI, setLoadingAI] = useState(true)
  const [days, setDays] = useState<DayData[] | null>(null)

  useEffect(() => {
    fetch(`/api/chw/${chw.id}/weekly`)
      .then((r) => (r.ok ? r.json() : null))
      .then((d) => d && setDays(d.days))
      .catch(() => null)

    fetch('/api/ai/chw-summary', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ chwId: chw.id }),
    })
      .then((r) => (r.ok ? r.json() : null))
      .then((d) => d && setSummary(d))
      .catch(() => null)
      .finally(() => setLoadingAI(false))
  }, [chw.id])

  const initials = chw.name.split(' ').map((n) => n[0]).join('').slice(0, 2)

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center" style={{ background: 'rgba(0,0,0,0.4)' }}>
      <div className="rounded-[12px] w-[440px] max-h-[80vh] overflow-y-auto shadow-2xl" style={{ background: '#fff' }}>
        {/* Header */}
        <div className="flex items-center justify-between p-[16px_18px]" style={{ borderBottom: '1px solid #E5E5E5' }}>
          <div className="flex items-center gap-3">
            <div className="w-[40px] h-[40px] rounded-full flex items-center justify-center text-[14px] font-medium"
              style={{ background: '#E6F1FB', color: '#0C447C' }}>{initials}</div>
            <div>
              <div className="text-[14px] font-medium text-[#111]">{chw.name}</div>
              <div className="text-[11px] text-[#888]">{chw.employeeId} · {chw.blockName}</div>
            </div>
          </div>
          <button onClick={onClose} className="text-[#888] hover:text-[#333] text-[20px] leading-none">×</button>
        </div>

        <div className="p-[16px_18px] space-y-[12px]">
          {/* Stats row */}
          <div className="grid grid-cols-3 gap-2">
            <div className="rounded-[8px] p-[10px] text-center" style={{ background: '#f5f5f5' }}>
              <div className="text-[20px] font-medium text-[#111]">{chw.reportsCount}</div>
              <div className="text-[10px] text-[#888] mt-1">Total reports</div>
            </div>
            <div className="rounded-[8px] p-[10px] text-center" style={{ background: chw.active ? '#E1F5EE' : '#FAEEDA' }}>
              <div className="text-[13px] font-medium" style={{ color: chw.active ? '#085041' : '#633806' }}>
                {chw.active ? 'Online' : 'Offline'}
              </div>
              <div className="text-[10px] mt-1" style={{ color: chw.active ? '#085041' : '#633806' }}>Status</div>
            </div>
            <div className="rounded-[8px] p-[10px] text-center" style={{ background: '#f5f5f5' }}>
              <div className="text-[11px] font-medium text-[#111]">{chw.phone || '—'}</div>
              <div className="text-[10px] text-[#888] mt-1">Phone</div>
            </div>
          </div>

          {chw.lastSyncAt && (
            <div className="text-[10px]" style={{ color: '#aaa' }}>
              Last sync: {new Date(chw.lastSyncAt).toLocaleString()}
            </div>
          )}

          {/* 7-day sparkline */}
          <div className="rounded-[8px] p-[12px]" style={{ background: '#f5f5f5' }}>
            <div className="text-[11px] font-medium mb-[8px]" style={{ color: '#555' }}>
              Reports — last 7 days
            </div>
            {days ? (
              <Sparkline days={days} />
            ) : (
              <div className="h-[48px] rounded animate-pulse" style={{ background: '#e0e0e0' }} />
            )}
          </div>

          {/* Gemma AI summary */}
          <div className="rounded-[8px] p-[12px]" style={{ background: '#E6F1FB' }}>
            <div className="text-[11px] font-medium mb-[8px]" style={{ color: '#0C447C' }}>
              Gemma 4 · performance assessment
            </div>
            {loadingAI ? (
              <div className="space-y-2">
                {[85, 65, 75, 55].map((w, i) => (
                  <div key={i} className="h-[9px] rounded animate-pulse" style={{ background: '#B5D4F4', width: `${w}%` }} />
                ))}
              </div>
            ) : summary ? (
              <div className="space-y-[8px]">
                <p className="text-[11px] leading-[1.5]" style={{ color: '#0C447C' }}>{summary.performanceSummary}</p>
                <p className="text-[11px] leading-[1.5]" style={{ color: '#185FA5' }}>{summary.symptomPattern}</p>
                <div className="rounded-[6px] p-[7px] text-[10px]"
                  style={{ background: 'rgba(255,255,255,0.6)', color: '#0C447C' }}>
                  <span className="font-medium">Sync: </span>{summary.syncAlert}
                </div>
                <div className="rounded-[6px] p-[7px] text-[10px]"
                  style={{ background: '#0C447C', color: '#fff' }}>
                  <span className="font-medium">Recommendation: </span>{summary.recommendation}
                </div>
              </div>
            ) : (
              <div className="text-[11px]" style={{ color: '#888' }}>Gemma unavailable — check Ollama in Settings</div>
            )}
          </div>
        </div>
      </div>
    </div>
  )
}
