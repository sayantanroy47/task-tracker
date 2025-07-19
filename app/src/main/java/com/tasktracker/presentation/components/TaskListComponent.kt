package com.tasktracker.presentation.components

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.animation.core.tween
import androidx.compose.foundation.ExperimentalFoundationApi
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.derivedStateOf
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import com.tasktracker.domain.model.Task
import com.tasktracker.domain.model.RecurrenceType
import com.tasktracker.util.PerformanceMonitor

@OptIn(ExperimentalFoundationApi::class)
@Composable
fun TaskListComponent(
    tasks: List<Task> = emptyList(),
    isLoading: Boolean = false,
    onTaskComplete: (Task) -> Unit = {},
    modifier: Modifier = Modifier
) {
    // Performance optimization: Remember list state to maintain scroll position
    val listState = rememberLazyListState()
    
    // Performance optimization: Derive state to prevent unnecessary recompositions
    val isEmpty by remember(tasks) { derivedStateOf { tasks.isEmpty() } }
    
    // Performance optimization: Log memory usage for large lists
    LaunchedEffect(tasks.size) {
        if (tasks.size > 100) {
            PerformanceMonitor.logMemoryUsage("TaskList with ${tasks.size} items")
        }
    }
    
    when {
            isLoading -> {
                Box(
                    modifier = modifier.fillMaxSize(),
                    contentAlignment = Alignment.Center
                ) {
                    Text(
                        text = "Loading tasks...",
                        style = MaterialTheme.typography.bodyLarge,
                        color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.6f)
                    )
                }
            }
            isEmpty -> {
                EmptyTaskListState(modifier = modifier)
            }
            else -> {
                LazyColumn(
                    state = listState,
                    modifier = modifier.fillMaxWidth(),
                    contentPadding = PaddingValues(vertical = 8.dp),
                    verticalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    items(
                        items = tasks,
                        key = { task -> task.id },
                        contentType = { "TaskItem" } // Performance: Content type for better recycling
                    ) { task ->
                        // Performance optimization: Stable callback to prevent recomposition
                        val stableOnComplete = remember(task.id) {
                            { _: Task -> onTaskComplete(task) }
                        }
                        
                        TaskItemComponent(
                            task = task,
                            onTaskComplete = stableOnComplete,
                            modifier = Modifier
                                .fillMaxWidth()
                                .animateItemPlacement() // Smooth animations for list changes
                        )
                    }
                }
            }
        }
}

@Composable
private fun EmptyTaskListState(
    modifier: Modifier = Modifier
) {
    Box(
        modifier = modifier.fillMaxSize(),
        contentAlignment = Alignment.Center
    ) {
        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            Icon(
                imageVector = Icons.Default.CheckCircle,
                contentDescription = "No tasks",
                tint = MaterialTheme.colorScheme.primary.copy(alpha = 0.6f),
                modifier = Modifier.padding(16.dp)
            )
            Text(
                text = "No tasks yet",
                style = MaterialTheme.typography.headlineSmall,
                color = MaterialTheme.colorScheme.onSurface,
                textAlign = TextAlign.Center
            )
            Text(
                text = "Add your first task using the input field above",
                style = MaterialTheme.typography.bodyLarge,
                color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.7f),
                textAlign = TextAlign.Center,
                modifier = Modifier.padding(horizontal = 32.dp)
            )
        }
    }
}

@Preview(showBackground = true)
@Composable
fun TaskListComponentPreview() {
    MaterialTheme {
        TaskListComponent(
            tasks = listOf(
                Task(id = "1", description = "Buy groceries"),
                Task(id = "2", description = "Complete project", recurrenceType = RecurrenceType.DAILY),
                Task(id = "3", description = "Call dentist", reminderTime = System.currentTimeMillis() + 3600000)
            )
        )
    }
}

@Preview(showBackground = true)
@Composable
fun TaskListComponentEmptyPreview() {
    MaterialTheme {
        TaskListComponent(tasks = emptyList())
    }
}

@Preview(showBackground = true)
@Composable
fun TaskListComponentLoadingPreview() {
    MaterialTheme {
        TaskListComponent(isLoading = true)
    }
}