package com.tasktracker.presentation.analytics

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.core.Spring
import androidx.compose.animation.core.spring
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.slideInVertically
import androidx.compose.animation.slideOutVertically
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Analytics
import androidx.compose.material.icons.filled.EmojiEvents
import androidx.compose.material.icons.filled.Insights
import androidx.compose.material.icons.filled.TrendingUp
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import com.tasktracker.presentation.components.analytics.ChartType
import com.tasktracker.presentation.components.analytics.InsightsCard
import com.tasktracker.presentation.components.analytics.ProductivityChart
import com.tasktracker.presentation.components.analytics.StreakDisplay
import com.tasktracker.presentation.components.analytics.WeeklyTrendChart
import com.tasktracker.presentation.components.glassmorphism.GlassCard
import com.tasktracker.presentation.theme.adaptiveGlassColors
import kotlinx.coroutines.delay

/**
 * Analytics dashboard screen with glassmorphism design
 */
@Composable
fun AnalyticsScreen(
    modifier: Modifier = Modifier,
    viewModel: AnalyticsViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()
    val glassColors = adaptiveGlassColors()
    var showCelebration by remember { mutableStateOf(false) }
    
    // Trigger celebration animation for achievements
    LaunchedEffect(uiState.newAchievements) {
        if (uiState.newAchievements.isNotEmpty()) {
            showCelebration = true
            delay(3000)
            showCelebration = false
        }
    }
    
    Box(
        modifier = modifier
            .fillMaxSize()
            .background(
                brush = Brush.verticalGradient(
                    colors = listOf(
                        MaterialTheme.colorScheme.background,
                        MaterialTheme.colorScheme.background.copy(alpha = 0.8f)
                    )
                )
            )
    ) {
        LazyColumn(
            modifier = Modifier.fillMaxSize(),
            contentPadding = PaddingValues(16.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            // Header
            item {
                AnalyticsHeader(
                    totalTasksCompleted = uiState.productivityMetrics?.totalTasksCompleted ?: 0,
                    currentStreak = uiState.productivityMetrics?.currentStreak ?: 0
                )
            }
            
            // Streak Display
            item {
                AnimatedVisibility(
                    visible = true,
                    enter = slideInVertically(
                        animationSpec = spring(
                            dampingRatio = Spring.DampingRatioMediumBouncy,
                            stiffness = Spring.StiffnessLow
                        )
                    ) + fadeIn()
                ) {
                    StreakDisplay(
                        currentStreak = uiState.productivityMetrics?.currentStreak ?: 0,
                        longestStreak = uiState.productivityMetrics?.longestStreak ?: 0,
                        modifier = Modifier.fillMaxWidth()
                    )
                }
            }
            
            // Weekly Progress Chart
            item {
                AnimatedVisibility(
                    visible = uiState.weeklyTrend.isNotEmpty(),
                    enter = slideInVertically(
                        animationSpec = spring(
                            dampingRatio = Spring.DampingRatioMediumBouncy,
                            stiffness = Spring.StiffnessLow
                        ),
                        initialOffsetY = { it / 2 }
                    ) + fadeIn()
                ) {
                    ProductivityChart(
                        data = uiState.weeklyTrend,
                        chartType = ChartType.AREA,
                        modifier = Modifier.fillMaxWidth()
                    )
                }
            }
            
            // Weekly Summary
            item {
                AnimatedVisibility(
                    visible = uiState.weeklyTrend.isNotEmpty(),
                    enter = slideInVertically(
                        animationSpec = spring(
                            dampingRatio = Spring.DampingRatioMediumBouncy,
                            stiffness = Spring.StiffnessLow
                        ),
                        initialOffsetY = { it / 3 }
                    ) + fadeIn()
                ) {
                    WeeklyTrendChart(
                        weeklyData = uiState.weeklyTrend,
                        modifier = Modifier.fillMaxWidth()
                    )
                }
            }
            
            // Productivity Insights
            item {
                if (uiState.insights.isNotEmpty()) {
                    InsightsSection(
                        insights = uiState.insights,
                        onInsightDismiss = { insightId ->
                            viewModel.markInsightAsRead(insightId)
                        }
                    )
                }
            }
            
            // Analytics Summary Cards
            item {
                AnalyticsSummaryCards(
                    completionRate = uiState.productivityMetrics?.completionRate ?: 0f,
                    averageDailyTasks = uiState.productivityMetrics?.averageDailyTasks ?: 0f,
                    peakHours = uiState.productivityMetrics?.peakProductivityHours ?: emptyList()
                )
            }
            
            // Achievement Showcase
            item {
                if (uiState.recentAchievements.isNotEmpty()) {
                    AchievementShowcase(
                        achievements = uiState.recentAchievements
                    )
                }
            }
        }
        
        // Celebration overlay for new achievements
        AnimatedVisibility(
            visible = showCelebration,
            enter = fadeIn() + slideInVertically(),
            exit = fadeOut() + slideOutVertically(),
            modifier = Modifier.align(Alignment.Center)
        ) {
            CelebrationOverlay(
                achievements = uiState.newAchievements
            )
        }
    }
}

/**
 * Analytics header with key metrics
 */
@Composable
private fun AnalyticsHeader(
    totalTasksCompleted: Int,
    currentStreak: Int,
    modifier: Modifier = Modifier
) {
    val glassColors = adaptiveGlassColors()
    
    GlassCard(
        modifier = modifier.fillMaxWidth()
    ) {
        Column {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Column {
                    Text(
                        text = "Your Analytics",
                        style = MaterialTheme.typography.headlineMedium,
                        fontWeight = FontWeight.Bold,
                        color = glassColors.onSurface
                    )
                    Text(
                        text = "Track your productivity journey",
                        style = MaterialTheme.typography.bodyMedium,
                        color = glassColors.onSurface.copy(alpha = 0.7f)
                    )
                }
                
                Box(
                    modifier = Modifier
                        .size(48.dp)
                        .background(
                            color = MaterialTheme.colorScheme.primary.copy(alpha = 0.1f),
                            shape = CircleShape
                        ),
                    contentAlignment = Alignment.Center
                ) {
                    Icon(
                        imageVector = Icons.Default.Analytics,
                        contentDescription = null,
                        modifier = Modifier.size(24.dp),
                        tint = MaterialTheme.colorScheme.primary
                    )
                }
            }
            
            Spacer(modifier = Modifier.height(16.dp))
            
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceEvenly
            ) {
                MetricCard(
                    value = totalTasksCompleted.toString(),
                    label = "Tasks Completed",
                    icon = Icons.Default.EmojiEvents,
                    color = Color(0xFF4CAF50)
                )
                
                MetricCard(
                    value = "${currentStreak}d",
                    label = "Current Streak",
                    icon = Icons.Default.TrendingUp,
                    color = Color(0xFFFF9800)
                )
            }
        }
    }
}

/**
 * Individual metric card
 */
@Composable
private fun MetricCard(
    value: String,
    label: String,
    icon: androidx.compose.ui.graphics.vector.ImageVector,
    color: Color,
    modifier: Modifier = Modifier
) {
    val glassColors = adaptiveGlassColors()
    
    Column(
        modifier = modifier,
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Box(
            modifier = Modifier
                .size(40.dp)
                .background(
                    color = color.copy(alpha = 0.1f),
                    shape = CircleShape
                ),
            contentAlignment = Alignment.Center
        ) {
            Icon(
                imageVector = icon,
                contentDescription = null,
                modifier = Modifier.size(20.dp),
                tint = color
            )
        }
        
        Spacer(modifier = Modifier.height(8.dp))
        
        Text(
            text = value,
            style = MaterialTheme.typography.titleLarge,
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
 * Insights section with animated cards
 */
@Composable
private fun InsightsSection(
    insights: List<com.tasktracker.domain.model.ProductivityInsight>,
    onInsightDismiss: (String) -> Unit,
    modifier: Modifier = Modifier
) {
    val glassColors = adaptiveGlassColors()
    
    Column(
        modifier = modifier
    ) {
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Text(
                text = "💡 Insights",
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.SemiBold,
                color = glassColors.onSurface
            )
            
            Icon(
                imageVector = Icons.Default.Insights,
                contentDescription = null,
                modifier = Modifier.size(20.dp),
                tint = MaterialTheme.colorScheme.primary
            )
        }
        
        Spacer(modifier = Modifier.height(12.dp))
        
        insights.forEach { insight ->
            InsightsCard(
                insight = insight,
                modifier = Modifier.fillMaxWidth(),
                onDismiss = { onInsightDismiss(insight.id) }
            )
            
            Spacer(modifier = Modifier.height(8.dp))
        }
    }
}

/**
 * Analytics summary cards
 */
@Composable
private fun AnalyticsSummaryCards(
    completionRate: Float,
    averageDailyTasks: Float,
    peakHours: List<Int>,
    modifier: Modifier = Modifier
) {
    val glassColors = adaptiveGlassColors()
    
    Column(
        modifier = modifier,
        verticalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        Text(
            text = "📊 Summary",
            style = MaterialTheme.typography.titleMedium,
            fontWeight = FontWeight.SemiBold,
            color = glassColors.onSurface
        )
        
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            GlassCard(
                modifier = Modifier.weight(1f)
            ) {
                Column(
                    horizontalAlignment = Alignment.CenterHorizontally
                ) {
                    Text(
                        text = "${(completionRate * 100).toInt()}%",
                        style = MaterialTheme.typography.titleLarge,
                        fontWeight = FontWeight.Bold,
                        color = MaterialTheme.colorScheme.primary
                    )
                    Text(
                        text = "Completion Rate",
                        style = MaterialTheme.typography.bodySmall,
                        color = glassColors.onSurface.copy(alpha = 0.7f)
                    )
                }
            }
            
            GlassCard(
                modifier = Modifier.weight(1f)
            ) {
                Column(
                    horizontalAlignment = Alignment.CenterHorizontally
                ) {
                    Text(
                        text = "${averageDailyTasks.toInt()}",
                        style = MaterialTheme.typography.titleLarge,
                        fontWeight = FontWeight.Bold,
                        color = Color(0xFF4CAF50)
                    )
                    Text(
                        text = "Daily Average",
                        style = MaterialTheme.typography.bodySmall,
                        color = glassColors.onSurface.copy(alpha = 0.7f)
                    )
                }
            }
        }
        
        if (peakHours.isNotEmpty()) {
            GlassCard(
                modifier = Modifier.fillMaxWidth()
            ) {
                Column {
                    Text(
                        text = "⏰ Peak Hours",
                        style = MaterialTheme.typography.titleSmall,
                        fontWeight = FontWeight.SemiBold,
                        color = glassColors.onSurface
                    )
                    Spacer(modifier = Modifier.height(8.dp))
                    Text(
                        text = peakHours.joinToString(", ") { "${it}:00" },
                        style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.primary,
                        fontWeight = FontWeight.Medium
                    )
                }
            }
        }
    }
}

/**
 * Achievement showcase
 */
@Composable
private fun AchievementShowcase(
    achievements: List<com.tasktracker.domain.model.Achievement>,
    modifier: Modifier = Modifier
) {
    val glassColors = adaptiveGlassColors()
    
    GlassCard(
        modifier = modifier.fillMaxWidth()
    ) {
        Column {
            Text(
                text = "🏆 Recent Achievements",
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.SemiBold,
                color = glassColors.onSurface
            )
            
            Spacer(modifier = Modifier.height(12.dp))
            
            achievements.take(3).forEach { achievement ->
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(12.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text(
                        text = "🎉",
                        style = MaterialTheme.typography.titleMedium
                    )
                    
                    Column(
                        modifier = Modifier.weight(1f)
                    ) {
                        Text(
                            text = achievement.title,
                            style = MaterialTheme.typography.bodyMedium,
                            fontWeight = FontWeight.Medium,
                            color = glassColors.onSurface
                        )
                        Text(
                            text = achievement.description,
                            style = MaterialTheme.typography.bodySmall,
                            color = glassColors.onSurface.copy(alpha = 0.7f)
                        )
                    }
                }
                
                if (achievement != achievements.last()) {
                    Spacer(modifier = Modifier.height(8.dp))
                }
            }
        }
    }
}

/**
 * Celebration overlay for new achievements
 */
@Composable
private fun CelebrationOverlay(
    achievements: List<com.tasktracker.domain.model.Achievement>,
    modifier: Modifier = Modifier
) {
    GlassCard(
        modifier = modifier.padding(32.dp),
        transparency = 0.2f
    ) {
        Column(
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Text(
                text = "🎉",
                style = MaterialTheme.typography.displayMedium
            )
            
            Spacer(modifier = Modifier.height(16.dp))
            
            Text(
                text = "Achievement Unlocked!",
                style = MaterialTheme.typography.titleLarge,
                fontWeight = FontWeight.Bold,
                color = MaterialTheme.colorScheme.primary
            )
            
            Spacer(modifier = Modifier.height(8.dp))
            
            achievements.firstOrNull()?.let { achievement ->
                Text(
                    text = achievement.title,
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.SemiBold
                )
                
                Text(
                    text = achievement.description,
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.8f)
                )
            }
        }
    }
}