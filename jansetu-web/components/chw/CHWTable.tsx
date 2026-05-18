'use client'
import { useState } from 'react'
import { format } from 'date-fns'
import { CHWModal } from './CHWModal'

type CHW = {
  id: string
  name: string
  employeeId: string
  phone: string | null
  reportsCount: number
  lastSyncAt: string | null
  blockName: string
  active: boolean
}

export function CHWTable({ chws, maxReports }: { chws: CHW[]; maxReports: number }) {
  const [selected, setSelected] = useState<CHW | null>(null)

  return (
    <>
      <div className="rounded-[10px] overflow-hidden" style={{ background: '#fff', border: '1px solid #E5E5E5' }}>
        <table className="w-full border-collapse" style={{ fontSize: 11 }}>
          <thead>
            <tr style={{ borderBottom: '1px solid #E5E5E5' }}>
              {['CHW', 'Block', 'Reports total', 'Last sync', 'Status', ''].map((h) => (
                <th key={h} className="text-left px-[12px] py-[8px] font-medium" style={{ color: '#888', fontSize: 10 }}>
                  {h}
                </th>
              ))}
            </tr>
          </thead>
          <tbody>
            {chws.map((chw) => {
              const initials = chw.name.split(' ').map((n) => n[0]).join('').slice(0, 2)
              return (
                <tr key={chw.id} className="hover:bg-[#fafafa] cursor-pointer"
                  style={{ borderBottom: '1px solid #f5f5f5' }}
                  onClick={() => setSelected(chw)}>
                  <td className="px-[12px] py-[8px]">
                    <div className="flex items-center gap-2">
                      <div className="w-[28px] h-[28px] rounded-full flex items-center justify-center text-[10px] font-medium flex-shrink-0"
                        style={{ background: '#E6F1FB', color: '#0C447C' }}>{initials}</div>
                      <div>
                        <div className="text-[11px] font-medium text-[#222]">{chw.name}</div>
                        <div className="text-[10px] text-[#aaa]">{chw.employeeId}</div>
                      </div>
                    </div>
                  </td>
                  <td className="px-[12px] py-[8px] text-[#555]">{chw.blockName}</td>
                  <td className="px-[12px] py-[8px]">
                    <div className="flex items-center gap-2">
                      <div className="flex-1 h-[3px] rounded-[2px]" style={{ background: '#f0f0f0', width: 60 }}>
                        <div className="h-full rounded-[2px]"
                          style={{ width: `${(chw.reportsCount / maxReports) * 100}%`, background: chw.reportsCount >= 8 ? '#1D9E75' : '#EF9F27' }} />
                      </div>
                      <span className="text-[10px] text-[#888]">{chw.reportsCount}</span>
                    </div>
                  </td>
                  <td className="px-[12px] py-[8px] text-[#555]">
                    {chw.lastSyncAt ? format(new Date(chw.lastSyncAt), 'MMM d, HH:mm') : 'Never'}
                  </td>
                  <td className="px-[12px] py-[8px]">
                    <span className="text-[9px] px-[6px] py-[2px] rounded-[5px] font-medium"
                      style={chw.active ? { background: '#E1F5EE', color: '#085041' } : { background: '#FAEEDA', color: '#633806' }}>
                      {chw.active ? 'Online' : 'Offline'}
                    </span>
                  </td>
                  <td className="px-[12px] py-[8px]">
                    <span className="text-[10px]" style={{ color: '#185FA5' }}>AI insight →</span>
                  </td>
                </tr>
              )
            })}
          </tbody>
        </table>
      </div>

      {selected && <CHWModal chw={selected} onClose={() => setSelected(null)} />}
    </>
  )
}
