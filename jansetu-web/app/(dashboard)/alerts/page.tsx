import { getServerSession } from 'next-auth'
import { authOptions } from '@/lib/auth'
import { prisma } from '@/lib/prisma'
import { Topbar } from '@/components/layout/Topbar'
import Link from 'next/link'
import { formatTimeAgo } from '@/lib/utils'

export const dynamic = 'force-dynamic'

const TABS = [
  { label: 'Active', value: 'active' },
  { label: 'Responding', value: 'responding' },
  { label: 'Resolved', value: 'resolved' },
  { label: 'All', value: 'all' },
]

export default async function AlertsPage({ searchParams }: { searchParams: { tab?: string } }) {
  const session = await getServerSession(authOptions)
  const districtId = (session?.user as any)?.districtId || 'dist001varanasi'
  const tab = searchParams.tab || 'active'

  const alerts = await prisma.alert.findMany({
    where: { districtId, ...(tab !== 'all' ? { status: tab } : {}) },
    include: { actions: true },
    orderBy: { createdAt: 'desc' },
  })

  return (
    <>
      <Topbar title="Alerts" subtitle="Disease outbreak monitoring" />
      <div className="flex-1 overflow-y-auto p-[14px_18px]">
        <div className="flex gap-1 mb-4">
          {TABS.map((t) => (
            <Link key={t.value} href={`/alerts?tab=${t.value}`}
              className="text-[11px] px-3 py-1.5 rounded-lg font-medium transition-colors"
              style={tab === t.value
                ? { background: '#185FA5', color: '#fff' }
                : { background: '#fff', color: '#555', border: '1px solid #E5E5E5' }}>
              {t.label}
            </Link>
          ))}
        </div>

        <div className="space-y-3">
          {alerts.map((alert) => {
            const isOutbreak = alert.type === 'outbreak'
            const style = isOutbreak
              ? { bg: '#FCEBEB', color: '#A32D2D' }
              : { bg: '#FAEEDA', color: '#633806' }
            const doneCount = alert.actions.filter((a) => a.status === 'done').length
            const villages = alert.affectedVillages

            return (
              <Link key={alert.id} href={`/alerts/${alert.id}`}
                className="block rounded-[10px] p-[14px] hover:shadow-sm transition-shadow"
                style={{ background: '#fff', border: '1px solid #E5E5E5' }}>
                <div className="flex items-start justify-between gap-3">
                  <div className="flex-1">
                    <div className="flex items-center gap-2 flex-wrap mb-1">
                      <span className="text-[10px] px-[7px] py-[2px] rounded-[5px] font-medium"
                        style={{ background: style.bg, color: style.color }}>
                        {isOutbreak ? 'Outbreak' : 'Watch'}
                      </span>
                      <span className="text-[10px] px-[7px] py-[2px] rounded-[5px] font-medium"
                        style={{ background: '#E6F1FB', color: '#0C447C' }}>
                        {alert.confidence} confidence
                      </span>
                      <span className="text-[10px]" style={{ color: '#aaa' }}>
                        {formatTimeAgo(alert.createdAt)}
                      </span>
                    </div>
                    <div className="text-[13px] font-medium text-[#111]">{alert.title}</div>
                    <div className="text-[11px] text-[#666] mt-1 leading-[1.5]">
                      {alert.description.slice(0, 120)}…
                    </div>
                    <div className="flex gap-3 mt-2 text-[10px] text-[#888]">
                      <span>{alert.caseCount} cases</span>
                      <span>{villages.join(', ')}</span>
                      {alert.actions.length > 0 && (
                        <span>{doneCount}/{alert.actions.length} steps done</span>
                      )}
                    </div>
                  </div>
                  <div className="text-[10px] px-[7px] py-[2px] rounded-[5px] font-medium flex-shrink-0"
                    style={{ background: '#f5f5f5', color: '#666' }}>
                    {alert.status}
                  </div>
                </div>
              </Link>
            )
          })}
          {alerts.length === 0 && (
            <div className="text-center py-12 text-[13px] text-gray-400">
              No {tab === 'all' ? '' : tab} alerts
            </div>
          )}
        </div>
      </div>
    </>
  )
}
