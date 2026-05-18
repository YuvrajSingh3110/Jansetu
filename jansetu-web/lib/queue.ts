import Bull from 'bull'
import { runOutbreakDetection } from './outbreak-detector'

let outbreakQueue: Bull.Queue | null = null

function getQueue(): Bull.Queue | null {
  if (outbreakQueue) return outbreakQueue
  if (!process.env.REDIS_URL) return null

  try {
    outbreakQueue = new Bull('outbreak-detection', process.env.REDIS_URL)

    outbreakQueue.process(async (job) => {
      const { districtId } = job.data
      await runOutbreakDetection(districtId, 72)
    })

    // Every 2 hours regardless of ingestion
    outbreakQueue.add(
      { districtId: 'dist001varanasi' },
      { repeat: { cron: '0 */2 * * *' } }
    )

    outbreakQueue.on('failed', (job, err) => {
      console.error('Outbreak detection job failed:', err)
    })

    return outbreakQueue
  } catch (err) {
    console.error('Redis not available, queue disabled:', err)
    return null
  }
}

export async function enqueueOutbreakDetection(districtId: string): Promise<boolean> {
  try {
    const queue = getQueue()
    if (!queue) return false
    await queue.add({ districtId }, { attempts: 2, backoff: 5000 })
    return true
  } catch (err) {
    console.error('Failed to enqueue detection:', err)
    return false
  }
}
