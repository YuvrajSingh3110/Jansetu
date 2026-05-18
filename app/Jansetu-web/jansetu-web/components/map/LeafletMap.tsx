'use client'
import { useEffect, useRef } from 'react'
import L from 'leaflet'

interface VillageData {
  id: string
  name: string
  block: string
  lat: number
  lng: number
  caseCount: number
  topSymptom: string | null
  symptomCounts: Record<string, number>
  riskLevel: 'high' | 'medium' | 'low'
}

const RISK_COLORS = {
  high: '#E24B4A',
  medium: '#EF9F27',
  low: '#1D9E75',
}

interface LeafletMapProps {
  villages: VillageData[]
  onVillageClick: (village: VillageData) => void
}

export default function LeafletMap({ villages, onVillageClick }: LeafletMapProps) {
  const containerRef = useRef<HTMLDivElement>(null)
  const mapRef = useRef<L.Map | null>(null)
  const circlesRef = useRef<L.CircleMarker[]>([])

  useEffect(() => {
    if (!containerRef.current || mapRef.current) return

    // Center on Varanasi district
    const map = L.map(containerRef.current, {
      center: [25.45, 82.91],
      zoom: 12,
      zoomControl: true,
    })

    L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
      attribution: '© OpenStreetMap contributors',
      maxZoom: 18,
    }).addTo(map)

    mapRef.current = map
    return () => {
      map.remove()
      mapRef.current = null
    }
  }, [])

  useEffect(() => {
    const map = mapRef.current
    if (!map) return

    // Remove old circles
    circlesRef.current.forEach((c) => c.remove())
    circlesRef.current = []

    villages.forEach((v) => {
      const radius = Math.max(6, Math.sqrt(v.caseCount) * 8)
      const color = RISK_COLORS[v.riskLevel]

      const circle = L.circleMarker([v.lat, v.lng], {
        radius,
        fillColor: color,
        color: '#fff',
        weight: 1.5,
        fillOpacity: 0.8,
        className: v.riskLevel === 'high' ? 'outbreak-pulse' : '',
      })

      circle.bindTooltip(
        `<div style="font-size:11px;font-weight:500">${v.name}</div>
         <div style="font-size:10px;color:#666">${v.caseCount} cases · ${v.block}</div>
         ${v.topSymptom ? `<div style="font-size:10px;color:#888">Top: ${v.topSymptom}</div>` : ''}`,
        { sticky: true, offset: [8, 0] }
      )

      circle.on('click', () => onVillageClick(v))
      circle.addTo(map)
      circlesRef.current.push(circle)
    })
  }, [villages, onVillageClick])

  return <div ref={containerRef} style={{ height: '100%', width: '100%' }} />
}
