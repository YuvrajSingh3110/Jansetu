import { NextRequest, NextResponse } from 'next/server'
import { getServerSession } from 'next-auth'
import { authOptions } from '@/lib/auth'
import { prisma } from '@/lib/prisma'
import { format } from 'date-fns'

export async function GET(req: NextRequest) {
  const session = await getServerSession(authOptions)
  if (!session) return NextResponse.json({ error: 'unauthorized' }, { status: 401 })

  const districtId = (session.user as any)?.districtId || 'dist001varanasi'
  const { searchParams } = new URL(req.url)

  const where: any = {
    village: { block: { districtId } },
    ...(searchParams.get('villageId') ? { villageId: searchParams.get('villageId') } : {}),
    ...(searchParams.get('source') ? { sourceType: searchParams.get('source') } : {}),
    ...(searchParams.get('severity') ? { severity: searchParams.get('severity') } : {}),
  }

  const reports = await prisma.report.findMany({
    where,
    include: { village: true, chw: { select: { name: true, employeeId: true } } },
    orderBy: { syncedAt: 'desc' },
    take: 5000,
  })

  const symptomFilter = searchParams.get('symptom')
  const filtered = symptomFilter
    ? reports.filter((r) => r.symptoms.includes(symptomFilter))
    : reports

  const header = 'Time,Village,Source,CHW,Age Group,Gender,Symptoms,Duration,Severity,Referral,Reported At\n'
  const rows = filtered.map((r) =>
    [
      format(r.syncedAt, 'yyyy-MM-dd HH:mm'),
      r.village.name,
      r.sourceType,
      r.chw ? `${r.chw.name} (${r.chw.employeeId})` : '',
      r.ageGroup,
      r.gender,
      `"${r.symptoms.join('; ')}"`,
      r.duration ?? '',
      r.severity,
      r.referral ? 'Yes' : 'No',
      format(r.reportedAt, 'yyyy-MM-dd HH:mm'),
    ].join(',')
  ).join('\n')

  return new NextResponse(header + rows, {
    headers: {
      'Content-Type': 'text/csv',
      'Content-Disposition': `attachment; filename="jansetu-reports-${format(new Date(), 'yyyy-MM-dd')}.csv"`,
    },
  })
}
