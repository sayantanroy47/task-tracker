package com.tasktracker.presentation.profile

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
import androidx.compose.material.icons.filled.Edit
import androidx.compose.material.icons.filled.Person
import androidx.compose.material.icons.filled.Settings
import androidx.compose.material.icons.filled.TrendingUp
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
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
import androidx.compose.ui.unit.sp
import androidx.hilt.navigation.compose.hiltViewModel
import com.tasktracker.domain.model.ProductivityLevel
import com.tasktracker.presentation.components.glassmorphism.GlassButton
import com.tasktracker.presentation.components.glassmorphism.GlassCard
import com.tasktracker.presentation.theme.adaptiveGlassColors

/**
 * Profile screen with glassmorphism design
 */
@Composable
fun ProfileScreen(
    modifier: Modifier = Modifier,
    viewModel: ProfileViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()
    val glassColors = adaptiveGlassColors()
    var showSettings by remember { mutableStateOf(false) }
    
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
            // Profile Header
            item {
                ProfileHeader(
                    profile = uiState.profile,
                    onEditProfile = { /* Handle edit */ },
                    onShowSettings = { showSettings = true }
                )
            }
            
            // Productivity Level Card
            item {
                uiState.profile?.let { profile ->
                    ProductivityLevelCard(
                        level = profile.getProductivityLevel(),
                        statistics = profile.statistics,
                        onViewDetails = { /* Handle view details */ }
                    )
                }
            }
            
            // Quick Stats
            item {
                uiState.profile?.let { profile ->
                    QuickStatsCard(
                        statistics = profile.statistics
                    )
                }
            }
            
            // Personal Insights
            if (uiState.personalInsights.isNotEmpty()) {
                item {
                    PersonalInsightsSection(
                        insights = uiState.personalInsights,
                        onInsightClick = { insight ->
                            viewModel.markInsightAsRead(insight.id)
                        },
                        onDismissInsight = { insightId ->
                            viewModel.dismissInsight(insightId)
                        }
                    )
                }
            }
            
            // Custom Goals
            if (uiState.customGoals.isNotEmpty()) {
                item {
                    CustomGoalsSection(
                        goals = uiState.customGoals,
                        onGoalClick = { /* Handle goal click */ },
                        onAddGoal = { /* Handle add goal */ }
                    )
                }
            }
            
            // Achievement Showcase
            if (uiState.recentAchievements.isNotEmpty()) {
                item {
                    AchievementShowcase(
                        achievements = uiState.recentAchievements
                    )
                }
            }
            
            // Profile Customization
            item {
                ProfileCustomizationCard(
                    customizations = uiState.profile?.customizations,
                    onCustomizationChange = { customizations ->
                        viewModel.updateCustomizations(customizations)
                    }
                )
            }
        }
        
        // Settings Overlay
        AnimatedVisibility(
            visible = showSettings,
            enter = fadeIn() + slideInVertically(),
            exit = fadeOut() + slideOutVertically(),
            modifier = Modifier.align(Alignment.Center)
        ) {
            ProfileSettingsOverlay(
                preferences = uiState.profile?.preferences,
                onPreferencesChange = { preferences ->
                    viewModel.updatePreferences(preferences)
                },
                onDismiss = { showSettings = false }
            )
        }
    }
}

/**
 * Profile header with avatar and basic info
 */
@Composable
private fun ProfileHeader(
    profile: com.tasktracker.domain.model.UserProfile?,
    onEditProfile: () -> Unit,
    onShowSettings: () -> Unit,
    modifier: Modifier = Modifier
) {
    val glassColors = adaptiveGlassColors()
    
    GlassCard(
        modifier = modifier.fillMaxWidth()
    ) {
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Row(
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(16.dp)
            ) {
                // Avatar
                Box(
                    modifier = Modifier
                        .size(64.dp)
                        .background(
                            color = MaterialTheme.colorScheme.primary.copy(alpha = 0.1f),
                            shape = CircleShape
                        ),
                    contentAlignment = Alignment.Center
                ) {
                    Text(
                        text = profile?.customizations?.avatarEmoji ?: "😊",
                        fontSize = 32.sp
                    )
                }
                
                Column {
                    Text(
                        text = "Your Profile",
                        style = MaterialTheme.typography.titleLarge,
                        fontWeight = FontWeight.Bold,
                        color = glassColors.onSurface
                    )
                    
                    Text(
                        text = "Member since ${formatDate(profile?.createdAt)}",
                        style = MaterialTheme.typography.bodyMedium,
                        color = glassColors.onSurface.copy(alpha = 0.7f)
                    )
                }
            }
            
            Row(
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                GlassButton(
                    onClick = onEditProfile,
                    modifier = Modifier.size(40.dp)
                ) {
                    Icon(
                        imageVector = Icons.Default.Edit,
                        contentDescription = "Edit Profile",
                        modifier = Modifier.size(20.dp)
                    )
                }
                
                GlassButton(
                    onClick = onShowSettings,
                    modifier = Modifier.size(40.dp)
                ) {
                    Icon(
                        imageVector = Icons.Default.Settings,
                        contentDescription = "Settings",
                        modifier = Modifier.size(20.dp)
                    )
                }
            }
        }
    }
}

/**
 * Productivity level card with progress
 */
@Composable
private fun ProductivityLevelCard(
    level: ProductivityLevel,
    statistics: com.tasktracker.domain.model.UserStatistics,
    onViewDetails: () -> Unit,
    modifier: Modifier = Modifier
) {
    val glassColors = adaptiveGlassColors()
    val levelColor = Color(android.graphics.Color.parseColor(level.color))
    val currentScore = statistics.getOverallProductivityScore()
    val progressToNext = level.getProgressToNext(currentScore)
    
    GlassCard(
        modifier = modifier.fillMaxWidth(),
        onClick = onViewDetails
    ) {
        Column {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Column(modifier = Modifier.weight(1f)) {
                    Text(
                        text = "🏆 ${level.displayName}",
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.SemiBold,
                        color = levelColor
                    )
                    Text(
                        text = level.description,
                        style = MaterialTheme.typography.bodySmall,
                        color = glassColors.onSurface.copy(alpha = 0.7f)
                    )
                }
                
                Text(
                    text = "${(currentScore * 100).toInt()}%",
                    style = MaterialTheme.typography.headlineSmall,
                    fontWeight = FontWeight.Bold,
                    color = levelColor
                )
            }
            
            Spacer(modifier = Modifier.height(12.dp))
            
            // Progress to next level
            level.getNextLevel()?.let { nextLevel ->
                Column {
                    Text(
                        text = "Progress to ${nextLevel.displayName}",
                        style = MaterialTheme.typography.bodySmall,
                        color = glassColors.onSurface.copy(alpha = 0.7f)
                    )
                    
                    Spacer(modifier = Modifier.height(4.dp))
                    
                    LinearProgressIndicator(
                        progress = progressToNext,
                        color = levelColor,
                        modifier = Modifier.fillMaxWidth()
                    )
                }
            }
        }
    }
}

/**
 * Quick statistics overview
 */
@Composable
private fun QuickStatsCard(
    statistics: com.tasktracker.domain.model.UserStatistics,
    modifier: Modifier = Modifier
) {
    val glassColors = adaptiveGlassColors()
    
    GlassCard(
        modifier = modifier.fillMaxWidth()
    ) {
        Column {
            Text(
                text = "📊 Quick Stats",
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.SemiBold,
                color = glassColors.onSurface
            )
            
            Spacer(modifier = Modifier.height(16.dp))
            
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceEvenly
            ) {
                StatItem(
                    value = statistics.totalTasksCompleted.toString(),
                    label = "Tasks Done",
                    icon = "✅"
                )
                
                StatItem(
                    value = "${(statistics.averageCompletionRate * 100).toInt()}%",
                    label = "Success Rate",
                    icon = "🎯"
                )
                
                StatItem(
                    value = "${statistics.currentStreak}d",
                    label = "Current Streak",
                    icon = "🔥"
                )
            }
            
            Spacer(modifier = Modifier.height(12.dp))
            
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceEvenly
            ) {
                StatItem(
                    value = formatDuration(statistics.totalFocusTime),
                    label = "Focus Time",
                    icon = "⏱️"
                )
                
                StatItem(
                    value = "${statistics.averageDailyTasks.toInt()}",
                    label = "Daily Avg",
                    icon = "📈"
                )
                
                StatItem(
                    value = "${(statistics.consistencyScore * 100).toInt()}%",
                    label = "Consistency",
                    icon = "📊"
                )
            }
        }
    }
}

/**
 * Individual stat item
 */
@Composable
private fun StatItem(
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
            fontSize = 20.sp
        )
        
        Spacer(modifier = Modifier.height(4.dp))
        
        Text(
            text = value,
            style = MaterialTheme.typography.titleSmall,
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
 * Personal insights section
 */
@Composable
private fun PersonalInsightsSection(
    insights: List<com.tasktracker.domain.model.PersonalInsight>,
    onInsightClick: (com.tasktracker.domain.model.PersonalInsight) -> Unit,
    onDismissInsight: (String) -> Unit,
    modifier: Modifier = Modifier
) {
    val glassColors = adaptiveGlassColors()
    
    Column(
        modifier = modifier
    ) {
        Text(
            text = "💡 Personal Insights",
            style = MaterialTheme.typography.titleMedium,
            fontWeight = FontWeight.SemiBold,
            color = glassColors.onSurface
        )
        
        Spacer(modifier = Modifier.height(12.dp))
        
        insights.take(3).forEach { insight ->
            PersonalInsightCard(
                insight = insight,
                onClick = { onInsightClick(insight) },
                onDismiss = { onDismissInsight(insight.id) }
            )
            
            if (insight != insights.last()) {
                Spacer(modifier = Modifier.height(8.dp))
            }
        }
    }
}

/**
 * Individual personal insight card
 */
@Composable
private fun PersonalInsightCard(
    insight: com.tasktracker.domain.model.PersonalInsight,
    onClick: () -> Unit,
    onDismiss: () -> Unit,
    modifier: Modifier = Modifier
) {
    val glassColors = adaptiveGlassColors()
    
    GlassCard(
        modifier = modifier.fillMaxWidth(),
        onClick = onClick
    ) {
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween
        ) {
            Column(modifier = Modifier.weight(1f)) {
                Text(
                    text = insight.title,
                    style = MaterialTheme.typography.bodyMedium,
                    fontWeight = FontWeight.Medium,
                    color = glassColors.onSurface
                )
                
                Text(
                    text = insight.description,
                    style = MaterialTheme.typography.bodySmall,
                    color = glassColors.onSurface.copy(alpha = 0.7f)
                )
                
                if (insight.recommendation.isNotEmpty()) {
                    Spacer(modifier = Modifier.height(4.dp))
                    Text(
                        text = "💡 ${insight.recommendation}",
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
                        color = MaterialTheme.colorScheme.primary.copy(alpha = insight.confidence),
                        shape = CircleShape
                    )
            )
        }
    }
}

/**
 * Custom goals section
 */
@Composable
private fun CustomGoalsSection(
    goals: List<com.tasktracker.domain.model.CustomGoal>,
    onGoalClick: (com.tasktracker.domain.model.CustomGoal) -> Unit,
    onAddGoal: () -> Unit,
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
                Text(
                    text = "🎯 Your Goals",
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.SemiBold,
                    color = glassColors.onSurface
                )
                
                GlassButton(
                    onClick = onAddGoal
                ) {
                    Text("Add Goal")
                }
            }
            
            Spacer(modifier = Modifier.height(12.dp))
            
            goals.take(3).forEach { goal ->
                CustomGoalItem(
                    goal = goal,
                    onClick = { onGoalClick(goal) }
                )
                
                if (goal != goals.last()) {
                    Spacer(modifier = Modifier.height(8.dp))
                }
            }
        }
    }
}

/**
 * Individual custom goal item
 */
@Composable
private fun CustomGoalItem(
    goal: com.tasktracker.domain.model.CustomGoal,
    onClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    val glassColors = adaptiveGlassColors()
    val progress = goal.getProgress()
    
    Column(
        modifier = modifier
            .fillMaxWidth()
            .padding(vertical = 4.dp)
    ) {
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Text(
                text = goal.title,
                style = MaterialTheme.typography.bodyMedium,
                fontWeight = FontWeight.Medium,
                color = glassColors.onSurface
            )
            
            Text(
                text = "${(progress * 100).toInt()}%",
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.primary,
                fontWeight = FontWeight.SemiBold
            )
        }
        
        Spacer(modifier = Modifier.height(4.dp))
        
        LinearProgressIndicator(
            progress = progress,
            color = MaterialTheme.colorScheme.primary,
            modifier = Modifier.fillMaxWidth()
        )
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
                AchievementItem(achievement = achievement)
                
                if (achievement != achievements.last()) {
                    Spacer(modifier = Modifier.height(8.dp))
                }
            }
        }
    }
}

/**
 * Individual achievement item
 */
@Composable
private fun AchievementItem(
    achievement: com.tasktracker.domain.model.Achievement,
    modifier: Modifier = Modifier
) {
    val glassColors = adaptiveGlassColors()
    
    Row(
        modifier = modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.spacedBy(12.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Text(
            text = "🎉",
            fontSize = 20.sp
        )
        
        Column(modifier = Modifier.weight(1f)) {
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
}

/**
 * Profile customization card
 */
@Composable
private fun ProfileCustomizationCard(
    customizations: com.tasktracker.domain.model.ProfileCustomizations?,
    onCustomizationChange: (com.tasktracker.domain.model.ProfileCustomizations) -> Unit,
    modifier: Modifier = Modifier
) {
    val glassColors = adaptiveGlassColors()
    
    GlassCard(
        modifier = modifier.fillMaxWidth()
    ) {
        Column {
            Text(
                text = "🎨 Customization",
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.SemiBold,
                color = glassColors.onSurface
            )
            
            Spacer(modifier = Modifier.height(12.dp))
            
            // Avatar selection
            Text(
                text = "Avatar",
                style = MaterialTheme.typography.bodyMedium,
                fontWeight = FontWeight.Medium,
                color = glassColors.onSurface
            )
            
            Spacer(modifier = Modifier.height(8.dp))
            
            Row(
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                val avatarOptions = listOf("😊", "🚀", "🎯", "⭐", "🔥", "💎")
                avatarOptions.forEach { emoji ->
                    AvatarOption(
                        emoji = emoji,
                        isSelected = customizations?.avatarEmoji == emoji,
                        onClick = {
                            customizations?.let { current ->
                                onCustomizationChange(current.copy(avatarEmoji = emoji))
                            }
                        }
                    )
                }
            }
        }
    }
}

/**
 * Avatar selection option
 */
@Composable
private fun AvatarOption(
    emoji: String,
    isSelected: Boolean,
    onClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    Box(
        modifier = modifier
            .size(40.dp)
            .background(
                color = if (isSelected) {
                    MaterialTheme.colorScheme.primary.copy(alpha = 0.2f)
                } else {
                    Color.Transparent
                },
                shape = CircleShape
            )
            .padding(8.dp),
        contentAlignment = Alignment.Center
    ) {
        Text(
            text = emoji,
            fontSize = 20.sp
        )
    }
}

/**
 * Settings overlay
 */
@Composable
private fun ProfileSettingsOverlay(
    preferences: com.tasktracker.domain.model.UserPreferences?,
    onPreferencesChange: (com.tasktracker.domain.model.UserPreferences) -> Unit,
    onDismiss: () -> Unit,
    modifier: Modifier = Modifier
) {
    GlassCard(
        modifier = modifier.padding(32.dp)
    ) {
        Column {
            Text(
                text = "⚙️ Settings",
                style = MaterialTheme.typography.titleLarge,
                fontWeight = FontWeight.Bold
            )
            
            Spacer(modifier = Modifier.height(16.dp))
            
            // Settings content would go here
            Text(
                text = "Settings panel coming soon...",
                style = MaterialTheme.typography.bodyMedium
            )
            
            Spacer(modifier = Modifier.height(16.dp))
            
            GlassButton(
                onClick = onDismiss,
                modifier = Modifier.fillMaxWidth()
            ) {
                Text("Close")
            }
        }
    }
}

/**
 * Linear progress indicator
 */
@Composable
private fun LinearProgressIndicator(
    progress: Float,
    color: Color,
    modifier: Modifier = Modifier
) {
    Box(
        modifier = modifier
            .height(4.dp)
            .background(
                color = color.copy(alpha = 0.2f),
                shape = androidx.compose.foundation.shape.RoundedCornerShape(2.dp)
            )
    ) {
        Box(
            modifier = Modifier
                .fillMaxWidth(progress)
                .height(4.dp)
                .background(
                    color = color,
                    shape = androidx.compose.foundation.shape.RoundedCornerShape(2.dp)
                )
        )
    }
}

// Helper functions
private fun formatDate(instant: java.time.Instant?): String {
    return instant?.let {
        val formatter = java.time.format.DateTimeFormatter.ofPattern("MMM yyyy")
        it.atZone(java.time.ZoneId.systemDefault()).format(formatter)
    } ?: "Unknown"
}

private fun formatDuration(duration: java.time.Duration): String {
    val hours = duration.toHours()
    val minutes = duration.toMinutes() % 60
    
    return when {
        hours > 0 -> "${hours}h ${minutes}m"
        minutes > 0 -> "${minutes}m"
        else -> "${duration.seconds}s"
    }
}