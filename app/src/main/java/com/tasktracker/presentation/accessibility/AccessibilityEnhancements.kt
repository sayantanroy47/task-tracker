package com.tasktracker.presentation.accessibility

import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.semantics.Role
import androidx.compose.foundation.semantics.clearAndSetSemantics
import androidx.compose.foundation.semantics.contentDescription
import androidx.compose.foundation.semantics.role
import androidx.compose.foundation.semantics.semantics
import androidx.compose.foundation.semantics.stateDescription
import androidx.compose.material3.MaterialTheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.luminance
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.semantics.SemanticsPropertyKey
import androidx.compose.ui.semantics.SemanticsPropertyReceiver
import androidx.compose.ui.unit.dp
import android.content.Context
import android.provider.Settings

/**
 * Accessibility utilities for glassmorphism components
 */
object AccessibilityEnhancements {
    
    /**
     * Check if high contrast mode is enabled
     */
    fun isHighContrastEnabled(context: Context): Boolean {
        return Settings.Secure.getInt(
            context.contentResolver,
            "high_text_contrast_enabled",
            0
        ) == 1
    }
    
    /**
     * Check if animations should be reduced
     */
    fun shouldReduceAnimations(context: Context): Boolean {
        return Settings.Global.getFloat(
            context.contentResolver,
            Settings.Global.ANIMATOR_DURATION_SCALE,
            1f
        ) == 0f
    }
    
    /**
     * Calculate contrast ratio between two colors
     */
    fun calculateContrastRatio(color1: Color, color2: Color): Float {
        val luminance1 = color1.luminance() + 0.05f
        val luminance2 = color2.luminance() + 0.05f
        
        return if (luminance1 > luminance2) {
            luminance1 / luminance2
        } else {
            luminance2 / luminance1
        }
    }
    
    /**
     * Ensure minimum contrast ratio for accessibility
     */
    fun ensureAccessibleContrast(
        foreground: Color,
        background: Color,
        minimumRatio: Float = 4.5f
    ): Color {
        val currentRatio = calculateContrastRatio(foreground, background)
        
        return if (currentRatio >= minimumRatio) {
            foreground
        } else {
            // Adjust foreground color to meet contrast requirements
            if (background.luminance() > 0.5f) {
                // Light background, darken foreground
                Color(
                    red = foreground.red * 0.7f,
                    green = foreground.green * 0.7f,
                    blue = foreground.blue * 0.7f,
                    alpha = foreground.alpha
                )
            } else {
                // Dark background, lighten foreground
                Color(
                    red = minOf(foreground.red * 1.3f, 1f),
                    green = minOf(foreground.green * 1.3f, 1f),
                    blue = minOf(foreground.blue * 1.3f, 1f),
                    alpha = foreground.alpha
                )
            }
        }
    }
    
    /**
     * Get accessible glassmorphism transparency
     */
    fun getAccessibleTransparency(
        context: Context,
        defaultTransparency: Float
    ): Float {
        return if (isHighContrastEnabled(context)) {
            // Reduce transparency for better contrast
            minOf(defaultTransparency * 2f, 0.9f)
        } else {
            defaultTransparency
        }
    }
    
    /**
     * Get accessible blur radius
     */
    fun getAccessibleBlurRadius(
        context: Context,
        defaultBlurRadius: Float
    ): Float {
        return if (isHighContrastEnabled(context)) {
            // Reduce blur for better readability
            defaultBlurRadius * 0.5f
        } else {
            defaultBlurRadius
        }
    }
}

/**
 * Accessibility-aware glassmorphism configuration
 */
@Composable
fun rememberAccessibleGlassmorphismConfig(): AccessibleGlassmorphismConfig {
    val context = LocalContext.current
    
    return remember {
        AccessibleGlassmorphismConfig(
            isHighContrastEnabled = AccessibilityEnhancements.isHighContrastEnabled(context),
            shouldReduceAnimations = AccessibilityEnhancements.shouldReduceAnimations(context),
            accessibleTransparency = AccessibilityEnhancements.getAccessibleTransparency(context, 0.15f),
            accessibleBlurRadius = AccessibilityEnhancements.getAccessibleBlurRadius(context, 24f)
        )
    }
}

data class AccessibleGlassmorphismConfig(
    val isHighContrastEnabled: Boolean,
    val shouldReduceAnimations: Boolean,
    val accessibleTransparency: Float,
    val accessibleBlurRadius: Float
)

/**
 * Semantic properties for glassmorphism components
 */
val GlassmorphismRole = SemanticsPropertyKey<String>("GlassmorphismRole")
val GlassmorphismState = SemanticsPropertyKey<String>("GlassmorphismState")

fun SemanticsPropertyReceiver.glassmorphismRole(role: String) {
    this[GlassmorphismRole] = role
}

fun SemanticsPropertyReceiver.glassmorphismState(state: String) {
    this[GlassmorphismState] = state
}

/**
 * Accessibility modifiers for glassmorphism components
 */
fun Modifier.accessibleGlassCard(
    contentDescription: String,
    isInteractive: Boolean = false
): Modifier = this.semantics {
    this.contentDescription = contentDescription
    if (isInteractive) {
        role = Role.Button
    }
    glassmorphismRole("glass_card")
}

fun Modifier.accessibleGlassButton(
    contentDescription: String,
    enabled: Boolean = true
): Modifier = this.semantics {
    this.contentDescription = contentDescription
    role = Role.Button
    stateDescription = if (enabled) "enabled" else "disabled"
    glassmorphismRole("glass_button")
    glassmorphismState(if (enabled) "enabled" else "disabled")
}

fun Modifier.accessibleGlassTextField(
    contentDescription: String,
    value: String,
    hasError: Boolean = false
): Modifier = this.semantics {
    this.contentDescription = contentDescription
    role = Role.Button // Text fields are treated as buttons for TalkBack
    stateDescription = when {
        hasError -> "error, $value"
        value.isEmpty() -> "empty"
        else -> value
    }
    glassmorphismRole("glass_text_field")
    glassmorphismState(if (hasError) "error" else "normal")
}

/**
 * High contrast theme adjustments
 */
@Composable
fun HighContrastAdjustments(
    content: @Composable () -> Unit
) {
    val accessibleConfig = rememberAccessibleGlassmorphismConfig()
    
    if (accessibleConfig.isHighContrastEnabled) {
        // Apply high contrast adjustments
        androidx.compose.material3.LocalContentColor.current.let { contentColor ->
            val backgroundColor = MaterialTheme.colorScheme.background
            val adjustedColor = AccessibilityEnhancements.ensureAccessibleContrast(
                contentColor,
                backgroundColor
            )
            
            androidx.compose.runtime.CompositionLocalProvider(
                androidx.compose.material3.LocalContentColor provides adjustedColor
            ) {
                content()
            }
        }
    } else {
        content()
    }
}

/**
 * Reduced motion wrapper
 */
@Composable
fun ReducedMotionWrapper(
    content: @Composable (shouldReduceMotion: Boolean) -> Unit
) {
    val accessibleConfig = rememberAccessibleGlassmorphismConfig()
    content(accessibleConfig.shouldReduceAnimations)
}