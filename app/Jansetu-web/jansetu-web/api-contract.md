# API_CONTRACT.md — Android ↔ Jansetu Web
> Share this. This is the only document he needs.
> Last updated: Apr 25, 2026

---

## Base URL

```
Dev (local):   http://192.168.x.x:3000    (Priyanshu's machine LAN IP)
Production:    https://jansetu.district.health.in
```

## Auth header (required on all requests)

```
Authorization: Bearer jansetu-internal-2026
```

---

## POST /api/ingest/reports

Sync a batch of anonymised symptom reports. Call this whenever the phone gets any signal.

**Request body:**
```json
{
  "deviceId": "550e8400-e29b-41d4-a716-446655440000",
  "chwId": "VR-2847",
  "sourceType": "chw",
  "reports": [
    {
      "villageId": "clv001rampur",
      "ageGroup": "adult",
      "gender": "F",
      "symptoms": ["fever", "cough", "breathlessness"],
      "duration": 3,
      "severity": "moderate",
      "hasPhoto": false,
      "referral": true,
      "reportedAt": "2026-04-21T09:42:00Z"
    }
  ]
}
```

**Field reference:**

| Field | Type | Values | Notes |
|-------|------|--------|-------|
| deviceId | string | UUID | Android device UUID |
| chwId | string or null | e.g. "VR-2847" | null for village users |
| sourceType | string | "chw" or "village_user" | |
| villageId | string | see village ID map below | |
| ageGroup | string | "child" / "adult" / "elderly" | |
| gender | string | "M" / "F" / "unknown" | |
| symptoms | string[] | see symptom codes below | |
| duration | number or null | days as integer | |
| severity | string | "mild" / "moderate" / "severe" | |
| hasPhoto | boolean | was a photo taken | |
| referral | boolean | PHC referral recommended | |
| reportedAt | string | ISO 8601 UTC | when CHW actually saw patient |

**Response 200:**
```json
{ "received": 3, "queued": true }
```

**Response 400:**
```json
{ "error": "missing required field: villageId" }
```

**Response 401:**
```json
{ "error": "unauthorized" }
```

---

## GET /api/villages

Fetch village list for a district. Call on first app launch, cache in SQLite.

**Request:**
```
GET /api/villages?districtId=varanasi
Authorization: Bearer jansetu-internal-2026
```

**Response:**
```json
{
  "villages": [
    { "id": "clv001rampur", "name": "Rampur", "block": "Rampur Block", "lat": 25.4358, "lng": 82.9109 }
  ]
}
```

---

## Symptom codes — use exactly these strings

```
fever          cough          breathlessness    diarrhoea
vomiting       rash           headache          bodyache
sore_throat    runny_nose     malnutrition      jaundice
conjunctivitis seizure        unconscious       bleeding
```

Note: lowercase, underscore for spaces, no variations.

---

## Village ID map (Varanasi district seed)

Hardcode these in the Android app until `GET /api/villages` is integrated:

```
Rampur   → clv001rampur      Barsara  → clv002barsara
Khajuri  → clv003khajuri     Mau      → clv004mau
Saidpur  → clv005saidpur     Chakia   → clv006chakia
Deoria   → clv007deoria      Bhelpur  → clv008bhelpur
Harahua  → clv009harahua     Cholapur → clv010cholapur
```

---

## Retry policy (Android side)

- Retry on any 5xx with exponential backoff: 1s → 2s → 4s → 8s → max 5 retries
- On 400 (bad request): do NOT retry, log error, skip that batch
- On 401: notify user to check connectivity settings
- Store failed batches in SQLite with retry_count column
- Max batch size: 100 reports per POST
- Add `Content-Encoding: gzip` header if payload >1KB

---

## Data privacy notes

- The web server never stores names, phone numbers, or any PII
- `chwId` is an employee ID (e.g. "VR-2847") — not a name
- All analysis is village-level only
- Android must strip PII before building the payload (E4B handles this on-device)