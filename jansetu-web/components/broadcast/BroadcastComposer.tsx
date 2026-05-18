'use client'
import { useState } from 'react'

interface BroadcastComposerProps {
  alertId?: string
  prefillVillage?: string
}

const BLOCKS = [
  { id: 'blk001rampur', label: 'Rampur block (5 CHWs)' },
  { id: 'blk002mau', label: 'Mau block (8 CHWs)' },
  { id: 'blk003khajuri', label: 'Khajuri block (6 CHWs)' },
]

export function BroadcastComposer({ alertId, prefillVillage }: BroadcastComposerProps) {
  const [selectedBlocks, setSelectedBlocks] = useState<string[]>(alertId ? ['blk001rampur'] : [])
  const [channel, setChannel] = useState<'app' | 'sms' | 'both'>('app')
  const [hindi, setHindi] = useState('')
  const [english, setEnglish] = useState('')
  const [drafting, setDrafting] = useState(false)
  const [sending, setSending] = useState(false)
  const [sent, setSent] = useState(false)
  const [showConfirm, setShowConfirm] = useState(false)

  const toggleBlock = (id: string) => {
    setSelectedBlocks((prev) =>
      prev.includes(id) ? prev.filter((b) => b !== id) : [...prev, id]
    )
  }

  const draftMessage = async () => {
    if (!alertId && !prefillVillage) return
    setDrafting(true)
    try {
      const res = await fetch('/api/broadcast/draft', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ alertId, village: prefillVillage }),
      })
      const data = await res.json()
      if (data.hindi) setHindi(data.hindi)
      if (data.english) setEnglish(data.english)
    } catch {
      setHindi('संदेश तैयार नहीं हो सका। कृपया मैन्युअल रूप से लिखें।')
      setEnglish('Could not generate message. Please write manually.')
    }
    setDrafting(false)
  }

  const sendBroadcast = async () => {
    if (!hindi || !english) return
    setSending(true)
    try {
      await fetch('/api/broadcast/send', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          alertId,
          targetType: 'block',
          targetIds: selectedBlocks,
          channel: channel === 'both' ? ['app', 'sms'] : [channel],
          messageHi: hindi,
          messageEn: english,
        }),
      })
      setSent(true)
      setShowConfirm(false)
    } finally {
      setSending(false)
    }
  }

  const estimatedReach = selectedBlocks.length * 1200

  if (sent) {
    return (
      <div className="text-center py-12">
        <div className="text-[24px] mb-2">✓</div>
        <div className="text-[13px] font-medium text-[#1D9E75]">Broadcast sent</div>
        <div className="text-[11px] text-[#888] mt-1">Message logged and delivered</div>
        <button
          className="mt-4 text-[11px] px-4 py-2 rounded-[7px]"
          style={{ background: '#E6F1FB', color: '#0C447C' }}
          onClick={() => { setSent(false); setHindi(''); setEnglish('') }}
        >
          Send another
        </button>
      </div>
    )
  }

  return (
    <div className="grid grid-cols-3 gap-[10px]">
      {/* Step 1: Targets */}
      <div className="rounded-[10px] p-[12px_14px]" style={{ background: '#fff', border: '1px solid #E5E5E5' }}>
        <div className="text-[12px] font-medium text-[#333] mb-[8px]">1. Select target areas</div>
        <div className="text-[10px] font-medium mb-[5px]" style={{ color: '#888' }}>Blocks</div>
        {BLOCKS.map((b) => (
          <label key={b.id} className="flex items-center gap-[6px] mb-[5px] cursor-pointer text-[11px] text-[#555]">
            <input type="checkbox" checked={selectedBlocks.includes(b.id)} onChange={() => toggleBlock(b.id)} />
            {b.label}
          </label>
        ))}

        <div className="h-[0.5px] my-[8px]" style={{ background: '#E5E5E5' }} />
        <div className="text-[10px] font-medium mb-[5px]" style={{ color: '#888' }}>Channel</div>
        {([['app', 'App push to CHW phones'], ['sms', 'SMS (104 gateway)'], ['both', 'Both']] as const).map(([val, label]) => (
          <label key={val} className="flex items-center gap-[6px] mb-[5px] cursor-pointer text-[11px] text-[#555]">
            <input type="radio" name="channel" checked={channel === val} onChange={() => setChannel(val)} />
            {label}
          </label>
        ))}

        {alertId && (
          <>
            <div className="h-[0.5px] my-[8px]" style={{ background: '#E5E5E5' }} />
            <div className="text-[10px] font-medium mb-[5px]" style={{ color: '#888' }}>Linked alert</div>
            <div className="text-[11px] text-[#555] truncate">Rampur cluster — ILI outbreak</div>
          </>
        )}
      </div>

      {/* Step 2: Message */}
      <div className="rounded-[10px] p-[12px_14px]" style={{ background: '#fff', border: '1px solid #E5E5E5' }}>
        <div className="text-[12px] font-medium text-[#333] mb-[8px]">2. AI-drafted message</div>
        <div
          className="rounded-[6px] p-[6px_9px] text-[10px] mb-[7px]"
          style={{ background: '#E6F1FB', color: '#0C447C' }}
        >
          Gemma 4 31B · {alertId ? 'generated from outbreak context' : 'manual draft'}
        </div>
        <button
          onClick={draftMessage}
          disabled={drafting || (!alertId && !prefillVillage)}
          className="w-full mb-2 py-1.5 rounded-[6px] text-[11px] font-medium transition-opacity disabled:opacity-50"
          style={{ background: '#E6F1FB', color: '#185FA5' }}
        >
          {drafting ? 'Generating…' : '✦ Generate AI draft'}
        </button>

        <div className="text-[10px] font-medium mb-1" style={{ color: '#555' }}>Hindi</div>
        <textarea
          value={hindi}
          onChange={(e) => setHindi(e.target.value)}
          className="w-full text-[11px] border border-[#E5E5E5] rounded-[8px] p-[10px] outline-none resize-none leading-[1.6] mb-2"
          style={{ minHeight: 70, color: '#444' }}
          placeholder="हिंदी संदेश यहाँ लिखें…"
          dir="auto"
        />
        <div className="text-[10px] font-medium mb-1" style={{ color: '#555' }}>English (for records)</div>
        <textarea
          value={english}
          onChange={(e) => setEnglish(e.target.value)}
          className="w-full text-[11px] border border-[#E5E5E5] rounded-[8px] p-[10px] outline-none resize-none leading-[1.6]"
          style={{ minHeight: 55, color: '#444' }}
          placeholder="English message here…"
        />
      </div>

      {/* Step 3: Preview + Send */}
      <div className="rounded-[10px] p-[12px_14px]" style={{ background: '#fff', border: '1px solid #E5E5E5' }}>
        <div className="text-[12px] font-medium text-[#333] mb-[8px]">3. Preview + send</div>

        <div className="rounded-[8px] p-[10px] mb-[8px]" style={{ background: '#f9f9f9' }}>
          <div className="text-[10px] font-medium text-[#333] mb-[4px]">Summary</div>
          <div className="text-[11px] leading-[1.6]" style={{ color: '#555' }}>
            Sending to: <strong>{selectedBlocks.length * 5} CHWs</strong><br />
            Channel: <strong>{channel === 'both' ? 'App + SMS' : channel === 'app' ? 'App push' : 'SMS'}</strong><br />
            Estimated reach: <strong>~{estimatedReach.toLocaleString()} people</strong><br />
            {alertId && <>Linked alert: <strong>Rampur cluster</strong></>}
          </div>
        </div>

        <button
          onClick={() => setShowConfirm(true)}
          disabled={!hindi || !english || selectedBlocks.length === 0}
          className="w-full py-[10px] rounded-[8px] text-center text-[12px] font-medium text-white mb-[6px] transition-opacity disabled:opacity-50"
          style={{ background: '#0C447C' }}
        >
          Send broadcast now
        </button>

        <div
          className="rounded-[7px] p-[8px]"
          style={{ background: '#E1F5EE' }}
        >
          <div className="text-[10px] leading-[1.5]" style={{ color: '#085041' }}>
            All AI-generated messages are logged. You can edit before sending. SMS via 104 gateway is free.
          </div>
        </div>
      </div>

      {/* Confirm modal */}
      {showConfirm && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40">
          <div className="bg-white rounded-[12px] p-6 w-[340px] shadow-xl">
            <div className="text-[14px] font-medium text-[#111] mb-2">Confirm broadcast</div>
            <div className="text-[12px] text-[#666] mb-4 leading-[1.5]">
              This will send a message to ~{estimatedReach.toLocaleString()} people via {channel === 'both' ? 'App + SMS' : channel}. This action cannot be undone.
            </div>
            <div className="flex gap-2">
              <button
                onClick={() => setShowConfirm(false)}
                className="flex-1 py-2 rounded-[7px] text-[12px] font-medium"
                style={{ border: '1px solid #E5E5E5', color: '#555' }}
              >
                Cancel
              </button>
              <button
                onClick={sendBroadcast}
                disabled={sending}
                className="flex-1 py-2 rounded-[7px] text-[12px] font-medium text-white disabled:opacity-60"
                style={{ background: '#E24B4A' }}
              >
                {sending ? 'Sending…' : 'Send now'}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}
