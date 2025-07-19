package com.tasktracker.presentation.performance

import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.async
import kotlinx.coroutines.awaitAll
import kotlinx.coroutines.coroutineScope
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.buffer
import kotlinx.coroutines.flow.flowOn
import kotlinx.coroutines.withContext
import java.util.concurrent.ConcurrentHashMap
import kotlin.system.measureTimeMillis

/**
 * Performance optimizer for analytics calculations
 */
object AnalyticsPerformanceOptimizer {
    
    // Cache for expensive calculations
    internal val calculationCache = ConcurrentHashMap<String, Any>()
    internal val cacheTimestamps = ConcurrentHashMap<String, Long>()
    internal const val CACHE_DURATION = 5 * 60 * 1000L // 5 minutes
    
    /**
     * Cache expensive calculations with automatic expiration
     */
    fun <T> cached(
        key: String,
        calculation: suspend () -> T
    ): suspend () -> T = {
        val currentTime = System.currentTimeMillis()
        val cachedTime = cacheTimestamps[key] ?: 0L
        
        if (currentTime - cachedTime < CACHE_DURATION && calculationCache.containsKey(key)) {
            calculationCache[key] as T
        } else {
            val result = calculation()
            calculationCache[key] = result as Any
            cacheTimestamps[key] = currentTime
            result
        }
    }
    
    /**
     * Optimize flow operations for better performance
     */
    fun <T> Flow<T>.optimizeForAnalytics(): Flow<T> {
        return this
            .buffer(capacity = 64) // Buffer items to reduce backpressure
            .flowOn(Dispatchers.Default) // Use background dispatcher for calculations
    }
    
    /**
     * Parallel processing for multiple analytics calculations
     */
    suspend fun <T> parallelCalculations(
        calculations: List<suspend () -> T>
    ): List<T> = coroutineScope {
        calculations.map { calculation ->
            async(Dispatchers.Default) {
                calculation()
            }
        }.awaitAll()
    }
    
    /**
     * Batch process analytics data for better performance
     */
    suspend fun <T, R> batchProcess(
        items: List<T>,
        batchSize: Int = 100,
        processor: suspend (List<T>) -> List<R>
    ): List<R> = withContext(Dispatchers.Default) {
        items.chunked(batchSize).flatMap { batch ->
            processor(batch)
        }
    }
    
    /**
     * Measure and log performance of analytics operations
     */
    suspend fun <T> measureAnalyticsPerformance(
        operationName: String,
        operation: suspend () -> T
    ): T {
        val result: T
        val executionTime = measureTimeMillis {
            result = operation()
        }
        
        // Log performance metrics (in a real app, this would go to analytics)
        if (executionTime > 100) { // Log slow operations
            println("Analytics operation '$operationName' took ${executionTime}ms")
        }
        
        return result
    }
    
    /**
     * Clear expired cache entries
     */
    fun clearExpiredCache() {
        val currentTime = System.currentTimeMillis()
        val expiredKeys = cacheTimestamps.entries
            .filter { currentTime - it.value > CACHE_DURATION }
            .map { it.key }
        
        expiredKeys.forEach { key ->
            calculationCache.remove(key)
            cacheTimestamps.remove(key)
        }
    }
    
    /**
     * Get cache statistics for monitoring
     */
    fun getCacheStats(): CacheStats {
        return CacheStats(
            totalEntries = calculationCache.size,
            expiredEntries = cacheTimestamps.entries.count { 
                System.currentTimeMillis() - it.value > CACHE_DURATION 
            }
        )
    }
    
    data class CacheStats(
        val totalEntries: Int,
        val expiredEntries: Int
    )
}

/**
 * Extension functions for optimized analytics calculations
 */

/**
 * Optimized task completion rate calculation
 */
suspend fun List<com.tasktracker.domain.model.Task>.calculateCompletionRateOptimized(): Float = 
    withContext(Dispatchers.Default) {
        if (isEmpty()) return@withContext 0f
        
        val completedCount = count { it.isCompleted }
        completedCount.toFloat() / size.toFloat()
    }

/**
 * Optimized productivity streak calculation
 */
suspend fun List<com.tasktracker.domain.model.Task>.calculateStreakOptimized(): Int = 
    withContext(Dispatchers.Default) {
        if (isEmpty()) return@withContext 0
        
        val sortedTasks = sortedByDescending { it.completedAt ?: 0L }
        var streak = 0
        var currentDay = -1L
        
        for (task in sortedTasks) {
            if (!task.isCompleted) continue
            
            val taskDay = (task.completedAt ?: 0L) / (24 * 60 * 60 * 1000)
            
            if (currentDay == -1L) {
                currentDay = taskDay
                streak = 1
            } else if (taskDay == currentDay - 1) {
                currentDay = taskDay
                streak++
            } else if (taskDay != currentDay) {
                break
            }
        }
        
        streak
    }

/**
 * Optimized daily statistics calculation
 */
suspend fun List<com.tasktracker.domain.model.Task>.calculateDailyStatsOptimized(): Map<Long, Int> = 
    withContext(Dispatchers.Default) {
        groupBy { task ->
            val timestamp = task.completedAt ?: task.createdAt
            timestamp / (24 * 60 * 60 * 1000) // Convert to day
        }.mapValues { (_, tasks) ->
            tasks.count { it.isCompleted }
        }
    }