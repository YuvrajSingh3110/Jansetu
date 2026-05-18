import { getServerSession } from 'next-auth'
import { authOptions } from '@/lib/auth'
import { prisma } from '@/lib/prisma'
import { Topbar } from '@/components/layout/Topbar'
import { format } from 'date-fns'
export const dynamic = 'force-dynamic'
const PAGE_SIZE = 25

export default async function ReportsPage({
  searchParams,
}: {
  searchParams: { villageId?: string; symptom?: string; source?: string; severity?: string; page?: string }
}) {
  const session = await getServerSession(authOptions)
  const districtId = (session?.user as any)?.districtId || 'dist001varanasi'

  const page = parseInt(searchParams.page || '1')
  const skip = (page - 1) * PAGE_SIZE

  const baseWhere: any = {
    village: { block: { districtId } },
    ...(searchParams.villageId ? { villageId: searchParams.villageId } : {}),
    ...(searchParams.source ? { sourceType: searchParams.source } : {}),
    ...(searchParams.severity ? { severity: searchParams.severity } : {}),
  }

  const [allReports, villages] = await Promise.all([
    prisma.report.findMany({
      where: baseWhere,
      include: { village: true, chw: { select: { name: true, employeeId: true } } },
      orderBy: { syncedAt: 'desc' },
    }),
    prisma.village.findMany({
      where: { block: { districtId } },
      select: { id: true, name: true },
      orderBy: { name: 'asc' },
    }),
  ])

  // Filter by symptom in-memory (SQLite doesn't support array contains)
  const filtered = searchParams.symptom
    ? allReports.filter((r) => r.symptoms.includes(searchParams.symptom!))
    : allReports

  const total = filtered.length
  const reports = filtered.slice(skip, skip + PAGE_SIZE)
  const totalPages = Math.ceil(total / PAGE_SIZE)

  const SYMPTOMS = ['fever', 'cough', 'diarrhoea', 'rash', 'breathlessness', 'headache', 'vomiting']

  const pillStyle = (type: string) =>
    type === 'chw' ? { bg: '#E6F1FB', color: '#0C447C' } : { bg: '#E1F5EE', color: '#085041' }

  const sevStyle = (sev: string) => {
    if (sev === 'severe') return { bg: '#FCEBEB', color: '#A32D2D' }
    if (sev === 'moderate') return { bg: '#FAEEDA', color: '#633806' }
    return { bg: '#E1F5EE', color: '#085041' }
  }

  return (
    <>
      <Topbar title="All reports" subtitle={`${total} total · page ${page} of ${Math.max(totalPages, 1)}`} />
      <div className="flex-1 overflow-y-auto p-[14px_18px]">
        <div className="flex gap-2 mb-4 flex-wrap items-center">
          <form className="flex gap-2 flex-wrap">
            <select name="villageId" defaultValue={searchParams.villageId || ''}
              className="text-[11px] border border-[#E5E5E5] rounded-[6px] px-2 py-1.5 bg-white text-[#555]">
              <option value="">All villages</option>
              {villages.map((v) => <option key={v.id} value={v.id}>{v.name}</option>)}
            </select>
            <select name="symptom" defaultValue={searchParams.symptom || ''}
              className="text-[11px] border border-[#E5E5E5] rounded-[6px] px-2 py-1.5 bg-white text-[#555]">
              <option value="">All symptoms</option>
              {SYMPTOMS.map((s) => <option key={s} value={s}>{s}</option>)}
            </select>
            <select name="source" defaultValue={searchParams.source || ''}
              className="text-[11px] border border-[#E5E5E5] rounded-[6px] px-2 py-1.5 bg-white text-[#555]">
              <option value="">All sources</option>
              <option value="chw">CHW</option>
              <option value="village_user">Village user</option>
            </select>
            <select name="severity" defaultValue={searchParams.severity || ''}
              className="text-[11px] border border-[#E5E5E5] rounded-[6px] px-2 py-1.5 bg-white text-[#555]">
              <option value="">All severity</option>
              <option value="mild">Mild</option>
              <option value="moderate">Moderate</option>
              <option value="severe">Severe</option>
            </select>
            <button type="submit" className="text-[11px] px-3 py-1.5 rounded-[6px] font-medium text-white" style={{ background: '#185FA5' }}>
              Filter
            </button>
          </form>
          <a
            href={`/api/reports/export?${new URLSearchParams({
              ...(searchParams.villageId ? { villageId: searchParams.villageId } : {}),
              ...(searchParams.symptom ? { symptom: searchParams.symptom } : {}),
              ...(searchParams.source ? { source: searchParams.source } : {}),
              ...(searchParams.severity ? { severity: searchParams.severity } : {}),
            }).toString()}`}
            className="text-[11px] px-3 py-1.5 rounded-[6px] font-medium"
            style={{ background: '#fff', border: '1px solid #E5E5E5', color: '#555' }}
          >
            ↓ Export CSV
          </a>
        </div>

        <div className="rounded-[10px] overflow-hidden" style={{ background: '#fff', border: '1px solid #E5E5E5' }}>
          <table className="w-full border-collapse" style={{ fontSize: 11 }}>
            <thead>
              <tr style={{ borderBottom: '1px solid #E5E5E5' }}>
                {['Time', 'Village', 'Source', 'Patient', 'Symptoms', 'Severity', 'Referral'].map((h) => (
                  <th key={h} className="text-left px-[8px] py-[6px] font-medium" style={{ color: '#888', fontSize: 10 }}>{h}</th>
                ))}
              </tr>
            </thead>
            <tbody>
              {reports.map((r) => {
                const ps = pillStyle(r.sourceType)
                const ss = sevStyle(r.severity)
                const syms = r.symptoms
                return (
                  <tr key={r.id} style={{ borderBottom: '1px solid #f5f5f5' }}>
                    <td className="px-[8px] py-[6px] text-[#444]">{format(r.syncedAt, 'HH:mm')}</td>
                    <td className="px-[8px] py-[6px] text-[#444]">{r.village.name}</td>
                    <td className="px-[8px] py-[6px]">
                      <span className="text-[9px] px-[7px] py-[2px] rounded-[8px] font-medium" style={{ background: ps.bg, color: ps.color }}>
                        {r.sourceType === 'chw' ? 'CHW' : 'Village'}
                      </span>
                    </td>
                    <td className="px-[8px] py-[6px] text-[#444]">{r.gender} / {r.ageGroup}</td>
                    <td className="px-[8px] py-[6px]">
                      <div className="flex flex-wrap gap-[2px]">
                        {syms.slice(0, 3).map((s) => (
                          <span key={s} className="text-[9px] px-[6px] py-[1px] rounded-[8px]" style={{ background: '#FCEBEB', color: '#A32D2D' }}>{s}</span>
                        ))}
                      </div>
                    </td>
                    <td className="px-[8px] py-[6px]">
                      <span className="text-[9px] px-[6px] py-[1px] rounded-[8px] font-medium" style={{ background: ss.bg, color: ss.color }}>{r.severity}</span>
                    </td>
                    <td className="px-[8px] py-[6px]">
                      <span className="text-[9px] px-[6px] py-[1px] rounded-[8px]"
                        style={r.referral ? { background: '#FCEBEB', color: '#A32D2D' } : { background: '#E1F5EE', color: '#085041' }}>
                        {r.referral ? 'Yes' : 'No'}
                      </span>
                    </td>
                  </tr>
                )
              })}
              {reports.length === 0 && (
                <tr><td colSpan={7} className="px-[8px] py-[24px] text-center text-[#aaa] text-[11px]">No reports found</td></tr>
              )}
            </tbody>
          </table>

          <div className="flex items-center justify-between px-[14px] py-[10px]" style={{ borderTop: '1px solid #f5f5f5' }}>
            <div className="text-[11px]" style={{ color: '#888' }}>
              Showing {skip + 1}–{Math.min(skip + PAGE_SIZE, total)} of {total}
            </div>
            <div className="flex gap-1">
              {page > 1 && (
                <a href={`/reports?page=${page - 1}`} className="px-[8px] py-[4px] rounded-[5px] text-[11px] text-[#555]" style={{ border: '1px solid #E5E5E5' }}>← Prev</a>
              )}
              {page < totalPages && (
                <a href={`/reports?page=${page + 1}`} className="px-[8px] py-[4px] rounded-[5px] text-[11px] text-white" style={{ background: '#0C447C' }}>Next →</a>
              )}
            </div>
          </div>
        </div>
      </div>
    </>
  )
}
