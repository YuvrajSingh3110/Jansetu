'use client'
import { format, subDays } from 'date-fns'

interface TimelineSliderProps {
  days: number
  onChange: (days: number) => void
}

export function TimelineSlider({ days, onChange }: TimelineSliderProps) {
  const start = subDays(new Date(), days)
  const end = new Date()

  return (
    <div className="bg-white rounded-[10px] p-[10px_14px]" style={{ border: '1px solid #E5E5E5' }}>
      <div className="flex items-center justify-between mb-2">
        <div className="text-[11px] font-medium text-[#333]">Time range</div>
        <div className="text-[10px]" style={{ color: '#888' }}>
          {format(start, 'MMM d')} – {format(end, 'MMM d, yyyy')}
        </div>
      </div>
      <input
        type="range"
        min={1}
        max={30}
        value={days}
        onChange={(e) => onChange(parseInt(e.target.value))}
        className="w-full accent-[#185FA5]"
        style={{ accentColor: '#185FA5' }}
      />
      <div className="flex justify-between text-[9px] mt-1" style={{ color: '#aaa' }}>
        <span>1 day</span>
        <span>15 days</span>
        <span>30 days</span>
      </div>
    </div>
  )
}
