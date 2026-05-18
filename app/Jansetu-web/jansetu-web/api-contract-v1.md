Jansetu Android API Contract — v1.0
Base URL

https://jansetu-web-delta.vercel.app
Authentication
Every request (except /api/android/health) must include this header:


Authorization: Bearer jansetu-internal-2026
If missing or wrong → 401 { "error": "unauthorized" }

Recommended App Flow

App first install:
  1. GET  /api/android/health          ← is server reachable?
  2. GET  /api/android/bootstrap       ← download villages, blocks, symptom codes
  3. GET  /api/android/chw/profile     ← CHW enters employee ID → login

Normal daily use (whenever connectivity is available):
  4. POST /api/android/sync            ← upload queued reports, get new alerts back

Optionally:
  5. GET  /api/android/alerts          ← fetch alerts if needed separately
  
Endpoints
1. GET /api/android/health
No auth required. Call this on every app startup before attempting a sync.

Request:


GET https://jansetu-web-delta.vercel.app/api/android/health
Response 200:


{
  "status": "ok",
  "db": "connected",
  "serverTime": "2026-04-26T09:00:00.000Z",
  "version": "1.0.0"
}
Response 503 (server/DB down — retry in 30s):


{ "status": "error", "db": "unreachable" }
Use serverTime to detect clock drift on field devices. If device time is off by more than 5 minutes, warn the CHW.

2. GET /api/android/bootstrap
Call once on first install (or after app reset). Downloads everything the app needs to operate offline: all villages with GPS coordinates, block names, district info, and valid symptom codes.

Request:


GET /api/android/bootstrap?districtId=dist001varanasi
Authorization: Bearer jansetu-internal-2026
Query params:

Param	Required	Description
districtId	Yes	District ID. Currently: dist001varanasi
Response 200:


{
  "district": {
    "id": "dist001varanasi",
    "name": "Varanasi",
    "state": "Uttar Pradesh"
  },
  "blocks": [
    { "id": "blk001rampur",  "name": "Rampur Block" },
    { "id": "blk002mau",     "name": "Mau Block" },
    { "id": "blk003khajuri", "name": "Khajuri Block" }
  ],
  "villages": [
    { "id": "clv001rampur",  "name": "Rampur",   "lat": 25.4358, "lng": 82.9109, "blockId": "blk001rampur", "block": "Rampur Block" },
    { "id": "clv002barsara", "name": "Barsara",  "lat": 25.4421, "lng": 82.9234, "blockId": "blk001rampur", "block": "Rampur Block" },
    { "id": "clv003khajuri", "name": "Khajuri",  "lat": 25.4289, "lng": 82.9312, "blockId": "blk001rampur", "block": "Rampur Block" },
    { "id": "clv004mau",     "name": "Mau",      "lat": 25.4512, "lng": 82.8967, "blockId": "blk002mau",    "block": "Mau Block" },
    { "id": "clv005saidpur", "name": "Saidpur",  "lat": 25.4601, "lng": 82.8812, "blockId": "blk002mau",    "block": "Mau Block" },
    { "id": "clv006chakia",  "name": "Chakia",   "lat": 25.4189, "lng": 82.8756, "blockId": "blk002mau",    "block": "Mau Block" },
    { "id": "clv007deoria",  "name": "Deoria",   "lat": 25.4698, "lng": 82.9456, "blockId": "blk003khajuri","block": "Khajuri Block" },
    { "id": "clv008bhelpur", "name": "Bhelpur",  "lat": 25.4123, "lng": 82.9567, "blockId": "blk003khajuri","block": "Khajuri Block" },
    { "id": "clv009harahua", "name": "Harahua",  "lat": 25.4756, "lng": 82.9123, "blockId": "blk003khajuri","block": "Khajuri Block" },
    { "id": "clv010cholapur","name": "Cholapur", "lat": 25.4034, "lng": 82.8934, "blockId": "blk001rampur", "block": "Rampur Block" }
  ],
  "symptomCodes": [
    "fever", "cough", "breathlessness", "diarrhoea", "vomiting",
    "rash", "headache", "bodyache", "sore_throat", "runny_nose",
    "malnutrition", "jaundice", "conjunctivitis", "seizure",
    "unconscious", "bleeding"
  ],
  "syncedAt": "2026-04-26T09:00:00.000Z"
}
Store this locally in SQLite. Only call again when explicitly re-syncing or on fresh install. The symptomCodes list is the exhaustive list — only these strings are accepted in reports.

3. GET /api/android/chw/profile
CHW login screen. When a CHW enters their employee ID (e.g. VR-2841), call this. Returns their profile and the list of villages in their block.

Request:


GET /api/android/chw/profile?employeeId=VR-2841
Authorization: Bearer jansetu-internal-2026
Query params:

Param	Required	Description
employeeId	Yes	Printed on CHW's ID card (format: VR-XXXX)
Response 200:


{
  "chw": {
    "id": "chw001seema",
    "employeeId": "VR-2841",
    "name": "Seema Devi",
    "phone": "+919000001234",
    "isActive": true,
    "reportsCount": 47,
    "lastSyncAt": "2026-04-26T09:00:00.000Z",
    "block": {
      "id": "blk001rampur",
      "name": "Rampur Block",
      "villages": [
        { "id": "clv001rampur",  "name": "Rampur",   "lat": 25.4358, "lng": 82.9109 },
        { "id": "clv002barsara", "name": "Barsara",  "lat": 25.4421, "lng": 82.9234 },
        { "id": "clv003khajuri", "name": "Khajuri",  "lat": 25.4289, "lng": 82.9312 },
        { "id": "clv010cholapur","name": "Cholapur", "lat": 25.4034, "lng": 82.8934 }
      ]
    }
  }
}
Response 404:


{ "error": "CHW not found" }
This call also updates the CHW's lastSyncAt timestamp on the server — the web dashboard uses this to show who is active. Call it every time the CHW opens the app.

All active CHW employee IDs (demo data):

Employee ID	Name	Block
VR-2841	Seema Devi	Rampur Block
VR-2842	Priya Mishra	Rampur Block
VR-2843	Rama Kumari	Mau Block
VR-2844	Anita Singh	Mau Block
VR-2845	Sunita Yadav	Khajuri Block
4. POST /api/android/sync ← Main endpoint
The primary sync call. Send all queued reports in one batch and receive any new disease alerts back — designed for a single round-trip over 2G. Always returns 200 fast even if 0 reports are sent (use it as a heartbeat).

Request:


POST /api/android/sync
Authorization: Bearer jansetu-internal-2026
Content-Type: application/json
Request body:


{
  "chwId": "VR-2841",
  "sourceType": "chw",
  "deviceId": "550e8400-e29b-41d4-a716-446655440000",
  "reports": [
    {
      "villageId": "clv001rampur",
      "ageGroup": "adult",
      "gender": "F",
      "symptoms": ["fever", "cough"],
      "duration": 3,
      "severity": "mild",
      "hasPhoto": false,
      "referral": false,
      "reportedAt": "2026-04-26T09:30:00Z"
    },
    {
      "villageId": "clv001rampur",
      "ageGroup": "child",
      "gender": "M",
      "symptoms": ["fever", "cough", "breathlessness"],
      "duration": 2,
      "severity": "moderate",
      "hasPhoto": true,
      "referral": true,
      "reportedAt": "2026-04-26T10:15:00Z"
    }
  ]
}
Field rules:

Field	Type	Required	Allowed values
chwId	string	No	CHW employee ID (VR-XXXX). Omit for village user reports
sourceType	string	Yes	"chw" or "village_user"
deviceId	string	No	Any UUID — for future dedup
reports	array	Yes	Can be empty [] for heartbeat-only calls
reports[].villageId	string	Yes	Must be a valid village ID from bootstrap
reports[].ageGroup	string	Yes	"child", "adult", "elderly"
reports[].gender	string	Yes	"M", "F", "unknown"
reports[].symptoms	string[]	Yes	One or more codes from symptomCodes list
reports[].duration	int	No	Number of days patient has had symptoms
reports[].severity	string	Yes	"mild", "moderate", "severe"
reports[].hasPhoto	bool	No	Default false
reports[].referral	bool	No	Default false — set true if patient was referred to PHC
reports[].reportedAt	string	Yes	ISO 8601 timestamp of when CHW assessed the patient
Invalid symptoms are silently dropped — only codes from the symptomCodes list in bootstrap are stored. Always validate locally before sending.

Response 200:


{
  "received": 2,
  "queued": true,
  "chwReportsCount": 49,
  "newAlerts": [
    {
      "id": "cmoejl1qc0025qajf61k1awew",
      "type": "outbreak",
      "title": "Rampur cluster · ILI outbreak",
      "confidence": "high",
      "affectedVillages": ["Rampur", "Barsara", "Khajuri"],
      "caseCount": 26,
      "createdAt": "2026-04-25T20:00:00.000Z"
    }
  ],
  "syncedAt": "2026-04-26T10:20:05.000Z"
}
Response field	Description
received	Number of reports successfully stored
queued	true means AI outbreak detection was triggered in background
chwReportsCount	CHW's updated total report count — show in app profile
newAlerts	Active alerts created since this CHW's last sync — show as notifications
syncedAt	Server timestamp — save this and use as since param in next alerts fetch
Empty sync (heartbeat only):


{
  "chwId": "VR-2841",
  "sourceType": "chw",
  "reports": []
}
Returns received: 0 — still updates CHW's lastSyncAt and returns any new alerts.

5. GET /api/android/alerts
Fetch active disease alerts for a district. Use the since parameter so only new alerts are returned — saves bandwidth.

Request:


GET /api/android/alerts?districtId=dist001varanasi&since=2026-04-25T00:00:00Z
Authorization: Bearer jansetu-internal-2026
Query params:

Param	Required	Description
districtId	Yes	dist001varanasi
since	No	ISO 8601 timestamp. Only returns alerts created after this time. Store syncedAt from previous sync and pass it here
Response 200:


{
  "alerts": [
    {
      "id": "cmoejl1qc0025qajf61k1awew",
      "type": "outbreak",
      "confidence": "high",
      "title": "Rampur cluster · ILI outbreak",
      "description": "18 fever+cough cases detected across 3 geographically adjacent villages within 72 hours.",
      "affectedVillages": ["Rampur", "Barsara", "Khajuri"],
      "symptomCluster": ["fever", "cough", "breathlessness"],
      "caseCount": 26,
      "timeWindowHrs": 72,
      "status": "active",
      "createdAt": "2026-04-25T20:00:00.000Z"
    }
  ],
  "fetchedAt": "2026-04-26T10:30:00.000Z"
}
Alert field	Values
type	"outbreak" (high risk) or "watch" (medium risk, monitoring)
confidence	"high", "medium", "low"
status	"active", "responding", "resolved"
affectedVillages	Village names (strings, not IDs)
symptomCluster	Dominant symptoms in this cluster
Error Reference
HTTP Code	Meaning	What to do
200	Success	Process response
400	Bad request — missing/invalid field	Log and fix the payload
401	Wrong or missing Authorization header	Check the Bearer token
404	Village ID or employee ID not found	Re-run bootstrap, validate IDs
503	Server or DB temporarily down	Retry after 30 seconds
Symptom Codes (complete list)
Only these exact strings are valid in reports[].symptoms:


fever          cough          breathlessness    diarrhoea
vomiting       rash           headache          bodyache
sore_throat    runny_nose     malnutrition      jaundice
conjunctivitis seizure        unconscious       bleeding
Village ID Reference
Village	ID	Block
Rampur	clv001rampur	Rampur Block
Barsara	clv002barsara	Rampur Block
Khajuri	clv003khajuri	Rampur Block
Mau	clv004mau	Mau Block
Saidpur	clv005saidpur	Mau Block
Chakia	clv006chakia	Mau Block
Deoria	clv007deoria	Khajuri Block
Bhelpur	clv008bhelpur	Khajuri Block
Harahua	clv009harahua	Khajuri Block
Cholapur	clv010cholapur	Rampur Block
Quick Test (copy-paste into terminal)

# 1. Health check
curl https://jansetu-web-delta.vercel.app/api/android/health

# 2. Bootstrap
curl -H "Authorization: Bearer jansetu-internal-2026" \
  "https://jansetu-web-delta.vercel.app/api/android/bootstrap?districtId=dist001varanasi"

# 3. CHW login
curl -H "Authorization: Bearer jansetu-internal-2026" \
  "https://jansetu-web-delta.vercel.app/api/android/chw/profile?employeeId=VR-2841"

# 4. Submit reports + get alerts
curl -X POST https://jansetu-web-delta.vercel.app/api/android/sync \
  -H "Authorization: Bearer jansetu-internal-2026" \
  -H "Content-Type: application/json" \
  -d '{
    "chwId": "VR-2841",
    "sourceType": "chw",
    "reports": [{
      "villageId": "clv001rampur",
      "ageGroup": "adult",
      "gender": "F",
      "symptoms": ["fever", "cough"],
      "duration": 2,
      "severity": "mild",
      "hasPhoto": false,
      "referral": false,
      "reportedAt": "2026-04-26T10:00:00Z"
    }]
  }'

# 5. Get active alerts
curl -H "Authorization: Bearer jansetu-internal-2026" \
  "https://jansetu-web-delta.vercel.app/api/android/alerts?districtId=dist001varanasi"

Machine-readable version of this contract: GET https://jansetu-web-delta.vercel.app/api/android/docs