package com.tasktracker.presentation.components.glassmorphism

import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.tween
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.interaction.collectIsPressedAsState
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material3.LocalTextStyle
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.scale
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.input.VisualTransformation
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import com.tasktracker.presentation.theme.BlurredSurface
import com.tasktracker.presentation.theme.LocalGlassmorphismConfig
import com.tasktracker.presentation.theme.adaptiveGlassColors

/**
 * Glassmorphism card component with blur effects
 */
@Composable
fun GlassCard(
    modifier: Modifier = Modifier,
    onClick: (() -> Unit)? = null,
    blurRadius: Dp? = null,
    transparency: Float? = null,
    elevation: Dp? = null,
    shape: RoundedCornerShape = RoundedCornerShape(16.dp),
    contentPadding: PaddingValues = PaddingValues(16.dp),
    content: @Composable () -> Unit
) {
    val interactionSource = remember { MutableInteractionSource() }
    val isPressed by interactionSource.collectIsPressedAsState()
    
    val scale by animateFloatAsState(
        targetValue = if (isPressed) 0.98f else 1f,
        animationSpec = tween(durationMillis = 100),
        label = "glass_card_scale"
    )
    
    BlurredSurface(
        modifier = modifier
            .scale(scale)
            .then(
                if (onClick != null) {
                    Modifier.clickable(
                        interactionSource = interactionSource,
                        indication = null
                    ) { onClick() }
                } else {
                    Modifier
                }
            ),
        blurRadius = blurRadius,
        transparency = transparency,
        elevation = elevation,
        shape = shape
    ) {
        Box(
            modifier = Modifier.padding(contentPadding)
        ) {
            content()
        }
    }
}

/**
 * Glassmorphism button component
 */
@Composable
fun GlassButton(
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    enabled: Boolean = true,
    shape: RoundedCornerShape = RoundedCornerShape(12.dp),
    contentPadding: PaddingValues = PaddingValues(horizontal = 24.dp, vertical = 12.dp),
    content: @Composable () -> Unit
) {
    val interactionSource = remember { MutableInteractionSource() }
    val isPressed by interactionSource.collectIsPressedAsState()
    val config = LocalGlassmorphismConfig.current
    val glassColors = adaptiveGlassColors()
    
    val scale by animateFloatAsState(
        targetValue = if (isPressed) 0.95f else 1f,
        animationSpec = tween(durationMillis = 100),
        label = "glass_button_scale"
    )
    
    val transparency by animateFloatAsState(
        targetValue = if (isPressed) config.transparency * 1.5f else config.transparency,
        animationSpec = tween(durationMillis = 100),
        label = "glass_button_transparency"
    )
    
    BlurredSurface(
        modifier = modifier
            .scale(scale)
            .clickable(
                interactionSource = interactionSource,
                indication = null,
                enabled = enabled
            ) { onClick() },
        transparency = transparency,
        shape = shape
    ) {
        Box(
            modifier = Modifier.padding(contentPadding),
            contentAlignment = Alignment.Center
        ) {
            content()
        }
    }
}

/**
 * Glassmorphism text field component
 */
@Composable
fun GlassTextField(
    value: String,
    onValueChange: (String) -> Unit,
    modifier: Modifier = Modifier,
    placeholder: String = "",
    textStyle: TextStyle = LocalTextStyle.current,
    keyboardOptions: KeyboardOptions = KeyboardOptions.Default,
    keyboardActions: KeyboardActions = KeyboardActions.Default,
    visualTransformation: VisualTransformation = VisualTransformation.None,
    shape: RoundedCornerShape = RoundedCornerShape(12.dp),
    contentPadding: PaddingValues = PaddingValues(16.dp)
) {
    val glassColors = adaptiveGlassColors()
    
    BlurredSurface(
        modifier = modifier,
        shape = shape
    ) {
        BasicTextField(
            value = value,
            onValueChange = onValueChange,
            modifier = Modifier
                .fillMaxWidth()
                .padding(contentPadding),
            textStyle = textStyle.copy(color = glassColors.onSurface),
            keyboardOptions = keyboardOptions,
            keyboardActions = keyboardActions,
            visualTransformation = visualTransformation,
            cursorBrush = SolidColor(MaterialTheme.colorScheme.primary),
            decorationBox = { innerTextField ->
                Box {
                    if (value.isEmpty() && placeholder.isNotEmpty()) {
                        Text(
                            text = placeholder,
                            style = textStyle.copy(
                                color = glassColors.onSurface.copy(alpha = 0.6f)
                            )
                        )
                    }
                    innerTextField()
                }
            }
        )
    }
}

/**
 * Glassmorphism bottom sheet component
 */
@Composable
fun GlassBottomSheet(
    modifier: Modifier = Modifier,
    shape: RoundedCornerShape = RoundedCornerShape(topStart = 24.dp, topEnd = 24.dp),
    contentPadding: PaddingValues = PaddingValues(24.dp),
    content: @Composable () -> Unit
) {
    BlurredSurface(
        modifier = modifier,
        transparency = 0.2f,
        shape = shape
    ) {
        Box(
            modifier = Modifier.padding(contentPadding)
        ) {
            content()
        }
    }
}

/**
 * Glassmorphism floating action button
 */
@Composable
fun GlassFab(
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    shape: RoundedCornerShape = RoundedCornerShape(16.dp),
    content: @Composable () -> Unit
) {
    val interactionSource = remember { MutableInteractionSource() }
    val isPressed by interactionSource.collectIsPressedAsState()
    
    val scale by animateFloatAsState(
        targetValue = if (isPressed) 0.9f else 1f,
        animationSpec = tween(durationMillis = 150),
        label = "glass_fab_scale"
    )
    
    BlurredSurface(
        modifier = modifier
            .scale(scale)
            .clickable(
                interactionSource = interactionSource,
                indication = null
            ) { onClick() },
        transparency = 0.2f,
        elevation = 12.dp,
        shape = shape
    ) {
        Box(
            modifier = Modifier.padding(16.dp),
            contentAlignment = Alignment.Center
        ) {
            content()
        }
    }
}

/**
 * Glassmorphism navigation bar
 */
@Composable
fun GlassNavigationBar(
    modifier: Modifier = Modifier,
    shape: RoundedCornerShape = RoundedCornerShape(topStart = 20.dp, topEnd = 20.dp),
    contentPadding: PaddingValues = PaddingValues(horizontal = 16.dp, vertical = 12.dp),
    content: @Composable () -> Unit
) {
    BlurredSurface(
        modifier = modifier,
        transparency = 0.15f,
        shape = shape
    ) {
        Box(
            modifier = Modifier.padding(contentPadding)
        ) {
            content()
        }
    }
}