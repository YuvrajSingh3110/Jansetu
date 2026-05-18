import { getServerSession } from 'next-auth'
import { authOptions } from '@/lib/auth'
import { prisma } from '@/lib/prisma'
import { Topbar } from '@/components/layout/Topbar'
import { OllamaStatus } from '@/components/settings/OllamaStatus'
import { ThresholdForm } from '@/components/settings/ThresholdForm'

export const dynamic = 'force-dynamic'

export default async function SettingsPage() {
  const session = await getServerSession(authOptions)
  const districtId = (session?.user as any)?.districtId || 'dist001varanasi'

  const [district, officers, dbSettings] = await Promise.all([
    prisma.district.findUnique({ where: { id: districtId } }),
    prisma.officer.findMany({
      where: { districtId },
      select: { id: true, name: true, email: true, role: true, createdAt: true },
    }),
    prisma.setting.findMany({ orderBy: { key: 'asc' } }),
  ])

  const settingsMap = Object.fromEntries(dbSettings.map((s) => [s.key, { value: s.value, label: s.label }]))

  return (
    <>
      <Topbar title="Settings" subtitle="District configuration" />
      <div className="flex-1 overflow-y-auto p-[14px_18px]">
        <div className="grid grid-cols-2 gap-[10px] max-w-3xl">
          {/* District profile */}
          <div className="rounded-[10px] p-[14px]" style={{ background: '#fff', border: '1px solid #E5E5E5' }}>
            <div className="text-[12px] font-medium text-[#333] mb-[10px]">District profile</div>
            <div className="space-y-2">
              <div>
                <div className="text-[10px] text-[#888] mb-1">District name</div>
                <div className="text-[13px] font-medium text-[#111]">{district?.name}</div>
              </div>
              <div>
                <div className="text-[10px] text-[#888] mb-1">State</div>
                <div className="text-[13px] text-[#333]">{district?.state}</div>
              </div>
              <div>
                <div className="text-[10px] text-[#888] mb-1">District ID</div>
                <div className="text-[11px] font-mono text-[#666]">{districtId}</div>
              </div>
            </div>
          </div>

          {/* Ollama status */}
          <OllamaStatus />

          {/* Officers */}
          <div
            className="col-span-2 rounded-[10px] p-[14px]"
            style={{ background: '#fff', border: '1px solid #E5E5E5' }}
          >
            <div className="text-[12px] font-medium text-[#333] mb-[10px]">Officers</div>
            <table className="w-full border-collapse" style={{ fontSize: 11 }}>
              <thead>
                <tr style={{ borderBottom: '1px solid #E5E5E5' }}>
                  {['Name', 'Email', 'Role', 'Joined'].map((h) => (
                    <th key={h} className="text-left px-[8px] py-[5px] font-medium" style={{ color: '#888', fontSize: 10 }}>
                      {h}
                    </th>
                  ))}
                </tr>
              </thead>
              <tbody>
                {officers.map((o) => (
                  <tr key={o.id} style={{ borderBottom: '1px solid #f5f5f5' }}>
                    <td className="px-[8px] py-[7px] text-[#222] font-medium">{o.name}</td>
                    <td className="px-[8px] py-[7px] text-[#555]">{o.email}</td>
                    <td className="px-[8px] py-[7px]">
                      <span className="text-[9px] px-[6px] py-[2px] rounded-[5px] font-medium uppercase"
                        style={{ background: '#E6F1FB', color: '#0C447C' }}>
                        {o.role}
                      </span>
                    </td>
                    <td className="px-[8px] py-[7px] text-[#888]">
                      {new Date(o.createdAt).toLocaleDateString()}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>

          {/* Alert thresholds — editable */}
          <div
            className="col-span-2 rounded-[10px] p-[14px]"
            style={{ background: '#fff', border: '1px solid #E5E5E5' }}
          >
            <div className="text-[12px] font-medium text-[#333] mb-[4px]">Detection thresholds</div>
            <div className="text-[11px] mb-[12px]" style={{ color: '#888' }}>
              Controls when Gemma triggers disease alerts. Changes take effect on the next sync or detection run.
            </div>
            <ThresholdForm settings={settingsMap} />
            <div className="text-[10px] mt-3" style={{ color: '#aaa' }}>
              AI model: Gemma 3 27B via Google AI Studio · Detection runs every 2 hours + on every Android sync
            </div>
          </div>
        </div>
      </div>
    </>
  )
}
