package com.example.jansetu

import android.content.Context
import kotlinx.coroutines.flow.Flow
import java.util.Date
import java.text.SimpleDateFormat
import java.util.Locale
import java.util.TimeZone

data class HealthSignal(
    val type: String,
    val payload: String
)

class SyncQueueRepository(private val context: Context) {
    private val database = SyncQueueDatabase.getDatabase(context)
    private val dao = database.reportDao()

    suspend fun queueReport(signal: HealthSignal) {
        val sdf = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss'Z'", Locale.US)
        sdf.timeZone = TimeZone.getTimeZone("UTC")
        val timestamp = sdf.format(Date())

        val entity = ReportEntity(
            timestamp = timestamp,
            signalType = signal.type,
            payload = signal.payload,
            payloadSize = signal.payload.toByteArray(Charsets.UTF_8).size,
            status = "PENDING"
        )
        dao.insert(entity)
        SyncWorker.schedule(context)
    }

    fun getAllReports(): Flow<List<ReportEntity>> = dao.getAllReports()
    fun getPendingCount(): Flow<Int> = dao.getPendingCount()
    fun getPendingSize(): Flow<Long?> = dao.getPendingSize()
    
    suspend fun clearSent() = dao.clearSent()
}
