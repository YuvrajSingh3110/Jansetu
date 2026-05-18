import { getServerSession } from 'next-auth'
import { authOptions } from '@/lib/auth'
import { prisma } from '@/lib/prisma'
import { Topbar } from '@/components/layout/Topbar'
import { format } from 'date-fns'
import { CHWTable } from '@/components/chw/CHWTable'

export const dynamic = 'force-dynamic'

export default async function CHWPage() {
  const session = await getServerSession(authOptions)
  const districtId = (session?.user as any)?.districtId || 'dist001varanasi'

  const since24h = new Date(Date.now() - 86400000)

  const chws = await prisma.cHW.findMany({
    where: { block: { districtId } },
    include: { block: { select: { name: true } } },
    orderBy: { reportsCount: 'desc' },
  })

  const activeCount = chws.filter((c) => c.lastSyncAt && c.lastSyncAt >= since24h).length
  const notSyncedCount = chws.filter((c) => !c.lastSyncAt || c.lastSyncAt < since24h).length

  const chwData = chws.map((c) => ({
    id: c.id,
    name: c.name,
    employeeId: c.employeeId,
    phone: c.phone,
    reportsCount: c.reportsCount,
    lastSyncAt: c.lastSyncAt?.toISOString() || null,
    blockName: c.block.name,
    active: !!(c.lastSyncAt && c.lastSyncAt >= since24h),
  }))

  const maxReports = Math.max(...chws.map((c) => c.reportsCount), 1)

  return (
    <>
      <Topbar title="CHW network" subtitle="Community health worker monitoring" />
      <div className="flex-1 overflow-y-auto p-[14px_18px]">
        <div className="grid grid-cols-3 gap-[10px] mb-4">
          <div className="rounded-[10px] p-[12px_14px]" style={{ background: '#fff', border: '1px solid #E5E5E5' }}>
            <div className="text-[24px] font-medium text-[#1D9E75]">{activeCount}</div>
            <div className="text-[11px] text-[#888] mt-1">Active (synced &lt;24h)</div>
          </div>
          <div className="rounded-[10px] p-[12px_14px]" style={{ background: '#fff', border: '1px solid #E5E5E5' }}>
            <div className="text-[24px] font-medium text-[#EF9F27]">{notSyncedCount}</div>
            <div className="text-[11px] text-[#888] mt-1">Not synced 24h+</div>
          </div>
          <div className="rounded-[10px] p-[12px_14px]" style={{ background: '#fff', border: '1px solid #E5E5E5' }}>
            <div className="text-[24px] font-medium text-[#111]">{chws.length}</div>
            <div className="text-[11px] text-[#888] mt-1">Total CHWs</div>
          </div>
        </div>

        <CHWTable chws={chwData} maxReports={maxReports} />
      </div>
    </>
  )
}
