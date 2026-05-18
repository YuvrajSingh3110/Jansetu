import { prisma } from './prisma'
import { generateOutbreakAnalysis } from './ollama'

async function getThresholds() {
  const rows = await prisma.setting.findMany({
    where: { key: { in: ['outbreak_high_cases', 'outbreak_medium_cases', 'outbreak_low_cases', 'outbreak_window_hrs', 'outbreak_min_reports'] } },
  })
  const m = Object.fromEntries(rows.map((r) => [r.key, Number(r.value)]))
  return {
    high: m.outbreak_high_cases ?? 15,
    medium: m.outbreak_medium_cases ?? 8,
    low: m.outbreak_low_cases ?? 5,
    windowHrs: m.outbreak_window_hrs ?? 72,
    minReports: m.outbreak_min_reports ?? 5,
  }
}

export async function runOutbreakDetection(districtId: string, windowHrsOverride?: number) {
  const thresholds = await getThresholds()
  const windowHrs = windowHrsOverride ?? thresholds.windowHrs
  const since = new Date(Date.now() - windowHrs * 60 * 60 * 1000)

  const reports = await prisma.report.findMany({
    where: {
      syncedAt: { gte: since },
      village: { block: { districtId } },
    },
    include: { village: { include: { block: true } } },
  })

  if (reports.length < thresholds.minReports) return null

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

  const lines = Object.entries(aggregated)
    .map(([village, counts]) => {
      const symptomStr = Object.entries(counts)
        .sort((a, b) => b[1] - a[1])
        .map(([s, n]) => `${s}×${n}`)
        .join(', ')
      return `${village} (${meta[village].block}): ${symptomStr}`
    })
    .join('\n')

  const district = await prisma.district.findUnique({ where: { id: districtId } })
  const districtName = district?.name || districtId

  let analysis: any
  try {
    analysis = await generateOutbreakAnalysis(lines, districtName, windowHrs, thresholds)
  } catch (err) {
    console.error('Ollama detection failed:', err)
    return null
  }

  if (!analysis || analysis.riskLevel === 'none') return null

  return await prisma.alert.create({
    data: {
      districtId,
      type: analysis.riskLevel === 'high' ? 'outbreak' : 'watch',
      confidence: analysis.confidence,
      title: analysis.alertTitle,
      description: analysis.alertDescription,
      affectedVillages: analysis.affectedVillages || [],
      symptomCluster: analysis.dominantSymptoms || [],
      caseCount: analysis.caseCount || 0,
      timeWindowHrs: windowHrs,
      aggregatedInput: aggregated,
      aiAnalysis: analysis,
      actions: {
        create: (analysis.recommendedActions || []).map((a: any) => ({
          step: a.step, title: a.title, description: a.description, status: 'pending',
        })),
      },
    },
  })
}
