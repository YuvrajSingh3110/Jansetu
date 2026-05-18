'use client'
import Link from 'next/link'
import { usePathname } from 'next/navigation'
import {
  LayoutDashboard,
  AlertTriangle,
  Map,
  FileText,
  Users,
  Megaphone,
  Activity,
  Settings,
  Zap,
} from 'lucide-react'

interface NavItem {
  href: string
  label: string
  icon: React.ReactNode
  badge?: number
  color?: string
}

interface NavSection {
  label?: string
  items: NavItem[]
}

export function Sidebar({ alertCount = 0 }: { alertCount?: number }) {
  const pathname = usePathname()

  const sections: NavSection[] = [
    {
      items: [
        { href: '/dashboard', label: 'Dashboard', icon: <LayoutDashboard size={14} /> },
        {
          href: '/alerts',
          label: 'Alerts',
          icon: <AlertTriangle size={14} />,
          badge: alertCount,
          color: 'red',
        },
        { href: '/heatmap', label: 'Heatmap', icon: <Map size={14} />, color: 'green' },
        { href: '/reports', label: 'Reports', icon: <FileText size={14} /> },
      ],
    },
    {
      label: 'Response',
      items: [
        { href: '/alerts', label: 'Deploy teams', icon: <Zap size={14} />, color: 'amber' },
        { href: '/broadcast', label: 'Broadcast', icon: <Megaphone size={14} /> },
      ],
    },
    {
      label: 'Network',
      items: [
        { href: '/chw', label: 'CHW status', icon: <Activity size={14} />, color: 'green' },
        { href: '/settings', label: 'Settings', icon: <Settings size={14} /> },
      ],
    },
  ]

  const iconBg = (color?: string) => {
    if (color === 'red') return 'rgba(226,75,74,0.6)'
    if (color === 'green') return 'rgba(29,158,117,0.6)'
    if (color === 'amber') return 'rgba(239,159,39,0.5)'
    return 'rgba(255,255,255,0.2)'
  }

  return (
    <aside
      className="flex-shrink-0 flex flex-col"
      style={{ width: 220, background: '#0C447C', minHeight: '100vh' }}
    >
      {/* Logo */}
      <div className="px-[14px] py-[16px] pb-[12px]" style={{ borderBottom: '1px solid rgba(255,255,255,0.1)' }}>
        <div className="text-[15px] font-medium text-white tracking-[-0.3px]">Jansetu</div>
        <div className="text-[10px] mt-[2px]" style={{ color: '#85B7EB' }}>
          Varanasi District
        </div>
      </div>

      {/* Nav */}
      <nav className="flex-1 px-[8px] py-[10px]">
        {sections.map((section, si) => (
          <div key={si}>
            {section.label && (
              <div
                className="text-[9px] uppercase tracking-[0.06em] mx-[6px] mb-[4px] mt-[10px]"
                style={{ color: '#85B7EB' }}
              >
                {section.label}
              </div>
            )}
            {section.items.map((item) => {
              const active = pathname === item.href || (item.href !== '/dashboard' && pathname.startsWith(item.href))
              return (
                <Link
                  key={item.href + item.label}
                  href={item.href}
                  className="flex items-center gap-[8px] px-[8px] py-[7px] rounded-[7px] mb-[1px] transition-colors"
                  style={{
                    background: active ? 'rgba(255,255,255,0.15)' : 'transparent',
                  }}
                >
                  <span
                    className="flex items-center justify-center rounded-[4px] flex-shrink-0"
                    style={{
                      width: 16,
                      height: 16,
                      background: iconBg(item.color),
                    }}
                  >
                    <span style={{ color: 'white', opacity: 0.9 }}>{item.icon}</span>
                  </span>
                  <span
                    className="text-[11px] flex-1"
                    style={{
                      color: active ? '#fff' : '#B5D4F4',
                      fontWeight: active ? 500 : 400,
                    }}
                  >
                    {item.label}
                  </span>
                  {item.badge != null && item.badge > 0 && (
                    <span
                      className="text-white text-[9px] px-[5px] py-[1px] rounded-[8px]"
                      style={{ background: '#E24B4A' }}
                    >
                      {item.badge}
                    </span>
                  )}
                </Link>
              )
            })}
          </div>
        ))}
      </nav>
    </aside>
  )
}
