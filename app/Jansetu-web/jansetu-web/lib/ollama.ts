const OLLAMA_URL = process.env.OLLAMA_URL || 'http://localhost:11434'
const OLLAMA_MODEL = process.env.OLLAMA_MODEL || 'gemma4:31b'

// gemma-4-31b-it cannot produce JSON output via this API (reasoning model, outputs bullet text).
// gemini-2.5-flash is on the same Google AI key, works correctly, and is free-tier.
const GEMMA_MODELS = [
  'gemini-2.5-flash',       // primary — confirmed working
  'gemini-flash-latest',    // alias fallback
  'gemini-2.5-flash-lite',  // lighter fallback
]

function extractJSON(text: string): any {
  // Try direct parse first
  try { return JSON.parse(text.trim()) } catch {}

  // Strip markdown code fences
  const stripped = text.replace(/^```(?:json)?\s*/im, '').replace(/\s*```\s*$/im, '').trim()
  try { return JSON.parse(stripped) } catch {}

  // Find the outermost JSON object — handles preamble like "AI assistant: {..."
  const start = text.indexOf('{')
  if (start !== -1) {
    let depth = 0
    for (let i = start; i < text.length; i++) {
      if (text[i] === '{') depth++
      else if (text[i] === '}') { depth--; if (depth === 0) return JSON.parse(text.slice(start, i + 1)) }
    }
  }

  throw new Error(`No JSON found in model output: ${text.slice(0, 120)}`)
}

async function gemmaModelGenerate(model: string, prompt: string, temperature: number, key: string): Promise<any> {
  const url = `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${key}`
  console.log(`[Gemma] Trying model: ${model}`)
  const res = await fetch(url, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      systemInstruction: {
        parts: [{ text: 'You are a JSON API. Respond ONLY with a valid JSON object. No explanations, no markdown, no preamble. Output the JSON object and nothing else.' }],
      },
      contents: [{ role: 'user', parts: [{ text: prompt }] }],
      generationConfig: {
        responseMimeType: 'application/json',
        temperature,
      },
    }),
    signal: AbortSignal.timeout(60000),
  })
  if (!res.ok) {
    const err = await res.text()
    throw new Error(`${model} error ${res.status}: ${err}`)
  }
  const data = await res.json()
  const rawText: string = data.candidates?.[0]?.content?.parts?.[0]?.text ?? ''
  if (!rawText) throw new Error(`${model} returned empty response`)
  return extractJSON(rawText)
}

async function gemmaCloudGenerate(prompt: string, temperature = 0.1): Promise<any> {
  const key = process.env.GOOGLE_AI_KEY
  if (!key) throw new Error('GOOGLE_AI_KEY env var is not set')

  console.log(`[Gemma] Key present: yes, models to try: ${GEMMA_MODELS.join(', ')}`)

  let lastErr: Error = new Error('No models tried')
  for (const model of GEMMA_MODELS) {
    try {
      const result = await gemmaModelGenerate(model, prompt, temperature, key)
      console.log(`[Gemma] Success with model: ${model}`)
      return result
    } catch (err) {
      console.error(`[Gemma] Model ${model} failed:`, err)
      lastErr = err as Error
    }
  }
  throw lastErr
}

async function ollamaGenerate(prompt: string, temperature = 0.1): Promise<any> {
  // When GOOGLE_AI_KEY is set, skip local Ollama and go straight to Gemma cloud.
  // Ollama's 2-minute timeout would kill Vercel serverless functions.
  if (process.env.GOOGLE_AI_KEY) return gemmaCloudGenerate(prompt, temperature)

  // Local dev without a cloud key: use Ollama directly
  try {
    const res = await fetch(`${OLLAMA_URL}/api/generate`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        model: OLLAMA_MODEL,
        prompt,
        stream: false,
        format: 'json',
        options: { temperature },
      }),
      signal: AbortSignal.timeout(120000),
    })
    if (!res.ok) throw new Error('Ollama request failed')
    const data = await res.json()
    return JSON.parse(data.response)
  } catch (err) {
    console.error('[Ollama] Failed, no GOOGLE_AI_KEY set:', err)
    throw new Error(`Ollama unavailable and no GOOGLE_AI_KEY set: ${err}`)
  }
}

export async function generateOutbreakAnalysis(
  villageLines: string,
  districtName: string,
  windowHrs: number,
  thresholds = { high: 15, medium: 8, low: 5 }
) {
  return ollamaGenerate(`You are a district epidemiologist AI for rural India.

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
- "high": ${thresholds.high}+ cases OR breathlessness/seizure/unconscious in cluster
- "medium": ${thresholds.medium}-${thresholds.high - 1} cases OR 2+ villages same pattern
- "low": ${thresholds.low}-${thresholds.medium - 1} cases, single village, mild symptoms only
- "none": random noise, no cluster`, 0.1)
}

export async function draftBroadcastMessage(description: string, villages: string[]) {
  return ollamaGenerate(`Draft a health advisory for rural village people in India.
Situation: ${description}
Targets: ${villages.join(', ')}

Rules:
- Hindi: everyday language, no medical jargon, max 3 sentences, end with action to take
- English: same meaning, for official records
- Tone: calm, reassuring, practical

Output ONLY: { "hindi": "...", "english": "..." }`, 0.3)
}

export async function generateDailyBriefing(
  districtName: string,
  stats: { reportsToday: number; activeAlerts: number; activeCHWs: number; totalCHWs: number },
  alertSummaries: Array<{ title: string; type: string; confidence: string; caseCount: number; villages: string[] }>,
  topSymptoms: Array<{ name: string; count: number }>
) {
  const alertLines = alertSummaries.length
    ? alertSummaries.map((a) => `- ${a.type.toUpperCase()} "${a.title}": ${a.caseCount} cases in ${a.villages.join(', ')} (${a.confidence} confidence)`).join('\n')
    : '- No active alerts'

  const symptomLines = topSymptoms.map((s) => `${s.name}: ${s.count}`).join(', ')

  return ollamaGenerate(`You are an AI assistant for district health officers in rural India.

Generate a concise morning health briefing for ${districtName} district.

Today's data:
- Reports received today: ${stats.reportsToday}
- Active disease alerts: ${stats.activeAlerts}
- CHWs synced in last 24h: ${stats.activeCHWs} of ${stats.totalCHWs}
- Top symptoms this week: ${symptomLines || 'none'}

Active alerts:
${alertLines}

Output ONLY valid JSON:
{
  "headline": "<one sentence summary, most urgent thing today>",
  "situation": "<2-3 sentences: current disease situation across the district>",
  "watchPoints": ["<specific concern 1>", "<specific concern 2>", "<specific concern 3>"],
  "recommendedFocus": "<1-2 sentences: what the DHO should prioritize today>",
  "positives": "<1 sentence: what is going well>"
}`, 0.3)
}

export async function generateVillageInsight(
  villageName: string,
  blockName: string,
  symptomCounts: Record<string, number>,
  totalCases: number,
  days: number
) {
  const symptomLines = Object.entries(symptomCounts)
    .sort((a, b) => b[1] - a[1])
    .map(([s, n]) => `${s}: ${n} cases`)
    .join(', ')

  return ollamaGenerate(`You are an epidemiologist AI analyzing a single village's health data in rural India.

Village: ${villageName}, ${blockName}
Period: last ${days} days
Total cases: ${totalCases}
Symptom breakdown: ${symptomLines || 'none'}

Write a brief health assessment for this village.

Output ONLY valid JSON:
{
  "narrative": "<2-3 plain sentences: what is happening in this village, is this concerning, any pattern>",
  "riskAssessment": "<one sentence: current risk level and why>",
  "recommendation": "<one actionable sentence for the health officer>"
}`, 0.3)
}

export async function generateCHWSummary(
  chwName: string,
  blockName: string,
  totalReports: number,
  recentSymptoms: Record<string, number>,
  lastSyncHoursAgo: number | null,
  villagesCount: number
) {
  const symptomLines = Object.entries(recentSymptoms)
    .sort((a, b) => b[1] - a[1])
    .slice(0, 5)
    .map(([s, n]) => `${s}: ${n}`)
    .join(', ')

  const syncStatus = lastSyncHoursAgo === null
    ? 'never synced'
    : lastSyncHoursAgo < 24
      ? `last synced ${lastSyncHoursAgo}h ago (active)`
      : `last synced ${lastSyncHoursAgo}h ago (overdue)`

  return ollamaGenerate(`You are an AI assistant evaluating a Community Health Worker's performance in rural India.

CHW: ${chwName}, ${blockName}
Total reports submitted: ${totalReports}
Sync status: ${syncStatus}
Villages covered: ${villagesCount}
Top reported symptoms: ${symptomLines || 'none recorded'}

Assess this CHW's performance and field situation.

Output ONLY valid JSON:
{
  "performanceSummary": "<2 sentences: overall reporting performance and consistency>",
  "symptomPattern": "<1 sentence: what the reported symptoms suggest about their coverage area>",
  "syncAlert": "<one sentence: is their sync pattern healthy or concerning?>",
  "recommendation": "<one actionable suggestion for the health officer managing this CHW>"
}`, 0.3)
}

export async function generateDifferentialDiagnosis(
  symptoms: string[],
  caseCount: number,
  villages: string[],
  windowHrs: number
) {
  return ollamaGenerate(`You are a clinical epidemiologist AI for rural India.

A cluster has been detected with the following profile:
- Symptoms: ${symptoms.join(', ')}
- Cases: ${caseCount} across ${villages.length} village(s): ${villages.join(', ')}
- Time window: ${windowHrs} hours

Provide a differential diagnosis ranked by likelihood for this rural Indian context.

Output ONLY valid JSON:
{
  "differentials": [
    { "disease": "<name>", "likelihood": <0-100>, "reasoning": "<one sentence why>", "keyDistinguisher": "<what test or sign confirms/rules out>" },
    { "disease": "<name>", "likelihood": <0-100>, "reasoning": "<one sentence why>", "keyDistinguisher": "<what test or sign confirms/rules out>" },
    { "disease": "<name>", "likelihood": <0-100>, "reasoning": "<one sentence why>", "keyDistinguisher": "<what test or sign confirms/rules out>" }
  ],
  "urgentFlag": "<null or a one-sentence red flag if any symptom warrants immediate escalation>",
  "suggestedTests": ["<rapid test or clinical sign 1>", "<rapid test or clinical sign 2>"]
}`, 0.1)
}

export async function checkOllamaHealth(): Promise<boolean> {
  try {
    const res = await fetch(`${OLLAMA_URL}/api/tags`, {
      signal: AbortSignal.timeout(5000),
    })
    return res.ok
  } catch {
    return false
  }
}
