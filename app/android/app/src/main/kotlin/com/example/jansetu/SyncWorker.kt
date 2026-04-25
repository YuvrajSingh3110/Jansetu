package com.example.jansetu

import android.content.Context
import androidx.work.*
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import org.json.JSONArray
import org.json.JSONObject
import java.io.ByteArrayOutputStream
import java.net.HttpURLConnection
import java.net.URL
import java.util.zip.GZIPOutputStream

class SyncWorker(context: Context, params: WorkerParameters) : CoroutineWorker(context, params) {

    override suspend fun doWork(): Result = withContext(Dispatchers.IO) {
        val database = SyncQueueDatabase.getDatabase(applicationContext)
        val dao = database.reportDao()
        val deviceId = DeviceIdentity.getDeviceId(applicationContext)

        val pending = dao.getPendingReports(100)
        if (pending.isEmpty()) return@withContext Result.success()

        var currentBatch = mutableListOf<ReportEntity>()
        var currentBatchSize = 0
        
        for (report in pending) {
            // Chunk toward ~2KB
            if (currentBatchSize + report.payloadSize > 2048 && currentBatch.isNotEmpty()) {
                val uploadResult = uploadBatch(currentBatch, deviceId)
                handleUploadResult(dao, currentBatch, uploadResult)
                if (uploadResult == UploadResult.RETRY) return@withContext Result.retry()
                
                currentBatch = mutableListOf()
                currentBatchSize = 0
            }
            currentBatch.add(report)
            currentBatchSize += report.payloadSize
        }
        
        if (currentBatch.isNotEmpty()) {
            val uploadResult = uploadBatch(currentBatch, deviceId)
            handleUploadResult(dao, currentBatch, uploadResult)
            if (uploadResult == UploadResult.RETRY) return@withContext Result.retry()
        }

        Result.success()
    }

    private suspend fun handleUploadResult(dao: ReportDao, reports: List<ReportEntity>, result: UploadResult) {
        val ids = reports.map { it.id }
        when (result) {
            UploadResult.SUCCESS -> dao.updateStatus(ids, "SENT")
            UploadResult.FAILED_400 -> dao.updateStatus(ids, "FAILED")
            UploadResult.RETRY -> { /* Do nothing, WorkManager will retry */ }
        }
    }

    private fun uploadBatch(reports: List<ReportEntity>, deviceId: String): UploadResult {
        val root = JSONObject()
        val array = JSONArray()
        reports.forEach {
            val item = JSONObject()
            item.put("timestamp", it.timestamp)
            item.put("signal_type", it.signalType)
            try {
                item.put("payload", JSONObject(it.payload))
            } catch (e: Exception) {
                item.put("payload", it.payload)
            }
            array.put(item)
        }
        root.put("reports", array)

        val body = root.toString().toByteArray(Charsets.UTF_8)
        val useGzip = body.size > 1024

        return try {
            val url = URL("https://your-api-endpoint.com/api/ingest/reports") // Placeholder
            val conn = url.openConnection() as HttpURLConnection
            conn.requestMethod = "POST"
            conn.doOutput = true
            conn.setRequestProperty("Content-Type", "application/json")
            conn.setRequestProperty("X-Device-ID", deviceId)

            val finalBody = if (useGzip) {
                conn.setRequestProperty("Content-Encoding", "gzip")
                val bos = ByteArrayOutputStream()
                GZIPOutputStream(bos).use { it.write(body) }
                bos.toByteArray()
            } else {
                body
            }

            conn.outputStream.use { it.write(finalBody) }

            val code = conn.responseCode
            when (code) {
                in 200..299 -> UploadResult.SUCCESS
                400 -> UploadResult.FAILED_400
                else -> UploadResult.RETRY
            }
        } catch (e: Exception) {
            UploadResult.RETRY
        }
    }

    enum class UploadResult {
        SUCCESS, FAILED_400, RETRY
    }

    companion object {
        fun schedule(context: Context) {
            val constraints = Constraints.Builder()
                .setRequiredNetworkType(NetworkType.CONNECTED)
                .build()

            val request = OneTimeWorkRequestBuilder<SyncWorker>()
                .setConstraints(constraints)
                .setBackoffCriteria(BackoffPolicy.EXPONENTIAL, WorkRequest.MIN_BACKOFF_MILLIS, java.util.concurrent.TimeUnit.MILLISECONDS)
                .build()

            WorkManager.getInstance(context).enqueueUniqueWork(
                "sync_reports",
                ExistingWorkPolicy.APPEND_OR_REPLACE,
                request
            )
        }
    }
}
