'use client'
import { useSession, signOut } from 'next-auth/react'
import { format } from 'date-fns'

interface TopbarProps {
  title: string
  subtitle?: string
  activeAlerts?: number
  chwOnline?: number
}

export function Topbar({ title, subtitle, activeAlerts = 0, chwOnline = 0 }: TopbarProps) {
  const { data: session } = useSession()
  const now = new Date()

  return (
    <div
      className="flex items-center justify-between flex-shrink-0 px-[18px]"
      style={{
        height: 56,
        background: '#fff',
        borderBottom: '1px solid #E5E5E5',
      }}
    >
      <div>
        <div className="text-[14px] font-medium text-[#111]">{title}</div>
        {subtitle ? (
          <div className="text-[11px] text-[#888] mt-[1px]">{subtitle}</div>
        ) : (
          <div className="text-[11px] text-[#888] mt-[1px]">
            {format(now, 'MMM d, yyyy')} · {format(now, 'HH:mm')} ·{' '}
            <span className="text-[#1D9E75] font-medium">Live</span>
          </div>
        )}
      </div>

      <div className="flex items-center gap-2">
        {activeAlerts > 0 && (
          <span
            className="text-[10px] px-[9px] py-[3px] rounded-[6px] font-medium"
            style={{ background: '#FCEBEB', color: '#A32D2D' }}
          >
            {activeAlerts} active alert{activeAlerts !== 1 ? 's' : ''}
          </span>
        )}
        {chwOnline > 0 && (
          <span
            className="text-[10px] px-[9px] py-[3px] rounded-[6px] font-medium"
            style={{ background: '#E1F5EE', color: '#085041' }}
          >
            {chwOnline} CHWs online
          </span>
        )}
        <button
          onClick={() => signOut({ callbackUrl: '/login' })}
          className="text-[10px] px-[9px] py-[3px] rounded-[6px] font-medium cursor-pointer"
          style={{ background: '#E6F1FB', color: '#0C447C' }}
        >
          {session?.user?.name || 'Officer'}
        </button>
      </div>
    </div>
  )
}
