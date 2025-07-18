package com.tasktracker.presentation.theme

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

/**
 * Performance monitor for glassmorphism effects
 */
class GlassmorphismPerformanceMonitor(private val context: Context) {
    
    private var frameDropCount = 0
    private var lastFrameTime = System.currentTimeMillis()
    
    /**
     * Check if device can handle full glassmorphism effects
     */
    fun canUseFullEffects(): Boolean {
        return when {
            Build.VERSION.SDK_INT < Build.VERSION_CODES.R -> false
            isLowEndDevice() -> false
            hasLowMemory() -> false
            else -> true
        }
    }
    
    /**
     * Get recommended blur radius based on device performance
     */
    fun getRecommendedBlurRadius(): Float {
        return when {
            !canUseFullEffects() -> 0f
            isLowEndDevice() -> 12f
            else -> 24f
        }
    }
    
    /**
     * Get recommended transparency based on device performance
     */
    fun getRecommendedTransparency(): Float {
        return when {
            !canUseFullEffects() -> 0.8f
            isLowEndDevice() -> 0.25f
            else -> 0.15f
        }
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
     * Monitor frame drops and adjust effects accordingly
     */
    fun onFrameRendered() {
        val currentTime = System.currentTimeMillis()
        val frameDuration = currentTime - lastFrameTime
        
        // If frame took longer than 16.67ms (60fps), consider it a drop
        if (frameDuration > 17) {
            frameDropCount++
        }
        
        lastFrameTime = currentTime
    }
    
    /**
     * Check if effects should be reduced due to performance issues
     */
    fun shouldReduceEffects(): Boolean {
        return frameDropCount > 10 // Arbitrary threshold
    }
    
    /**
     * Reset performance counters
     */
    fun reset() {
        frameDropCount = 0
        lastFrameTime = System.currentTimeMillis()
    }
}

/**
 * Composable that provides adaptive glassmorphism configuration
 */
@Composable
fun rememberAdaptiveGlassmorphismConfig(): GlassmorphismConfig {
    val context = LocalContext.current
    val monitor = remember { GlassmorphismPerformanceMonitor(context) }
    
    var config by remember {
        mutableStateOf(
            GlassmorphismConfig(
                blurRadius = monitor.getRecommendedBlurRadius().dp,
                transparency = monitor.getRecommendedTransparency(),
                enableBlur = monitor.canUseFullEffects()
            )
        )
    }
    
    // Monitor performance and adjust config if needed
    LaunchedEffect(Unit) {
        while (true) {
            delay(5000) // Check every 5 seconds
            
            if (monitor.shouldReduceEffects()) {
                config = config.copy(
                    blurRadius = (config.blurRadius.value * 0.8f).dp,
                    transparency = minOf(config.transparency * 1.2f, 0.8f),
                    enableBlur = config.blurRadius.value > 8f
                )
                monitor.reset()
            }
        }
    }
    
    return config
}

/**
 * Extension function to convert Float to Dp
 */
private val Float.dp: androidx.compose.ui.unit.Dp
    get() = androidx.compose.ui.unit.dp(this)