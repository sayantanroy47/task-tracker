package com.tasktracker.presentation.components.focus

import androidx.compose.animation.core.Animatable
import androidx.compose.animation.core.LinearEasing
import androidx.compose.animation.core.RepeatMode
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.infiniteRepeatable
import androidx.compose.animation.core.tween
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Pause
import androidx.compose.material.icons.filled.PlayArrow
import androidx.compose.material.icons.filled.Stop
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.drawscope.DrawScope
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.tasktracker.domain.model.FocusMode
import com.tasktracker.domain.model.FocusSession
import com.tasktracker.presentation.components.glassmorphism.GlassButton
import com.tasktracker.presentation.components.glassmorphism.GlassCard
import com.tasktracker.presentation.theme.adaptiveGlassColors
import java.time.Duration
import kotlin.math.cos
import kotlin.math.sin

/**
 * Focus mode toggle component with elegant mode selection
 */
@Composable
fun FocusModeToggle(
    isActive: Boolean,
    currentMode: FocusMode,
    onToggle: (Boolean) -> Unit,
    onModeChange: (FocusMode) -> Unit,
    modifier: Modifier = Modifier
) {
    val glassColors = adaptiveGlassColors()
    
    GlassCard(
        modifier = modifier.fillMaxWidth(),
        onClick = if (!isActive) { { onToggle(true) } } else null
    ) {
        Column {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Column(modifier = Modifier.weight(1f)) {
                    Text(
                        text = "🎯 Focus Mode",
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.SemiBold,
                        color = glassColors.onSurface
                    )
                    Text(
                        text = if (isActive) "Active: ${currentMode.displayName}" else "Tap to start focusing",
                        style = MaterialTheme.typography.bodySmall,
                        color = glassColors.onSurface.copy(alpha = 0.7f)
                    )
                }
                
                FocusModeIndicator(
                    isActive = isActive,
                    mode = currentMode
                )
            }
            
            if (!isActive) {
                Spacer(modifier = Modifier.height(12.dp))
                
                // Mode selection chips
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    FocusMode.values().take(3).forEach { mode ->
                        FocusModeChip(
                            mode = mode,
                            isSelected = mode == currentMode,
                            onClick = { onModeChange(mode) },
                            modifier = Modifier.weight(1f)
                        )
                    }
                }
            }
        }
    }
}

/**
 * Focus mode indicator with animated states
 */
@Composable
private fun FocusModeIndicator(
    isActive: Boolean,
    mode: FocusMode,
    modifier: Modifier = Modifier
) {
    val pulseAnimation = remember { Animatable(0f) }
    
    LaunchedEffect(isActive) {
        if (isActive) {
            pulseAnimation.animateTo(
                targetValue = 1f,
                animationSpec = infiniteRepeatable(
                    animation = tween(2000, easing = LinearEasing),
                    repeatMode = RepeatMode.Reverse
                )
            )
        } else {
            pulseAnimation.snapTo(0f)
        }
    }
    
    Box(
        modifier = modifier
            .size(48.dp)
            .background(
                color = Color(android.graphics.Color.parseColor(mode.color))
                    .copy(alpha = 0.1f + if (isActive) pulseAnimation.value * 0.2f else 0f),
                shape = CircleShape
            ),
        contentAlignment = Alignment.Center
    ) {
        Text(
            text = if (isActive) "⚡" else "🎯",
            fontSize = 20.sp
        )
    }
}

/**
 * Focus mode selection chip
 */
@Composable
private fun FocusModeChip(
    mode: FocusMode,
    isSelected: Boolean,
    onClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    val glassColors = adaptiveGlassColors()
    val backgroundColor = if (isSelected) {
        Color(android.graphics.Color.parseColor(mode.color)).copy(alpha = 0.2f)
    } else {
        glassColors.surface
    }
    
    Box(
        modifier = modifier
            .clip(RoundedCornerShape(8.dp))
            .background(backgroundColor)
            .clickable { onClick() }
            .padding(vertical = 8.dp, horizontal = 12.dp),
        contentAlignment = Alignment.Center
    ) {
        Text(
            text = mode.displayName,
            style = MaterialTheme.typography.labelSmall,
            color = if (isSelected) {
                Color(android.graphics.Color.parseColor(mode.color))
            } else {
                glassColors.onSurface.copy(alpha = 0.7f)
            },
            fontWeight = if (isSelected) FontWeight.SemiBold else FontWeight.Normal,
            textAlign = TextAlign.Center
        )
    }
}

/**
 * Circular progress timer with calming animations
 */
@Composable
fun FocusTimer(
    session: FocusSession?,
    remainingTime: Duration,
    elapsedTime: Duration,
    onPause: () -> Unit,
    onResume: () -> Unit,
    onStop: () -> Unit,
    modifier: Modifier = Modifier
) {
    val glassColors = adaptiveGlassColors()
    val progress = if (session != null) {
        val totalMinutes = session.plannedDuration.toMinutes().toFloat()
        val elapsedMinutes = elapsedTime.toMinutes().toFloat()
        (elapsedMinutes / totalMinutes).coerceIn(0f, 1f)
    } else 0f
    
    val animatedProgress by animateFloatAsState(
        targetValue = progress,
        animationSpec = tween(durationMillis = 500),
        label = "timer_progress"
    )
    
    GlassCard(
        modifier = modifier.fillMaxWidth()
    ) {
        Column(
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            // Timer display
            Box(
                modifier = Modifier.size(200.dp),
                contentAlignment = Alignment.Center
            ) {
                Canvas(
                    modifier = Modifier.fillMaxSize()
                ) {
                    drawTimerCircle(
                        progress = animatedProgress,
                        session = session,
                        glassColors = glassColors
                    )
                }
                
                Column(
                    horizontalAlignment = Alignment.CenterHorizontally
                ) {
                    Text(
                        text = formatDuration(remainingTime),
                        style = MaterialTheme.typography.headlineLarge,
                        fontWeight = FontWeight.Bold,
                        color = glassColors.onSurface
                    )
                    
                    session?.let {
                        Text(
                            text = it.mode.displayName,
                            style = MaterialTheme.typography.bodyMedium,
                            color = Color(android.graphics.Color.parseColor(it.mode.color))
                        )
                    }
                }
            }
            
            Spacer(modifier = Modifier.height(24.dp))
            
            // Control buttons
            if (session != null) {
                Row(
                    horizontalArrangement = Arrangement.spacedBy(16.dp)
                ) {
                    GlassButton(
                        onClick = onStop,
                        modifier = Modifier.weight(1f)
                    ) {
                        Row(
                            verticalAlignment = Alignment.CenterVertically,
                            horizontalArrangement = Arrangement.spacedBy(8.dp)
                        ) {
                            Icon(
                                imageVector = Icons.Default.Stop,
                                contentDescription = "Stop",
                                modifier = Modifier.size(16.dp)
                            )
                            Text("Stop")
                        }
                    }
                    
                    GlassButton(
                        onClick = if (session.isPaused) onResume else onPause,
                        modifier = Modifier.weight(1f)
                    ) {
                        Row(
                            verticalAlignment = Alignment.CenterVertically,
                            horizontalArrangement = Arrangement.spacedBy(8.dp)
                        ) {
                            Icon(
                                imageVector = if (session.isPaused) Icons.Default.PlayArrow else Icons.Default.Pause,
                                contentDescription = if (session.isPaused) "Resume" else "Pause",
                                modifier = Modifier.size(16.dp)
                            )
                            Text(if (session.isPaused) "Resume" else "Pause")
                        }
                    }
                }
            }
        }
    }
}

/**
 * Focus session summary component for post-session feedback
 */
@Composable
fun FocusSessionSummary(
    session: FocusSession,
    onStartNewSession: () -> Unit,
    onClose: () -> Unit,
    modifier: Modifier = Modifier
) {
    val glassColors = adaptiveGlassColors()
    
    GlassCard(
        modifier = modifier.fillMaxWidth()
    ) {
        Column(
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            // Celebration icon
            Text(
                text = "🎉",
                fontSize = 48.sp
            )
            
            Spacer(modifier = Modifier.height(16.dp))
            
            Text(
                text = "Focus Session Complete!",
                style = MaterialTheme.typography.headlineSmall,
                fontWeight = FontWeight.Bold,
                color = glassColors.onSurface
            )
            
            Spacer(modifier = Modifier.height(16.dp))
            
            // Session stats
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceEvenly
            ) {
                SessionStatItem(
                    value = formatDuration(session.actualDuration ?: Duration.ZERO),
                    label = "Duration",
                    icon = "⏱️"
                )
                
                SessionStatItem(
                    value = session.tasksCompleted.toString(),
                    label = "Tasks Done",
                    icon = "✅"
                )
                
                SessionStatItem(
                    value = "${(session.focusScore * 100).toInt()}%",
                    label = "Focus Score",
                    icon = "🎯"
                )
            }
            
            Spacer(modifier = Modifier.height(24.dp))
            
            // Action buttons
            Row(
                horizontalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                GlassButton(
                    onClick = onClose,
                    modifier = Modifier.weight(1f)
                ) {
                    Text("Done")
                }
                
                GlassButton(
                    onClick = onStartNewSession,
                    modifier = Modifier.weight(1f)
                ) {
                    Text("Start Another")
                }
            }
        }
    }
}

/**
 * Individual session stat item
 */
@Composable
private fun SessionStatItem(
    value: String,
    label: String,
    icon: String,
    modifier: Modifier = Modifier
) {
    val glassColors = adaptiveGlassColors()
    
    Column(
        modifier = modifier,
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Text(
            text = icon,
            fontSize = 24.sp
        )
        
        Spacer(modifier = Modifier.height(4.dp))
        
        Text(
            text = value,
            style = MaterialTheme.typography.titleMedium,
            fontWeight = FontWeight.Bold,
            color = glassColors.onSurface
        )
        
        Text(
            text = label,
            style = MaterialTheme.typography.bodySmall,
            color = glassColors.onSurface.copy(alpha = 0.7f)
        )
    }
}

/**
 * Focus mode settings panel
 */
@Composable
fun FocusSettingsPanel(
    settings: com.tasktracker.domain.model.FocusSettings,
    onSettingsChange: (com.tasktracker.domain.model.FocusSettings) -> Unit,
    modifier: Modifier = Modifier
) {
    val glassColors = adaptiveGlassColors()
    
    GlassCard(
        modifier = modifier.fillMaxWidth()
    ) {
        Column {
            Text(
                text = "⚙️ Focus Settings",
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.SemiBold,
                color = glassColors.onSurface
            )
            
            Spacer(modifier = Modifier.height(16.dp))
            
            // Default mode selection
            Text(
                text = "Default Focus Mode",
                style = MaterialTheme.typography.bodyMedium,
                fontWeight = FontWeight.Medium,
                color = glassColors.onSurface
            )
            
            Spacer(modifier = Modifier.height(8.dp))
            
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                FocusMode.values().forEach { mode ->
                    FocusModeChip(
                        mode = mode,
                        isSelected = mode == settings.defaultMode,
                        onClick = { 
                            onSettingsChange(settings.copy(defaultMode = mode))
                        },
                        modifier = Modifier.weight(1f)
                    )
                }
            }
            
            Spacer(modifier = Modifier.height(16.dp))
            
            // Settings toggles
            SettingToggleItem(
                title = "Enable Breaks",
                description = "Automatic break reminders",
                isEnabled = settings.enableBreaks,
                onToggle = { onSettingsChange(settings.copy(enableBreaks = it)) }
            )
            
            SettingToggleItem(
                title = "Hide Completed Tasks",
                description = "Hide finished tasks during focus",
                isEnabled = settings.hideCompletedTasks,
                onToggle = { onSettingsChange(settings.copy(hideCompletedTasks = it)) }
            )
            
            SettingToggleItem(
                title = "Haptic Feedback",
                description = "Vibration for focus events",
                isEnabled = settings.enableHapticFeedback,
                onToggle = { onSettingsChange(settings.copy(enableHapticFeedback = it)) }
            )
        }
    }
}

/**
 * Setting toggle item
 */
@Composable
private fun SettingToggleItem(
    title: String,
    description: String,
    isEnabled: Boolean,
    onToggle: (Boolean) -> Unit,
    modifier: Modifier = Modifier
) {
    val glassColors = adaptiveGlassColors()
    
    Row(
        modifier = modifier
            .fillMaxWidth()
            .clickable { onToggle(!isEnabled) }
            .padding(vertical = 8.dp),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically
    ) {
        Column(modifier = Modifier.weight(1f)) {
            Text(
                text = title,
                style = MaterialTheme.typography.bodyMedium,
                fontWeight = FontWeight.Medium,
                color = glassColors.onSurface
            )
            Text(
                text = description,
                style = MaterialTheme.typography.bodySmall,
                color = glassColors.onSurface.copy(alpha = 0.7f)
            )
        }
        
        Box(
            modifier = Modifier
                .size(24.dp)
                .background(
                    color = if (isEnabled) MaterialTheme.colorScheme.primary else glassColors.surface,
                    shape = CircleShape
                ),
            contentAlignment = Alignment.Center
        ) {
            if (isEnabled) {
                Text(
                    text = "✓",
                    color = Color.White,
                    fontSize = 12.sp,
                    fontWeight = FontWeight.Bold
                )
            }
        }
    }
}

// Helper functions
private fun DrawScope.drawTimerCircle(
    progress: Float,
    session: FocusSession?,
    glassColors: com.tasktracker.presentation.theme.GlassColors
) {
    val center = Offset(size.width / 2, size.height / 2)
    val radius = size.minDimension / 2 - 20.dp.toPx()
    
    // Background circle
    drawCircle(
        color = glassColors.surface,
        radius = radius,
        center = center,
        style = Stroke(width = 8.dp.toPx())
    )
    
    // Progress arc
    if (session != null && progress > 0f) {
        val sweepAngle = 360f * progress
        val color = Color(android.graphics.Color.parseColor(session.mode.color))
        
        drawArc(
            color = color,
            startAngle = -90f,
            sweepAngle = sweepAngle,
            useCenter = false,
            style = Stroke(width = 8.dp.toPx(), cap = StrokeCap.Round),
            topLeft = Offset(center.x - radius, center.y - radius),
            size = Size(radius * 2, radius * 2)
        )
    }
}

private fun formatDuration(duration: Duration): String {
    val minutes = duration.toMinutes()
    val seconds = duration.seconds % 60
    return String.format("%02d:%02d", minutes, seconds)
}