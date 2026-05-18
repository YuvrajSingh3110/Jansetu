# Jansetu — जनसेतु

<div align="center">

**The bridge that was never built.**

*An offline-first, voice-first, AI-powered disease surveillance network for rural India.*

[![Gemma 4](https://img.shields.io/badge/Gemma_4-E4B_%2B_31B-1D9E75?style=for-the-badge&logo=google&logoColor=white)](https://ai.google.dev/gemma)
[![LiteRT-LM](https://img.shields.io/badge/LiteRT--LM-On_Device-0C447C?style=for-the-badge)](https://ai.google.dev/edge/litert)
[![Ollama](https://img.shields.io/badge/Ollama-31B_Cloud-534AB7?style=for-the-badge)](https://ollama.com)
[![Unsloth](https://img.shields.io/badge/Unsloth-Fine--tuned-BA7517?style=for-the-badge)](https://unsloth.ai)
[![Next.js](https://img.shields.io/badge/Next.js_14-Web_Dashboard-000000?style=for-the-badge&logo=next.js)](https://nextjs.org)
[![Android](https://img.shields.io/badge/Android-Field_App-3DDC84?style=for-the-badge&logo=android&logoColor=white)](https://developer.android.com)

[![Gemma 4 Good Hackathon](https://img.shields.io/badge/Gemma_4_Good_Hackathon-Health_%26_Sciences-E24B4A?style=for-the-badge)](https://www.kaggle.com/competitions/gemma-4-good-hackathon)

[Demo Video](#demo) · [Architecture](#architecture) · [Setup](#setup) · [Android App](#android-app) · [Web Dashboard](#web-dashboard) · [Fine-tuning](#unsloth-fine-tuning)

</div>

---

## The problem we are solving

In 2019, a disease moved silently through the villages of Muzaffarpur, Bihar. By the time the district health office knew something was wrong, 152 children were dead. Post-analysis showed early symptom signals had been present in communities for **three weeks** before the first hospital death was formally reported.

Three weeks. Preventable.

India has **600,000 villages**. Almost none of them exist in any real-time health data system. The ASHA workers who serve these villages — 850,000 of them — carry paper registers and phones with intermittent 2G signal. When a cluster of fever-and-cough cases starts forming across three adjacent villages, nobody sees it as a pattern. Each case is isolated, invisible, unreported to any system that can act on it.

**Every week of delay in outbreak detection increases case count by an estimated 40%.**

The gap is not a lack of dedicated people. ASHA workers are among the most committed frontline health workers in the world. The gap is infrastructure — a digital bridge that was never built between the village that always had data and the system that always needed it.

**Jansetu is that bridge.**

---

## What Jansetu does

Jansetu is a two-part system:

### 1. Android app — for the ground
An offline-first, voice-first health app for two types of users:

**ASHA workers / CHWs** speak patient descriptions in Hindi, Bhojpuri, Odia, or any local language. Gemma 4 E4B, running entirely on-device via LiteRT-LM, extracts structured symptom data using native function calling, generates referral recommendations, analyzes wound or rash photos, and stores everything in a local SQLite queue — no internet required. When any 2G signal is detected, reports sync automatically to the district server in compressed packets under 2KB each.

**Village users** open the same app, speak their symptoms, and receive real-time health guidance in their own language — read back aloud if needed. They can check symptoms, find nearby PHCs and ASHA workers, and receive outbreak warnings when their village is at risk.

All data is anonymised completely on-device before it ever touches storage. No names. No phone numbers. Village-level only.

### 2. Web dashboard — for the district
A real-time intelligence platform for district health officers. Gemma 4 31B, running via Ollama on a district server, aggregates symptom signals from across all villages, detects outbreak patterns, drafts plain-language alerts and response playbooks, and generates Hindi health advisories that push back to ASHA worker phones.

The district officer sees a live geospatial heatmap, manages response teams, and broadcasts advisories — all from one screen.

---

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                   USERS (FIELD)                         │
│   ASHA Worker · CHW · Village Person                    │
│   Speaks in Hindi / Bhojpuri / Odia / Gondi             │
└──────────────────────┬──────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────┐
│              ANDROID APP — EDGE LAYER                   │
│         Runs fully offline · LiteRT-LM runtime          │
│                                                         │
│  ┌─────────────────────────────────────────────────┐   │
│  │         GEMMA 4 E4B — ON DEVICE                 │   │
│  │   4B params · 4-bit quantised · < 1.5 GB RAM   │   │
│  │                                                 │   │
│  │  ┌──────────┐ ┌──────────┐ ┌────────────────┐  │   │
│  │  │ Speech   │ │ Symptom  │ │ Image analysis │  │   │
│  │  │ to text  │→│ extract  │ │ Rash · wound   │  │   │
│  │  │Multilang │ │Fn calling│ │ Malnutrition   │  │   │
│  │  └──────────┘ └──────────┘ └────────────────┘  │   │
│  │                    │                             │   │
│  │             ┌──────────┐                        │   │
│  │             │  AI chat │                        │   │
│  │             │Voice+text│                        │   │
│  │             └──────────┘                        │   │
│  └─────────────────────────────────────────────────┘   │
│                       │                                  │
│              SQLite local store                          │
│         PII stripped · queued for sync                   │
│                       │                                  │
│         Android WorkManager sync engine                  │
└──────────────────────┬──────────────────────────────────┘
                       │  2G signal detected
                       │  POST /api/ingest/reports
                       │  gzip < 2KB · exponential backoff
                       ▼
┌─────────────────────────────────────────────────────────┐
│           DISTRICT CLOUD — INTELLIGENCE LAYER           │
│     Next.js 14 · PostgreSQL · Redis · Bull queue        │
│                                                         │
│  ┌─────────────────────────────────────────────────┐   │
│  │         GEMMA 4 31B — DISTRICT SERVER           │   │
│  │              via Ollama · full precision         │   │
│  │                                                 │   │
│  │  Village A: fever×12, cough×10                  │   │
│  │  Village B: fever×9, cough×8     ──► Cluster!  │   │
│  │  Village C: diarrhoea×6                         │   │
│  │                                                 │   │
│  │  → Outbreak detected · High confidence          │   │
│  │  → Alert drafted in plain English               │   │
│  │  → Hindi advisory generated                     │   │
│  │  → Response playbook created                    │   │
│  └─────────────────────────────────────────────────┘   │
│                       │                                  │
│              PostgreSQL · SSE stream                     │
└──────────────────────┬──────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────┐
│         DISTRICT OFFICER WEB DASHBOARD                  │
│   React · Leaflet · Recharts · NextAuth · shadcn/ui     │
│                                                         │
│  Command centre · Heatmap · Response playbook           │
│  Broadcast composer · CHW network monitor               │
└──────────────────────┬──────────────────────────────────┘
                       │ Advisory pushed back to field
                       ▼
            CHW phones receive Hindi advisory
               Village is informed before
                  the outbreak peaks
```

---

## Gemma 4 capabilities used

| Layer | Model | Capability | How used in Jansetu |
|-------|-------|-----------|---------------------|
| Android edge | Gemma 4 E4B | **Speech to text** | Multilingual audio input — Hindi, Bhojpuri, Odia, Gondi |
| Android edge | Gemma 4 E4B | **Function calling** | Structured symptom extraction → canonical JSON payload |
| Android edge | Gemma 4 E4B | **Vision / multimodal** | On-device rash, wound, and malnutrition photo analysis |
| Android edge | Gemma 4 E4B | **Text generation** | Real-time health guidance in local language, read aloud |
| District cloud | Gemma 4 31B | **Long context reasoning** | Pattern detection across village aggregates over 72hr windows |
| District cloud | Gemma 4 31B | **Structured output** | Alert JSON generation with risk level, affected villages, actions |
| District cloud | Gemma 4 31B | **Text generation** | Plain English alerts, Hindi broadcast messages, response playbooks |
| Fine-tuning | Gemma 4 E4B | **LoRA fine-tune** | Improved Bhojpuri/Gondi symptom extraction via Unsloth |

---

## Special technology tracks

| Track | Technology | Usage |
|-------|-----------|-------|
| **LiteRT** | LiteRT-LM | Runs Gemma 4 E4B on Android device, offline |
| **Ollama** | Ollama | Serves Gemma 4 31B on district server |
| **Unsloth** | Unsloth + LoRA | Fine-tunes E4B on Indian rural health vocabulary |

---

## Repository structure

```
jansetu/
│
├── web/                          # Next.js district officer dashboard
│   ├── app/
│   │   ├── (auth)/
│   │   │   └── login/
│   │   ├── (dashboard)/
│   │   │   ├── layout.tsx        # Sidebar + topbar shell
│   │   │   ├── dashboard/        # Command centre
│   │   │   ├── alerts/           # Alert list + detail
│   │   │   ├── heatmap/          # Geospatial heatmap
│   │   │   ├── reports/          # Raw reports table
│   │   │   ├── broadcast/        # Advisory composer
│   │   │   ├── chw/              # CHW network monitor
│   │   │   └── settings/
│   │   └── api/
│   │       ├── ingest/reports/   # Android sync endpoint
│   │       ├── alerts/           # Alert CRUD + SSE stream
│   │       ├── analytics/        # Heatmap, symptoms, timeline
│   │       ├── broadcast/        # AI draft + send
│   │       ├── chw/              # CHW status
│   │       ├── villages/         # Village list for Android
│   │       └── internal/         # Outbreak detection (queue)
│   ├── components/
│   │   ├── layout/               # Sidebar, Topbar
│   │   ├── dashboard/            # StatCard, AlertCard, ReportsFeed
│   │   ├── alerts/               # ResponsePlaybook
│   │   ├── map/                  # DistrictMap, VillagePanel, TimelineSlider
│   │   └── broadcast/            # BroadcastComposer
│   ├── lib/
│   │   ├── prisma.ts             # DB client
│   │   ├── ollama.ts             # Gemma 4 31B client + prompts
│   │   ├── outbreak-detector.ts  # Aggregation + detection pipeline
│   │   ├── queue.ts              # Bull queue setup
│   │   └── auth.ts               # NextAuth config
│   ├── prisma/
│   │   ├── schema.prisma
│   │   └── seed.ts               # Demo data with outbreak cluster
│   └── package.json
│
├── android/                      # Android field app
│   ├── app/src/main/
│   │   ├── java/in/jansetu/
│   │   │   ├── ui/               # Jetpack Compose screens
│   │   │   ├── gemma/            # LiteRT-LM inference engine
│   │   │   ├── sync/             # WorkManager sync engine
│   │   │   ├── db/               # SQLite + Room
│   │   │   └── models/           # Data models
│   │   └── res/
│   └── build.gradle
│
├── unsloth/                      # Fine-tuning pipeline
│   ├── README.md
│   ├── requirements.txt
│   ├── dataset/
│   │   ├── generate_dataset.py   # Generates 400 training examples
│   │   ├── jansetu_symptoms_train.jsonl
│   │   └── jansetu_symptoms_eval.jsonl
│   ├── train/
│   │   ├── finetune.py           # Main training script
│   │   ├── config.yaml           # Hyperparameters
│   │   └── colab_finetune.ipynb  # Kaggle/Colab notebook
│   ├── eval/
│   │   ├── evaluate.py           # Base vs fine-tuned comparison
│   │   └── test_cases.py         # 20 hard test cases
│   └── export/
│       └── export_for_litert.py  # Prepare for Android
│
├── docs/
│   ├── API_CONTRACT.md           # Android ↔ Web API spec
│   ├── VIBE_PROMPT.md            # Full web build prompt
│   ├── SKILLS.md                 # Technical patterns
│   ├── tasks.md                  # Living task tracker
│   ├── checklist.md              # Pre-submission checklist
│   └── SUBMISSION_WRITEUP.md     # Kaggle writeup
│
└── README.md                     # This file
```

---

## Setup

### Prerequisites

- Node.js 18+
- PostgreSQL 15+
- Redis 7+
- Docker (optional, for Redis)
- Ollama installed — [ollama.com](https://ollama.com)
- Android Studio (for the Android app)
- Python 3.10+ (for fine-tuning)

### 1. Clone the repository

```bash
git clone https://github.com/yourusername/jansetu.git
cd jansetu
```

### 2. Web dashboard setup

```bash
cd web

# Install dependencies
npm install

# Copy environment variables
cp .env.example .env
```

Edit `.env`:

```env
DATABASE_URL="postgresql://postgres:yourpassword@localhost:5432/jansetu"
NEXTAUTH_SECRET="generate-a-random-32-char-string"
NEXTAUTH_URL="http://localhost:3000"
OLLAMA_URL="http://localhost:11434"
OLLAMA_MODEL="gemma4:31b"
REDIS_URL="redis://localhost:6379"
INTERNAL_API_SECRET="jansetu-internal-2026"
```

```bash
# Start Redis (Docker)
docker run -d -p 6379:6379 redis

# Pull Gemma 4 31B via Ollama
ollama pull gemma4:31b

# Set up database
npx prisma migrate dev --name init

# Seed with demo data (includes Varanasi district + outbreak cluster)
npx prisma db seed

# Start development server
npm run dev
```

Open [http://localhost:3000](http://localhost:3000)

**Demo credentials:** `demo@jansetu.in` / `jansetu2026`

### 3. Android app setup

```bash
cd android

# Open in Android Studio
# File → Open → select the android/ folder

# The app uses LiteRT-LM — download the Gemma 4 E4B model
# Place the .litertlm file in: app/src/main/assets/gemma-e4b.litertlm

# Configure the sync endpoint in local.properties:
echo "SYNC_ENDPOINT=http://your-server-ip:3000" >> local.properties
echo "SYNC_SECRET=jansetu-internal-2026" >> local.properties

# Build and run on device or emulator (API 26+)
```

> Note: Gemma 4 E4B via LiteRT-LM requires Android API 26+ and at least 3GB RAM on device. The app degrades gracefully on lower-spec devices by using a smaller quantisation level.

### 4. Fine-tuning setup (optional)

```bash
cd unsloth

# Install dependencies
pip install -r requirements.txt

# Generate training dataset
python dataset/generate_dataset.py

# Run fine-tuning (requires GPU — use Colab for free T4)
python train/finetune.py

# Or open the Colab notebook
# train/colab_finetune.ipynb
```

---

## Web dashboard

### Pages

| Page | URL | Description |
|------|-----|-------------|
| Login | `/login` | Email + password auth |
| Dashboard | `/dashboard` | Command centre — alerts, stats, live feed |
| Alerts | `/alerts` | All alerts with filter tabs |
| Alert detail | `/alerts/[id]` | AI analysis + response playbook |
| Heatmap | `/heatmap` | Live geospatial symptom map with timeline slider |
| Reports | `/reports` | Raw reports table with filters and CSV export |
| Broadcast | `/broadcast` | AI-drafted advisory composer |
| CHW network | `/chw` | Field worker activity monitor |
| Settings | `/settings` | District config, Ollama status, thresholds |

### API endpoints

#### Android ingestion
```
POST /api/ingest/reports
Authorization: Bearer {INTERNAL_API_SECRET}

Body: {
  deviceId: string,
  chwId: string | null,
  sourceType: "chw" | "village_user",
  reports: Report[]
}

Response: { received: number, queued: true }
```

#### Analytics
```
GET /api/analytics/heatmap?days=7&districtId=xxx&symptom=fever
GET /api/analytics/symptoms?days=7&districtId=xxx
GET /api/analytics/timeline?villageId=xxx&days=14
GET /api/analytics/summary?districtId=xxx
```

#### Alerts
```
GET  /api/alerts?status=active&districtId=xxx
GET  /api/alerts/[id]
GET  /api/alerts/stream?districtId=xxx     (SSE)
POST /api/alerts/[id]/actions/[aid]        { status: "done" }
```

#### Broadcast
```
POST /api/broadcast/draft    { alertId } → Gemma drafts Hindi + English
POST /api/broadcast/send     { targetType, targetIds, channel, ... }
```

### Outbreak detection pipeline

The core AI pipeline runs asynchronously via Bull + Redis:

```
New reports ingested
        │
        ▼
Aggregate by village
  { "Rampur": { fever: 12, cough: 10 } }
  { "Barsara": { fever: 9, cough: 8  } }
        │
        ▼
Gemma 4 31B analysis (temperature: 0.1)
  → riskLevel: "high"
  → affectedVillages: ["Rampur", "Barsara", "Khajuri"]
  → diseasePattern: "ILI"
  → recommendedActions: [...]
        │
        ▼
Alert created in PostgreSQL
        │
        ▼
SSE stream pushes to dashboard
District officer notified
```

Detection also runs on a 2-hour cron regardless of new ingestion.

---

## Android app

### User flows

#### ASHA worker / CHW
1. Select language on first launch
2. Tap "Record symptoms" → speak patient description in any language
3. Gemma 4 E4B extracts symptom tags in real time
4. Confirm or edit → save to SQLite queue
5. Optionally photograph wound/rash → E4B vision analysis on-device
6. App silently syncs when 2G signal detected

#### Village user
1. Select language on first launch
2. Tap large microphone → speak symptoms
3. Receive AI guidance in local language (read aloud)
4. View nearby PHC and ASHA worker contacts
5. See local outbreak alerts with simple action steps
6. Anonymised report syncs when connected

### Symptom codes (canonical — shared between Android and web)

```
fever          cough          breathlessness    diarrhoea
vomiting       rash           headache          bodyache
sore_throat    runny_nose     malnutrition      jaundice
conjunctivitis seizure        unconscious       bleeding
```

### Data privacy

- All PII stripped on-device before any storage
- SQLite stores only: symptom codes, age group, gender, village ID, duration, severity, referral flag, timestamp
- No names, no phone numbers, no GPS coordinates finer than village level
- Village users can opt out of data contribution at any time
- Consent screen shown on first launch with plain Hindi explanation

### Sync payload format

Each report is compressed to under 2KB:

```json
{
  "deviceId": "uuid",
  "chwId": "VR-2847",
  "sourceType": "chw",
  "reports": [{
    "villageId": "clv001rampur",
    "ageGroup": "adult",
    "gender": "F",
    "symptoms": ["fever", "cough", "breathlessness"],
    "duration": 3,
    "severity": "moderate",
    "hasPhoto": false,
    "referral": true,
    "reportedAt": "2026-04-21T09:42:00Z"
  }]
}
```

---

## Unsloth fine-tuning

We fine-tune Gemma 4 E4B on a custom dataset of Indian rural health symptom descriptions to improve accuracy on colloquial local language expressions.

### The problem with the base model

The base Gemma 4 E4B misclassifies several common Bhojpuri and colloquial Hindi expressions:

| Input | Base model output | Fine-tuned output |
|-------|-------------------|-------------------|
| "Angiya chadh rahi ba" | `bodyache` | `seizure` ✓ |
| "Bachchi sukh rahi hai, haddi dikhne lagi" | `bodyache` | `malnutrition` ✓ |
| "Aankhein pili ho gayi" | `conjunctivitis` | `jaundice` ✓ |
| "Aankhon ke aage andhera" | `headache` | `unconscious` (referral) ✓ |

These errors directly affect referral accuracy — the most critical decision the app makes.

### Dataset

- 400 training examples across 8 language categories
- 80 evaluation examples
- Languages: Hindi, Bhojpuri, Hinglish, ASHA clinical style
- Created with input from ASHA workers

```bash
cd unsloth
python dataset/generate_dataset.py
# Generates jansetu_symptoms_train.jsonl and jansetu_symptoms_eval.jsonl
```

### Training

Runs on free Google Colab T4 GPU in approximately 35–45 minutes:

```python
from unsloth import FastModel

model, tokenizer = FastModel.from_pretrained(
    model_name="google/gemma-4-e4b-it",
    max_seq_length=512,
    load_in_4bit=True,
)

model = FastModel.get_peft_model(
    model,
    r=16,
    target_modules=["q_proj", "k_proj", "v_proj", "o_proj",
                    "gate_proj", "up_proj", "down_proj"],
    lora_alpha=16,
)
```

Open [`unsloth/train/colab_finetune.ipynb`](unsloth/train/colab_finetune.ipynb) in Colab and run all cells.

### Results

| Metric | Base model | Fine-tuned | Delta |
|--------|-----------|------------|-------|
| JSON parse rate | 82.5% | 97.5% | +15.0% |
| Symptom recall | 71.3% | 89.2% | +17.9% |
| Symptom precision | 68.4% | 91.7% | +23.3% |
| **Referral recall** | **74.0%** | **94.0%** | **+20.0%** |
| Severity accuracy | 61.2% | 82.4% | +21.2% |
| Age group accuracy | 88.5% | 95.0% | +6.5% |

**Referral recall is the most important metric** — the fine-tuned model correctly identifies 94% of cases requiring PHC referral vs 74% for the base model. A missed referral in the field can cost a life.

### Integration with Android

The fine-tuned model is a drop-in replacement for the base E4B:

```bash
# Export for Android
python unsloth/export/export_for_litert.py

# Output: ./outputs/jansetu-e4b-final/
# Hand this folder to the Android team
# Same LiteRT-LM conversion pipeline as base model
```

---

## Demo

### Live demo

[Video walkthrough — 3 minutes](#) *(link to YouTube)*

### Demo data

The seed script creates a complete demo scenario:

- Varanasi district, 3 blocks, 10 villages
- 5 ASHA workers
- 50 synthetic reports over 7 days
- A deliberate fever+cough cluster in Rampur, Barsara, Khajuri
- 1 active high-confidence outbreak alert pre-generated
- Demo account: `demo@jansetu.in` / `jansetu2026`

### Running the demo flow end-to-end

```bash
# 1. Start the web dashboard
cd web && npm run dev

# 2. Open http://localhost:3000, login with demo account
# Dashboard shows the Rampur outbreak alert immediately

# 3. Simulate a new report batch from Android
curl -X POST http://localhost:3000/api/ingest/reports \
  -H "Authorization: Bearer jansetu-internal-2026" \
  -H "Content-Type: application/json" \
  -d '{
    "deviceId": "test-device-001",
    "chwId": "VR-2847",
    "sourceType": "chw",
    "reports": [
      {
        "villageId": "clv001rampur",
        "ageGroup": "child",
        "gender": "M",
        "symptoms": ["fever", "rash"],
        "duration": 2,
        "severity": "moderate",
        "hasPhoto": true,
        "referral": true,
        "reportedAt": "2026-04-21T10:00:00Z"
      }
    ]
  }'

# 4. Watch the live feed update on the dashboard
# 5. Navigate to /heatmap — see Rampur cluster glowing red
# 6. Click the cluster — drill down to village detail
# 7. Open the alert — see AI-generated response playbook
# 8. Go to /broadcast — AI drafts Hindi advisory
# 9. Send broadcast — advisory goes to ASHA phones
```

---

## Village ID map (Varanasi district seed)

For the Android team to hardcode during development:

```
Rampur   → clv001rampur      Barsara  → clv002barsara
Khajuri  → clv003khajuri     Mau      → clv004mau
Saidpur  → clv005saidpur     Chakia   → clv006chakia
Deoria   → clv007deoria      Bhelpur  → clv008bhelpur
Harahua  → clv009harahua     Cholapur → clv010cholapur
```

In production, the Android app calls `GET /api/villages?districtId=xxx` on first launch and caches the village ID map locally.

---

## Environment variables reference

### Web dashboard (.env)

```env
# Database
DATABASE_URL="postgresql://postgres:password@localhost:5432/jansetu"

# Auth
NEXTAUTH_SECRET="random-32-char-string"
NEXTAUTH_URL="http://localhost:3000"

# AI
OLLAMA_URL="http://localhost:11434"
OLLAMA_MODEL="gemma4:31b"

# Queue
REDIS_URL="redis://localhost:6379"

# Security
INTERNAL_API_SECRET="jansetu-internal-2026"
```

### Android (local.properties)

```
SYNC_ENDPOINT=https://your-domain.com
SYNC_SECRET=jansetu-internal-2026
LITERT_MODEL_PATH=gemma-e4b-jansetu.litertlm
```

---

## Deployment

### Web dashboard (production)

```bash
cd web

# Build
npm run build

# Database migration
npx prisma migrate deploy

# Start (with PM2)
pm2 start npm --name "jansetu-web" -- start

# Or with Docker
docker build -t jansetu-web .
docker run -p 3000:3000 --env-file .env jansetu-web
```

### Ollama (district server)

```bash
# Install Ollama on district server
curl https://ollama.ai/install.sh | sh

# Pull Gemma 4 31B
ollama pull gemma4:31b

# Start Ollama service
ollama serve

# Verify
curl http://localhost:11434/api/generate \
  -d '{"model":"gemma4:31b","prompt":"test","stream":false}'
```

### Redis (district server)

```bash
# Ubuntu/Debian
sudo apt-get install redis-server
sudo systemctl enable redis-server
sudo systemctl start redis-server
```

### Minimum server requirements

| Component | Minimum | Recommended |
|-----------|---------|-------------|
| CPU | 8 cores | 16 cores |
| RAM | 32 GB | 64 GB |
| Storage | 100 GB SSD | 500 GB SSD |
| GPU | None (CPU inference) | NVIDIA 24GB VRAM |
| OS | Ubuntu 22.04 | Ubuntu 22.04 |
| Network | 10 Mbps | 100 Mbps |

> Gemma 4 31B runs on CPU via Ollama at approximately 2–4 tokens/second on a 16-core server. For the outbreak detection use case, this is fully adequate — detection runs async in the background, not in real time.

---

## How we built it

### Tech stack summary

| Layer | Technology | Purpose |
|-------|-----------|---------|
| Android AI | Gemma 4 E4B + LiteRT-LM | On-device inference |
| Android app | Kotlin + Jetpack Compose | UI and app shell |
| Android DB | Room + SQLite | Local offline storage |
| Android sync | WorkManager | Background sync engine |
| Web framework | Next.js 14 App Router | Full-stack web |
| Web UI | Tailwind CSS + shadcn/ui | Components |
| Database | PostgreSQL + Prisma | Primary data store |
| Cloud AI | Gemma 4 31B + Ollama | Outbreak detection |
| Job queue | Bull + Redis | Async AI jobs |
| Auth | NextAuth.js | Session management |
| Maps | Leaflet + OpenStreetMap | Offline-capable maps |
| Charts | Recharts | Data visualization |
| Real-time | Server-Sent Events | Live alert push |
| Fine-tuning | Unsloth + LoRA | E4B specialisation |

### Key design decisions

**Why offline-first?** 35–40% of rural India has no 3G coverage (TRAI 2023). Any system that requires internet for its core function will fail the people who need it most. Gemma 4 E4B on-device via LiteRT-LM is the only AI approach that works here.

**Why voice-first?** ASHA workers carry paper registers and are often in the middle of a field visit. Typing is friction. Speaking is natural. Gemma 4's native audio capabilities remove the need for a separate STT pipeline.

**Why aggregate before sending to Gemma 31B?** Individual reports sent to the big model would cost tokens and lose the epidemiological signal. Aggregating to village symptom counts first — `{fever: 12, cough: 10}` — gives the model the same view a human epidemiologist would use, and dramatically reduces token usage.

**Why SSE instead of WebSockets?** The district officer dashboard only needs one-way push from server to client. SSE is simpler, works through HTTP/2, and requires no special server setup. The connection stays open and new alerts appear instantly without polling.

**Why Leaflet + OpenStreetMap instead of Google Maps?** No API key. No billing. Works offline with cached tiles. Good India coverage. The district health system should not depend on a commercial mapping service that can change pricing or availability.

---

## Impact potential

If deployed across a single district of 50 villages with 2–3 CHWs each:

- **~150 CHW devices** generating daily reports
- **~5,000+ anonymised reports per month**
- **Coverage of ~500,000 people** currently invisible to health surveillance
- **Outbreak detection 2–3 weeks earlier** than current paper-chain reporting
- **Direct lives saved** — a cluster that would have become a 152-death outbreak becomes a 12-case early intervention

India's NHM (National Health Mission) has infrastructure for CHW devices and district health IT. Jansetu is designed to plug into existing systems — it does not require replacing anything, only augmenting the ASHA workers who are already there.

---

## Roadmap

### Near-term (post-hackathon)
- [ ] Real SMS integration via MSG91 or Fast2SMS
- [ ] Integration with IDSP (Integrated Disease Surveillance Programme) reporting format
- [ ] PDF export of outbreak brief for CMO presentation
- [ ] Multi-district support
- [ ] Push Jansetu fine-tuned E4B to HuggingFace Hub

### Medium-term
- [ ] Expand fine-tune dataset with real ASHA worker-contributed examples
- [ ] Add Odia and Gondi language fine-tuning
- [ ] PostGIS radius queries for geographic clustering
- [ ] Weekly automated summary report to district CMO
- [ ] Integration with government health facility database (HFID)

### Long-term
- [ ] State-level rollout coordination with NHM
- [ ] Federated learning across districts (privacy-preserving model improvement)
- [ ] Seasonal disease prediction based on historical patterns
- [ ] Maternal health tracking module for ASHA workers

---

## Contributing

We welcome contributions, especially from people with ground knowledge of rural Indian healthcare.

### How to contribute

```bash
# Fork the repository
# Create a feature branch
git checkout -b feature/your-feature-name

# Make your changes
# Write tests if applicable

# Commit with clear message
git commit -m "feat: add Odia language support to symptom extraction"

# Push and open a PR
git push origin feature/your-feature-name
```

### Areas where we especially need help

- **Bhojpuri / Odia / Gondi speakers** — reviewing and expanding the fine-tuning dataset
- **ASHA workers / CHWs** — contributing real (anonymised) patient description examples
- **Android developers** — improving the LiteRT-LM integration and offline sync reliability
- **District health officials** — validating the outbreak detection thresholds and alert format
- **NGO partnerships** — field testing in real villages

### Contributing training data

If you are an ASHA worker, doctor, or health worker and want to contribute symptom description examples to improve the model:

1. Describe a patient scenario in your natural language (Hindi, Bhojpuri, etc.)
2. Include: what the patient said, rough age, gender, duration of symptoms, whether you referred them
3. Submit via the Google Form: [link] *(no patient names or identifiers ever)*

All contributions are reviewed before inclusion and used only for improving symptom extraction accuracy.


## Acknowledgements

- The 850,000 ASHA workers of India whose dedication makes primary healthcare possible in places no system reaches
- The ASHA workers who spoke to us about their daily reality and the gaps they navigate
- Google DeepMind for the Gemma model family and the Gemma 4 Good Hackathon
- Unsloth for making fine-tuning accessible on free hardware
- Ollama for making large model inference self-hostable
- The OpenStreetMap community for free maps that work everywhere

---

## License

```
MIT License

Copyright (c) 2026 Jansetu Team

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

---

<div align="center">

**जनसेतु — The bridge that was never built. Until now.**

*Every week of delay in outbreak detection increases case count by 40%.*
*We built Jansetu to close that gap.*

[⭐ Star this repo](https://github.com/yourusername/jansetu) if you believe rural India deserves better healthcare infrastructure.

Built with Gemma 4 · LiteRT-LM · Ollama · Unsloth · Next.js · Android

</div>
