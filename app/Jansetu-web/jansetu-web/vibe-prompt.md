# Jansetu — Vibe Coding Master Prompt (Final v2)
> Copy this entire file into Cursor / Windsurf / Lovable as your very first message.
> Do not split it. The AI coding tool needs the full context at once.

---

## What we are building

**Jansetu** (जनसेतु — "bridge for the people") is a district-level epidemiological intelligence
web platform for rural India. Used by district health officers (DHO) and block medical officers (BMO) to:

1. Receive real-time anonymised symptom signals from Android field devices (ASHA workers + village users)
2. Aggregate those signals per village and run AI outbreak pattern detection (Gemma 4 27B via Ollama)
3. Display a live geospatial heatmap with timeline slider of disease clusters across the district
4. Generate and broadcast health advisories in Hindi + English to villages
5. Manage rapid response team deployment with AI-generated playbooks
6. Monitor the CHW (community health worker) network activity

This is the **web frontend + backend only**. The Android app is built separately.

---

## System architecture

```
Android phones (field)
  ├─ CHW: speaks symptoms → Gemma 4 E4B on-device → JSON payload
  └─ Village user: chats symptoms → Gemma 4 E4B answers + JSON payload
       Both stored in SQLite, synced on any 2G signal burst (<2KB packets)
              │
              ▼  POST /api/ingest/reports
┌──────────────────────────────────────────┐
│           Jansetu Web (Next.js)          │
│                                          │
│  STEP 1: Store reports in PostgreSQL     │
│  STEP 2: Queue outbreak detection job    │
│                                          │
│  STEP 6 — Pattern Detection:             │
│    Aggregate by village                  │
│    → Village A: fever×12, cough×10       │
│    → Village B: fever×9, cough×8         │
│    → Village C: diarrhoea×6 (children)   │
│    Send to Gemma 4 27B via Ollama        │
│    → Detects cluster, drafts alert       │
│    → Creates Alert in DB                 │
│                                          │
│  STEP 7 — Heatmap + Alert Dashboard:     │
│    Live heatmap (Leaflet + OSM)          │
│    Timeline slider (re-fetches by date)  │
│    AI-generated alerts sidebar           │
│    Village drill-down panel              │
│    Broadcast composer (Gemma drafts)     │
└──────────────────────────────────────────┘
              │
              ▼  Push advisory to CHW phones + SMS
```

---

## Tech stack

- **Frontend**: Next.js 14 App Router, TypeScript, Tailwind CSS, shadcn/ui
- **Backend**: Next.js API routes (same monorepo, full-stack)
- **Database**: PostgreSQL via Prisma ORM
- **AI**: Ollama running Gemma 4 27B → `http://localhost:11434`
- **Maps**: Leaflet.js + react-leaflet + OpenStreetMap (no API key, works offline)
- **Charts**: Recharts
- **Auth**: NextAuth.js credentials provider (email + bcrypt password)
- **Real-time**: Server-Sent Events (SSE) for live alert push
- **Job queue**: Bull + Redis (async outbreak detection — never block ingest)
- **Deployment**: Single Linux VM (district NIC server or cloud)

---

## Color palette — use exactly, everywhere

```
Primary blue:        #185FA5
Primary blue dark:   #0C447C   (sidebar bg)
Primary blue light:  #E6F1FB

Alert red:           #E24B4A
Alert red bg:        #FCEBEB
Alert red text:      #A32D2D

Warning amber:       #EF9F27
Warning amber bg:    #FAEEDA
Warning amber text:  #633806

Safe green:          #1D9E75
Safe green bg:       #E1F5EE
Safe green text:     #085041

Page bg:             #F5F5F5
Card bg:             #FFFFFF
Border:              1px solid #E5E5E5
Sidebar text:        #B5D4F4
Sidebar active:      rgba(255,255,255,0.15)
```

Font: Inter. Weights: 400 and 500 only.
Layout: sidebar 220px fixed + topbar 56px + scrollable main.

---

## Database schema (Prisma)

```prisma
generator client {
  provider = "prisma-client-js"
}

datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
}

model District {
  id        String    @id @default(cuid())
  name      String
  state     String
  blocks    Block[]
  officers  Officer[]
  alerts    Alert[]
  createdAt DateTime  @default(now())
}

model Block {
  id         String    @id @default(cuid())
  name       String
  district   District  @relation(fields: [districtId], references: [id])
  districtId String
  villages   Village[]
  chws       CHW[]
}

model Village {
  id      String   @id @default(cuid())
  name    String
  lat     Float
  lng     Float
  block   Block    @relation(fields: [blockId], references: [id])
  blockId String
  reports Report[]
}

model CHW {
  id           String    @id @default(cuid())
  name         String
  employeeId   String    @unique
  phone        String?
  block        Block     @relation(fields: [blockId], references: [id])
  blockId      String
  lastSyncAt   DateTime?
  reportsCount Int       @default(0)
  isActive     Boolean   @default(true)
  reports      Report[]
}

model Report {
  id         String   @id @default(cuid())
  sourceType String   // "chw" | "village_user"
  village    Village  @relation(fields: [villageId], references: [id])
  villageId  String
  chw        CHW?     @relation(fields: [chwId], references: [id])
  chwId      String?
  ageGroup   String   // "child" | "adult" | "elderly"
  gender     String   // "M" | "F" | "unknown"
  symptoms   String[]
  duration   Int?
  severity   String   // "mild" | "moderate" | "severe"
  hasPhoto   Boolean  @default(false)
  referral   Boolean  @default(false)
  syncedAt   DateTime @default(now())
  reportedAt DateTime
}

model Alert {
  id               String           @id @default(cuid())
  district         District         @relation(fields: [districtId], references: [id])
  districtId       String
  type             String           // "outbreak" | "watch"
  confidence       String           // "high" | "medium" | "low"
  title            String
  description      String
  affectedVillages String[]
  symptomCluster   String[]
  caseCount        Int
  timeWindowHrs    Int
  aggregatedInput  Json             // village aggregation sent to Gemma
  aiAnalysis       Json             // full Gemma response
  status           String           @default("active")
  createdAt        DateTime         @default(now())
  updatedAt        DateTime         @updatedAt
  actions          ResponseAction[]
  broadcasts       Broadcast[]
}

model ResponseAction {
  id          String    @id @default(cuid())
  alert       Alert     @relation(fields: [alertId], references: [id])
  alertId     String
  step        Int
  title       String
  description String
  status      String    @default("pending")
  assignedTo  String?
  completedAt DateTime?
  createdAt   DateTime  @default(now())
}

model Broadcast {
  id         String    @id @default(cuid())
  alert      Alert?    @relation(fields: [alertId], references: [id])
  alertId    String?
  targetType String
  targetIds  String[]
  messageHi  String
  messageEn  String
  channel    String[]
  sentAt     DateTime?
  status     String    @default("draft")
  createdAt  DateTime  @default(now())
}

model Officer {
  id         String   @id @default(cuid())
  name       String
  email      String   @unique
  password   String
  role       String   // "dho" | "bmo" | "admin"
  district   District @relation(fields: [districtId], references: [id])
  districtId String
  createdAt  DateTime @default(now())
}
```

---

## STEP 6 — Pattern Detection (Gemma 4 27B)

This is the core AI pipeline. Build in `lib/outbreak-detector.ts`.

### 6a — Aggregate reports by village FIRST (never send raw reports to Gemma)

```typescript
// lib/outbreak-detector.ts
import { prisma } from './prisma'
import { generateOutbreakAnalysis } from './ollama'

export async function runOutbreakDetection(districtId: string, windowHrs = 72) {
  const since = new Date(Date.now() - windowHrs * 60 * 60 * 1000)

  const reports = await prisma.report.findMany({
    where: {
      syncedAt: { gte: since },
      village: { block: { districtId } }
    },
    include: { village: { include: { block: true } } }
  })

  if (reports.length < 5) return null

  // AGGREGATE by village — this exact format goes to Gemma
  const aggregated: Record<string, Record<string, number>> = {}
  const meta: Record<string, { block: string; lat: number; lng: number }> = {}

  for (const r of reports) {
    const v = r.village.name
    if (!aggregated[v]) {
      aggregated[v] = {}
      meta[v] = { block: r.village.block.name, lat: r.village.lat, lng: r.village.lng }
    }
    for (const s of r.symptoms) {
      aggregated[v][s] = (aggregated[v][s] || 0) + 1
    }
  }

  // Format for prompt:
  // Village A (Rampur Block): fever×12, cough×10, breathlessness×3
  // Village B (Mau Block): fever×9, cough×8
  // Village C (Khajuri Block): diarrhoea×6
  const lines = Object.entries(aggregated).map(([village, counts]) => {
    const symptomStr = Object.entries(counts)
      .sort((a, b) => b[1] - a[1])
      .map(([s, n]) => `${s}×${n}`)
      .join(', ')
    return `${village} (${meta[village].block}): ${symptomStr}`
  }).join('\n')

  const analysis = await generateOutbreakAnalysis(lines, districtId, windowHrs)
  if (analysis.riskLevel === 'none') return null

  return await prisma.alert.create({
    data: {
      districtId,
      type: analysis.riskLevel === 'high' ? 'outbreak' : 'watch',
      confidence: analysis.confidence,
      title: analysis.alertTitle,
      description: analysis.alertDescription,
      affectedVillages: analysis.affectedVillages,
      symptomCluster: analysis.dominantSymptoms,
      caseCount: analysis.caseCount,
      timeWindowHrs: windowHrs,
      aggregatedInput: aggregated,
      aiAnalysis: analysis,
      actions: {
        create: analysis.recommendedActions.map((a: any) => ({
          step: a.step, title: a.title, description: a.description, status: 'pending'
        }))
      }
    }
  })
}
```

### 6b — Gemma 4 27B prompt (in `lib/ollama.ts`)

```typescript
export async function generateOutbreakAnalysis(
  villageLines: string,
  districtName: string,
  windowHrs: number
) {
  const prompt = `
You are a district epidemiologist AI for rural India.

Analyze these aggregated symptom signals from the last ${windowHrs} hours in ${districtName}:
Format: "VillageName (Block): symptom×count"

${villageLines}

Detect:
- Clusters: same symptoms in geographically adjacent villages in same time window
- Anomalies: unusual spikes compared to background noise
- Early outbreak signals: patterns that historically precede outbreaks

Output ONLY valid JSON (no markdown, no extra text):
{
  "riskLevel": "high | medium | low | none",
  "confidence": "high | medium | low",
  "diseasePattern": "ILI | gastroenteritis | measles | cholera | dengue | malnutrition | unknown",
  "affectedVillages": ["village names"],
  "dominantSymptoms": ["symptom names"],
  "caseCount": <number>,
  "alertTitle": "<10 words max>",
  "alertDescription": "<2-3 sentences, plain English, for health officer>",
  "hindiBroadcast": "<3 sentences max, simple Hindi, calm tone, actionable>",
  "recommendedActions": [
    { "step": 1, "title": "...", "description": "..." },
    { "step": 2, "title": "...", "description": "..." },
    { "step": 3, "title": "...", "description": "..." }
  ],
  "reasoning": "<1-2 sentences why this triggered>"
}

Thresholds:
- "high": 15+ cases OR breathlessness/seizure/unconscious in cluster
- "medium": 8–14 cases OR 2+ villages same pattern
- "low": 5–7 cases, single village, mild symptoms only
- "none": random noise, no cluster
`
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
  return JSON.parse((await res.json()).response)
}

export async function draftBroadcastMessage(description: string, villages: string[]) {
  const prompt = `
Draft a health advisory for rural village people in India.
Situation: ${description}
Targets: ${villages.join(', ')}

Rules:
- Hindi: everyday language, no medical jargon, max 3 sentences, end with action to take
- English: same meaning, for official records
- Tone: calm, reassuring, practical

Output ONLY: { "hindi": "...", "english": "..." }
`
  const res = await fetch(`${process.env.OLLAMA_URL}/api/generate`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      model: process.env.OLLAMA_MODEL,
      prompt,
      stream: false,
      format: 'json',
      options: { temperature: 0.3 }
    })
  })
  return JSON.parse((await res.json()).response)
}
```

### 6c — Bull queue (async — never block ingest request)

```typescript
// lib/queue.ts
import Bull from 'bull'
import { runOutbreakDetection } from './outbreak-detector'

export const outbreakQueue = new Bull('outbreak-detection', process.env.REDIS_URL!)

outbreakQueue.process(async (job) => {
  const { districtId } = job.data
  await runOutbreakDetection(districtId, 72)
})

// Also run every 2 hours regardless of ingestion
outbreakQueue.add({ districtId: 'all' }, { repeat: { cron: '0 */2 * * *' } })
```

---

## STEP 7 — Heatmap + Alert Dashboard

### Heatmap API

```typescript
// app/api/analytics/heatmap/route.ts
export async function GET(req: Request) {
  const { searchParams } = new URL(req.url)
  const days = parseInt(searchParams.get('days') || '7')
  const districtId = searchParams.get('districtId')!
  const symptom = searchParams.get('symptom') // optional filter

  const since = new Date(Date.now() - days * 24 * 60 * 60 * 1000)

  const villages = await prisma.village.findMany({
    where: { block: { districtId } },
    include: {
      reports: {
        where: {
          syncedAt: { gte: since },
          ...(symptom ? { symptoms: { has: symptom } } : {})
        }
      }
    }
  })

  return Response.json({
    villages: villages.map(v => {
      const counts: Record<string, number> = {}
      v.reports.forEach(r => r.symptoms.forEach(s => { counts[s] = (counts[s] || 0) + 1 }))
      const top = Object.entries(counts).sort((a, b) => b[1] - a[1])[0]?.[0] || null
      return {
        id: v.id, name: v.name, lat: v.lat, lng: v.lng,
        caseCount: v.reports.length,
        topSymptom: top,
        symptomCounts: counts,
        riskLevel: getRiskLevel(v.reports.length, days)
      }
    })
  })
}

function getRiskLevel(cases: number, days: number) {
  const rate = cases / days
  if (rate >= 5) return 'high'
  if (rate >= 2) return 'medium'
  return 'low'
}
```

### Heatmap page — full feature list (all required)

```
/heatmap must have:

1. LIVE HEATMAP (Leaflet + OSM)
   - Circle per village, radius = Math.sqrt(caseCount) * 8
   - red (#E24B4A) = high risk, amber (#EF9F27) = medium, green (#1D9E75) = low
   - Subtle CSS pulse animation on outbreak villages

2. TIMELINE SLIDER
   - Range input: "30 days ago" to "today"
   - On change: re-fetch /api/analytics/heatmap?days=X and re-render
   - Show selected range as text: "Apr 1 – Apr 21, 2026"

3. SYMPTOM FILTER CHIPS
   - Pills: All / Fever / Cough / Diarrhoea / Rash / Malnutrition / Breathlessness
   - Active chip = blue, passes ?symptom=fever to API
   - "All" clears the filter

4. AI ALERTS SIDEBAR
   - Right panel listing active alerts
   - Each: severity badge, title, case count, time ago
   - Click → /alerts/[id]

5. VILLAGE DRILL-DOWN
   - Click any village circle → side panel slides in from right
   - Shows: name, block, case count, symptom breakdown bars, 7-day sparkline
   - Buttons: "View reports" → /reports?villageId=xxx
             "Create broadcast" → opens /broadcast with village pre-selected
```

### SSE live stream

```typescript
// app/api/alerts/stream/route.ts
export async function GET(req: Request) {
  const districtId = new URL(req.url).searchParams.get('districtId')
  let lastChecked = new Date()

  const stream = new ReadableStream({
    start(controller) {
      const enc = new TextEncoder()

      const heartbeat = setInterval(() => {
        controller.enqueue(enc.encode(': heartbeat\n\n'))
      }, 30000)

      const poll = setInterval(async () => {
        const alerts = await prisma.alert.findMany({
          where: { districtId, createdAt: { gt: lastChecked } }
        })
        if (alerts.length > 0) {
          lastChecked = new Date()
          alerts.forEach(a => {
            controller.enqueue(enc.encode(`data: ${JSON.stringify(a)}\n\n`))
          })
        }
      }, 5000)

      req.signal.addEventListener('abort', () => {
        clearInterval(heartbeat)
        clearInterval(poll)
        controller.close()
      })
    }
  })

  return new Response(stream, {
    headers: {
      'Content-Type': 'text/event-stream',
      'Cache-Control': 'no-cache',
      'Connection': 'keep-alive'
    }
  })
}
```

---

## All API endpoints

```
# Ingestion (Android → web)
POST /api/ingest/reports              store + queue detection job, return 200 fast

# Alerts
GET  /api/alerts                      ?status=active&districtId=xxx
GET  /api/alerts/[id]
GET  /api/alerts/stream               SSE ?districtId=xxx
POST /api/alerts/[id]/actions/[aid]   body: { status: "done" }

# Analytics
GET  /api/analytics/heatmap           ?days=7&districtId=xxx&symptom=fever
GET  /api/analytics/symptoms          ?days=7&districtId=xxx
GET  /api/analytics/timeline          ?villageId=xxx&days=14
GET  /api/analytics/summary           ?districtId=xxx  (dashboard stat cards)

# CHW
GET  /api/chw                         ?districtId=xxx
GET  /api/chw/[id]/reports            ?days=7

# Broadcast
POST /api/broadcast/draft             body: { alertId } → Gemma drafts message
POST /api/broadcast/send              body: { targetType, targetIds, channel, messageHi, messageEn, alertId? }

# Villages (used by Android app on first launch)
GET  /api/villages                    ?districtId=xxx

# Internal (queue workers only, protected by INTERNAL_API_SECRET)
POST /api/internal/detect-outbreak    body: { districtId, windowHrs }
```

---

## Pages — full spec

### `/login`
Email + password form. NextAuth credentials. Redirect to `/dashboard`.

### `/dashboard`
- 4 stat cards: Reports today / Active outbreaks / CHWs online / Villages covered
- Active alert cards (red/amber) with action buttons
- Symptom trend bars (last 7 days, top 5)
- Live reports feed (SSE, new at top)
- CHW activity mini-list (top 3 today)

### `/alerts`
- Tabs: Active / Responding / Resolved / All
- Cards: severity, title, villages, case count, confidence, time ago

### `/alerts/[id]`
- Gemma AI analysis box
- Affected villages bar chart
- Response playbook (steps, tickable: pending → in_progress → done)
- Event timeline
- Broadcast button → inline composer with AI pre-filled

### `/heatmap`
Full feature list in STEP 7 above.

### `/reports`
- Filters: village, block, symptom, date range, source, severity
- Table: time, village, source badge, patient, symptoms pills, severity, referral
- Pagination 25/page + CSV export

### `/broadcast`
- Step 1: Select targets (blocks / villages / district)
- Step 2: Channel (App push / SMS / Both)
- Step 3: Link alert (optional)
- Step 4: AI drafts Hindi + English (both editable)
- Step 5: Preview (estimated reach count)
- Send with confirmation modal

### `/chw`
- Stat cards: Active / Not synced 24h / Total
- Table: name, block, reports today (progress bar), last sync, status
- Click → detail modal (7-day sparkline, village list, contact)

### `/settings`
- District profile
- Officer account management
- Ollama connection test + status
- Alert threshold config (saved to DB)

---

## File structure

```
jansetu-web/
├── app/
│   ├── (auth)/login/page.tsx
│   ├── (dashboard)/
│   │   ├── layout.tsx
│   │   ├── dashboard/page.tsx
│   │   ├── alerts/page.tsx
│   │   ├── alerts/[id]/page.tsx
│   │   ├── heatmap/page.tsx
│   │   ├── reports/page.tsx
│   │   ├── broadcast/page.tsx
│   │   ├── chw/page.tsx
│   │   └── settings/page.tsx
│   └── api/
│       ├── auth/[...nextauth]/route.ts
│       ├── ingest/reports/route.ts
│       ├── alerts/route.ts
│       ├── alerts/stream/route.ts
│       ├── alerts/[id]/route.ts
│       ├── alerts/[id]/actions/[aid]/route.ts
│       ├── analytics/heatmap/route.ts
│       ├── analytics/symptoms/route.ts
│       ├── analytics/timeline/route.ts
│       ├── analytics/summary/route.ts
│       ├── broadcast/draft/route.ts
│       ├── broadcast/send/route.ts
│       ├── chw/route.ts
│       ├── villages/route.ts
│       └── internal/detect-outbreak/route.ts
├── components/
│   ├── layout/Sidebar.tsx
│   ├── layout/Topbar.tsx
│   ├── dashboard/StatCard.tsx
│   ├── dashboard/AlertCard.tsx
│   ├── dashboard/ReportsFeed.tsx
│   ├── alerts/ResponsePlaybook.tsx
│   ├── map/DistrictMap.tsx          ← dynamic import wrapper
│   ├── map/LeafletMap.tsx           ← actual Leaflet, no SSR
│   ├── map/VillagePanel.tsx         ← drill-down side panel
│   ├── map/TimelineSlider.tsx       ← date range slider
│   └── broadcast/BroadcastComposer.tsx
├── lib/
│   ├── prisma.ts
│   ├── ollama.ts
│   ├── outbreak-detector.ts
│   ├── queue.ts
│   └── auth.ts
├── prisma/
│   ├── schema.prisma
│   └── seed.ts
├── tasks.md
├── checklist.md
├── SKILLS.md
└── API_CONTRACT.md
```

---

## Seed data

```typescript
// Varanasi district, 3 blocks, 10 villages, 5 CHWs, 1 DHO officer
// Villages with real lat/lng near Varanasi:
{ name: 'Rampur',   lat: 25.4358, lng: 82.9109, block: 'Rampur Block'  }
{ name: 'Barsara',  lat: 25.4421, lng: 82.9234, block: 'Rampur Block'  }
{ name: 'Khajuri',  lat: 25.4289, lng: 82.9312, block: 'Rampur Block'  }
{ name: 'Mau',      lat: 25.4512, lng: 82.8967, block: 'Mau Block'     }
{ name: 'Saidpur',  lat: 25.4601, lng: 82.8812, block: 'Mau Block'     }
{ name: 'Chakia',   lat: 25.4189, lng: 82.8756, block: 'Mau Block'     }
{ name: 'Deoria',   lat: 25.4698, lng: 82.9456, block: 'Khajuri Block' }
{ name: 'Bhelpur',  lat: 25.4123, lng: 82.9567, block: 'Khajuri Block' }
{ name: 'Harahua',  lat: 25.4756, lng: 82.9123, block: 'Khajuri Block' }
{ name: 'Cholapur', lat: 25.4034, lng: 82.8934, block: 'Rampur Block'  }

// Demo officer: demo@jansetu.in / jansetu2026

// Synthetic reports — CREATE A DELIBERATE CLUSTER for demo:
// Rampur: 12 fever+cough reports over last 72h
// Barsara: 8 fever+cough reports over last 72h
// Khajuri: 6 fever+cough reports over last 72h
// Other villages: 1-3 random mild reports
// → This triggers riskLevel: "high" from Gemma
// → Pre-create the resulting alert so dashboard shows it immediately on seed
```

---

## Environment variables

```env
DATABASE_URL="postgresql://postgres:password@localhost:5432/jansetu"
NEXTAUTH_SECRET="change-to-random-32-char-string"
NEXTAUTH_URL="http://localhost:3000"
OLLAMA_URL="http://localhost:11434"
OLLAMA_MODEL="gemma4:27b"
REDIS_URL="redis://localhost:6379"
INTERNAL_API_SECRET="jansetu-internal-2026"
```

---

## Hard rules — read before writing any code

1. No PII ever stored — village-level only, never individual identity
2. Ingest returns 200 in <200ms — detection is always async via queue
3. Aggregate before Gemma — never send raw reports, always village symptom counts
4. Heatmap works without AI — reads PostgreSQL only, Ollama down = map still loads
5. All AI text is editable — officer reviews before anything is sent
6. SSE only on new Alert — not every report
7. CHW active = lastSyncAt within 24h
8. SMS = mock — log to console + DB, no real gateway
9. Timeline slider = re-fetch — don't cache all time windows client-side
10. Gemma temperature 0.1 for JSON, 0.3 for broadcast messages

---

## Build order

```
Day 1: npx create-next-app → install deps → schema → migrate → seed → verify DB
Day 2: Sidebar + Topbar + layout shell → /dashboard with hardcoded mock data
Day 3: POST /api/ingest/reports → wire /dashboard to real DB → share API with app team
Day 4: Bull + Redis → outbreak-detector.ts → Ollama integration → test detection
Day 5: /alerts list → /alerts/[id] → SSE stream → live feed on dashboard
Day 6: /heatmap → Leaflet map → timeline slider → symptom chips → village panel
Day 7: /broadcast → /chw → /reports table
Day 8-9: Polish seed data → full E2E test → demo screenshots
```

---

## Dependencies

```bash
npm install @prisma/client prisma
npm install next-auth bcryptjs @types/bcryptjs
npm install recharts
npm install leaflet react-leaflet @types/leaflet
npm install bull ioredis @types/bull
npm install date-fns

npx shadcn@latest init
npx shadcn@latest add button card badge input select table dialog tabs
```

---

## Android sync contract (share with Yuvraj)

```
POST /api/ingest/reports
Authorization: Bearer jansetu-internal-2026
Content-Type: application/json

{
  "deviceId": "uuid",
  "chwId": "VR-2847",         // null for village users
  "sourceType": "chw",        // or "village_user"
  "reports": [{
    "villageId": "clv001rampur",
    "ageGroup": "child | adult | elderly",
    "gender": "M | F | unknown",
    "symptoms": ["fever", "cough"],
    "duration": 3,
    "severity": "mild | moderate | severe",
    "hasPhoto": false,
    "referral": false,
    "reportedAt": "2026-04-21T09:42:00Z"
  }]
}

Response 200: { "received": 3, "queued": true }
Response 400: { "error": "description" }
```

Symptom codes (use exactly these strings in both apps):
```
fever, cough, breathlessness, diarrhoea, vomiting, rash,
headache, bodyache, sore_throat, runny_nose, malnutrition,
jaundice, conjunctivitis, seizure, unconscious, bleeding
```

Village IDs (from seed — share with app team):
```
Rampur   → clv001rampur    Barsara  → clv002barsara
Khajuri  → clv003khajuri   Mau      → clv004mau
Saidpur  → clv005saidpur   Chakia   → clv006chakia
Deoria   → clv007deoria    Bhelpur  → clv008bhelpur
Harahua  → clv009harahua   Cholapur → clv010cholapur
```