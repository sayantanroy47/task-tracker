package com.tasktracker.util

import android.app.Application
import android.util.Log
import androidx.lifecycle.DefaultLifecycleObserver
import androidx.lifecycle.LifecycleOwner
// import androidx.lifecycle.ProcessLifecycleOwner // Commented out due to dependency issues
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import java.lang.ref.WeakReference
import java.util.concurrent.ConcurrentHashMap

/**
 * Memory leak detection utility for monitoring potential memory leaks in the app.
 * Tracks object references and monitors memory usage patterns.
 */
class MemoryLeakDetector private constructor() : DefaultLifecycleObserver {
    
    companion object {
        private const val TAG = "MemoryLeakDetector"
        private const val MEMORY_CHECK_INTERVAL_MS = 30000L // 30 seconds
        private const val HIGH_MEMORY_THRESHOLD = 0.8f // 80% of max memory
        
        @Volatile
        private var INSTANCE: MemoryLeakDetector? = null
        
        fun getInstance(): MemoryLeakDetector {
            return INSTANCE ?: synchronized(this) {
                INSTANCE ?: MemoryLeakDetector().also { INSTANCE = it }
            }
        }
    }
    
    private val trackedObjects = ConcurrentHashMap<String, WeakReference<Any>>()
    private val memoryUsageHistory = mutableListOf<MemorySnapshot>()
    private var monitoringJob: Job? = null
    private val coroutineScope = CoroutineScope(Dispatchers.Default)
    
    data class MemorySnapshot(
        val timestamp: Long,
        val usedMemoryMB: Long,
        val maxMemoryMB: Long,
        val usagePercentage: Float
    )
    
    fun initialize(application: Application) {
        // TODO: Fix ProcessLifecycleOwner dependency
        // ProcessLifecycleOwner.get().lifecycle.addObserver(this)
        startMemoryMonitoring()
        Log.d(TAG, "MemoryLeakDetector initialized")
    }
    
    override fun onStart(owner: LifecycleOwner) {
        super.onStart(owner)
        startMemoryMonitoring()
    }
    
    override fun onStop(owner: LifecycleOwner) {
        super.onStop(owner)
        stopMemoryMonitoring()
    }
    
    /**
     * Track an object for potential memory leaks.
     */
    fun trackObject(key: String, obj: Any) {
        trackedObjects[key] = WeakReference(obj)
        Log.d(TAG, "Tracking object: $key")
    }
    
    /**
     * Stop tracking an object.
     */
    fun stopTracking(key: String) {
        trackedObjects.remove(key)
        Log.d(TAG, "Stopped tracking object: $key")
    }
    
    /**
     * Check for potential memory leaks by examining tracked objects.
     */
    fun checkForLeaks(): List<String> {
        val potentialLeaks = mutableListOf<String>()
        
        // Force garbage collection to clean up unreferenced objects
        System.gc()
        
        // Wait a bit for GC to complete
        Thread.sleep(100)
        
        trackedObjects.entries.removeAll { (key, weakRef) ->
            if (weakRef.get() == null) {
                // Object was garbage collected - good
                Log.d(TAG, "Object properly garbage collected: $key")
                true
            } else {
                // Object still exists - potential leak
                potentialLeaks.add(key)
                Log.w(TAG, "Potential memory leak detected: $key")
                false
            }
        }
        
        return potentialLeaks
    }
    
    /**
     * Start continuous memory monitoring.
     */
    private fun startMemoryMonitoring() {
        if (monitoringJob?.isActive == true) return
        
        monitoringJob = coroutineScope.launch {
            while (true) {
                try {
                    val snapshot = captureMemorySnapshot()
                    memoryUsageHistory.add(snapshot)
                    
                    // Keep only last 100 snapshots to prevent memory growth
                    if (memoryUsageHistory.size > 100) {
                        memoryUsageHistory.removeAt(0)
                    }
                    
                    // Check for high memory usage
                    if (snapshot.usagePercentage > HIGH_MEMORY_THRESHOLD) {
                        Log.w(TAG, "High memory usage detected: ${snapshot.usagePercentage * 100}%")
                        checkForLeaks()
                    }
                    
                    // Check for memory leaks periodically
                    if (memoryUsageHistory.size % 10 == 0) {
                        checkForLeaks()
                    }
                    
                    delay(MEMORY_CHECK_INTERVAL_MS)
                } catch (e: Exception) {
                    Log.e(TAG, "Error during memory monitoring", e)
                }
            }
        }
    }
    
    /**
     * Stop memory monitoring.
     */
    private fun stopMemoryMonitoring() {
        monitoringJob?.cancel()
        monitoringJob = null
    }
    
    /**
     * Capture current memory usage snapshot.
     */
    private fun captureMemorySnapshot(): MemorySnapshot {
        val runtime = Runtime.getRuntime()
        val usedMemory = runtime.totalMemory() - runtime.freeMemory()
        val maxMemory = runtime.maxMemory()
        val usagePercentage = usedMemory.toFloat() / maxMemory.toFloat()
        
        return MemorySnapshot(
            timestamp = System.currentTimeMillis(),
            usedMemoryMB = usedMemory / 1024 / 1024,
            maxMemoryMB = maxMemory / 1024 / 1024,
            usagePercentage = usagePercentage
        )
    }
    
    /**
     * Get memory usage trend analysis.
     */
    fun getMemoryTrend(): String {
        if (memoryUsageHistory.size < 2) return "Insufficient data for trend analysis"
        
        val recent = memoryUsageHistory.takeLast(10)
        val avgUsage = recent.map { it.usagePercentage }.average()
        val trend = if (recent.size >= 2) {
            val first = recent.first().usagePercentage
            val last = recent.last().usagePercentage
            when {
                last > first + 0.1f -> "Increasing"
                last < first - 0.1f -> "Decreasing"
                else -> "Stable"
            }
        } else "Unknown"
        
        return """
            Memory Trend Analysis:
            Average usage: ${(avgUsage * 100).toInt()}%
            Trend: $trend
            Snapshots: ${memoryUsageHistory.size}
            Tracked objects: ${trackedObjects.size}
        """.trimIndent()
    }
    
    /**
     * Force a comprehensive memory leak check.
     */
    fun performLeakCheck(): String {
        val leaks = checkForLeaks()
        val memorySnapshot = captureMemorySnapshot()
        
        return """
            Memory Leak Check Results:
            Potential leaks: ${leaks.size}
            Leaked objects: ${leaks.joinToString(", ")}
            Current memory usage: ${memorySnapshot.usagePercentage * 100}%
            Used memory: ${memorySnapshot.usedMemoryMB}MB / ${memorySnapshot.maxMemoryMB}MB
        """.trimIndent()
    }
    
    /**
     * Clean up resources.
     */
    fun cleanup() {
        stopMemoryMonitoring()
        trackedObjects.clear()
        memoryUsageHistory.clear()
        Log.d(TAG, "MemoryLeakDetector cleaned up")
    }
}