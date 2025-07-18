package com.tasktracker.presentation.navigation

import androidx.compose.animation.animateColorAsState
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.tween
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Icon
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
import androidx.compose.ui.hapticfeedback.HapticFeedbackType
import androidx.compose.ui.platform.LocalHapticFeedback
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.navigation.NavDestination
import androidx.navigation.NavDestination.Companion.hierarchy
import com.tasktracker.presentation.components.glassmorphism.GlassNavigationBar
import com.tasktracker.presentation.theme.adaptiveGlassColors

/**
 * Glassmorphism bottom navigation bar
 */
@Composable
fun GlassBottomNavigation(
    currentDestination: NavDestination?,
    onNavigate: (String) -> Unit,
    modifier: Modifier = Modifier
) {
    val glassColors = adaptiveGlassColors()
    val hapticFeedback = LocalHapticFeedback.current
    
    GlassNavigationBar(
        modifier = modifier,
        shape = RoundedCornerShape(topStart = 24.dp, topEnd = 24.dp),
        contentPadding = PaddingValues(horizontal = 16.dp, vertical = 12.dp)
    ) {
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceEvenly,
            verticalAlignment = Alignment.CenterVertically
        ) {
            navigationScreens.forEach { screen ->
                val isSelected = currentDestination?.hierarchy?.any { it.route == screen.route } == true
                
                NavigationItem(
                    screen = screen,
                    isSelected = isSelected,
                    onClick = {
                        hapticFeedback.performHapticFeedback(HapticFeedbackType.LongPress)
                        onNavigate(screen.route)
                    }
                )
            }
        }
    }
}

/**
 * Individual navigation item with glassmorphism effects
 */
@Composable
private fun NavigationItem(
    screen: Screen,
    isSelected: Boolean,
    onClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    val glassColors = adaptiveGlassColors()
    val interactionSource = remember { MutableInteractionSource() }
    
    // Animated properties
    val scale by animateFloatAsState(
        targetValue = if (isSelected) 1.1f else 1f,
        animationSpec = tween(durationMillis = 200),
        label = "nav_item_scale"
    )
    
    val iconColor by animateColorAsState(
        targetValue = if (isSelected) {
            MaterialTheme.colorScheme.primary
        } else {
            glassColors.onSurface.copy(alpha = 0.6f)
        },
        animationSpec = tween(durationMillis = 200),
        label = "nav_item_icon_color"
    )
    
    val textColor by animateColorAsState(
        targetValue = if (isSelected) {
            MaterialTheme.colorScheme.primary
        } else {
            glassColors.onSurface.copy(alpha = 0.6f)
        },
        animationSpec = tween(durationMillis = 200),
        label = "nav_item_text_color"
    )
    
    val backgroundAlpha by animateFloatAsState(
        targetValue = if (isSelected) 0.2f else 0f,
        animationSpec = tween(durationMillis = 200),
        label = "nav_item_background"
    )
    
    Column(
        modifier = modifier
            .scale(scale)
            .clip(RoundedCornerShape(16.dp))
            .background(
                brush = Brush.radialGradient(
                    colors = listOf(
                        MaterialTheme.colorScheme.primary.copy(alpha = backgroundAlpha),
                        Color.Transparent
                    ),
                    radius = 60f
                )
            )
            .clickable(
                interactionSource = interactionSource,
                indication = null
            ) { onClick() }
            .padding(horizontal = 12.dp, vertical = 8.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(4.dp)
    ) {
        Icon(
            imageVector = screen.icon,
            contentDescription = screen.title,
            tint = iconColor,
            modifier = Modifier.size(24.dp)
        )
        
        Text(
            text = screen.title,
            style = MaterialTheme.typography.labelSmall.copy(
                fontSize = 11.sp,
                fontWeight = if (isSelected) FontWeight.SemiBold else FontWeight.Normal
            ),
            color = textColor
        )
    }
}