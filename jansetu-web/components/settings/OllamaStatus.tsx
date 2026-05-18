'use client'
import { useState } from 'react'

export function OllamaStatus() {
  const [status, setStatus] = useState<'idle' | 'checking' | 'ok' | 'error'>('idle')

  const check = async () => {
    setStatus('checking')
    try {
      const res = await fetch('/api/internal/detect-outbreak', {
        method: 'GET',
      })
      setStatus(res.ok ? 'ok' : 'error')
    } catch {
      setStatus('error')
    }
  }

  return (
    <div className="rounded-[10px] p-[14px]" style={{ background: '#fff', border: '1px solid #E5E5E5' }}>
      <div className="text-[12px] font-medium text-[#333] mb-[10px]">Ollama connection</div>
      <div className="space-y-2">
        <div>
          <div className="text-[10px] text-[#888] mb-1">Endpoint</div>
          <div className="text-[11px] font-mono text-[#555]">http://localhost:11434</div>
        </div>
        <div>
          <div className="text-[10px] text-[#888] mb-1">Model</div>
          <div className="text-[11px] font-mono text-[#555]">gemma4:31b</div>
        </div>
        <div className="flex items-center gap-2 mt-3">
          <button
            onClick={check}
            disabled={status === 'checking'}
            className="text-[11px] px-3 py-1.5 rounded-[6px] font-medium transition-opacity disabled:opacity-60"
            style={{ background: '#E6F1FB', color: '#185FA5' }}
          >
            {status === 'checking' ? 'Testing…' : 'Test connection'}
          </button>
          {status === 'ok' && (
            <span className="text-[10px] font-medium" style={{ color: '#1D9E75' }}>✓ Connected</span>
          )}
          {status === 'error' && (
            <span className="text-[10px] font-medium" style={{ color: '#E24B4A' }}>✗ Unreachable</span>
          )}
        </div>
      </div>
    </div>
  )
}
