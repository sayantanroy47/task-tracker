package com.tasktracker.presentation.components.analytics

import androidx.compose.animation.core.Animatable
import androidx.compose.animation.core.LinearEasing
import androidx.compose.animation.core.RepeatMode
import androidx.compose.animation.core.infiniteRepeatable
import androidx.compose.animation.core.tween
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.TrendingUp
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.drawscope.DrawScope
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.tasktracker.domain.model.DailyStats
import com.tasktracker.domain.model.ProductivityInsight
import com.tasktracker.presentation.components.glassmorphism.GlassCard
import com.tasktracker.presentation.theme.adaptiveGlassColors
import kotlinx.coroutines.delay
import kotlin.math.cos
import kotlin.math.sin

/**
 * Chart types for productivity visualization
 */
enum class ChartType {
    LINE,
    BAR,
    AREA,
    CIRCULAR
}

/**
 * Animated productivity chart component using Canvas API
 */
@Composable
fun ProductivityChart(
    data: List<DailyStats>,
    chartType: ChartType = ChartType.LINE,
    modifier: Modifier = Modifier,
    showAnimation: Boolean = true
) {
    val glassColors = adaptiveGlassColors()
    val animationProgress = remember { Animatable(0f) }
    
    LaunchedEffect(data, showAnimation) {
        if (showAnimation) {
            animationProgress.animateTo(
                targetValue = 1f,
                animationSpec = tween(durationMillis = 1500, easing = LinearEasing)
            )
        } else {
            animationProgress.snapTo(1f)
        }
    }
    
    GlassCard(
        modifier = modifier
    ) {
        Column {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = "Weekly Progress",
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.SemiBold,
                    color = glassColors.onSurface
                )
                Icon(
                    imageVector = Icons.Default.TrendingUp,
                    contentDescription = null,
                    modifier = Modifier.size(20.dp),
                    tint = MaterialTheme.colorScheme.primary
                )
            }
            
            Spacer(modifier = Modifier.height(16.dp))
            
            Canvas(
                modifier = Modifier
                    .fillMaxWidth()
                    .height(120.dp)
            ) {
                when (chartType) {
                    ChartType.LINE -> drawLineChart(data, animationProgress.value, glassColors)
                    ChartType.BAR -> drawBarChart(data, animationProgress.value, glassColors)
                    ChartType.AREA -> drawAreaChart(data, animationProgress.value, glassColors)
                    ChartType.CIRCULAR -> drawCircularChart(data, animationProgress.value, glassColors)
                }
            }
            
            Spacer(modifier = Modifier.height(8.dp))
            
            // Chart labels
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                data.take(7).forEach { stat ->
                    Text(
                        text = stat.date.dayOfWeek.name.take(3),
                        style = MaterialTheme.typography.labelSmall,
                        color = glassColors.onSurface.copy(alpha = 0.7f),
                        modifier = Modifier.weight(1f),
                        textAlign = TextAlign.Center
                    )
                }
            }
        }
    }
}

/**
 * Animated streak display with fire effects
 */
@Composable
fun StreakDisplay(
    currentStreak: Int,
    longestStreak: Int,
    modifier: Modifier = Modifier
) {
    val glassColors = adaptiveGlassColors()
    val fireAnimation = remember { Animatable(0f) }
    
    LaunchedEffect(currentStreak) {
        if (currentStreak > 0) {
            fireAnimation.animateTo(
                targetValue = 1f,
                animationSpec = infiniteRepeatable(
                    animation = tween(2000),
                    repeatMode = RepeatMode.Reverse
                )
            )
        }
    }
    
    GlassCard(
        modifier = modifier
    ) {
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Column {
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    Text(
                        text = "🔥",
                        fontSize = 24.sp,
                        modifier = Modifier
                            .background(
                                color = Color.Orange.copy(alpha = 0.1f + fireAnimation.value * 0.2f),
                                shape = CircleShape
                            )
                            .padding(8.dp)
                    )
                    Column {
                        Text(
                            text = "$currentStreak days",
                            style = MaterialTheme.typography.titleLarge,
                            fontWeight = FontWeight.Bold,
                            color = glassColors.onSurface
                        )
                        Text(
                            text = "Current streak",
                            style = MaterialTheme.typography.bodySmall,
                            color = glassColors.onSurface.copy(alpha = 0.7f)
                        )
                    }
                }
            }
            
            Column(
                horizontalAlignment = Alignment.End
            ) {
                Text(
                    text = "$longestStreak",
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.SemiBold,
                    color = MaterialTheme.colorScheme.primary
                )
                Text(
                    text = "Best streak",
                    style = MaterialTheme.typography.bodySmall,
                    color = glassColors.onSurface.copy(alpha = 0.7f)
                )
            }
        }
    }
}

/**
 * Insights card with glassmorphism styling
 */
@Composable
fun InsightsCard(
    insight: ProductivityInsight,
    modifier: Modifier = Modifier,
    onDismiss: (() -> Unit)? = null
) {
    val glassColors = adaptiveGlassColors()
    val iconColor = when (insight.type.name) {
        "PEAK_HOURS" -> Color(0xFF4CAF50)
        "COMPLETION_PATTERN" -> Color(0xFF2196F3)
        "STREAK_OPPORTUNITY" -> Color(0xFFFF9800)
        "FOCUS_IMPROVEMENT" -> Color(0xFF9C27B0)
        else -> MaterialTheme.colorScheme.primary
    }
    
    GlassCard(
        modifier = modifier,
        onClick = onDismiss
    ) {
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            Box(
                modifier = Modifier
                    .size(40.dp)
                    .background(
                        color = iconColor.copy(alpha = 0.1f),
                        shape = CircleShape
                    ),
                contentAlignment = Alignment.Center
            ) {
                Text(
                    text = getInsightIcon(insight.type.name),
                    fontSize = 20.sp
                )
            }
            
            Column(
                modifier = Modifier.weight(1f)
            ) {
                Text(
                    text = insight.title,
                    style = MaterialTheme.typography.titleSmall,
                    fontWeight = FontWeight.SemiBold,
                    color = glassColors.onSurface
                )
                Text(
                    text = insight.description,
                    style = MaterialTheme.typography.bodySmall,
                    color = glassColors.onSurface.copy(alpha = 0.8f)
                )
                insight.actionSuggestion?.let { suggestion ->
                    Spacer(modifier = Modifier.height(4.dp))
                    Text(
                        text = "💡 $suggestion",
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.primary,
                        fontWeight = FontWeight.Medium
                    )
                }
            }
            
            // Confidence indicator
            Box(
                modifier = Modifier
                    .size(8.dp)
                    .background(
                        color = iconColor.copy(alpha = insight.confidence),
                        shape = CircleShape
                    )
            )
        }
    }
}

/**
 * Weekly trend chart with smooth animations
 */
@Composable
fun WeeklyTrendChart(
    weeklyData: List<DailyStats>,
    modifier: Modifier = Modifier
) {
    val glassColors = adaptiveGlassColors()
    val animationProgress = remember { Animatable(0f) }
    
    LaunchedEffect(weeklyData) {
        animationProgress.animateTo(
            targetValue = 1f,
            animationSpec = tween(durationMillis = 1200)
        )
    }
    
    GlassCard(
        modifier = modifier
    ) {
        Column {
            Text(
                text = "This Week",
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.SemiBold,
                color = glassColors.onSurface
            )
            
            Spacer(modifier = Modifier.height(16.dp))
            
            Canvas(
                modifier = Modifier
                    .fillMaxWidth()
                    .height(80.dp)
            ) {
                drawWeeklyBars(weeklyData, animationProgress.value, glassColors)
            }
            
            Spacer(modifier = Modifier.height(8.dp))
            
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                val totalCompleted = weeklyData.sumOf { it.tasksCompleted }
                val totalCreated = weeklyData.sumOf { it.tasksCreated }
                val completionRate = if (totalCreated > 0) {
                    (totalCompleted.toFloat() / totalCreated.toFloat() * 100).toInt()
                } else 0
                
                Column {
                    Text(
                        text = "$totalCompleted",
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.Bold,
                        color = glassColors.onSurface
                    )
                    Text(
                        text = "Completed",
                        style = MaterialTheme.typography.bodySmall,
                        color = glassColors.onSurface.copy(alpha = 0.7f)
                    )
                }
                
                Column(
                    horizontalAlignment = Alignment.End
                ) {
                    Text(
                        text = "$completionRate%",
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.Bold,
                        color = MaterialTheme.colorScheme.primary
                    )
                    Text(
                        text = "Success rate",
                        style = MaterialTheme.typography.bodySmall,
                        color = glassColors.onSurface.copy(alpha = 0.7f)
                    )
                }
            }
        }
    }
}

// Drawing functions for different chart types
private fun DrawScope.drawLineChart(
    data: List<DailyStats>,
    animationProgress: Float,
    glassColors: com.tasktracker.presentation.theme.GlassColors
) {
    if (data.isEmpty()) return
    
    val maxValue = data.maxOfOrNull { it.tasksCompleted }?.toFloat() ?: 1f
    val stepX = size.width / (data.size - 1).coerceAtLeast(1)
    val path = Path()
    
    data.forEachIndexed { index, stat ->
        val x = index * stepX
        val y = size.height - (stat.tasksCompleted / maxValue) * size.height * animationProgress
        
        if (index == 0) {
            path.moveTo(x, y)
        } else {
            path.lineTo(x, y)
        }
        
        // Draw data points
        drawCircle(
            color = Color(0xFF2196F3),
            radius = 4.dp.toPx(),
            center = Offset(x, y)
        )
    }
    
    // Draw the line
    drawPath(
        path = path,
        color = Color(0xFF2196F3),
        style = Stroke(width = 3.dp.toPx(), cap = StrokeCap.Round)
    )
}

private fun DrawScope.drawBarChart(
    data: List<DailyStats>,
    animationProgress: Float,
    glassColors: com.tasktracker.presentation.theme.GlassColors
) {
    if (data.isEmpty()) return
    
    val maxValue = data.maxOfOrNull { it.tasksCompleted }?.toFloat() ?: 1f
    val barWidth = size.width / data.size * 0.7f
    val spacing = size.width / data.size * 0.3f
    
    data.forEachIndexed { index, stat ->
        val barHeight = (stat.tasksCompleted / maxValue) * size.height * animationProgress
        val x = index * (barWidth + spacing) + spacing / 2
        
        drawRoundRect(
            brush = Brush.verticalGradient(
                colors = listOf(
                    Color(0xFF4CAF50),
                    Color(0xFF2196F3)
                )
            ),
            topLeft = Offset(x, size.height - barHeight),
            size = Size(barWidth, barHeight),
            cornerRadius = androidx.compose.ui.geometry.CornerRadius(4.dp.toPx())
        )
    }
}

private fun DrawScope.drawAreaChart(
    data: List<DailyStats>,
    animationProgress: Float,
    glassColors: com.tasktracker.presentation.theme.GlassColors
) {
    if (data.isEmpty()) return
    
    val maxValue = data.maxOfOrNull { it.tasksCompleted }?.toFloat() ?: 1f
    val stepX = size.width / (data.size - 1).coerceAtLeast(1)
    val path = Path()
    
    // Start from bottom left
    path.moveTo(0f, size.height)
    
    data.forEachIndexed { index, stat ->
        val x = index * stepX
        val y = size.height - (stat.tasksCompleted / maxValue) * size.height * animationProgress
        path.lineTo(x, y)
    }
    
    // Close the path at bottom right
    path.lineTo(size.width, size.height)
    path.close()
    
    drawPath(
        path = path,
        brush = Brush.verticalGradient(
            colors = listOf(
                Color(0xFF2196F3).copy(alpha = 0.3f),
                Color(0xFF2196F3).copy(alpha = 0.1f)
            )
        )
    )
}

private fun DrawScope.drawCircularChart(
    data: List<DailyStats>,
    animationProgress: Float,
    glassColors: com.tasktracker.presentation.theme.GlassColors
) {
    val center = Offset(size.width / 2, size.height / 2)
    val radius = minOf(size.width, size.height) / 3
    val totalTasks = data.sumOf { it.tasksCompleted }.toFloat()
    
    if (totalTasks == 0f) return
    
    var startAngle = -90f
    val colors = listOf(
        Color(0xFF2196F3),
        Color(0xFF4CAF50),
        Color(0xFFFF9800),
        Color(0xFF9C27B0),
        Color(0xFFF44336),
        Color(0xFF00BCD4),
        Color(0xFF8BC34A)
    )
    
    data.forEachIndexed { index, stat ->
        val sweepAngle = (stat.tasksCompleted / totalTasks) * 360f * animationProgress
        
        drawArc(
            color = colors[index % colors.size],
            startAngle = startAngle,
            sweepAngle = sweepAngle,
            useCenter = false,
            style = Stroke(width = 12.dp.toPx(), cap = StrokeCap.Round),
            topLeft = Offset(center.x - radius, center.y - radius),
            size = Size(radius * 2, radius * 2)
        )
        
        startAngle += sweepAngle
    }
}

private fun DrawScope.drawWeeklyBars(
    data: List<DailyStats>,
    animationProgress: Float,
    glassColors: com.tasktracker.presentation.theme.GlassColors
) {
    if (data.isEmpty()) return
    
    val maxValue = data.maxOfOrNull { it.tasksCompleted }?.toFloat() ?: 1f
    val barWidth = size.width / data.size * 0.6f
    val spacing = size.width / data.size * 0.4f
    
    data.forEachIndexed { index, stat ->
        val barHeight = (stat.tasksCompleted / maxValue) * size.height * animationProgress
        val x = index * (barWidth + spacing) + spacing / 2
        
        drawRoundRect(
            brush = Brush.verticalGradient(
                colors = listOf(
                    Color(0xFF4CAF50).copy(alpha = 0.8f),
                    Color(0xFF4CAF50).copy(alpha = 0.4f)
                )
            ),
            topLeft = Offset(x, size.height - barHeight),
            size = Size(barWidth, barHeight),
            cornerRadius = androidx.compose.ui.geometry.CornerRadius(8.dp.toPx())
        )
    }
}

private fun getInsightIcon(insightType: String): String {
    return when (insightType) {
        "PEAK_HOURS" -> "⏰"
        "COMPLETION_PATTERN" -> "📊"
        "STREAK_OPPORTUNITY" -> "🔥"
        "FOCUS_IMPROVEMENT" -> "🎯"
        "TASK_BREAKDOWN" -> "📝"
        "PRODUCTIVITY_DECLINE" -> "📉"
        "ACHIEVEMENT_CELEBRATION" -> "🎉"
        "HABIT_FORMATION" -> "🔄"
        else -> "💡"
    }
}