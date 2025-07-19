package com.tasktracker.util

/**
 * Performance configuration constants and settings for the Task Tracker app.
 * Centralizes performance-related configurations for easy tuning.
 */
object PerformanceConfig {
    
    // Database performance settings
    const val MAX_TASKS_PER_QUERY = 1000
    const val PAGINATION_SIZE = 50
    const val DATABASE_QUERY_TIMEOUT_MS = 5000L
    
    // UI performance settings
    const val MAX_VISIBLE_TASKS = 100
    const val SCROLL_BUFFER_SIZE = 20
    const val ANIMATION_DURATION_MS = 300L
    
    // Memory management settings
    const val MAX_CACHED_TASKS = 500
    const val MEMORY_CLEANUP_THRESHOLD = 0.8f // 80% of max memory
    const val GC_TRIGGER_THRESHOLD = 0.9f // 90% of max memory
    
    // Background processing settings
    const val NOTIFICATION_BATCH_SIZE = 10
    const val RECURRING_TASK_BATCH_SIZE = 20
    const val BACKGROUND_SYNC_INTERVAL_MS = 300000L // 5 minutes
    
    // Performance monitoring settings
    const val SLOW_OPERATION_THRESHOLD_MS = 100L
    const val MEMORY_CHECK_INTERVAL_MS = 30000L // 30 seconds
    const val PERFORMANCE_LOG_ENABLED = true
    
    // Compose performance settings
    const val STABLE_COLLECTION_POLICY = true
    const val SKIP_TO_COMPOSITION_ENABLED = true
    const val RECOMPOSITION_HIGHLIGHTING = false // Only for debug
    
    /**
     * Get optimal batch size based on available memory.
     */
    fun getOptimalBatchSize(): Int {
        val runtime = Runtime.getRuntime()
        val availableMemory = runtime.maxMemory() - (runtime.totalMemory() - runtime.freeMemory())
        val availableMemoryMB = availableMemory / 1024 / 1024
        
        return when {
            availableMemoryMB > 100 -> PAGINATION_SIZE * 2
            availableMemoryMB > 50 -> PAGINATION_SIZE
            else -> PAGINATION_SIZE / 2
        }
    }
    
    /**
     * Check if performance monitoring should be enabled.
     */
    fun isPerformanceMonitoringEnabled(): Boolean {
        return PERFORMANCE_LOG_ENABLED && true // TODO: Fix BuildConfig.DEBUG reference
    }
    
    /**
     * Get memory cleanup threshold based on device capabilities.
     */
    fun getMemoryCleanupThreshold(): Float {
        val runtime = Runtime.getRuntime()
        val maxMemoryMB = runtime.maxMemory() / 1024 / 1024
        
        return when {
            maxMemoryMB > 512 -> MEMORY_CLEANUP_THRESHOLD
            maxMemoryMB > 256 -> 0.7f
            else -> 0.6f
        }
    }
}