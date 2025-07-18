package com.tasktracker.presentation.main

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.tween
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
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Analytics
import androidx.compose.material.icons.filled.FitnessCenter
import androidx.compose.material.icons.filled.LocalFireDepartment
import androidx.compose.material.icons.filled.Person
import androidx.compose.material.icons.filled.PlayArrow
import androidx.compose.material.icons.filled.Stop
import androidx.compose.material.icons.filled.TrendingUp
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.derivedStateOf
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.hilt.navigation.compose.hiltViewModel
import com.tasktracker.presentation.analytics.AnalyticsViewModel
import com.tasktracker.presentation.components.CompletedTasksSection
import com.tasktracker.presentation.components.TaskInputComponent
import com.tasktracker.presentation.components.TaskListComponent
import com.tasktracker.presentation.components.UndoSnackbar
import com.tasktracker.presentation.components.glassmorphism.GlassCard
import com.tasktracker.presentation.components.glassmorphism.GlassButton
import com.tasktracker.presentation.focus.FocusModeViewModel
import com.tasktracker.presentation.theme.BlurredSurface
import com.tasktracker.presentation.theme.GlassmorphismTheme
import com.tasktracker.presentation.theme.TaskTrackerTheme
import com.tasktracker.presentation.theme.adaptiveGlassColors
import com.tasktracker.domain.model.FocusMode
import com.tasktracker.domain.model.Task
import java.time.LocalTime
import java.time.format.DateTimeFormatter

@Composable
fun MainScreen(
    highlightedTaskId: String? = null,
    viewModel: MainViewModel = hiltViewModel(),
    analyticsViewModel: AnalyticsViewModel = hiltViewModel(),
    focusViewModel: FocusModeViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()
    val analyticsState by analyticsViewModel.uiState.collectAsState()
    val focusState by focusViewModel.uiState.collectAsState()
    
    val listState = rememberLazyListState()
    val glassColors = adaptiveGlassColors()
    
    // Dynamic blur based on scroll position
    val scrollOffset by remember {
        derivedStateOf {
            listState.firstVisibleItemScrollOffset.toFloat()
        }
    }
    
    val headerBlurIntensity by animateFloatAsState(
        targetValue = (scrollOffset / 200f).coerceIn(0f, 1f),
        animationSpec = tween(durationMillis = 300),
        label = "header_blur"
    )
    
    GlassmorphismTheme {
        Box(
            modifier = Modifier
                .fillMaxSize()
                .background(
                    brush = Brush.verticalGradient(
                        colors = listOf(
                            glassColors.background.copy(alpha = 0.8f),
                            glassColors.background.copy(alpha = 0.95f)
                        )
                    )
                )
        ) {
            LazyColumn(
                state = listState,
                modifier = Modifier.fillMaxSize(),
                contentPadding = PaddingValues(horizontal = 16.dp, vertical = 8.dp),
                verticalArrangement = Arrangement.spacedBy(16.dp)
            ) {
                // Glassmorphism Header
                item {
                    GlassmorphismHeader(
                        blurIntensity = headerBlurIntensity,
                        activeTasks = uiState.activeTasks,
                        focusState = focusState
                    )
                }
                
                // Analytics Preview Card
                item {
                    AnimatedVisibility(
                        visible = analyticsState.hasData,
                        enter = slideInVertically() + fadeIn(),
                        exit = slideOutVertically() + fadeOut()
                    ) {
                        AnalyticsPreviewCard(
                            analyticsState = analyticsState,
                            modifier = Modifier.fillMaxWidth()
                        )
                    }
                }
                
                // Task Input with Glassmorphism
                item {
                    GlassCard(
                        modifier = Modifier.fillMaxWidth(),
                        contentPadding = PaddingValues(16.dp)
                    ) {
                        TaskInputComponent(
                            onCreateTask = viewModel::createTask,
                            onCreateTaskWithReminder = viewModel::createTaskWithReminder,
                            onCreateTaskWithRecurrence = viewModel::createTaskWithRecurrence,
                            inputError = uiState.inputError,
                            showTaskCreatedFeedback = uiState.showTaskCreatedFeedback,
                            onClearInputError = viewModel::clearInputError,
                            onClearTaskCreatedFeedback = viewModel::clearTaskCreatedFeedback,
                            speechRecognitionService = viewModel.speechRecognitionService,
                            onRequestMicrophonePermission = viewModel::requestMicrophonePermission
                        )
                    }
                }
                
                // Focus Mode Toggle
                item {
                    FocusModeToggleCard(
                        focusState = focusState,
                        onStartFocus = { mode -> focusViewModel.startFocusSession(mode) },
                        onPauseFocus = focusViewModel::pauseFocusSession,
                        onResumeFocus = focusViewModel::resumeFocusSession,
                        onCompleteFocus = { focusViewModel.completeFocusSession() },
                        modifier = Modifier.fillMaxWidth()
                    )
                }
                
                // Task List with Glassmorphism
                item {
                    GlassCard(
                        modifier = Modifier.fillMaxWidth(),
                        contentPadding = PaddingValues(0.dp)
                    ) {
                        TaskListComponent(
                            tasks = if (focusState.isSessionActive) focusState.filteredTasks else uiState.activeTasks,
                            isLoading = uiState.isLoading,
                            onTaskComplete = viewModel::completeTask
                        )
                    }
                }
                
                // Completed Tasks Section
                item {
                    AnimatedVisibility(
                        visible = uiState.completedTasks.isNotEmpty() && !focusState.isSessionActive,
                        enter = slideInVertically() + fadeIn(),
                        exit = slideOutVertically() + fadeOut()
                    ) {
                        GlassCard(
                            modifier = Modifier.fillMaxWidth(),
                            transparency = 0.08f,
                            contentPadding = PaddingValues(0.dp)
                        ) {
                            CompletedTasksSection(
                                completedTasks = uiState.completedTasks,
                                isLoading = uiState.isLoadingCompleted,
                                onDeleteCompletedTask = viewModel::deleteCompletedTask,
                                onClearAllCompleted = viewModel::clearAllCompletedTasks
                            )
                        }
                    }
                }
                
                // Bottom spacing
                item {
                    Spacer(modifier = Modifier.height(80.dp))
                }
            }
            
            // Floating Undo Snackbar
            AnimatedVisibility(
                visible = uiState.showUndoOption && uiState.recentlyCompletedTask != null,
                enter = slideInVertically(initialOffsetY = { it }) + fadeIn(),
                exit = slideOutVertically(targetOffsetY = { it }) + fadeOut(),
                modifier = Modifier
                    .align(Alignment.BottomCenter)
                    .padding(16.dp)
            ) {
                uiState.recentlyCompletedTask?.let { task ->
                    GlassCard(
                        transparency = 0.2f,
                        elevation = 12.dp
                    ) {
                        UndoSnackbar(
                            task = task,
                            onUndo = viewModel::undoTaskCompletion,
                            onDismiss = viewModel::dismissUndo
                        )
                    }
                }
            }
        }
    }
    
    // Auto-dismiss undo option after 5 seconds
    LaunchedEffect(uiState.showUndoOption) {
        if (uiState.showUndoOption) {
            kotlinx.coroutines.delay(5000)
            viewModel.dismissUndo()
        }
    }
}

/**
 * Glassmorphism header with greeting and status
 */
@Composable
private fun GlassmorphismHeader(
    blurIntensity: Float,
    activeTasks: List<com.tasktracker.domain.model.Task>,
    focusState: com.tasktracker.presentation.focus.FocusModeUiState,
    modifier: Modifier = Modifier
) {
    val glassColors = adaptiveGlassColors()
    val currentTime = remember { LocalTime.now() }
    
    val greeting = when (currentTime.hour) {
        in 5..11 -> "Good morning! 🌅"
        in 12..16 -> "Good afternoon! ☀️"
        in 17..20 -> "Good evening! 🌆"
        else -> "Good night! 🌙"
    }
    
    BlurredSurface(
        modifier = modifier.fillMaxWidth(),
        transparency = 0.1f + (blurIntensity * 0.1f),
        blurRadius = (20 + (blurIntensity * 10)).dp,
        shape = RoundedCornerShape(20.dp)
    ) {
        Column(
            modifier = Modifier.padding(20.dp),
            verticalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            Text(
                text = greeting,
                style = MaterialTheme.typography.headlineSmall.copy(
                    fontWeight = FontWeight.Medium,
                    fontSize = 24.sp
                ),
                color = glassColors.onSurface
            )
            
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                // Task count
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(4.dp)
                ) {
                    Text(
                        text = "${activeTasks.size} tasks",
                        style = MaterialTheme.typography.bodyMedium,
                        color = glassColors.onSurface.copy(alpha = 0.8f)
                    )
                    
                    if (focusState.isSessionActive) {
                        Text(
                            text = "•",
                            color = glassColors.onSurface.copy(alpha = 0.6f)
                        )
                        
                        Icon(
                            imageVector = Icons.Default.FitnessCenter,
                            contentDescription = "Focus mode active",
                            tint = MaterialTheme.colorScheme.primary,
                            modifier = Modifier.size(16.dp)
                        )
                        
                        Text(
                            text = "Focus: ${focusState.currentSession?.mode?.name?.lowercase()?.replace('_', ' ') ?: ""}",
                            style = MaterialTheme.typography.bodyMedium,
                            color = MaterialTheme.colorScheme.primary
                        )
                    }
                }
                
                // Time display
                Text(
                    text = currentTime.format(DateTimeFormatter.ofPattern("HH:mm")),
                    style = MaterialTheme.typography.bodyMedium.copy(
                        fontWeight = FontWeight.Medium
                    ),
                    color = glassColors.onSurface.copy(alpha = 0.7f)
                )
            }
        }
    }
}

/**
 * Analytics preview card with key metrics
 */
@Composable
private fun AnalyticsPreviewCard(
    analyticsState: com.tasktracker.presentation.analytics.AnalyticsUiState,
    modifier: Modifier = Modifier
) {
    val glassColors = adaptiveGlassColors()
    
    GlassCard(
        modifier = modifier,
        contentPadding = PaddingValues(16.dp)
    ) {
        Column(
            verticalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = "📊 Today's Progress",
                    style = MaterialTheme.typography.titleMedium.copy(
                        fontWeight = FontWeight.SemiBold
                    ),
                    color = glassColors.onSurface
                )
                
                Icon(
                    imageVector = Icons.Default.Analytics,
                    contentDescription = "Analytics",
                    tint = glassColors.onSurface.copy(alpha = 0.6f),
                    modifier = Modifier.size(20.dp)
                )
            }
            
            analyticsState.productivityMetrics?.let { metrics ->
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceEvenly
                ) {
                    // Tasks completed today
                    AnalyticsMetricItem(
                        value = "${metrics.tasksCompletedToday}/${metrics.tasksCompletedToday + (metrics.totalTasksCompleted - metrics.tasksCompletedToday)}",
                        label = "Tasks",
                        icon = Icons.Default.TrendingUp
                    )
                    
                    // Current streak
                    AnalyticsMetricItem(
                        value = "${metrics.currentStreak}",
                        label = "Streak",
                        icon = Icons.Default.LocalFireDepartment
                    )
                    
                    // Completion rate
                    AnalyticsMetricItem(
                        value = "${(metrics.completionRate * 100).toInt()}%",
                        label = "Rate",
                        icon = Icons.Default.Analytics
                    )
                }
            }
        }
    }
}

/**
 * Individual analytics metric item
 */
@Composable
private fun AnalyticsMetricItem(
    value: String,
    label: String,
    icon: androidx.compose.ui.graphics.vector.ImageVector,
    modifier: Modifier = Modifier
) {
    val glassColors = adaptiveGlassColors()
    
    Column(
        modifier = modifier,
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(4.dp)
    ) {
        Icon(
            imageVector = icon,
            contentDescription = label,
            tint = MaterialTheme.colorScheme.primary,
            modifier = Modifier.size(18.dp)
        )
        
        Text(
            text = value,
            style = MaterialTheme.typography.titleMedium.copy(
                fontWeight = FontWeight.Bold
            ),
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
 * Focus mode toggle card
 */
@Composable
private fun FocusModeToggleCard(
    focusState: com.tasktracker.presentation.focus.FocusModeUiState,
    onStartFocus: (com.tasktracker.domain.model.FocusMode) -> Unit,
    onPauseFocus: () -> Unit,
    onResumeFocus: () -> Unit,
    onCompleteFocus: () -> Unit,
    modifier: Modifier = Modifier
) {
    val glassColors = adaptiveGlassColors()
    
    GlassCard(
        modifier = modifier,
        contentPadding = PaddingValues(16.dp),
        transparency = if (focusState.isSessionActive) 0.2f else 0.12f
    ) {
        Column(
            verticalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = if (focusState.isSessionActive) "🎯 Focus Mode Active" else "🎯 Focus Mode",
                    style = MaterialTheme.typography.titleMedium.copy(
                        fontWeight = FontWeight.SemiBold
                    ),
                    color = if (focusState.isSessionActive) MaterialTheme.colorScheme.primary else glassColors.onSurface
                )
                
                if (focusState.isSessionActive) {
                    focusState.currentSession?.let { session ->
                        Text(
                            text = "${focusState.remainingTime.toMinutes()}:${String.format("%02d", focusState.remainingTime.seconds % 60)}",
                            style = MaterialTheme.typography.titleMedium.copy(
                                fontWeight = FontWeight.Bold
                            ),
                            color = MaterialTheme.colorScheme.primary
                        )
                    }
                }
            }
            
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                when {
                    focusState.canStartSession -> {
                        GlassButton(
                            onClick = { onStartFocus(com.tasktracker.domain.model.FocusMode.DEEP_WORK) },
                            modifier = Modifier.weight(1f)
                        ) {
                            Row(
                                verticalAlignment = Alignment.CenterVertically,
                                horizontalArrangement = Arrangement.spacedBy(8.dp)
                            ) {
                                Icon(
                                    imageVector = Icons.Default.PlayArrow,
                                    contentDescription = "Start focus",
                                    modifier = Modifier.size(18.dp)
                                )
                                Text("Start Focus")
                            }
                        }
                    }
                    
                    focusState.canPauseSession -> {
                        GlassButton(
                            onClick = onPauseFocus,
                            modifier = Modifier.weight(1f)
                        ) {
                            Row(
                                verticalAlignment = Alignment.CenterVertically,
                                horizontalArrangement = Arrangement.spacedBy(8.dp)
                            ) {
                                Icon(
                                    imageVector = Icons.Default.Stop,
                                    contentDescription = "Pause focus",
                                    modifier = Modifier.size(18.dp)
                                )
                                Text("Pause")
                            }
                        }
                        
                        GlassButton(
                            onClick = onCompleteFocus,
                            modifier = Modifier.weight(1f)
                        ) {
                            Text("Complete")
                        }
                    }
                    
                    focusState.canResumeSession -> {
                        GlassButton(
                            onClick = onResumeFocus,
                            modifier = Modifier.weight(1f)
                        ) {
                            Row(
                                verticalAlignment = Alignment.CenterVertically,
                                horizontalArrangement = Arrangement.spacedBy(8.dp)
                            ) {
                                Icon(
                                    imageVector = Icons.Default.PlayArrow,
                                    contentDescription = "Resume focus",
                                    modifier = Modifier.size(18.dp)
                                )
                                Text("Resume")
                            }
                        }
                    }
                }
            }
            
            // Progress bar for active session
            if (focusState.isSessionActive && focusState.progressPercentage > 0f) {
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(4.dp)
                        .background(
                            color = glassColors.onSurface.copy(alpha = 0.2f),
                            shape = RoundedCornerShape(2.dp)
                        )
                ) {
                    Box(
                        modifier = Modifier
                            .fillMaxWidth(focusState.progressPercentage)
                            .height(4.dp)
                            .background(
                                color = MaterialTheme.colorScheme.primary,
                                shape = RoundedCornerShape(2.dp)
                            )
                    )
                }
            }
        }
    }
}

@Preview(showBackground = true)
@Composable
fun MainScreenPreview() {
    TaskTrackerTheme {
        MainScreen()
    }
}

@Preview(showBackground = true, uiMode = android.content.res.Configuration.UI_MODE_NIGHT_YES)
@Composable
fun MainScreenDarkPreview() {
    TaskTrackerTheme {
        MainScreen()
    }
}