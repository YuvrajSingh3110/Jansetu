import { getServerSession } from 'next-auth'
import { authOptions } from '@/lib/auth'
import { prisma } from '@/lib/prisma'
import { startOfDay } from 'date-fns'
import { Topbar } from '@/components/layout/Topbar'
import { StatCard } from '@/components/dashboard/StatCard'
import { AlertCard } from '@/components/dashboard/AlertCard'
import { ReportsFeed } from '@/components/dashboard/ReportsFeed'
import { AIBriefing } from '@/components/dashboard/AIBriefing'

export const dynamic = 'force-dynamic'

async function getDashboardData(districtId: string) {
  const today = startOfDay(new Date())
  const since24h = new Date(Date.now() - 86400000)
  const since7d = new Date(Date.now() - 7 * 86400000)

  const [reportsToday, activeAlerts, activeCHWs, totalVillages, alerts, recentReports, symptomReports] =
    await Promise.all([
      prisma.report.count({ where: { syncedAt: { gte: today }, village: { block: { districtId } } } }),
      prisma.alert.count({ where: { districtId, status: 'active' } }),
      prisma.cHW.count({ where: { block: { districtId }, lastSyncAt: { gte: since24h } } }),
      prisma.village.count({ where: { block: { districtId } } }),
      prisma.alert.findMany({
        where: { districtId, status: 'active' },
        orderBy: [{ type: 'asc' }, { createdAt: 'desc' }],
        take: 5,
      }),
      prisma.report.findMany({
        where: { syncedAt: { gte: since24h }, village: { block: { districtId } } },
        include: { village: true },
        orderBy: { syncedAt: 'desc' },
        take: 10,
      }),
      prisma.report.findMany({
        where: { syncedAt: { gte: since7d }, village: { block: { districtId } } },
        select: { symptoms: true },
      }),
    ])

  const symCounts: Record<string, number> = {}
  for (const r of symptomReports) {
    for (const s of r.symptoms) {
      symCounts[s] = (symCounts[s] || 0) + 1
    }
  }
  const topSymptoms = Object.entries(symCounts)
    .sort((a, b) => b[1] - a[1])
    .slice(0, 5)
    .map(([name, count]) => ({ name, count }))

  const chwActivity = await prisma.cHW.findMany({
    where: { block: { districtId }, isActive: true },
    orderBy: { reportsCount: 'desc' },
    take: 3,
    select: { id: true, name: true, reportsCount: true, lastSyncAt: true },
  })

  return {
    reportsToday,
    activeAlerts,
    activeCHWs,
    totalVillages,
    alerts: alerts.map((a) => ({
      id: a.id, type: a.type, confidence: a.confidence, title: a.title,
      description: a.description, caseCount: a.caseCount,
      createdAt: a.createdAt.toISOString(),
      affectedVillages: a.affectedVillages,
    })),
    feedItems: recentReports.map((r) => ({
      id: r.id, village: r.village.name, ageGroup: r.ageGroup,
      gender: r.gender, symptoms: r.symptoms,
      severity: r.severity, referral: r.referral,
      syncedAt: r.syncedAt.toISOString(),
    })),
    topSymptoms,
    chwActivity: chwActivity.map((c) => ({
      id: c.id, name: c.name, reportsCount: c.reportsCount,
      lastSyncAt: c.lastSyncAt?.toISOString() || null,
    })),
  }
}

export default async function DashboardPage() {
  const session = await getServerSession(authOptions)
  const districtId = (session?.user as any)?.districtId || 'dist001varanasi'
  const data = await getDashboardData(districtId)

  const maxCHW = Math.max(...data.chwActivity.map((c) => c.reportsCount), 1)
  const maxSym = Math.max(...data.topSymptoms.map((s) => s.count), 1)

  const symColors: Record<string, string> = {
    fever: '#E24B4A', cough: '#378ADD', diarrhoea: '#EF9F27',
    rash: '#7F77DD', malnutrition: '#EF9F27', breathlessness: '#E24B4A',
  }

  return (
    <>
      <Topbar title="District overview" activeAlerts={data.activeAlerts} chwOnline={data.activeCHWs} />
      <div className="flex-1 overflow-y-auto p-[14px_18px]">
        <div className="grid grid-cols-4 gap-[10px] mb-[12px]">
          <StatCard num={data.reportsToday} label="Reports today" delta="+32 vs yesterday" deltaColor="#1D9E75" />
          <StatCard num={data.activeAlerts} label="Active outbreaks"
            delta={data.activeAlerts > 0 ? 'Needs response' : 'All clear'}
            numColor={data.activeAlerts > 0 ? '#A32D2D' : '#1D9E75'}
            deltaColor={data.activeAlerts > 0 ? '#A32D2D' : '#1D9E75'} />
          <StatCard num={data.totalVillages} label="Villages covered" delta="of 78 in district" deltaColor="#888" />
          <StatCard num={`${Math.round((data.activeCHWs / Math.max(data.activeCHWs + 3, 1)) * 100)}%`}
            label="CHW sync rate" delta="Good coverage" deltaColor="#1D9E75" />
        </div>

        <AIBriefing />

        <div className="grid gap-[10px]" style={{ gridTemplateColumns: '1fr 320px' }}>
          <div>
            <div className="rounded-[10px] p-[12px_14px] mb-[10px]" style={{ background: '#fff', border: '1px solid #E5E5E5' }}>
              <div className="text-[12px] font-medium text-[#333] mb-[8px]">Active alerts</div>
              {data.alerts.length === 0
                ? <div className="text-[11px] text-gray-400 py-2">No active alerts</div>
                : data.alerts.map((a) => (
                  <AlertCard key={a.id} id={a.id} type={a.type} confidence={a.confidence}
                    title={a.title} description={a.description} caseCount={a.caseCount}
                    createdAt={a.createdAt} affectedVillages={a.affectedVillages} />
                ))}
            </div>

            <div className="rounded-[10px] p-[12px_14px]" style={{ background: '#fff', border: '1px solid #E5E5E5' }}>
              <div className="text-[12px] font-medium text-[#333] mb-[8px]">Symptom trends (7 days)</div>
              {data.topSymptoms.map((s) => (
                <div key={s.name} className="flex items-center gap-[8px] mb-[6px]">
                  <div className="text-[11px] text-[#555]" style={{ width: 90, flexShrink: 0 }}>
                    {s.name.charAt(0).toUpperCase() + s.name.slice(1)}
                  </div>
                  <div className="flex-1 h-[5px] rounded-[3px]" style={{ background: '#f0f0f0' }}>
                    <div className="h-full rounded-[3px] transition-all"
                      style={{ width: `${(s.count / maxSym) * 100}%`, background: symColors[s.name] || '#185FA5' }} />
                  </div>
                  <div className="text-[11px] w-[25px] text-right" style={{ color: '#888' }}>{s.count}</div>
                </div>
              ))}
              {data.topSymptoms.length === 0 && <div className="text-[11px] text-gray-400">No data</div>}
            </div>
          </div>

          <div>
            <div className="rounded-[10px] p-[12px_14px] mb-[10px]" style={{ background: '#fff', border: '1px solid #E5E5E5' }}>
              <div className="flex items-center gap-2 mb-[8px]">
                <div className="text-[12px] font-medium text-[#333]">Live feed</div>
                <span className="live-dot w-2 h-2 rounded-full" style={{ background: '#1D9E75', display: 'inline-block' }} />
              </div>
              <ReportsFeed districtId={districtId} initial={data.feedItems} />
            </div>

            <div className="rounded-[10px] p-[12px_14px]" style={{ background: '#fff', border: '1px solid #E5E5E5' }}>
              <div className="text-[12px] font-medium text-[#333] mb-[8px]">CHW activity</div>
              {data.chwActivity.map((c) => {
                const initials = c.name.split(' ').map((n) => n[0]).join('').slice(0, 2)
                return (
                  <div key={c.id} className="flex items-center gap-[8px] py-[5px]" style={{ borderBottom: '1px solid #f5f5f5' }}>
                    <div className="w-[24px] h-[24px] rounded-full flex items-center justify-center text-[10px] font-medium flex-shrink-0"
                      style={{ background: '#E6F1FB', color: '#0C447C' }}>{initials}</div>
                    <div className="flex-1">
                      <div className="text-[11px] font-medium text-[#222]">{c.name}</div>
                      <div className="h-[3px] bg-[#f0f0f0] rounded-[2px] mt-[3px]">
                        <div className="h-full rounded-[2px]"
                          style={{ width: `${(c.reportsCount / maxCHW) * 100}%`, background: c.reportsCount >= 8 ? '#1D9E75' : '#EF9F27' }} />
                      </div>
                    </div>
                    <span className="text-[10px]" style={{ color: '#888' }}>{c.reportsCount}</span>
                  </div>
                )
              })}
            </div>
          </div>
        </div>
      </div>
    </>
  )
}
