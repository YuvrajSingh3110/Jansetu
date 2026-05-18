'use client'
import Link from 'next/link'
import { useState, useEffect } from 'react'

interface VillageData {
  id: string
  name: string
  block: string
  lat: number
  lng: number
  caseCount: number
  topSymptom: string | null
  symptomCounts: Record<string, number>
  riskLevel: 'high' | 'medium' | 'low'
}

interface VillagePanelProps {
  village: VillageData | null
  days: number
  onClose: () => void
}

type Insight = {
  narrative: string
  riskAssessment: string
  recommendation: string
}

const riskColors = {
  high: { bg: '#FCEBEB', text: '#A32D2D', label: 'High risk' },
  medium: { bg: '#FAEEDA', text: '#633806', label: 'Watch' },
  low: { bg: '#E1F5EE', text: '#085041', label: 'Normal' },
}

export function VillagePanel({ village, days, onClose }: VillagePanelProps) {
  const [insight, setInsight] = useState<Insight | null>(null)
  const [loadingInsight, setLoadingInsight] = useState(false)

  useEffect(() => {
    if (!village) return
    setInsight(null)
    setLoadingInsight(true)
    fetch('/api/ai/village-insight', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        villageName: village.name,
        blockName: village.block,
        symptomCounts: village.symptomCounts,
        totalCases: village.caseCount,
        days,
      }),
    })
      .then((r) => (r.ok ? r.json() : null))
      .then((data) => data && setInsight(data))
      .catch(() => null)
      .finally(() => setLoadingInsight(false))
  }, [village?.id])

  if (!village) return null

  const rc = riskColors[village.riskLevel]
  const symptoms = Object.entries(village.symptomCounts).sort((a, b) => b[1] - a[1])
  const maxCount = Math.max(...symptoms.map((s) => s[1]), 1)

  return (
    <div
      className="absolute right-0 top-0 bottom-0 w-[260px] overflow-y-auto shadow-xl"
      style={{ background: '#fff', borderLeft: '1px solid #E5E5E5', zIndex: 1000 }}
    >
      <div className="flex items-center justify-between p-[12px_14px]" style={{ borderBottom: '1px solid #E5E5E5' }}>
        <div>
          <div className="text-[13px] font-medium text-[#111]">{village.name}</div>
          <div className="text-[10px] text-[#888] mt-0.5">{village.block}</div>
        </div>
        <button onClick={onClose} className="text-[#888] hover:text-[#333] text-[16px] leading-none">×</button>
      </div>

      <div className="p-[12px_14px]">
        <span className="text-[10px] px-[8px] py-[2px] rounded-[6px] font-medium" style={{ background: rc.bg, color: rc.text }}>
          {rc.label}
        </span>

        <div className="grid grid-cols-2 gap-2 mt-3">
          <div className="rounded-[8px] p-[8px] text-center" style={{ background: '#f5f5f5' }}>
            <div className="text-[18px] font-medium text-[#111]">{village.caseCount}</div>
            <div className="text-[10px] text-[#888] mt-1">Total cases</div>
          </div>
          <div className="rounded-[8px] p-[8px] text-center" style={{ background: '#f5f5f5' }}>
            <div className="text-[14px] font-medium text-[#111]">{village.topSymptom || '—'}</div>
            <div className="text-[10px] text-[#888] mt-1">Top symptom</div>
          </div>
        </div>

        {symptoms.length > 0 && (
          <div className="mt-3">
            <div className="text-[11px] font-medium text-[#333] mb-2">Symptom breakdown</div>
            {symptoms.slice(0, 6).map(([s, n]) => (
              <div key={s} className="flex items-center gap-2 mb-1.5">
                <div className="text-[10px] text-[#555]" style={{ width: 80, flexShrink: 0 }}>{s}</div>
                <div className="flex-1 h-[4px] rounded-[2px]" style={{ background: '#f0f0f0' }}>
                  <div className="h-full rounded-[2px]" style={{ width: `${(n / maxCount) * 100}%`, background: '#185FA5' }} />
                </div>
                <div className="text-[10px]" style={{ color: '#888' }}>{n}</div>
              </div>
            ))}
          </div>
        )}

        {/* Gemma AI insight */}
        <div className="mt-3 rounded-[8px] p-[10px]" style={{ background: '#E6F1FB' }}>
          <div className="text-[10px] font-medium mb-[6px]" style={{ color: '#0C447C' }}>
            Gemma 4 · health assessment
          </div>
          {loadingInsight ? (
            <div className="space-y-1.5">
              {[90, 70, 80].map((w, i) => (
                <div key={i} className="h-[8px] rounded animate-pulse" style={{ background: '#B5D4F4', width: `${w}%` }} />
              ))}
            </div>
          ) : insight ? (
            <div className="space-y-[6px]">
              <div className="text-[10px] leading-[1.5]" style={{ color: '#0C447C' }}>{insight.narrative}</div>
              <div className="text-[10px] leading-[1.4] font-medium" style={{ color: '#0C447C', opacity: 0.8 }}>
                {insight.riskAssessment}
              </div>
              <div className="text-[10px] leading-[1.4] pt-[4px]" style={{ color: '#185FA5', borderTop: '1px solid #B5D4F4' }}>
                → {insight.recommendation}
              </div>
            </div>
          ) : (
            <div className="text-[10px]" style={{ color: '#888' }}>Insight unavailable — check Ollama connection</div>
          )}
        </div>

        <div className="flex flex-col gap-2 mt-4">
          <Link href={`/reports?villageId=${village.id}`}
            className="w-full py-2 rounded-[7px] text-[11px] font-medium text-center"
            style={{ background: '#f5f5f5', color: '#0C447C' }}>
            View reports
          </Link>
          <Link href={`/broadcast?village=${village.name}`}
            className="w-full py-2 rounded-[7px] text-[11px] font-medium text-center"
            style={{ background: '#0C447C', color: '#fff' }}>
            Create broadcast
          </Link>
        </div>
      </div>
    </div>
  )
}
