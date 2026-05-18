'use client'
import { useState, useCallback, useEffect } from 'react'
import { Topbar } from '@/components/layout/Topbar'
import DistrictMap from '@/components/map/DistrictMap'
import { VillagePanel } from '@/components/map/VillagePanel'
import { TimelineSlider } from '@/components/map/TimelineSlider'

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

const SYMPTOM_CHIPS = [
  { label: 'All', value: '' },
  { label: 'Fever', value: 'fever' },
  { label: 'Cough', value: 'cough' },
  { label: 'Diarrhoea', value: 'diarrhoea' },
  { label: 'Rash', value: 'rash' },
  { label: 'Malnutrition', value: 'malnutrition' },
  { label: 'Breathlessness', value: 'breathlessness' },
]

export default function HeatmapPage() {
  const [villages, setVillages] = useState<VillageData[]>([])
  const [selected, setSelected] = useState<VillageData | null>(null)
  const [days, setDays] = useState(7)
  const [symptom, setSymptom] = useState('')
  const [loading, setLoading] = useState(false)

  const fetchHeatmap = useCallback(
    async (d: number, s: string) => {
      setLoading(true)
      try {
        const params = new URLSearchParams({
          days: String(d),
          districtId: 'dist001varanasi',
          ...(s ? { symptom: s } : {}),
        })
        const res = await fetch(`/api/analytics/heatmap?${params}`)
        const data = await res.json()
        setVillages(data.villages || [])
      } catch {}
      setLoading(false)
    },
    []
  )

  useEffect(() => {
    fetchHeatmap(days, symptom)
  }, [days, symptom, fetchHeatmap])

  const totalCases = villages.reduce((s, v) => s + v.caseCount, 0)
  const outbreakCount = villages.filter((v) => v.riskLevel === 'high').length
  const sorted = [...villages].sort((a, b) => b.caseCount - a.caseCount)
  const maxCount = Math.max(...sorted.map((v) => v.caseCount), 1)

  return (
    <>
      <Topbar title="Symptom heatmap" subtitle="All villages · Varanasi district" />
      <div className="flex-1 overflow-hidden flex flex-col p-[14px_18px] gap-[10px]">
        {/* Symptom chips */}
        <div className="flex items-center gap-2 flex-wrap">
          {SYMPTOM_CHIPS.map((chip) => (
            <button
              key={chip.value}
              onClick={() => setSymptom(chip.value)}
              className="text-[10px] px-[9px] py-[3px] rounded-[6px] font-medium transition-colors"
              style={
                symptom === chip.value
                  ? { background: '#FCEBEB', color: '#A32D2D' }
                  : { background: '#f0f0f0', color: '#666' }
              }
            >
              {chip.label}
            </button>
          ))}
        </div>

        {/* Timeline */}
        <TimelineSlider days={days} onChange={(d) => { setDays(d); fetchHeatmap(d, symptom) }} />

        {/* Map + sidebar */}
        <div className="flex-1 flex gap-[10px] min-h-0">
          {/* Map */}
          <div className="flex-1 relative rounded-[10px] overflow-hidden" style={{ border: '1px solid #E5E5E5' }}>
            {loading && (
              <div className="absolute inset-0 z-10 flex items-center justify-center bg-white/60 rounded-[10px]">
                <div className="text-[11px] text-gray-500">Loading…</div>
              </div>
            )}

            <DistrictMap villages={villages} onVillageClick={setSelected} />

            {/* Legend */}
            <div
              className="absolute top-2 left-2 rounded-[7px] p-[6px_8px] z-[1000]"
              style={{ background: 'rgba(255,255,255,0.95)', boxShadow: '0 1px 4px rgba(0,0,0,0.1)' }}
            >
              {[
                { color: '#E24B4A', label: 'Outbreak (high)' },
                { color: '#EF9F27', label: 'Watch (medium)' },
                { color: '#1D9E75', label: 'Normal (low)' },
              ].map((l) => (
                <div key={l.label} className="flex items-center gap-[5px] text-[10px] text-[#333] mb-[3px] last:mb-0">
                  <div className="w-[10px] h-[10px] rounded-full" style={{ background: l.color }} />
                  {l.label}
                </div>
              ))}
            </div>

            {/* Village drill-down panel */}
            {selected && (
              <VillagePanel village={selected} days={days} onClose={() => setSelected(null)} />
            )}
          </div>

          {/* Right sidebar */}
          <div className="w-[240px] flex flex-col gap-[10px]">
            {/* Village ranking */}
            <div
              className="rounded-[10px] p-[12px_14px]"
              style={{ background: '#fff', border: '1px solid #E5E5E5', flex: 1, overflowY: 'auto' }}
            >
              <div className="text-[12px] font-medium text-[#333] mb-[8px]">Village ranking</div>
              {sorted.slice(0, 8).map((v) => (
                <div
                  key={v.id}
                  className="flex items-center gap-[8px] mb-[6px] cursor-pointer"
                  onClick={() => setSelected(v)}
                >
                  <div className="text-[11px] text-[#555]" style={{ width: 70, flexShrink: 0 }}>
                    {v.name}
                  </div>
                  <div className="flex-1 h-[5px] rounded-[3px]" style={{ background: '#f0f0f0' }}>
                    <div
                      className="h-full rounded-[3px]"
                      style={{
                        width: `${(v.caseCount / maxCount) * 100}%`,
                        background: v.riskLevel === 'high' ? '#E24B4A' : v.riskLevel === 'medium' ? '#EF9F27' : '#1D9E75',
                      }}
                    />
                  </div>
                  <div
                    className="text-[11px] w-[20px] text-right"
                    style={{ color: v.riskLevel === 'high' ? '#A32D2D' : '#888' }}
                  >
                    {v.caseCount}
                  </div>
                </div>
              ))}
              {villages.length === 0 && (
                <div className="text-[11px] text-gray-400">No data</div>
              )}
            </div>

            {/* District totals */}
            <div
              className="rounded-[10px] p-[12px_14px]"
              style={{ background: '#fff', border: '1px solid #E5E5E5' }}
            >
              <div className="text-[12px] font-medium text-[#333] mb-[8px]">District totals</div>
              <div className="grid grid-cols-2 gap-[6px]">
                <div className="rounded-[7px] p-[8px] text-center" style={{ background: '#f5f5f5' }}>
                  <div className="text-[18px] font-medium text-[#111]">{totalCases}</div>
                  <div className="text-[10px] text-[#888] mt-1">Total cases</div>
                </div>
                <div className="rounded-[7px] p-[8px] text-center" style={{ background: '#FCEBEB' }}>
                  <div className="text-[18px] font-medium" style={{ color: '#A32D2D' }}>{outbreakCount}</div>
                  <div className="text-[10px] mt-1" style={{ color: '#A32D2D' }}>Outbreak zones</div>
                </div>
                <div className="rounded-[7px] p-[8px] text-center" style={{ background: '#f5f5f5' }}>
                  <div className="text-[18px] font-medium text-[#111]">{villages.filter(v => v.caseCount > 0).length}</div>
                  <div className="text-[10px] text-[#888] mt-1">Villages active</div>
                </div>
                <div className="rounded-[7px] p-[8px] text-center" style={{ background: '#E1F5EE' }}>
                  <div className="text-[18px] font-medium" style={{ color: '#085041' }}>{days}d</div>
                  <div className="text-[10px] mt-1" style={{ color: '#085041' }}>Window</div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </>
  )
}
