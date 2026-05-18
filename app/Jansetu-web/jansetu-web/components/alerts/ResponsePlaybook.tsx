'use client'
import { useState } from 'react'

interface Action {
  id: string
  step: number
  title: string
  description: string
  status: string
  completedAt?: string | null
}

interface ResponsePlaybookProps {
  alertId: string
  actions: Action[]
}

const STATUS_CYCLE: Record<string, string> = {
  pending: 'in_progress',
  in_progress: 'done',
  done: 'pending',
}

const STATUS_STYLE: Record<string, { bg: string; color: string; numBg: string }> = {
  pending: { bg: '#FCEBEB', color: '#A32D2D', numBg: '#E24B4A' },
  in_progress: { bg: '#FAEEDA', color: '#633806', numBg: '#EF9F27' },
  done: { bg: '#E1F5EE', color: '#085041', numBg: '#1D9E75' },
}

export function ResponsePlaybook({ alertId, actions: initial }: ResponsePlaybookProps) {
  const [actions, setActions] = useState<Action[]>(initial)
  const [loading, setLoading] = useState<string | null>(null)

  const tick = async (action: Action) => {
    const next = STATUS_CYCLE[action.status] || 'pending'
    setLoading(action.id)
    try {
      const res = await fetch(`/api/alerts/${alertId}/actions/${action.id}`, {
        method: 'PATCH',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ status: next }),
      })
      if (res.ok) {
        setActions((prev) =>
          prev.map((a) => (a.id === action.id ? { ...a, status: next } : a))
        )
      }
    } finally {
      setLoading(null)
    }
  }

  return (
    <div>
      {actions.map((action) => {
        const s = STATUS_STYLE[action.status] || STATUS_STYLE.pending
        return (
          <div
            key={action.id}
            className="rounded-[7px] p-[8px_10px] mb-[5px] flex gap-[8px] cursor-pointer hover:opacity-90 transition-opacity"
            style={{ background: '#f9f9f9' }}
            onClick={() => loading !== action.id && tick(action)}
            title="Click to advance status"
          >
            <div
              className="w-[20px] h-[20px] rounded-full flex items-center justify-center text-[10px] font-medium flex-shrink-0 text-white"
              style={{ background: s.numBg }}
            >
              {action.step}
            </div>
            <div className="flex-1">
              <div className="text-[11px] font-medium text-[#222]">{action.title}</div>
              <div className="text-[10px] text-[#777] mt-[2px]">{action.description}</div>
              <span
                className="text-[9px] px-[6px] py-[2px] rounded-[5px] mt-1 inline-block font-medium"
                style={{ background: s.bg, color: s.color }}
              >
                {loading === action.id ? 'Saving…' : action.status === 'in_progress' ? 'In progress' : action.status.charAt(0).toUpperCase() + action.status.slice(1)}
              </span>
            </div>
          </div>
        )
      })}
    </div>
  )
}
