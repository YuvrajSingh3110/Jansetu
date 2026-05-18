import { NextResponse } from 'next/server'

const BASE = process.env.NEXTAUTH_URL || 'https://jansetu-web-delta.vercel.app'

/**
 * GET /api/android/docs
 * Returns the complete Android API contract as JSON.
 * Share this URL with the Android dev team.
 */
export async function GET() {
  return NextResponse.json({
    title: 'Jansetu Android API Contract',
    version: '1.0.0',
    baseUrl: BASE,
    auth: {
      type: 'Bearer token',
      header: 'Authorization: Bearer jansetu-internal-2026',
      note: 'All endpoints except /health require this header',
    },
    endpoints: [
      {
        id: 'health',
        method: 'GET',
        path: '/api/android/health',
        auth: false,
        description: 'Ping to check server reachability. Call on app startup before sync.',
        response: {
          status: 'ok',
          db: 'connected',
          serverTime: '2026-04-26T09:00:00.000Z',
          version: '1.0.0',
        },
      },
      {
        id: 'bootstrap',
        method: 'GET',
        path: '/api/android/bootstrap',
        auth: true,
        params: [{ name: 'districtId', required: true, example: 'dist001varanasi' }],
        description: 'First-launch sync. Returns villages, blocks, district info, and valid symptom codes. Cache locally — only call again after app reinstall or on demand.',
        response: {
          district: { id: 'dist001varanasi', name: 'Varanasi', state: 'Uttar Pradesh' },
          blocks: [{ id: 'blk001rampur', name: 'Rampur Block' }],
          villages: [{
            id: 'clv001rampur', name: 'Rampur',
            lat: 25.4358, lng: 82.9109,
            blockId: 'blk001rampur', block: 'Rampur Block',
          }],
          symptomCodes: ['fever', 'cough', 'breathlessness', 'diarrhoea', '...'],
          syncedAt: '2026-04-26T09:00:00.000Z',
        },
      },
      {
        id: 'chw-profile',
        method: 'GET',
        path: '/api/android/chw/profile',
        auth: true,
        params: [{ name: 'employeeId', required: true, example: 'VR-2841' }],
        description: 'CHW login. Call when CHW enters their employee ID on the app login screen. Also updates their last-seen timestamp.',
        response: {
          chw: {
            id: 'chw001seema',
            employeeId: 'VR-2841',
            name: 'Seema Devi',
            phone: '+919000001234',
            isActive: true,
            reportsCount: 47,
            lastSyncAt: '2026-04-26T09:00:00.000Z',
            block: {
              id: 'blk001rampur',
              name: 'Rampur Block',
              villages: [{ id: 'clv001rampur', name: 'Rampur', lat: 25.4358, lng: 82.9109 }],
            },
          },
        },
      },
      {
        id: 'sync',
        method: 'POST',
        path: '/api/android/sync',
        auth: true,
        description: 'Main sync endpoint. Send all queued reports + get new alerts back in one round-trip. Designed for 2G — minimal payload.',
        body: {
          chwId: 'VR-2841',
          sourceType: 'chw',
          deviceId: 'optional-uuid-for-dedup',
          reports: [{
            villageId: 'clv001rampur',
            ageGroup: 'adult',
            gender: 'F',
            symptoms: ['fever', 'cough'],
            duration: 3,
            severity: 'mild',
            hasPhoto: false,
            referral: false,
            reportedAt: '2026-04-26T09:30:00Z',
          }],
        },
        bodyNotes: {
          sourceType: '"chw" | "village_user"',
          ageGroup: '"child" | "adult" | "elderly"',
          gender: '"M" | "F" | "unknown"',
          severity: '"mild" | "moderate" | "severe"',
          symptoms: 'Array of valid symptom codes from bootstrap',
        },
        response: {
          received: 3,
          queued: true,
          chwReportsCount: 50,
          newAlerts: [{
            id: 'alert_id',
            type: 'outbreak',
            title: 'Rampur cluster · ILI outbreak',
            confidence: 'high',
            affectedVillages: ['Rampur', 'Barsara'],
            caseCount: 26,
            createdAt: '2026-04-25T20:00:00Z',
          }],
          syncedAt: '2026-04-26T09:30:05.000Z',
        },
      },
      {
        id: 'alerts',
        method: 'GET',
        path: '/api/android/alerts',
        auth: true,
        params: [
          { name: 'districtId', required: true, example: 'dist001varanasi' },
          { name: 'since', required: false, example: '2026-04-20T00:00:00Z', note: 'ISO timestamp — only return alerts newer than this' },
        ],
        description: 'Fetch active alerts for a district. Use the "since" param with the last sync time to only get new alerts.',
        response: {
          alerts: [{
            id: 'cmoejl1qc0025qajf61k1awew',
            type: 'outbreak',
            confidence: 'high',
            title: 'Rampur cluster · ILI outbreak',
            description: '18 fever+cough cases detected across 3 villages...',
            affectedVillages: ['Rampur', 'Barsara', 'Khajuri'],
            symptomCluster: ['fever', 'cough', 'breathlessness'],
            caseCount: 26,
            timeWindowHrs: 72,
            status: 'active',
            createdAt: '2026-04-25T20:00:00Z',
          }],
          fetchedAt: '2026-04-26T09:30:00.000Z',
        },
      },
    ],
    villageIds: {
      Rampur: 'clv001rampur',
      Barsara: 'clv002barsara',
      Khajuri: 'clv003khajuri',
      Mau: 'clv004mau',
      Saidpur: 'clv005saidpur',
      Chakia: 'clv006chakia',
      Deoria: 'clv007deoria',
      Bhelpur: 'clv008bhelpur',
      Harahua: 'clv009harahua',
      Cholapur: 'clv010cholapur',
    },
    chwIds: {
      'VR-2841': 'Seema Devi — Rampur Block',
      'VR-2842': 'Priya Mishra — Rampur Block',
      'VR-2843': 'Rama Kumari — Mau Block',
      'VR-2844': 'Anita Singh — Mau Block',
      'VR-2845': 'Sunita Yadav — Khajuri Block',
    },
    errorCodes: {
      401: 'Missing or invalid Authorization header',
      400: 'Missing required field — check body/params',
      404: 'Resource not found (wrong villageId / employeeId)',
      503: 'Server or DB temporarily unavailable — retry in 30s',
    },
  })
}
