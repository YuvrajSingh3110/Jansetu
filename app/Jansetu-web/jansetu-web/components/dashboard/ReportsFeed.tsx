'use client'
import { useEffect, useState } from 'react'
import { format } from 'date-fns'

interface FeedItem {
  id: string
  village: string
  ageGroup: string
  gender: string
  symptoms: string[]
  severity: string
  referral: boolean
  syncedAt: string
}

interface ReportsFeedProps {
  districtId: string
  initial: FeedItem[]
}

function severityDot(severity: string) {
  if (severity === 'severe') return '#E24B4A'
  if (severity === 'moderate') return '#EF9F27'
  return '#1D9E75'
}

function formatItem(item: FeedItem) {
  const g = item.gender === 'M' ? 'M' : item.gender === 'F' ? 'F' : '?'
  const a = item.ageGroup === 'child' ? 'child' : item.ageGroup === 'elderly' ? 'elderly' : 'adult'
  const syms = item.symptoms.slice(0, 3).join(', ')
  const ref = item.referral ? ' · referred PHC' : ''
  return `${g} / ${a} · ${item.village} · ${syms}${ref}`
}

export function ReportsFeed({ districtId, initial }: ReportsFeedProps) {
  const [items, setItems] = useState<FeedItem[]>(initial)

  useEffect(() => {
    const es = new EventSource(`/api/alerts/stream?districtId=${districtId}`)
    es.onmessage = (e) => {
      try {
        const alert = JSON.parse(e.data)
        const synth: FeedItem = {
          id: alert.id,
          village: alert.affectedVillages?.[0] || 'Unknown',
          ageGroup: 'adult',
          gender: 'unknown',
          symptoms: alert.symptomCluster || [],
          severity: alert.type === 'outbreak' ? 'severe' : 'moderate',
          referral: false,
          syncedAt: alert.createdAt,
        }
        setItems((prev) => [synth, ...prev].slice(0, 10))
      } catch {}
    }
    return () => es.close()
  }, [districtId])

  return (
    <div>
      {items.slice(0, 6).map((item, i) => (
        <div
          key={item.id + i}
          className="flex items-start gap-[8px] py-[7px]"
          style={{ borderBottom: '1px solid #f5f5f5' }}
        >
          <div
            className="rounded-full mt-1 flex-shrink-0 live-dot"
            style={{ width: 7, height: 7, background: severityDot(item.severity) }}
          />
          <div className="text-[11px] flex-1 leading-[1.4]" style={{ color: '#444' }}>
            {formatItem(item)}
          </div>
          <div className="text-[10px] flex-shrink-0" style={{ color: '#aaa' }}>
            {format(new Date(item.syncedAt), 'HH:mm')}
          </div>
        </div>
      ))}
      {items.length === 0 && (
        <div className="text-[11px] text-gray-400 py-4 text-center">No recent reports</div>
      )}
    </div>
  )
}
