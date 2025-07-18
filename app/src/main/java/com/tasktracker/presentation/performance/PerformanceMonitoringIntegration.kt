package com.tasktracker.presentation.performance

import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import com.tasktracker.presentation.theme.GlassmorphismConfig
import com.tasktracker.presentation.theme.LocalGlassmorphismConfig
import kotlinx.coroutines.delay

/**
 * Performance-aware glassmorphism configuration
 */
@Composable
fun PerformanceAwareGlassmorphismConfig(
    content: @Composable () -> Unit
) {
    val optimizer = rememberGlassmorphismPerformanceOptimizer()
    var config by remember { 
        mutableStateOf(
            GlassmorphismConfig(
                blurRadius = optimizer.getRecommendedBlurRadius().dp,
                transparency = optimizer.getRecommendedTransparency(),
                enableBlur = optimizer.canUseFullEffects()
            )
        )
    }
    
    // Monitor performance and adjust config
    LaunchedEffect(Unit) {
        while (true) {
            delay(3000) // Check every 3 seconds
            
            val optimizationResult = optimizer.optimizeEffects()
            
            config = when (optimizationResult) {
                GlassmorphismPerformanceOptimizer.OptimizationResult.REDUCE_EFFECTS -> {
                    config.copy(
                        blurRadius = 0.dp,
                        transparency = 0.9f,
                        enableBlur = false
                    )
                }
                GlassmorphismPerformanceOptimizer.OptimizationResult.REDUCE_BLUR -> {
                    config.copy(
                        blurRadius = (config.blurRadius.value * 0.7f).dp,
                        enableBlur = config.blurRadius.value > 4f
                    )
                }
                GlassmorphismPerformanceOptimizer.OptimizationResult.REDUCE_TRANSPARENCY -> {
                    config.copy(
                        transparency = minOf(config.transparency * 1.3f, 0.8f)
                    )
                }
                GlassmorphismPerformanceOptimizer.OptimizationResult.MAINTAIN_EFFECTS -> {
                    // Gradually restore effects if performance improves
                    config.copy(
                        blurRadius = minOf(config.blurRadius.value * 1.1f, optimizer.getRecommendedBlurRadius()).dp,
                        transparency = maxOf(config.transparency * 0.95f, optimizer.getRecommendedTransparency()),
                        enableBlur = optimizer.canUseFullEffects()
                    )
                }
            }
        }
    }
    
    androidx.compose.runtime.CompositionLocalProvider(
        LocalGlassmorphismConfig provides config
    ) {
        content()
    }
}

/**
 * Extension function to convert Float to Dp
 */
private val Float.dp: androidx.compose.ui.unit.Dp
    get() = androidx.compose.ui.unit.dp(this)

/**
 * Performance monitoring for analytics calculations
 */
@Composable
fun AnalyticsPerformanceMonitor(
    onSlowOperation: (String, Long) -> Unit = { _, _ -> }
) {
    LaunchedEffect(Unit) {
        while (true) {
            delay(10000) // Check every 10 seconds
            
            // Clear expired cache entries
            AnalyticsPerformanceOptimizer.clearExpiredCache()
            
            // Monitor cache performance
            val cacheStats = AnalyticsPerformanceOptimizer.getCacheStats()
            if (cacheStats.expiredEntries > cacheStats.totalEntries * 0.5) {
                // Too many expired entries, might indicate memory pressure
                onSlowOperation("High cache expiration rate", cacheStats.expiredEntries.toLong())
            }
        }
    }
}

/**
 * Comprehensive performance monitoring composable
 */
@Composable
fun ComprehensivePerformanceMonitor(
    onPerformanceIssue: (PerformanceIssue) -> Unit = {}
) {
    // Monitor glassmorphism performance
    PerformanceMonitor { metrics ->
        when {
            metrics.frameDropRate > 0.3f -> {
                onPerformanceIssue(
                    PerformanceIssue.HIGH_FRAME_DROP_RATE(metrics.frameDropRate)
                )
            }
            metrics.averageFrameTime > 25f -> {
                onPerformanceIssue(
                    PerformanceIssue.SLOW_FRAME_TIME(metrics.averageFrameTime)
                )
            }
            metrics.memoryUsage < 50 * 1024 * 1024 -> { // Less than 50MB
                onPerformanceIssue(
                    PerformanceIssue.LOW_MEMORY(metrics.memoryUsage)
                )
            }
        }
    }
    
    // Monitor analytics performance
    AnalyticsPerformanceMonitor { operation, duration ->
        if (duration > 1000) { // Operations taking more than 1 second
            onPerformanceIssue(
                PerformanceIssue.SLOW_ANALYTICS_OPERATION(operation, duration)
            )
        }
    }
}

/**
 * Performance issue types
 */
sealed class PerformanceIssue {
    data class HIGH_FRAME_DROP_RATE(val rate: Float) : PerformanceIssue()
    data class SLOW_FRAME_TIME(val time: Float) : PerformanceIssue()
    data class LOW_MEMORY(val available: Long) : PerformanceIssue()
    data class SLOW_ANALYTICS_OPERATION(val operation: String, val duration: Long) : PerformanceIssue()
}

/**
 * Performance optimization recommendations
 */
object PerformanceRecommendations {
    
    fun getRecommendation(issue: PerformanceIssue): String {
        return when (issue) {
            is PerformanceIssue.HIGH_FRAME_DROP_RATE -> {
                "High frame drop rate detected (${(issue.rate * 100).toInt()}%). " +
                "Consider reducing glassmorphism effects or blur radius."
            }
            is PerformanceIssue.SLOW_FRAME_TIME -> {
                "Slow frame rendering detected (${issue.time.toInt()}ms). " +
                "Consider disabling blur effects or reducing transparency."
            }
            is PerformanceIssue.LOW_MEMORY -> {
                "Low memory available (${issue.available / (1024 * 1024)}MB). " +
                "Consider clearing caches or reducing visual effects."
            }
            is PerformanceIssue.SLOW_ANALYTICS_OPERATION -> {
                "Slow analytics operation '${issue.operation}' (${issue.duration}ms). " +
                "Consider caching results or optimizing calculations."
            }
        }
    }
}