package com.tasktracker.presentation.animations

import androidx.compose.animation.core.Animatable
import androidx.compose.animation.core.AnimationSpec
import androidx.compose.animation.core.Spring
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.spring
import androidx.compose.animation.core.tween
import androidx.compose.foundation.gestures.detectTapGestures
import androidx.compose.foundation.layout.offset
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.composed
import androidx.compose.ui.draw.scale
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.unit.IntOffset
import androidx.compose.ui.unit.dp
import kotlinx.coroutines.delay
import kotlin.math.roundToInt

/**
 * Polished animation specifications for 2025 UI
 */
object PolishedAnimations {
    
    // Spring animations for natural feel
    val gentleSpring = spring<Float>(
        dampingRatio = Spring.DampingRatioMediumBouncy,
        stiffness = Spring.StiffnessLow
    )
    
    val responsiveSpring = spring<Float>(
        dampingRatio = Spring.DampingRatioLowBouncy,
        stiffness = Spring.StiffnessMedium
    )
    
    val snappySpring = spring<Float>(
        dampingRatio = Spring.DampingRatioNoBouncy,
        stiffness = Spring.StiffnessHigh
    )
    
    // Easing curves for smooth transitions
    val smoothEasing = tween<Float>(
        durationMillis = 300,
        easing = androidx.compose.animation.core.FastOutSlowInEasing
    )
    
    val quickEasing = tween<Float>(
        durationMillis = 150,
        easing = androidx.compose.animation.core.FastOutLinearInEasing
    )
    
    val delayedEasing = tween<Float>(
        durationMillis = 400,
        delayMillis = 100,
        easing = androidx.compose.animation.core.LinearOutSlowInEasing
    )
}

/**
 * Polished press animation with haptic feedback
 */
fun Modifier.polishedPressAnimation(
    enabled: Boolean = true,
    pressScale: Float = 0.96f,
    animationSpec: AnimationSpec<Float> = PolishedAnimations.responsiveSpring
): Modifier = composed {
    var isPressed by remember { mutableStateOf(false) }
    
    val scale by animateFloatAsState(
        targetValue = if (isPressed && enabled) pressScale else 1f,
        animationSpec = animationSpec,
        label = "press_scale"
    )
    
    this
        .scale(scale)
        .pointerInput(enabled) {
            if (enabled) {
                detectTapGestures(
                    onPress = {
                        isPressed = true
                        tryAwaitRelease()
                        isPressed = false
                    }
                )
            }
        }
}

/**
 * Floating animation for cards and elements
 */
fun Modifier.floatingAnimation(
    enabled: Boolean = true,
    amplitude: Float = 2f,
    duration: Int = 3000
): Modifier = composed {
    val density = LocalDensity.current
    val animatable = remember { Animatable(0f) }
    
    LaunchedEffect(enabled) {
        if (enabled) {
            while (true) {
                animatable.animateTo(
                    targetValue = amplitude,
                    animationSpec = tween(duration / 2)
                )
                animatable.animateTo(
                    targetValue = -amplitude,
                    animationSpec = tween(duration / 2)
                )
            }
        }
    }
    
    if (enabled) {
        this.offset {
            IntOffset(
                x = 0,
                y = with(density) { animatable.value.dp.roundToPx() }
            )
        }
    } else {
        this
    }
}

/**
 * Shimmer effect for loading states
 */
fun Modifier.shimmerEffect(
    enabled: Boolean = true,
    duration: Int = 1500
): Modifier = composed {
    val animatable = remember { Animatable(0f) }
    
    LaunchedEffect(enabled) {
        if (enabled) {
            while (true) {
                animatable.animateTo(
                    targetValue = 1f,
                    animationSpec = tween(duration)
                )
                animatable.snapTo(0f)
            }
        }
    }
    
    if (enabled) {
        this.graphicsLayer {
            alpha = 0.3f + (animatable.value * 0.7f)
        }
    } else {
        this
    }
}

/**
 * Parallax scrolling effect
 */
fun Modifier.parallaxEffect(
    scrollOffset: Float,
    parallaxRatio: Float = 0.5f
): Modifier = composed {
    val density = LocalDensity.current
    
    this.offset {
        IntOffset(
            x = 0,
            y = with(density) { (scrollOffset * parallaxRatio).dp.roundToPx() }
        )
    }
}

/**
 * Staggered entrance animation
 */
@Composable
fun StaggeredEntranceAnimation(
    itemCount: Int,
    staggerDelay: Long = 100L,
    content: @Composable (index: Int, animationProgress: Float) -> Unit
) {
    repeat(itemCount) { index ->
        var animationProgress by remember { mutableStateOf(0f) }
        
        LaunchedEffect(index) {
            delay(index * staggerDelay)
            
            val animatable = Animatable(0f)
            animatable.animateTo(
                targetValue = 1f,
                animationSpec = PolishedAnimations.gentleSpring
            )
            animationProgress = animatable.value
        }
        
        content(index, animationProgress)
    }
}

/**
 * Morphing animation between states
 */
@Composable
fun MorphingAnimation(
    targetState: Boolean,
    animationSpec: AnimationSpec<Float> = PolishedAnimations.smoothEasing,
    content: @Composable (progress: Float) -> Unit
) {
    val progress by animateFloatAsState(
        targetValue = if (targetState) 1f else 0f,
        animationSpec = animationSpec,
        label = "morphing_progress"
    )
    
    content(progress)
}

/**
 * Breathing animation for focus indicators
 */
fun Modifier.breathingAnimation(
    enabled: Boolean = true,
    minScale: Float = 0.95f,
    maxScale: Float = 1.05f,
    duration: Int = 2000
): Modifier = composed {
    val animatable = remember { Animatable(minScale) }
    
    LaunchedEffect(enabled) {
        if (enabled) {
            while (true) {
                animatable.animateTo(
                    targetValue = maxScale,
                    animationSpec = tween(duration / 2)
                )
                animatable.animateTo(
                    targetValue = minScale,
                    animationSpec = tween(duration / 2)
                )
            }
        }
    }
    
    if (enabled) {
        this.scale(animatable.value)
    } else {
        this
    }
}

/**
 * Ripple-like expansion animation
 */
fun Modifier.rippleExpansion(
    triggered: Boolean,
    maxScale: Float = 1.2f,
    duration: Int = 600
): Modifier = composed {
    val scale by animateFloatAsState(
        targetValue = if (triggered) maxScale else 1f,
        animationSpec = if (triggered) {
            tween(duration, easing = androidx.compose.animation.core.FastOutSlowInEasing)
        } else {
            tween(200, easing = androidx.compose.animation.core.LinearEasing)
        },
        label = "ripple_scale"
    )
    
    val alpha by animateFloatAsState(
        targetValue = if (triggered) 0.7f else 1f,
        animationSpec = tween(duration),
        label = "ripple_alpha"
    )
    
    this
        .scale(scale)
        .graphicsLayer { this.alpha = alpha }
}

/**
 * Elastic bounce animation
 */
fun Modifier.elasticBounce(
    triggered: Boolean,
    bounceScale: Float = 1.15f
): Modifier = composed {
    val scale by animateFloatAsState(
        targetValue = if (triggered) bounceScale else 1f,
        animationSpec = spring(
            dampingRatio = Spring.DampingRatioMediumBouncy,
            stiffness = Spring.StiffnessHigh
        ),
        label = "elastic_bounce"
    )
    
    this.scale(scale)
}

/**
 * Smooth reveal animation
 */
fun Modifier.smoothReveal(
    visible: Boolean,
    slideDistance: Float = 50f
): Modifier = composed {
    val density = LocalDensity.current
    
    val alpha by animateFloatAsState(
        targetValue = if (visible) 1f else 0f,
        animationSpec = PolishedAnimations.smoothEasing,
        label = "reveal_alpha"
    )
    
    val offsetY by animateFloatAsState(
        targetValue = if (visible) 0f else slideDistance,
        animationSpec = PolishedAnimations.smoothEasing,
        label = "reveal_offset"
    )
    
    this
        .graphicsLayer { this.alpha = alpha }
        .offset {
            IntOffset(
                x = 0,
                y = with(density) { offsetY.dp.roundToPx() }
            )
        }
}