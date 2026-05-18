# tasks.md — Jansetu web
> Update every day. Max 3 items in "Doing right now" at any time.
> Never delete completed tasks — mark ✅ with date. If a task is "in progress" 3+ days, break it smaller.

---

## 🔥 Doing right now
<!-- MAX 3 ITEMS -->

- [ ] Next.js project setup + Prisma schema
- [ ] Sidebar + Topbar layout shell

---

## 📋 Up next

### Week 1 (Apr 25 – May 1) — Foundation
- [ ] `prisma db seed` — Varanasi district + deliberate fever+cough cluster in Rampur
- [ ] Verify seed: check DB has 26 reports in Rampur/Barsara/Khajuri, pre-created alert
- [ ] `POST /api/ingest/reports` — store + queue, return 200 fast — **unblocks Android team**
- [ ] Share API_CONTRACT.md with Yuvraj (village IDs + endpoint spec)
- [ ] `/dashboard` with hardcoded mock data (get visual right first)
- [ ] NextAuth login page (demo@jansetu.in / jansetu2026)

### Week 2 (May 2–8) — AI pipeline (STEP 6)
- [ ] Docker Redis: `docker run -d -p 6379:6379 redis`
- [ ] `lib/outbreak-detector.ts` — aggregation logic (village symptom counts)
- [ ] `lib/ollama.ts` — Gemma 4 27B call with correct prompt + temperature 0.1
- [ ] Bull queue setup in `lib/queue.ts`
- [ ] `POST /api/internal/detect-outbreak` wired to queue
- [ ] Test: POST 20 fever+cough reports to Rampur → alert should appear in DB
- [ ] Wire `/dashboard` to real DB (stat cards + alert cards from real data)
- [ ] SSE stream `/api/alerts/stream` — live feed on dashboard

### Week 3 (May 9–14) — Heatmap + broadcast (STEP 7)
- [ ] Leaflet map component (dynamic import, no SSR)
- [ ] `GET /api/analytics/heatmap` with village aggregation
- [ ] Village circles on map (radius by case count, color by risk)
- [ ] Timeline slider (re-fetches API on drag)
- [ ] Symptom filter chips (fever, cough, diarrhoea, rash, malnutrition)
- [ ] Village drill-down side panel (click circle → stats)
- [ ] `/alerts` list page + `/alerts/[id]` detail + response playbook
- [ ] `/broadcast` page — AI draft + composer
- [ ] `POST /api/broadcast/draft` → Gemma drafts Hindi + English
- [ ] `/chw` network page
- [ ] `/reports` table with filters + CSV export

### Week 4 (May 15–17) — Polish + demo
- [ ] Seed data looks realistic (CHW names, timestamps spread naturally)
- [ ] Full E2E test: ingest → detection → alert appears → broadcast sent
- [ ] All pages load without errors on 1280px screen
- [ ] No placeholder/lorem ipsum text anywhere
- [ ] `/settings` page — Ollama connection test, officer accounts
- [ ] README.md with setup instructions (for Kaggle submission)
- [ ] Demo screenshots for submission writeup
- [ ] Brief Apoorv on how to run the full stack locally

---

## ✅ Completed


---

## 🚧 Blocked / needs decision


---

## 💡 Later (post-hackathon)
- Real SMS via MSG91 or Fast2SMS
- PDF export of outbreak brief for CMO
- Multi-district support
- Weekly summary email to DHO
- PostGIS radius queries for geo clustering