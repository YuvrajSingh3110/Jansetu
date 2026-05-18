import { getServerSession } from 'next-auth'
import { redirect } from 'next/navigation'
import { authOptions } from '@/lib/auth'
import { prisma } from '@/lib/prisma'
import { Sidebar } from '@/components/layout/Sidebar'

export default async function DashboardLayout({ children }: { children: React.ReactNode }) {
  const session = await getServerSession(authOptions)
  if (!session) redirect('/login')

  const activeAlerts = await prisma.alert.count({ where: { status: 'active' } })

  return (
    <div className="flex" style={{ minHeight: '100vh' }}>
      <Sidebar alertCount={activeAlerts} />
      <div className="flex-1 flex flex-col overflow-hidden">{children}</div>
    </div>
  )
}
