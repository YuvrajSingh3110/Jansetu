import type { Metadata } from 'next'
import './globals.css'
import 'leaflet/dist/leaflet.css'
import { AuthProvider } from '@/components/providers/AuthProvider'

export const metadata: Metadata = {
  title: 'Jansetu — District Health Intelligence',
  description: 'District-level epidemiological intelligence platform for rural India',
}

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <body>
        <AuthProvider>{children}</AuthProvider>
      </body>
    </html>
  )
}
