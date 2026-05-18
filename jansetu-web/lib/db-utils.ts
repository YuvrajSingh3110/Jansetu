export function arr(val: string | string[] | null | undefined): string[] {
  if (!val) return []
  if (Array.isArray(val)) return val
  try { return JSON.parse(val) } catch { return [] }
}

export function str(val: string | string[] | null | undefined): string {
  if (!val) return '[]'
  if (typeof val === 'string') return val
  return JSON.stringify(val)
}

export function jsonStr(val: object | string | null | undefined): string {
  if (!val) return '{}'
  if (typeof val === 'string') return val
  return JSON.stringify(val)
}

export function jsonObj(val: string | object | null | undefined): any {
  if (!val) return {}
  if (typeof val === 'object') return val
  try { return JSON.parse(val) } catch { return {} }
}
