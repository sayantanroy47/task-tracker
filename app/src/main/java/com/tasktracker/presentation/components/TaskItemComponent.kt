package com.tasktracker.presentation.components

import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.tween
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.Notifications
import androidx.compose.material.icons.filled.Repeat
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.SwipeToDismissBox
import androidx.compose.material3.SwipeToDismissBoxValue
import androidx.compose.material3.Text
import androidx.compose.material3.rememberSwipeToDismissBoxState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.scale
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.hapticfeedback.HapticFeedbackType
import androidx.compose.ui.platform.LocalHapticFeedback
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.role
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextDecoration
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import com.tasktracker.domain.model.RecurrenceType
import com.tasktracker.domain.model.Task
import com.tasktracker.presentation.components.glassmorphism.GlassCard
import com.tasktracker.presentation.theme.adaptiveGlassColors
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun TaskItemComponent(
    task: Task,
    onTaskComplete: (Task) -> Unit = {},
    modifier: Modifier = Modifier
) {
    val hapticFeedback = LocalHapticFeedback.current
    
    // Don't allow swiping if task is already completed
    val swipeState = rememberSwipeToDismissBoxState(
        confirmValueChange = { dismissValue ->
            if (task.isCompleted) {
                false // Don't allow swiping completed tasks
            } else {
                when (dismissValue) {
                    SwipeToDismissBoxValue.StartToEnd -> {
                        hapticFeedback.performHapticFeedback(HapticFeedbackType.LongPress)
                        onTaskComplete(task)
                        true
                    }
                    else -> false
                }
            }
        }
    )

    if (task.isCompleted) {
        // Show completed task without swipe functionality
        CompletedTaskCard(task = task, modifier = modifier)
    } else {
        // Show active task with swipe functionality
        SwipeToDismissBox(
            state = swipeState,
            modifier = modifier,
            backgroundContent = {
                SwipeBackground(swipeState.dismissDirection)
            }
        ) {
            TaskCard(task = task)
        }
    }
}

@Composable
private fun SwipeBackground(
    dismissDirection: SwipeToDismissBoxValue
) {
    val glassColors = adaptiveGlassColors()
    
    val backgroundBrush = when (dismissDirection) {
        SwipeToDismissBoxValue.StartToEnd -> Brush.horizontalGradient(
            colors = listOf(
                MaterialTheme.colorScheme.primary.copy(alpha = 0.8f),
                MaterialTheme.colorScheme.primary.copy(alpha = 0.4f)
            )
        )
        else -> Brush.horizontalGradient(
            colors = listOf(Color.Transparent, Color.Transparent)
        )
    }

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(backgroundBrush, RoundedCornerShape(16.dp))
            .padding(horizontal = 20.dp),
        contentAlignment = Alignment.CenterStart
    ) {
        if (dismissDirection == SwipeToDismissBoxValue.StartToEnd) {
            Icon(
                imageVector = Icons.Default.Check,
                contentDescription = "Complete task",
                tint = MaterialTheme.colorScheme.onPrimary,
                modifier = Modifier.size(24.dp)
            )
        }
    }
}

@Composable
private fun TaskCard(
    task: Task
) {
    val glassColors = adaptiveGlassColors()
    
    val taskDescription = buildString {
        append("Task: ${task.description}")
        if (task.hasReminder()) {
            append(", has reminder")
        }
        if (task.isRecurring()) {
            append(", recurring ${formatRecurrenceType(task.recurrenceType).lowercase()}")
        }
        append(", created ${formatCreatedTime(task.createdAt)}")
        append(", swipe right to complete")
    }
    
    GlassCard(
        modifier = Modifier.semantics {
            contentDescription = taskDescription
            role = Role.Button
        },
        contentPadding = PaddingValues(16.dp),
        transparency = 0.12f,
        elevation = 4.dp
    ) {
        Column(
            modifier = Modifier.fillMaxWidth(),
            verticalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            // Task description
            Text(
                text = task.description,
                style = MaterialTheme.typography.bodyLarge,
                fontWeight = FontWeight.Medium,
                color = glassColors.onSurface,
                maxLines = 2,
                overflow = TextOverflow.Ellipsis
            )
            
            // Task metadata row
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(16.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                // Created time
                Text(
                    text = formatCreatedTime(task.createdAt),
                    style = MaterialTheme.typography.bodySmall,
                    color = glassColors.onSurface.copy(alpha = 0.7f),
                    modifier = Modifier.weight(1f)
                )
                
                // Indicators row
                Row(
                    horizontalArrangement = Arrangement.spacedBy(8.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    // Reminder indicator
                    if (task.hasReminder()) {
                        Icon(
                            imageVector = Icons.Default.Notifications,
                            contentDescription = "Has reminder",
                            tint = MaterialTheme.colorScheme.primary,
                            modifier = Modifier.size(16.dp)
                        )
                    }
                    
                    // Recurrence indicator
                    if (task.isRecurring()) {
                        Row(
                            horizontalArrangement = Arrangement.spacedBy(4.dp),
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Icon(
                                imageVector = Icons.Default.Repeat,
                                contentDescription = "Recurring task",
                                tint = MaterialTheme.colorScheme.secondary,
                                modifier = Modifier.size(16.dp)
                            )
                            Text(
                                text = formatRecurrenceType(task.recurrenceType),
                                style = MaterialTheme.typography.labelSmall,
                                color = MaterialTheme.colorScheme.secondary
                            )
                        }
                    }
                }
            }
            
            // Reminder time (if set and in the future)
            task.reminderTime?.let { reminderTime ->
                if (reminderTime > System.currentTimeMillis()) {
                    Text(
                        text = "Reminder: ${formatReminderTime(reminderTime)}",
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.primary,
                        fontWeight = FontWeight.Medium
                    )
                }
            }
        }
    }
}

@Composable
private fun CompletedTaskCard(
    task: Task,
    modifier: Modifier = Modifier
) {
    val glassColors = adaptiveGlassColors()
    
    GlassCard(
        modifier = modifier,
        contentPadding = PaddingValues(16.dp),
        transparency = 0.08f,
        elevation = 2.dp
    ) {
        Column(
            modifier = Modifier.fillMaxWidth(),
            verticalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            // Task description with strikethrough
            Text(
                text = task.description,
                style = MaterialTheme.typography.bodyLarge,
                fontWeight = FontWeight.Medium,
                color = glassColors.onSurface.copy(alpha = 0.6f),
                textDecoration = TextDecoration.LineThrough,
                maxLines = 2,
                overflow = TextOverflow.Ellipsis
            )
            
            // Task metadata row
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(16.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                // Completed time
                task.completedAt?.let { completedTime ->
                    Text(
                        text = "Completed ${formatCreatedTime(completedTime)}",
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.primary.copy(alpha = 0.8f),
                        fontWeight = FontWeight.Medium,
                        modifier = Modifier.weight(1f)
                    )
                }
                
                // Completion indicator
                Icon(
                    imageVector = Icons.Default.Check,
                    contentDescription = "Completed task",
                    tint = MaterialTheme.colorScheme.primary.copy(alpha = 0.8f),
                    modifier = Modifier.size(16.dp)
                )
            }
        }
    }
}

private fun formatCreatedTime(timestamp: Long): String {
    val now = System.currentTimeMillis()
    val diff = now - timestamp
    
    return when {
        diff < 60_000 -> "Just now"
        diff < 3600_000 -> "${diff / 60_000}m ago"
        diff < 86400_000 -> "${diff / 3600_000}h ago"
        diff < 604800_000 -> "${diff / 86400_000}d ago"
        else -> {
            val formatter = SimpleDateFormat("MMM dd", Locale.getDefault())
            formatter.format(Date(timestamp))
        }
    }
}

private fun formatReminderTime(timestamp: Long): String {
    val now = System.currentTimeMillis()
    val diff = timestamp - now
    
    return when {
        diff < 3600_000 -> "${diff / 60_000}m"
        diff < 86400_000 -> "${diff / 3600_000}h"
        diff < 604800_000 -> "${diff / 86400_000}d"
        else -> {
            val formatter = SimpleDateFormat("MMM dd, HH:mm", Locale.getDefault())
            formatter.format(Date(timestamp))
        }
    }
}

private fun formatRecurrenceType(recurrenceType: RecurrenceType?): String {
    return when (recurrenceType) {
        RecurrenceType.DAILY -> "Daily"
        RecurrenceType.WEEKLY -> "Weekly"
        RecurrenceType.MONTHLY -> "Monthly"
        null -> ""
    }
}

@Preview(showBackground = true)
@Composable
fun TaskItemComponentPreview() {
    MaterialTheme {
        TaskItemComponent(
            task = Task(
                id = "1",
                description = "Buy groceries for the week including fruits, vegetables, and dairy products"
            )
        )
    }
}

@Preview(showBackground = true)
@Composable
fun TaskItemComponentWithReminderPreview() {
    MaterialTheme {
        TaskItemComponent(
            task = Task(
                id = "2",
                description = "Call dentist for appointment",
                reminderTime = System.currentTimeMillis() + 3600000 // 1 hour from now
            )
        )
    }
}

@Preview(showBackground = true)
@Composable
fun TaskItemComponentRecurringPreview() {
    MaterialTheme {
        TaskItemComponent(
            task = Task(
                id = "3",
                description = "Daily exercise routine",
                recurrenceType = RecurrenceType.DAILY,
                reminderTime = System.currentTimeMillis() + 86400000 // 1 day from now
            )
        )
    }
}

@Preview(showBackground = true)
@Composable
fun TaskItemComponentFullFeaturesPreview() {
    MaterialTheme {
        TaskItemComponent(
            task = Task(
                id = "4",
                description = "Weekly team meeting to discuss project progress and upcoming deadlines",
                recurrenceType = RecurrenceType.WEEKLY,
                reminderTime = System.currentTimeMillis() + 1800000 // 30 minutes from now
            )
        )
    }
}

@Preview(showBackground = true)
@Composable
fun TaskItemComponentCompletedPreview() {
    MaterialTheme {
        TaskItemComponent(
            task = Task(
                id = "5",
                description = "Completed task with strikethrough text",
                isCompleted = true,
                completedAt = System.currentTimeMillis() - 3600000 // 1 hour ago
            )
        )
    }
}