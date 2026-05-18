import { Topbar } from '@/components/layout/Topbar'
import { BroadcastComposer } from '@/components/broadcast/BroadcastComposer'

export default function BroadcastPage({
  searchParams,
}: {
  searchParams: { alertId?: string; village?: string }
}) {
  return (
    <>
      <Topbar
        title="Broadcast health advisory"
        subtitle="Gemma 4 drafts · you review · you send"
      />
      <div className="flex-1 overflow-y-auto p-[14px_18px]">
        <BroadcastComposer
          alertId={searchParams.alertId}
          prefillVillage={searchParams.village}
        />
      </div>
    </>
  )
}
