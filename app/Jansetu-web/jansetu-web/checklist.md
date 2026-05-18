# checklist.md — Jansetu pre-submission
> Go through this line by line in the final 3 days (May 15–17).
> Every unchecked item is a demo risk.

---

## 🔌 Android integration
- [ ] `POST /api/ingest/reports` tested with real Android device POST (not just curl)
- [ ] Returns `{ received: N, queued: true }` within 200ms
- [ ] Handles batch of 50 reports without timeout
- [ ] Auth header `Bearer jansetu-internal-2026` validated, rejects without it
- [ ] Village IDs match between Android SQLite and web DB seed
- [ ] Symptom codes match exactly (fever not Fever, not "FEVER")
- [ ] Reports from village_user source stored correctly (no chwId)

## 🧠 STEP 6 — AI pattern detection
- [ ] Aggregation groups by village correctly before Gemma call
- [ ] Village lines format is `VillageName (Block): symptom×count, ...`
- [ ] Gemma returns valid JSON (test with `format: 'json'` in Ollama call)
- [ ] `riskLevel: "none"` → no alert created (tested)
- [ ] `riskLevel: "high"` → Alert created in DB with correct fields
- [ ] ResponseActions created correctly from `recommendedActions` array
- [ ] Detection queued on every ingest (not run synchronously)
- [ ] Cron runs every 2 hours (Bull repeat job configured)
- [ ] Fallback: if Ollama is down, ingest still returns 200 (detection just fails quietly)
- [ ] Demo seed: Rampur cluster triggers alert automatically

## 🗺️ STEP 7 — Heatmap + dashboard
- [ ] Map loads on `/heatmap` (no SSR crash)
- [ ] Village circles appear at correct lat/lng
- [ ] Circle size proportional to case count
- [ ] Red / amber / green coloring by risk level
- [ ] Timeline slider changes date range and re-fetches map data
- [ ] Symptom filter chips filter the map correctly
- [ ] Clicking a village circle opens the detail panel
- [ ] Village detail shows: name, block, case count, symptom breakdown, 7-day trend
- [ ] "View reports" and "Create broadcast" buttons work from village panel
- [ ] Active alerts sidebar shows current alerts
- [ ] SSE live feed: new alert appears on dashboard without page refresh
- [ ] Heatmap loads correctly even when Ollama is down

## 📊 Dashboard
- [ ] Stat cards show real numbers from DB (not hardcoded)
- [ ] Alert cards sorted by severity (high first)
- [ ] Action buttons work: "Deploy team" ticks playbook step, "Broadcast" opens composer
- [ ] Live reports feed updates without refresh (SSE working)
- [ ] No console errors on load

## 🔔 Alerts
- [ ] Alert list loads, tabs filter correctly
- [ ] Alert detail shows Gemma AI analysis
- [ ] Response playbook: steps tick from pending → in_progress → done
- [ ] Tick status persists on page refresh
- [ ] Broadcast button opens composer with AI draft pre-filled

## 📢 Broadcast
- [ ] AI draft generates Hindi + English via Gemma
- [ ] Both messages are editable before sending
- [ ] Target selection (block/village/district) works
- [ ] Channel selection works
- [ ] Estimated reach count shown
- [ ] Send requires confirmation (no accidental sends)
- [ ] Sent broadcast logged to DB

## 👩‍⚕️ CHW network
- [ ] Active count correct (synced within 24h)
- [ ] Not synced count correct
- [ ] Progress bars reflect actual report counts today
- [ ] Last sync time displayed correctly

## 📋 Reports table
- [ ] Filters work (village, symptom, date range, source)
- [ ] Pagination works (25 per page)
- [ ] CSV export downloads correct data
- [ ] Source badge distinguishes CHW vs village_user

## 🔐 Auth
- [ ] Login works: demo@jansetu.in / jansetu2026
- [ ] Unauthenticated routes redirect to /login
- [ ] Session persists on page refresh

## 🌐 General quality
- [ ] No "lorem ipsum" or placeholder text anywhere
- [ ] All pages load without JavaScript errors
- [ ] Works correctly on 1280px screen (standard laptop)
- [ ] Color scheme matches design (blue sidebar, red alerts, amber watch)
- [ ] `.env.example` committed to repo with all required keys (no real values)
- [ ] `README.md` has: setup instructions, how to run seed, how to start Ollama

## 📹 Demo readiness (by May 15)
- [ ] Seed creates a realistic outbreak scenario immediately on fresh DB
- [ ] Full E2E flow works in under 5 minutes: ingest batch → alert detected → shown on dashboard → broadcast drafted → sent
- [ ] Demo account credentials noted for submission: demo@jansetu.in / jansetu2026
- [ ] Screenshots captured: dashboard, heatmap, alert detail, broadcast
- [ ] App team (Yuvraj) can run the web backend locally for integrated testing