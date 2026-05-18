import dynamic from 'next/dynamic'

const LeafletMap = dynamic(() => import('./LeafletMap'), {
  ssr: false,
  loading: () => (
    <div
      className="w-full h-full rounded-[8px] animate-pulse"
      style={{ background: '#c8dfa8' }}
    />
  ),
})

export default LeafletMap
