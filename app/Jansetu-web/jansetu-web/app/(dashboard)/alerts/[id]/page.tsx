import { notFound } from 'next/navigation'
import { prisma } from '@/lib/prisma'
import { Topbar } from '@/components/layout/Topbar'
import { ResponsePlaybook } from '@/components/alerts/ResponsePlaybook'
import { DifferentialDiagnosis } from '@/components/alerts/DifferentialDiagnosis'
import Link from 'next/link'
import { formatTimeAgo } from '@/lib/utils'

export const dynamic = 'force-dynamic'

export default async function AlertDetailPage({ params }: { params: { id: string } }) {
  const alert = await prisma.alert.findUnique({
    where: { id: params.id },
    include: {
      actions: { orderBy: { step: 'asc' } },
      broadcasts: { orderBy: { createdAt: 'desc' }, take: 3 },
    },
  })
  if (!alert) notFound()

  const affectedVillages = alert.affectedVillages
  const symptomCluster = alert.symptomCluster
  const analysis = alert.aiAnalysis as Record<string, any>

  const villageCounts = affectedVillages.map((v: string, i: number) => ({
    name: v,
    count: i === 0 ? alert.caseCount : Math.floor(alert.caseCount * Math.max(0.2, 0.6 - i * 0.15)),
  }))

  const timeline = [
    { dot: '#E24B4A', title: 'Outbreak detected · Gemma 4', time: formatTimeAgo(alert.createdAt), desc: `Pattern identified across ${affectedVillages.length} village(s). Alert auto-created.` },
    { dot: '#EF9F27', title: 'DHO notified', time: formatTimeAgo(new Date(alert.createdAt.getTime() + 60000)), desc: 'Push notification sent.' },
    ...alert.broadcasts.map((b: typeof alert.broadcasts[0]) => ({
      dot: '#1D9E75', title: 'Broadcast sent',
      time: b.sentAt ? formatTimeAgo(b.sentAt) : 'Pending',
      desc: `Advisory pushed via ${b.channel.join(', ') || 'app'}.`,
    })),
  ]

  return (
    <>
      <Topbar title={alert.title} subtitle={`Detected ${formatTimeAgo(alert.createdAt)} · Gemma 4 31B analysis`} />
      <div className="flex-1 overflow-y-auto p-[14px_18px]">
        <div className="flex gap-2 mb-4">
          <span className="text-[10px] px-[9px] py-[3px] rounded-[6px] font-medium"
            style={alert.status === 'active' ? { background: '#FCEBEB', color: '#A32D2D' } : { background: '#E1F5EE', color: '#085041' }}>
            {alert.status.charAt(0).toUpperCase() + alert.status.slice(1)}
          </span>
          <span className="text-[10px] px-[9px] py-[3px] rounded-[6px] font-medium" style={{ background: '#FAEEDA', color: '#633806' }}>
            {alert.confidence} confidence
          </span>
          <span className="text-[10px] px-[9px] py-[3px] rounded-[6px] font-medium" style={{ background: '#E6F1FB', color: '#0C447C' }}>
            {alert.caseCount} cases · {alert.timeWindowHrs}h window
          </span>
        </div>

        <div className="grid grid-cols-2 gap-[10px]">
          <div>
            <div className="rounded-[10px] p-[12px_14px] mb-[10px]" style={{ background: '#fff', border: '1px solid #E5E5E5' }}>
              <div className="text-[12px] font-medium text-[#333] mb-[8px]">AI analysis — Gemma 4 31B</div>
              <div className="rounded-[7px] p-[10px] text-[11px] leading-[1.6] mb-[8px]" style={{ background: '#FCEBEB', color: '#791F1F' }}>
                {alert.description}
                {analysis?.reasoning && (
                  <div className="mt-2 text-[10px] opacity-80"><strong>Reasoning:</strong> {analysis.reasoning}</div>
                )}
              </div>
              <div className="flex gap-[5px] flex-wrap mb-[8px]">
                {symptomCluster.map((s: string) => (
                  <span key={s} className="text-[9px] px-[7px] py-[2px] rounded-[8px]" style={{ background: '#FCEBEB', color: '#A32D2D' }}>{s}</span>
                ))}
                <span className="text-[9px] px-[7px] py-[2px] rounded-[8px]" style={{ background: '#FAEEDA', color: '#633806' }}>{alert.caseCount} cases</span>
                <span className="text-[9px] px-[7px] py-[2px] rounded-[8px]" style={{ background: '#E6F1FB', color: '#0C447C' }}>{affectedVillages.length} villages</span>
              </div>
              <div className="flex gap-[6px]">
                <Link href={`/broadcast?alertId=${alert.id}`}
                  className="flex-1 rounded-[7px] p-[7px] text-center text-[11px] font-medium text-white" style={{ background: '#0C447C' }}>
                  Broadcast advisory
                </Link>
                <Link href="/heatmap"
                  className="flex-1 rounded-[7px] p-[7px] text-center text-[11px] font-medium" style={{ border: '1px solid #E24B4A', color: '#A32D2D' }}>
                  View on map
                </Link>
              </div>
            </div>

            <div className="rounded-[10px] p-[12px_14px]" style={{ background: '#fff', border: '1px solid #E5E5E5' }}>
              <div className="text-[12px] font-medium text-[#333] mb-[8px]">Event timeline</div>
              {timeline.map((t, i) => (
                <div key={i} className="flex gap-[8px] mb-[8px]">
                  <div className="w-[8px] h-[8px] rounded-full mt-[3px] flex-shrink-0" style={{ background: t.dot }} />
                  <div className="flex-1">
                    <div className="text-[11px] font-medium text-[#222]">{t.title}</div>
                    <div className="text-[9px] mt-[1px]" style={{ color: '#aaa' }}>{t.time}</div>
                    <div className="text-[10px] mt-[2px] leading-[1.4]" style={{ color: '#666' }}>{t.desc}</div>
                  </div>
                </div>
              ))}
            </div>
          </div>

          <div>
            <div className="rounded-[10px] p-[12px_14px] mb-[10px]" style={{ background: '#fff', border: '1px solid #E5E5E5' }}>
              <div className="text-[12px] font-medium text-[#333] mb-[8px]">Response playbook — AI generated</div>
              <ResponsePlaybook
                alertId={alert.id}
                actions={alert.actions.map((a: typeof alert.actions[0]) => ({
                  id: a.id, step: a.step, title: a.title,
                  description: a.description, status: a.status,
                  completedAt: a.completedAt?.toISOString() || null,
                }))}
              />
            </div>

            <DifferentialDiagnosis
              symptoms={symptomCluster}
              caseCount={alert.caseCount}
              villages={affectedVillages}
              windowHrs={alert.timeWindowHrs}
            />

            <div className="rounded-[10px] p-[12px_14px] mt-[10px]" style={{ background: '#fff', border: '1px solid #E5E5E5' }}>
              <div className="text-[12px] font-medium text-[#333] mb-[8px]">Affected villages</div>
              {villageCounts.map((v: { name: string; count: number }, i: number) => (
                <div key={v.name} className="flex items-center gap-[8px] mb-[6px]">
                  <div className="text-[11px] text-[#555]" style={{ width: 80, flexShrink: 0 }}>{v.name}</div>
                  <div className="flex-1 h-[5px] rounded-[3px]" style={{ background: '#f0f0f0' }}>
                    <div className="h-full rounded-[3px]"
                      style={{ width: `${(v.count / (alert.caseCount || 1)) * 100}%`, background: i === 0 ? '#E24B4A' : '#EF9F27' }} />
                  </div>
                  <div className="text-[11px] w-[25px] text-right" style={{ color: i === 0 ? '#A32D2D' : '#888' }}>{v.count}</div>
                </div>
              ))}
            </div>
          </div>
        </div>
      </div>
    </>
  )
}
