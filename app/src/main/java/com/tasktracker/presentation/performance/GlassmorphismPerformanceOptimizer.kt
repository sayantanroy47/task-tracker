package com.tasktracker.presentation.performance

import android.app.ActivityManager
import android.content.Context
import android.os.Build
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.platform.LocalContext
import kotlinx.coroutines.delay
import kotlin.system.measureTimeMillis

/**
 * Performance optimizer for glassmorphism effects
 */
class GlassmorphismPerformanceOptimizer(private val context: Context) {
    
    private var frameDropCount = 0
    private var lastFrameTime = System.currentTimeMillis()
    private var averageFrameTime = 16.67f // Target 60fps
    private val frameTimeHistory = mutableListOf<Float>()
    
    /**
     * Performance metrics data class
     */
    data class PerformanceMetrics(
        val averageFrameTime: Float,
        val frameDropRate: Float,
        val memoryUsage: Long,
        val canUseFullEffects: Boolean,
        val recommendedBlurRadius: Float,
        val recommendedTransparency: Float
    )
    
    /**
     * Check if device can handle full glassmorphism effects
     */
    fun canUseFullEffects(): Boolean {
        return when {
            Build.VERSION.SDK_INT < Build.VERSION_CODES.R -> false
            isLowEndDevice() -> false
            hasLowMemory() -> false
            frameDropCount > 15 -> false // Too many frame drops
            else -> true
        }
    }
    
    /**
     * Get recommended blur radius based on device performance
     */
    fun getRecommendedBlurRadius(): Float {
        return when {
            !canUseFullEffects() -> 0f
            isLowEndDevice() -> 8f
            frameDropCount > 10 -> 12f
            averageFrameTime > 20f -> 16f
            else -> 24f
        }
    }
    
    /**
     * Get recommended transparency based on device performance
     */
    fun getRecommendedTransparency(): Float {
        return when {
            !canUseFullEffects() -> 0.9f
            isLowEndDevice() -> 0.3f
            frameDropCount > 10 -> 0.25f
            averageFrameTime > 20f -> 0.2f
            else -> 0.15f
        }
    }
    
    /**
     * Monitor frame rendering performance
     */
    fun onFrameRendered() {
        val currentTime = System.currentTimeMillis()
        val frameDuration = (currentTime - lastFrameTime).toFloat()
        
        // Update frame time history
        frameTimeHistory.add(frameDuration)
        if (frameTimeHistory.size > 30) {
            frameTimeHistory.removeAt(0)
        }
        
        // Calculate average frame time
        averageFrameTime = frameTimeHistory.average().toFloat()
        
        // Count frame drops (frames taking longer than 16.67ms for 60fps)
        if (frameDuration > 17f) {
            frameDropCount++
        }
        
        lastFrameTime = currentTime
    }
    
    /**
     * Get current performance metrics
     */
    fun getPerformanceMetrics(): PerformanceMetrics {
        val memoryInfo = ActivityManager.MemoryInfo()
        val activityManager = context.getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
        activityManager.getMemoryInfo(memoryInfo)
        
        val frameDropRate = if (frameTimeHistory.isNotEmpty()) {
            frameTimeHistory.count { it > 17f }.toFloat() / frameTimeHistory.size
        } else 0f
        
        return PerformanceMetrics(
            averageFrameTime = averageFrameTime,
            frameDropRate = frameDropRate,
            memoryUsage = memoryInfo.availMem,
            canUseFullEffects = canUseFullEffects(),
            recommendedBlurRadius = getRecommendedBlurRadius(),
            recommendedTransparency = getRecommendedTransparency()
        )
    }
    
    /**
     * Check if device is low-end
     */
    private fun isLowEndDevice(): Boolean {
        val activityManager = context.getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.KITKAT) {
            activityManager.isLowRamDevice
        } else {
            // Fallback for older devices
            val memInfo = ActivityManager.MemoryInfo()
            activityManager.getMemoryInfo(memInfo)
            memInfo.totalMem < 2L * 1024 * 1024 * 1024 // Less than 2GB RAM
        }
    }
    
    /**
     * Check if device has low memory
     */
    private fun hasLowMemory(): Boolean {
        val activityManager = context.getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
        val memInfo = ActivityManager.MemoryInfo()
        activityManager.getMemoryInfo(memInfo)
        return memInfo.lowMemory
    }
    
    /**
     * Reset performance counters
     */
    fun reset() {
        frameDropCount = 0
        frameTimeHistory.clear()
        averageFrameTime = 16.67f
        lastFrameTime = System.currentTimeMillis()
    }
    
    /**
     * Optimize glassmorphism effects based on current performance
     */
    fun optimizeEffects(): OptimizationResult {
        val metrics = getPerformanceMetrics()
        
        return when {
            metrics.frameDropRate > 0.3f -> OptimizationResult.REDUCE_EFFECTS
            metrics.averageFrameTime > 25f -> OptimizationResult.REDUCE_BLUR
            metrics.memoryUsage < 100 * 1024 * 1024 -> OptimizationResult.REDUCE_TRANSPARENCY // Less than 100MB available
            else -> OptimizationResult.MAINTAIN_EFFECTS
        }
    }
    
    enum class OptimizationResult {
        MAINTAIN_EFFECTS,
        REDUCE_BLUR,
        REDUCE_TRANSPARENCY,
        REDUCE_EFFECTS
    }
}

/**
 * Composable that provides adaptive performance optimization
 */
@Composable
fun rememberGlassmorphismPerformanceOptimizer(): GlassmorphismPerformanceOptimizer {
    val context = LocalContext.current
    val optimizer = remember { GlassmorphismPerformanceOptimizer(context) }
    
    // Monitor performance periodically
    LaunchedEffect(Unit) {
        while (true) {
            delay(1000) // Check every second
            optimizer.onFrameRendered()
        }
    }
    
    return optimizer
}

/**
 * Performance monitoring composable
 */
@Composable
fun PerformanceMonitor(
    onPerformanceUpdate: (GlassmorphismPerformanceOptimizer.PerformanceMetrics) -> Unit = {}
) {
    val optimizer = rememberGlassmorphismPerformanceOptimizer()
    
    LaunchedEffect(Unit) {
        while (true) {
            delay(5000) // Update every 5 seconds
            val metrics = optimizer.getPerformanceMetrics()
            onPerformanceUpdate(metrics)
        }
    }
}