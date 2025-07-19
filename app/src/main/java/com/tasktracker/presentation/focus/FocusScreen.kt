package com.tasktracker.presentation.focus

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
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.MaterialTheme
import androidx.compose.ui.unit.sp
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
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import com.tasktracker.domain.model.FocusMode
import com.tasktracker.domain.model.FocusSessionState
import com.tasktracker.presentation.components.focus.FocusModeToggle
import com.tasktracker.presentation.components.focus.FocusSessionSummary
import com.tasktracker.presentation.components.focus.FocusSettingsPanel
import com.tasktracker.presentation.components.focus.FocusTimer
import com.tasktracker.presentation.components.TaskItemComponent
import kotlinx.coroutines.delay
import java.time.Duration

/**
 * Focus mode screen with session management and task filtering
 */
@Composable
fun FocusScreen(
    modifier: Modifier = Modifier,
    viewModel: FocusModeViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()
    var selectedMode by remember { mutableStateOf(uiState.focusSettings.defaultMode) }
    var showSettings by remember { mutableStateOf(false) }
    var showSessionSummary by remember { mutableStateOf(false) }
    
    // Show session summary when session completes
    LaunchedEffect(uiState.sessionState) {
        if (uiState.sessionState == FocusSessionState.COMPLETED) {
            delay(1000) // Brief delay for completion animation
            showSessionSummary = true
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
            // Focus Mode Toggle
            item {
                FocusModeToggle(
                    isActive = uiState.isSessionActive || uiState.isSessionPaused,
                    currentMode = uiState.currentSession?.mode ?: selectedMode,
                    onToggle = { shouldStart ->
                        if (shouldStart) {
                            viewModel.startFocusSession(selectedMode)
                        }
                    },
                    onModeChange = { mode ->
                        selectedMode = mode
                    }
                )
            }
            
            // Focus Timer (when session is active)
            item {
                AnimatedVisibility(
                    visible = uiState.sessionState != FocusSessionState.INACTIVE,
                    enter = slideInVertically(
                        animationSpec = spring(
                            dampingRatio = Spring.DampingRatioMediumBouncy,
                            stiffness = Spring.StiffnessLow
                        )
                    ) + fadeIn(),
                    exit = slideOutVertically() + fadeOut()
                ) {
                    FocusTimer(
                        session = uiState.currentSession,
                        remainingTime = uiState.remainingTime,
                        elapsedTime = uiState.elapsedTime,
                        onPause = { viewModel.pauseFocusSession() },
                        onResume = { viewModel.resumeFocusSession() },
                        onStop = { viewModel.cancelFocusSession() }
                    )
                }
            }
            
            // Break Timer (when on break)
            item {
                AnimatedVisibility(
                    visible = uiState.isOnBreak,
                    enter = slideInVertically() + fadeIn(),
                    exit = slideOutVertically() + fadeOut()
                ) {
                    BreakTimer(
                        remainingTime = uiState.breakTimeRemaining,
                        onEndBreak = { viewModel.endBreak() }
                    )
                }
            }
            
            // Filtered Tasks (during focus session)
            if (uiState.isSessionActive && uiState.filteredTasks.isNotEmpty()) {
                item {
                    FocusTasksSection(
                        tasks = uiState.filteredTasks,
                        focusMode = uiState.currentSession?.mode,
                        onTaskComplete = { taskId ->
                            // Handle task completion during focus session
                            // This would typically call a task repository method
                        },
                        onDistractionRecorded = {
                            viewModel.recordDistraction()
                        }
                    )
                }
            }
            
            // Focus Settings (when not in session)
            if (uiState.sessionState == FocusSessionState.INACTIVE) {
                item {
                    FocusSettingsPanel(
                        settings = uiState.focusSettings,
                        onSettingsChange = { settings ->
                            viewModel.updateFocusSettings(settings)
                        }
                    )
                }
            }
            
            // Focus Statistics
            if (uiState.focusStats.totalSessions > 0) {
                item {
                    FocusStatsCard(
                        stats = uiState.focusStats
                    )
                }
            }
        }
        
        // Session Summary Overlay
        AnimatedVisibility(
            visible = showSessionSummary && uiState.currentSession != null,
            enter = fadeIn() + slideInVertically(),
            exit = fadeOut() + slideOutVertically(),
            modifier = Modifier
                .align(Alignment.Center)
                .padding(32.dp)
        ) {
            uiState.currentSession?.let { session ->
                FocusSessionSummary(
                    session = session,
                    onStartNewSession = {
                        showSessionSummary = false
                        viewModel.startFocusSession(session.mode)
                    },
                    onClose = {
                        showSessionSummary = false
                    }
                )
            }
        }
        
        // Completion Celebration
        AnimatedVisibility(
            visible = uiState.showCompletionCelebration,
            enter = fadeIn() + slideInVertically(),
            exit = fadeOut() + slideOutVertically(),
            modifier = Modifier.align(Alignment.Center)
        ) {
            CompletionCelebration()
        }
    }
}

/**
 * Break timer component
 */
@Composable
private fun BreakTimer(
    remainingTime: Duration,
    onEndBreak: () -> Unit,
    modifier: Modifier = Modifier
) {
    com.tasktracker.presentation.components.glassmorphism.GlassCard(
        modifier = modifier.fillMaxWidth()
    ) {
        Column(
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            androidx.compose.material3.Text(
                text = "☕ Break Time",
                style = MaterialTheme.typography.titleLarge,
                fontWeight = androidx.compose.ui.text.font.FontWeight.Bold
            )
            
            Spacer(modifier = Modifier.height(16.dp))
            
            androidx.compose.material3.Text(
                text = formatDuration(remainingTime),
                style = MaterialTheme.typography.headlineMedium,
                fontWeight = androidx.compose.ui.text.font.FontWeight.Bold,
                color = MaterialTheme.colorScheme.primary
            )
            
            Spacer(modifier = Modifier.height(16.dp))
            
            com.tasktracker.presentation.components.glassmorphism.GlassButton(
                onClick = onEndBreak
            ) {
                androidx.compose.material3.Text("End Break Early")
            }
        }
    }
}

/**
 * Focus tasks section with filtered task list
 */
@Composable
private fun FocusTasksSection(
    tasks: List<com.tasktracker.domain.model.Task>,
    focusMode: FocusMode?,
    onTaskComplete: (String) -> Unit,
    onDistractionRecorded: () -> Unit,
    modifier: Modifier = Modifier
) {
    val glassColors = com.tasktracker.presentation.theme.adaptiveGlassColors()
    
    com.tasktracker.presentation.components.glassmorphism.GlassCard(
        modifier = modifier.fillMaxWidth()
    ) {
        Column {
            androidx.compose.material3.Text(
                text = "🎯 Focus Tasks",
                style = MaterialTheme.typography.titleMedium,
                fontWeight = androidx.compose.ui.text.font.FontWeight.SemiBold,
                color = glassColors.onSurface
            )
            
            androidx.compose.material3.Text(
                text = "${tasks.size} tasks filtered for ${focusMode?.displayName ?: "focus"}",
                style = MaterialTheme.typography.bodySmall,
                color = glassColors.onSurface.copy(alpha = 0.7f)
            )
            
            Spacer(modifier = Modifier.height(12.dp))
            
            tasks.take(5).forEach { task -> // Limit to 5 tasks for focus
                TaskItemComponent(
                    task = task,
                    onTaskComplete = { onTaskComplete(task.id) },
                    modifier = Modifier.fillMaxWidth()
                )
                
                if (task != tasks.last()) {
                    Spacer(modifier = Modifier.height(8.dp))
                }
            }
            
            if (tasks.size > 5) {
                Spacer(modifier = Modifier.height(8.dp))
                androidx.compose.material3.Text(
                    text = "... and ${tasks.size - 5} more tasks",
                    style = MaterialTheme.typography.bodySmall,
                    color = glassColors.onSurface.copy(alpha = 0.5f)
                )
            }
        }
    }
}

/**
 * Focus statistics card
 */
@Composable
private fun FocusStatsCard(
    stats: com.tasktracker.domain.model.FocusStats,
    modifier: Modifier = Modifier
) {
    val glassColors = com.tasktracker.presentation.theme.adaptiveGlassColors()
    
    com.tasktracker.presentation.components.glassmorphism.GlassCard(
        modifier = modifier.fillMaxWidth()
    ) {
        Column {
            androidx.compose.material3.Text(
                text = "📈 Focus Statistics",
                style = MaterialTheme.typography.titleMedium,
                fontWeight = androidx.compose.ui.text.font.FontWeight.SemiBold,
                color = glassColors.onSurface
            )
            
            Spacer(modifier = Modifier.height(16.dp))
            
            androidx.compose.foundation.layout.Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceEvenly
            ) {
                FocusStatItem(
                    value = stats.totalSessions.toString(),
                    label = "Sessions",
                    icon = "🎯"
                )
                
                FocusStatItem(
                    value = "${(stats.getCompletionRate() * 100).toInt()}%",
                    label = "Success Rate",
                    icon = "✅"
                )
                
                FocusStatItem(
                    value = formatDuration(stats.averageSessionLength),
                    label = "Avg Length",
                    icon = "⏱️"
                )
            }
            
            Spacer(modifier = Modifier.height(12.dp))
            
            androidx.compose.foundation.layout.Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceEvenly
            ) {
                FocusStatItem(
                    value = stats.currentStreak.toString(),
                    label = "Current Streak",
                    icon = "🔥"
                )
                
                FocusStatItem(
                    value = "${(stats.averageFocusScore * 100).toInt()}%",
                    label = "Focus Score",
                    icon = "🎖️"
                )
                
                FocusStatItem(
                    value = formatDuration(stats.totalFocusTime),
                    label = "Total Time",
                    icon = "⏰"
                )
            }
        }
    }
}

/**
 * Individual focus stat item
 */
@Composable
private fun FocusStatItem(
    value: String,
    label: String,
    icon: String,
    modifier: Modifier = Modifier
) {
    val glassColors = com.tasktracker.presentation.theme.adaptiveGlassColors()
    
    Column(
        modifier = modifier,
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        androidx.compose.material3.Text(
            text = icon,
            fontSize = 20.sp
        )
        
        Spacer(modifier = Modifier.height(4.dp))
        
        androidx.compose.material3.Text(
            text = value,
            style = MaterialTheme.typography.titleSmall,
            fontWeight = androidx.compose.ui.text.font.FontWeight.Bold,
            color = glassColors.onSurface
        )
        
        androidx.compose.material3.Text(
            text = label,
            style = MaterialTheme.typography.bodySmall,
            color = glassColors.onSurface.copy(alpha = 0.7f)
        )
    }
}

/**
 * Completion celebration animation
 */
@Composable
private fun CompletionCelebration(
    modifier: Modifier = Modifier
) {
    com.tasktracker.presentation.components.glassmorphism.GlassCard(
        modifier = modifier.padding(32.dp)
    ) {
        Column(
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            androidx.compose.material3.Text(
                text = "🎉",
                fontSize = 48.sp
            )
            
            Spacer(modifier = Modifier.height(16.dp))
            
            androidx.compose.material3.Text(
                text = "Great Focus!",
                style = MaterialTheme.typography.headlineSmall,
                fontWeight = androidx.compose.ui.text.font.FontWeight.Bold
            )
            
            androidx.compose.material3.Text(
                text = "You completed your focus session",
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.8f)
            )
        }
    }
}

// Helper function
private fun formatDuration(duration: Duration): String {
    val hours = duration.toHours()
    val minutes = duration.toMinutes() % 60
    
    return when {
        hours > 0 -> "${hours}h ${minutes}m"
        minutes > 0 -> "${minutes}m"
        else -> "${duration.seconds}s"
    }
}