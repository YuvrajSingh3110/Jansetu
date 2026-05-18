# SKILLS.md — Jansetu technical decisions + patterns
> This is your project memory. Paste relevant sections into your AI coding tool when stuck.
> Update every time you solve a non-obvious problem.

---

## Architecture decisions

### Why Next.js App Router
React Server Components fetch DB data directly in page components without extra API calls. Less boilerplate for data-heavy dashboard pages.

### Why SSE not WebSockets
One-way server→client push only. Next.js App Router supports SSE natively via streaming Response. No separate server needed.

### Why Leaflet not Google Maps / Mapbox
No API key, no billing, works offline with cached OSM tiles. Good India coverage. Must dynamic-import in Next.js to avoid SSR crash.

### Why Bull + Redis for detection
Ollama inference takes 10–30s. Cannot block the ingest request. Queue it, process async, return 200 immediately to Android.

### Why aggregate before Gemma (CRITICAL)
Never send raw individual reports to Gemma. Always aggregate to village symptom counts first:
- Reduces token count dramatically
- Makes pattern detection clearer
- Matches how an epidemiologist actually reads data
Format: `Village A (Block): fever×12, cough×10`

### Why temperature 0.1 for detection, 0.3 for broadcast
- Detection needs consistent, parseable JSON → 0.1 (nearly deterministic)
- Broadcast needs natural language → 0.3 (slightly more varied)

---

## Code patterns

### Aggregate reports before Gemma call

```typescript
const aggregated: Record<string, Record<string, number>> = {}
for (const r of reports) {
  const v = r.village.name
  if (!aggregated[v]) aggregated[v] = {}
  for (const s of r.symptoms) {
    aggregated[v][s] = (aggregated[v][s] || 0) + 1
  }
}
// Result: { "Rampur": { fever: 12, cough: 10 }, "Barsara": { fever: 9, cough: 8 } }
```

### Ollama call (always use format: 'json')

```typescript
const res = await fetch(`${process.env.OLLAMA_URL}/api/generate`, {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({
    model: process.env.OLLAMA_MODEL,
    prompt,
    stream: false,
    format: 'json',
    options: { temperature: 0.1 }
  })
})
const data = await res.json()
return JSON.parse(data.response)
```

### Leaflet dynamic import (required — SSR breaks Leaflet)

```typescript
// components/map/DistrictMap.tsx
import dynamic from 'next/dynamic'
const Map = dynamic(() => import('./LeafletMap'), { ssr: false })
```

### Leaflet marker icon fix for Next.js

```typescript
// In LeafletMap.tsx, before rendering
import L from 'leaflet'
delete (L.Icon.Default.prototype as any)._getIconUrl
L.Icon.Default.mergeOptions({
  iconUrl: 'https://unpkg.com/leaflet@1.9.4/dist/images/marker-icon.png',
  iconRetinaUrl: 'https://unpkg.com/leaflet@1.9.4/dist/images/marker-icon-2x.png',
  shadowUrl: 'https://unpkg.com/leaflet@1.9.4/dist/images/marker-shadow.png',
})
```

### Village circle sizing for heatmap

```typescript
// Radius proportional to case count, min 6px
const radius = Math.max(6, Math.sqrt(village.caseCount) * 8)

// Color by risk level
const color = {
  high: '#E24B4A',
  medium: '#EF9F27',
  low: '#1D9E75'
}[village.riskLevel]

L.circleMarker([village.lat, village.lng], {
  radius,
  fillColor: color,
  color: '#fff',
  weight: 1.5,
  fillOpacity: 0.75
}).addTo(map)
```

### Timeline slider — re-fetch on change

```typescript
// components/map/TimelineSlider.tsx
const [days, setDays] = useState(7)

const handleChange = (e: React.ChangeEvent<HTMLInputElement>) => {
  const d = parseInt(e.target.value)
  setDays(d)
  onDaysChange(d) // parent re-fetches /api/analytics/heatmap?days=d
}

// In parent LeafletMap:
const fetchHeatmap = async (days: number) => {
  const res = await fetch(`/api/analytics/heatmap?days=${days}&districtId=${districtId}`)
  const { villages } = await res.json()
  // re-render circles
}
```

### SSE consumer (React client component)

```typescript
// components/dashboard/ReportsFeed.tsx
'use client'
useEffect(() => {
  const es = new EventSource(`/api/alerts/stream?districtId=${districtId}`)
  es.onmessage = (e) => {
    const alert = JSON.parse(e.data)
    setAlerts(prev => [alert, ...prev])
  }
  return () => es.close()
}, [districtId])
```

### Risk level calculation

```typescript
function getRiskLevel(cases: number, days: number): 'high' | 'medium' | 'low' {
  const rate = cases / days
  if (rate >= 5) return 'high'   // 5+ cases/day
  if (rate >= 2) return 'medium' // 2–5 cases/day
  return 'low'                    // <2 cases/day
}
```

### Server component data fetching

```typescript
// app/(dashboard)/dashboard/page.tsx
import { prisma } from '@/lib/prisma'
import { startOfDay } from 'date-fns'

export default async function DashboardPage() {
  const [reportsToday, activeAlerts, activeCHWs] = await Promise.all([
    prisma.report.count({ where: { syncedAt: { gte: startOfDay(new Date()) } } }),
    prisma.alert.count({ where: { status: 'active' } }),
    prisma.cHW.count({ where: { lastSyncAt: { gte: new Date(Date.now() - 86400000) } } }),
  ])
  return <DashboardClient reportsToday={reportsToday} activeAlerts={activeAlerts} activeCHWs={activeCHWs} />
}
```

---

## Gotchas (update as you discover more)

- **Leaflet CSS** must be in `app/layout.tsx`: `import 'leaflet/dist/leaflet.css'`
- **Bull + Redis**: start with `docker run -d -p 6379:6379 redis` before testing queues
- **Ollama cold start**: first inference takes 30–60s to load model weights. Add a startup ping
- **Prisma String[]**: maps to PostgreSQL `text[]` — no extra config needed
- **NextAuth App Router**: needs `authOptions` exported from `app/api/auth/[...nextauth]/route.ts`
- **Gemma JSON mode**: always pass `format: 'json'` in Ollama request body, else it adds markdown
- **SSE in Next.js**: set `'Connection': 'keep-alive'` header, otherwise Vercel/nginx may buffer

---

## PostGIS (optional — not required for hackathon)

For the hackathon, plain lat/lng + JavaScript distance filtering is enough.
Only add PostGIS if you need "find all villages within 20km of outbreak" server-side.

If you add it:
```sql
CREATE EXTENSION postgis;
-- Add to Village in schema.prisma:
-- location Unsupported("geography(Point, 4326)")?
-- Radius query:
-- WHERE ST_DWithin(location, ST_MakePoint($lng, $lat)::geography, 20000)
```

---

## Symptom codes (canonical — both apps must use exactly these)

```
fever, cough, breathlessness, diarrhoea, vomiting, rash,
headache, bodyache, sore_throat, runny_nose, malnutrition,
jaundice, conjunctivitis, seizure, unconscious, bleeding
```

---

## Village IDs (from seed — share with Android team)

```
Rampur   → clv001rampur    Barsara  → clv002barsara
Khajuri  → clv003khajuri   Mau      → clv004mau
Saidpur  → clv005saidpur   Chakia   → clv006chakia
Deoria   → clv007deoria    Bhelpur  → clv008bhelpur
Harahua  → clv009harahua   Cholapur → clv010cholapur
```

In production, app fetches from `GET /api/villages` on first launch and caches in SQLite.