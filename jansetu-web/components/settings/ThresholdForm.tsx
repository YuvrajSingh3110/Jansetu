'use client'
import { useState } from 'react'

type SettingMap = Record<string, { value: string; label: string }>

const KEYS = [
  { key: 'outbreak_min_reports', label: 'Min. reports before AI runs', unit: 'cases', hint: 'Below this count, no AI analysis is triggered' },
  { key: 'outbreak_low_cases', label: 'Low-risk threshold', unit: 'cases', hint: 'Single village, mild symptoms' },
  { key: 'outbreak_medium_cases', label: 'Medium-risk threshold', unit: 'cases', hint: 'Multi-village pattern or elevated case count' },
  { key: 'outbreak_high_cases', label: 'High-risk threshold', unit: 'cases', hint: 'Immediate alert — possible outbreak' },
  { key: 'outbreak_window_hrs', label: 'Detection window', unit: 'hours', hint: 'Time window over which cases are aggregated' },
]

export function ThresholdForm({ settings }: { settings: SettingMap }) {
  const [values, setValues] = useState<Record<string, string>>(
    Object.fromEntries(KEYS.map((k) => [k.key, settings[k.key]?.value ?? '']))
  )
  const [saving, setSaving] = useState(false)
  const [saved, setSaved] = useState(false)
  const [error, setError] = useState<string | null>(null)

  async function handleSave() {
    setSaving(true)
    setSaved(false)
    setError(null)
    try {
      const res = await fetch('/api/settings', {
        method: 'PATCH',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(values),
      })
      if (!res.ok) throw new Error('Save failed')
      setSaved(true)
      setTimeout(() => setSaved(false), 3000)
    } catch {
      setError('Failed to save. Please try again.')
    } finally {
      setSaving(false)
    }
  }

  return (
    <div>
      <div className="space-y-[10px]">
        {KEYS.map(({ key, label, unit, hint }) => (
          <div key={key} className="flex items-start gap-[12px]">
            <div className="flex-1">
              <div className="text-[11px] font-medium text-[#333] mb-[1px]">{label}</div>
              <div className="text-[10px]" style={{ color: '#aaa' }}>{hint}</div>
            </div>
            <div className="flex items-center gap-[6px] flex-shrink-0">
              <input
                type="number"
                min="1"
                value={values[key] ?? ''}
                onChange={(e) => setValues((v) => ({ ...v, [key]: e.target.value }))}
                className="rounded-[6px] text-[12px] text-[#111] text-center outline-none"
                style={{
                  width: 64,
                  border: '1px solid #D0D0D0',
                  padding: '5px 8px',
                  background: '#FAFAFA',
                }}
              />
              <span className="text-[10px]" style={{ color: '#888', width: 40 }}>{unit}</span>
            </div>
          </div>
        ))}
      </div>

      <div className="flex items-center gap-[10px] mt-[14px]">
        <button
          onClick={handleSave}
          disabled={saving}
          className="text-[11px] font-medium px-[14px] py-[7px] rounded-[7px] transition-opacity"
          style={{ background: '#0C447C', color: '#fff', opacity: saving ? 0.6 : 1 }}
        >
          {saving ? 'Saving…' : 'Save thresholds'}
        </button>
        {saved && <span className="text-[11px]" style={{ color: '#1D9E75' }}>Saved</span>}
        {error && <span className="text-[11px]" style={{ color: '#E24B4A' }}>{error}</span>}
      </div>
    </div>
  )
}
