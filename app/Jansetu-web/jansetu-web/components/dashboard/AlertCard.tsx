'use client'
import Link from 'next/link'
import { formatTimeAgo } from '@/lib/utils'

interface AlertCardProps {
  id: string
  type: string
  confidence: string
  title: string
  description: string
  caseCount: number
  createdAt: string | Date
  affectedVillages: string[]
}

export function AlertCard({
  id,
  type,
  confidence,
  title,
  description,
  caseCount,
  createdAt,
  affectedVillages,
}: AlertCardProps) {
  const isOutbreak = type === 'outbreak'

  const colors = isOutbreak
    ? { bg: '#FCEBEB', border: '#E24B4A', titleColor: '#A32D2D', bodyColor: '#791F1F', btnPrimary: '#E24B4A', btnSecBorder: '#F09595', btnSecColor: '#A32D2D' }
    : { bg: '#FAEEDA', border: '#BA7517', titleColor: '#633806', bodyColor: '#854F0B', btnPrimary: '#BA7517', btnSecBorder: '#ddd', btnSecColor: '#666' }

  return (
    <div
      className="rounded-[8px] p-[10px_12px] mb-[7px]"
      style={{
        background: colors.bg,
        borderLeft: `3px solid ${colors.border}`,
      }}
    >
      <div className="text-[12px] font-medium" style={{ color: colors.titleColor }}>
        {isOutbreak ? 'Outbreak' : 'Watch'} · {confidence.charAt(0).toUpperCase() + confidence.slice(1)} confidence · {title}
      </div>
      <div className="text-[11px] leading-[1.5] mt-[3px]" style={{ color: colors.bodyColor }}>
        {description}
      </div>
      <div className="text-[10px] mt-1" style={{ color: colors.titleColor }}>
        {caseCount} cases · {affectedVillages.join(', ')} · {formatTimeAgo(createdAt)}
      </div>
      <div className="flex gap-[5px] mt-[6px] flex-wrap">
        <Link
          href={`/alerts/${id}`}
          className="text-[10px] px-[9px] py-[3px] rounded-[5px] font-medium text-white"
          style={{ background: colors.btnPrimary }}
        >
          {isOutbreak ? 'Deploy team' : 'Monitor'}
        </Link>
        <Link
          href={`/heatmap`}
          className="text-[10px] px-[9px] py-[3px] rounded-[5px] font-medium"
          style={{ background: '#fff', color: colors.btnSecColor, border: `1px solid ${colors.btnSecBorder}` }}
        >
          View on map
        </Link>
        <Link
          href={`/broadcast?alertId=${id}`}
          className="text-[10px] px-[9px] py-[3px] rounded-[5px] font-medium"
          style={{ background: '#fff', color: colors.btnSecColor, border: `1px solid ${colors.btnSecBorder}` }}
        >
          Broadcast
        </Link>
      </div>
    </div>
  )
}
