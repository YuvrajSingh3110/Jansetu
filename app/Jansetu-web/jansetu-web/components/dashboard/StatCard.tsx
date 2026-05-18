interface StatCardProps {
  num: string | number
  label: string
  delta?: string
  deltaColor?: string
  numColor?: string
}

export function StatCard({ num, label, delta, deltaColor = '#888', numColor = '#111' }: StatCardProps) {
  return (
    <div
      className="rounded-[10px] p-[12px_14px]"
      style={{ background: '#fff', border: '1px solid #E5E5E5' }}
    >
      <div className="text-[24px] font-medium leading-none" style={{ color: numColor }}>
        {num}
      </div>
      <div className="text-[11px] mt-1" style={{ color: '#888' }}>
        {label}
      </div>
      {delta && (
        <div className="text-[10px] mt-1" style={{ color: deltaColor }}>
          {delta}
        </div>
      )}
    </div>
  )
}
