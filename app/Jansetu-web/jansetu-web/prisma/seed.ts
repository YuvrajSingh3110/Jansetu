import { PrismaClient } from '@prisma/client'
import bcrypt from 'bcryptjs'

const prisma = new PrismaClient()

function hoursAgo(h: number) {
  return new Date(Date.now() - h * 60 * 60 * 1000)
}

function randomItem<T>(arr: T[]): T {
  return arr[Math.floor(Math.random() * arr.length)]
}

async function main() {
  console.log('Seeding Jansetu database (PostgreSQL)...')

  const district = await prisma.district.upsert({
    where: { id: 'dist001varanasi' },
    update: {},
    create: { id: 'dist001varanasi', name: 'Varanasi', state: 'Uttar Pradesh' },
  })

  const blockRampur = await prisma.block.upsert({
    where: { id: 'blk001rampur' },
    update: {},
    create: { id: 'blk001rampur', name: 'Rampur Block', districtId: district.id },
  })
  const blockMau = await prisma.block.upsert({
    where: { id: 'blk002mau' },
    update: {},
    create: { id: 'blk002mau', name: 'Mau Block', districtId: district.id },
  })
  const blockKhajuri = await prisma.block.upsert({
    where: { id: 'blk003khajuri' },
    update: {},
    create: { id: 'blk003khajuri', name: 'Khajuri Block', districtId: district.id },
  })

  const villages = [
    { id: 'clv001rampur',   name: 'Rampur',   lat: 25.4358, lng: 82.9109, blockId: blockRampur.id },
    { id: 'clv002barsara',  name: 'Barsara',  lat: 25.4421, lng: 82.9234, blockId: blockRampur.id },
    { id: 'clv003khajuri',  name: 'Khajuri',  lat: 25.4289, lng: 82.9312, blockId: blockRampur.id },
    { id: 'clv004mau',      name: 'Mau',      lat: 25.4512, lng: 82.8967, blockId: blockMau.id },
    { id: 'clv005saidpur',  name: 'Saidpur',  lat: 25.4601, lng: 82.8812, blockId: blockMau.id },
    { id: 'clv006chakia',   name: 'Chakia',   lat: 25.4189, lng: 82.8756, blockId: blockMau.id },
    { id: 'clv007deoria',   name: 'Deoria',   lat: 25.4698, lng: 82.9456, blockId: blockKhajuri.id },
    { id: 'clv008bhelpur',  name: 'Bhelpur',  lat: 25.4123, lng: 82.9567, blockId: blockKhajuri.id },
    { id: 'clv009harahua',  name: 'Harahua',  lat: 25.4756, lng: 82.9123, blockId: blockKhajuri.id },
    { id: 'clv010cholapur', name: 'Cholapur', lat: 25.4034, lng: 82.8934, blockId: blockRampur.id },
  ]

  for (const v of villages) {
    await prisma.village.upsert({ where: { id: v.id }, update: {}, create: v })
  }

  const chwData = [
    { id: 'chw001seema',  name: 'Seema Devi',   employeeId: 'VR-2841', blockId: blockRampur.id },
    { id: 'chw002priya',  name: 'Priya Mishra', employeeId: 'VR-2842', blockId: blockRampur.id },
    { id: 'chw003rama',   name: 'Rama Kumari',  employeeId: 'VR-2843', blockId: blockMau.id },
    { id: 'chw004anita',  name: 'Anita Singh',  employeeId: 'VR-2844', blockId: blockMau.id },
    { id: 'chw005sunita', name: 'Sunita Yadav', employeeId: 'VR-2845', blockId: blockKhajuri.id },
  ]
  for (const c of chwData) {
    await prisma.cHW.upsert({
      where: { id: c.id },
      update: {},
      create: { ...c, phone: `+919000001234`, lastSyncAt: hoursAgo(Math.floor(Math.random() * 20)), reportsCount: Math.floor(4 + Math.random() * 10), isActive: true },
    })
  }

  const hashedPassword = await bcrypt.hash('jansetu2026', 10)
  await prisma.officer.upsert({
    where: { email: 'demo@jansetu.in' },
    update: {},
    create: { name: 'Dr. Sharma', email: 'demo@jansetu.in', password: hashedPassword, role: 'dho', districtId: district.id },
  })

  await prisma.report.deleteMany({})

  type ReportInput = {
    sourceType: string; villageId: string; chwId: string | null
    ageGroup: string; gender: string; symptoms: string[]; duration: number | null
    severity: string; hasPhoto: boolean; referral: boolean
    reportedAt: Date
  }

  const reports: ReportInput[] = []

  // Rampur cluster: 12 fever+cough
  for (let i = 0; i < 12; i++) {
    reports.push({
      sourceType: i % 3 === 0 ? 'village_user' : 'chw',
      villageId: 'clv001rampur',
      chwId: i % 3 !== 0 ? 'chw001seema' : null,
      ageGroup: randomItem(['child', 'adult', 'elderly']),
      gender: randomItem(['M', 'F']),
      symptoms: i < 3 ? ['fever', 'cough', 'breathlessness'] : ['fever', 'cough'],
      duration: Math.floor(1 + Math.random() * 4),
      severity: i < 3 ? 'moderate' : 'mild',
      hasPhoto: false, referral: i < 2,
      reportedAt: hoursAgo(Math.floor(Math.random() * 72)),
    })
  }
  // Barsara: 8 fever+cough
  for (let i = 0; i < 8; i++) {
    reports.push({
      sourceType: 'chw', villageId: 'clv002barsara', chwId: 'chw002priya',
      ageGroup: randomItem(['child', 'adult', 'elderly']), gender: randomItem(['M', 'F']),
      symptoms: ['fever', 'cough'], duration: 2, severity: 'mild',
      hasPhoto: false, referral: false,
      reportedAt: hoursAgo(Math.floor(Math.random() * 72)),
    })
  }
  // Khajuri: 6 fever+cough
  for (let i = 0; i < 6; i++) {
    reports.push({
      sourceType: 'chw', villageId: 'clv003khajuri', chwId: 'chw005sunita',
      ageGroup: randomItem(['child', 'adult']), gender: randomItem(['M', 'F']),
      symptoms: ['fever', 'cough'], duration: 2, severity: 'mild',
      hasPhoto: false, referral: false,
      reportedAt: hoursAgo(Math.floor(Math.random() * 72)),
    })
  }
  // Mau: 5 diarrhoea
  for (let i = 0; i < 5; i++) {
    reports.push({
      sourceType: 'chw', villageId: 'clv004mau', chwId: 'chw003rama',
      ageGroup: randomItem(['child', 'adult', 'elderly']), gender: randomItem(['M', 'F']),
      symptoms: ['diarrhoea', 'vomiting'], duration: 1, severity: 'moderate',
      hasPhoto: false, referral: false,
      reportedAt: hoursAgo(Math.floor(Math.random() * 48)),
    })
  }
  // Other villages: 1-3 random
  for (const vid of ['clv005saidpur', 'clv006chakia', 'clv007deoria', 'clv008bhelpur', 'clv009harahua', 'clv010cholapur']) {
    const count = Math.floor(1 + Math.random() * 3)
    for (let i = 0; i < count; i++) {
      reports.push({
        sourceType: 'chw', villageId: vid, chwId: null,
        ageGroup: randomItem(['child', 'adult']), gender: randomItem(['M', 'F']),
        symptoms: [randomItem(['fever', 'cough', 'headache', 'bodyache'])],
        duration: 1, severity: 'mild', hasPhoto: false, referral: false,
        reportedAt: hoursAgo(Math.floor(Math.random() * 72)),
      })
    }
  }

  for (const r of reports) {
    await prisma.report.create({ data: r })
  }

  // Pre-created alerts
  await prisma.alert.deleteMany({ where: { districtId: district.id } })

  const alert = await prisma.alert.create({
    data: {
      districtId: district.id,
      type: 'outbreak', confidence: 'high',
      title: 'Rampur cluster · ILI outbreak',
      description: '18 fever+cough cases detected across 3 geographically adjacent villages (Rampur, Barsara, Khajuri) within 72 hours. Case density: 6/day. Consistent with influenza-like illness.',
      affectedVillages: ['Rampur', 'Barsara', 'Khajuri'],
      symptomCluster: ['fever', 'cough', 'breathlessness'],
      caseCount: 26, timeWindowHrs: 72,
      aggregatedInput: { Rampur: { fever: 12, cough: 12, breathlessness: 3 }, Barsara: { fever: 8, cough: 8 }, Khajuri: { fever: 6, cough: 6 } },
      aiAnalysis: { riskLevel: 'high', confidence: 'high', diseasePattern: 'ILI', caseCount: 26, reasoning: 'Same symptom cluster across 3 adjacent villages in 72h window exceeds high-risk threshold.' },
      status: 'active',
      createdAt: hoursAgo(14),
      actions: {
        create: [
          { step: 1, title: 'Deploy rapid response to Rampur', description: 'Doctor + 2 nurses, ILI test kits, antipyretics, ORS', status: 'pending' },
          { step: 2, title: 'Broadcast advisory to 3 villages', description: 'Hindi voice message via CHW phones', status: 'in_progress' },
          { step: 3, title: 'Increase CHW reporting 2x/day', description: 'Requested for 7 days in affected block', status: 'done' },
        ],
      },
    },
  })

  await prisma.alert.create({
    data: {
      districtId: district.id,
      type: 'watch', confidence: 'medium',
      title: 'Mau diarrhoea watch',
      description: '5 diarrhoea cases in 2 days in Mau block. Below outbreak threshold but trending upward.',
      affectedVillages: ['Mau'],
      symptomCluster: ['diarrhoea', 'vomiting'],
      caseCount: 5, timeWindowHrs: 48,
      aggregatedInput: { Mau: { diarrhoea: 5, vomiting: 3 } },
      aiAnalysis: { riskLevel: 'medium', confidence: 'medium', diseasePattern: 'gastroenteritis' },
      status: 'active',
      createdAt: hoursAgo(6),
      actions: {
        create: [
          { step: 1, title: 'Monitor Mau village closely', description: 'Increase CHW check-in frequency to daily', status: 'pending' },
          { step: 2, title: 'Advise boiling water', description: 'Send basic hygiene advisory', status: 'pending' },
        ],
      },
    },
  })

  // Default alert threshold settings
  const defaultSettings = [
    { key: 'outbreak_high_cases', value: '15', label: 'High-risk case threshold' },
    { key: 'outbreak_medium_cases', value: '8', label: 'Medium-risk case threshold' },
    { key: 'outbreak_low_cases', value: '5', label: 'Low-risk case threshold' },
    { key: 'outbreak_window_hrs', value: '72', label: 'Detection window (hours)' },
    { key: 'outbreak_min_reports', value: '5', label: 'Minimum reports to trigger AI check' },
  ]
  for (const s of defaultSettings) {
    await prisma.setting.upsert({ where: { key: s.key }, update: {}, create: s })
  }

  console.log('Seed complete. Login: demo@jansetu.in / jansetu2026')
  console.log('Alert ID:', alert.id)
}

main().catch((e) => { console.error(e); process.exit(1) }).finally(() => prisma.$disconnect())
