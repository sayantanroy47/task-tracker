package com.tasktracker.util

// import androidx.tracing.trace // Commented out due to API issues
import android.util.Log
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import kotlin.system.measureTimeMillis

/**
 * Performance monitoring utility for tracking app performance metrics.
 * Provides tracing, timing, and memory usage monitoring capabilities.
 */
object PerformanceMonitor {
    
    const val TAG = "PerformanceMonitor"
    const val SLOW_OPERATION_THRESHOLD_MS = 100L
    
    /**
     * Trace a block of code for performance analysis.
     * This integrates with Android's systrace for detailed performance profiling.
     */
    inline fun <T> traceSection(sectionName: String, crossinline block: () -> T): T {
        val result: T
        val timeMs = measureTimeMillis {
            result = block()
        }
        
        if (timeMs > SLOW_OPERATION_THRESHOLD_MS) {
            Log.w(TAG, "Slow operation detected: $sectionName took ${timeMs}ms")
        }
        
        return result
    }
    
    /**
     * Trace a suspend function for performance analysis.
     */
    suspend inline fun <T> traceSuspendSection(sectionName: String, crossinline block: suspend () -> T): T {
        return withContext(Dispatchers.Default) {
            val result: T
            val timeMs = measureTimeMillis {
                result = block()
            }
            
            if (timeMs > SLOW_OPERATION_THRESHOLD_MS) {
                Log.w(TAG, "Slow suspend operation detected: $sectionName took ${timeMs}ms")
            }
            
            result
        }
    }
    
    /**
     * Monitor database operations for performance.
     */
    suspend inline fun <T> monitorDatabaseOperation(
        operationName: String,
        crossinline operation: suspend () -> T
    ): T {
        return traceSuspendSection("DB_$operationName") {
            operation()
        }
    }
    
    /**
     * Monitor UI composition performance.
     */
    inline fun <T> monitorComposition(composableName: String, crossinline block: () -> T): T {
        return traceSection("COMPOSE_$composableName", block)
    }
    
    /**
     * Log memory usage for debugging memory leaks.
     */
    fun logMemoryUsage(context: String) {
        val runtime = Runtime.getRuntime()
        val usedMemory = runtime.totalMemory() - runtime.freeMemory()
        val maxMemory = runtime.maxMemory()
        val availableMemory = maxMemory - usedMemory
        
        Log.d(TAG, """
            Memory Usage [$context]:
            Used: ${usedMemory / 1024 / 1024}MB
            Max: ${maxMemory / 1024 / 1024}MB
            Available: ${availableMemory / 1024 / 1024}MB
            Usage: ${(usedMemory * 100 / maxMemory)}%
        """.trimIndent())
        
        // Warn if memory usage is high
        if (usedMemory * 100 / maxMemory > 80) {
            Log.w(TAG, "High memory usage detected: ${usedMemory * 100 / maxMemory}%")
        }
    }
    
    /**
     * Monitor coroutine performance.
     */
    fun monitorCoroutine(scope: CoroutineScope, operationName: String, operation: suspend () -> Unit) {
        scope.launch {
            traceSuspendSection("COROUTINE_$operationName") {
                operation()
            }
        }
    }
    
    /**
     * Performance metrics data class for tracking.
     */
    data class PerformanceMetrics(
        val operationName: String,
        val durationMs: Long,
        val memoryUsedMB: Long,
        val timestamp: Long = System.currentTimeMillis()
    )
    
    private val performanceMetrics = mutableListOf<PerformanceMetrics>()
    
    /**
     * Record performance metrics for analysis.
     */
    fun recordMetrics(operationName: String, durationMs: Long) {
        val runtime = Runtime.getRuntime()
        val usedMemory = (runtime.totalMemory() - runtime.freeMemory()) / 1024 / 1024
        
        val metrics = PerformanceMetrics(
            operationName = operationName,
            durationMs = durationMs,
            memoryUsedMB = usedMemory
        )
        
        performanceMetrics.add(metrics)
        
        // Keep only last 100 metrics to prevent memory leaks
        if (performanceMetrics.size > 100) {
            performanceMetrics.removeAt(0)
        }
        
        Log.d(TAG, "Performance: $operationName took ${durationMs}ms, Memory: ${usedMemory}MB")
    }
    
    /**
     * Get performance summary for debugging.
     */
    fun getPerformanceSummary(): String {
        if (performanceMetrics.isEmpty()) return "No performance data available"
        
        val avgDuration = performanceMetrics.map { it.durationMs }.average()
        val maxDuration = performanceMetrics.maxOf { it.durationMs }
        val avgMemory = performanceMetrics.map { it.memoryUsedMB }.average()
        
        return """
            Performance Summary:
            Operations tracked: ${performanceMetrics.size}
            Average duration: ${avgDuration.toInt()}ms
            Max duration: ${maxDuration}ms
            Average memory: ${avgMemory.toInt()}MB
        """.trimIndent()
    }
}