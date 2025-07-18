package com.tasktracker.presentation.theme

import android.graphics.RenderEffect
import android.graphics.Shader
import android.os.Build
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.MaterialTheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.compositionLocalOf
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.asComposeRenderEffect
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp

/**
 * Configuration for glassmorphism effects
 */
data class GlassmorphismConfig(
    val blurRadius: Dp = 24.dp,
    val transparency: Float = 0.15f,
    val borderOpacity: Float = 0.3f,
    val shadowElevation: Dp = 8.dp,
    val adaptToWallpaper: Boolean = true,
    val enableBlur: Boolean = true
)

/**
 * Local composition for glassmorphism configuration
 */
val LocalGlassmorphismConfig = compositionLocalOf { GlassmorphismConfig() }

/**
 * Performance detector for glassmorphism effects
 */
object GlassmorphismPerformance {
    
    fun canUseBlurEffects(): Boolean {
        return Build.VERSION.SDK_INT >= Build.VERSION_CODES.S
    }
    
    fun shouldUseReducedEffects(): Boolean {
        // Simple heuristic - in a real app, you'd check device performance metrics
        return Build.VERSION.SDK_INT < Build.VERSION_CODES.R
    }
}

/**
 * Main glassmorphism theme wrapper
 */
@Composable
fun GlassmorphismTheme(
    config: GlassmorphismConfig = GlassmorphismConfig(),
    content: @Composable () -> Unit
) {
    val optimizedConfig = remember(config) {
        when {
            !GlassmorphismPerformance.canUseBlurEffects() -> {
                config.copy(enableBlur = false, transparency = 0.8f)
            }
            GlassmorphismPerformance.shouldUseReducedEffects() -> {
                config.copy(blurRadius = 12.dp, transparency = 0.25f)
            }
            else -> config
        }
    }
    
    CompositionLocalProvider(
        LocalGlassmorphismConfig provides optimizedConfig
    ) {
        content()
    }
}

/**
 * Core blurred surface component with glassmorphism effects
 */
@Composable
fun BlurredSurface(
    modifier: Modifier = Modifier,
    blurRadius: Dp? = null,
    transparency: Float? = null,
    elevation: Dp? = null,
    shape: RoundedCornerShape = RoundedCornerShape(16.dp),
    content: @Composable () -> Unit
) {
    val config = LocalGlassmorphismConfig.current
    val effectiveBlurRadius = blurRadius ?: config.blurRadius
    val effectiveTransparency = transparency ?: config.transparency
    val effectiveElevation = elevation ?: config.shadowElevation
    
    val surfaceColor = MaterialTheme.colorScheme.surface
    val onSurfaceColor = MaterialTheme.colorScheme.onSurface
    
    // Create glassmorphism background
    val glassBrush = remember(surfaceColor, effectiveTransparency) {
        Brush.linearGradient(
            colors = listOf(
                surfaceColor.copy(alpha = effectiveTransparency),
                surfaceColor.copy(alpha = effectiveTransparency * 0.8f)
            )
        )
    }
    
    // Create border brush
    val borderBrush = remember(onSurfaceColor, config.borderOpacity) {
        Brush.linearGradient(
            colors = listOf(
                onSurfaceColor.copy(alpha = config.borderOpacity),
                onSurfaceColor.copy(alpha = config.borderOpacity * 0.5f)
            )
        )
    }
    
    Box(
        modifier = modifier
            .clip(shape)
            .then(
                if (config.enableBlur && Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                    Modifier.graphicsLayer {
                        renderEffect = RenderEffect
                            .createBlurEffect(
                                effectiveBlurRadius.toPx(),
                                effectiveBlurRadius.toPx(),
                                Shader.TileMode.CLAMP
                            )
                            .asComposeRenderEffect()
                    }
                } else {
                    Modifier
                }
            )
            .background(brush = glassBrush, shape = shape)
            .border(
                width = 1.dp,
                brush = borderBrush,
                shape = shape
            )
    ) {
        content()
    }
}

/**
 * Adaptive color palette that responds to system wallpaper
 */
@Composable
fun adaptiveGlassColors(): GlassColors {
    val isDark = MaterialTheme.colorScheme.surface.luminance() < 0.5f
    
    return if (isDark) {
        GlassColors(
            surface = Color.White.copy(alpha = 0.1f),
            onSurface = Color.White.copy(alpha = 0.9f),
            border = Color.White.copy(alpha = 0.2f),
            shadow = Color.Black.copy(alpha = 0.3f)
        )
    } else {
        GlassColors(
            surface = Color.Black.copy(alpha = 0.05f),
            onSurface = Color.Black.copy(alpha = 0.8f),
            border = Color.Black.copy(alpha = 0.1f),
            shadow = Color.Black.copy(alpha = 0.1f)
        )
    }
}

/**
 * Color scheme for glassmorphism effects
 */
data class GlassColors(
    val surface: Color,
    val onSurface: Color,
    val border: Color,
    val shadow: Color
)

/**
 * Extension function to get luminance of a color
 */
private fun Color.luminance(): Float {
    return (0.299f * red + 0.587f * green + 0.114f * blue)
}