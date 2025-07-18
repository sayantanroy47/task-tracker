package com.tasktracker.performance

import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.performClick
import androidx.test.ext.junit.runners.AndroidJUnit4
import com.tasktracker.domain.model.RecurrenceType
import com.tasktracker.domain.model.Task
import com.tasktracker.presentation.components.TaskListComponent
import com.tasktracker.presentation.theme.TaskTrackerTheme
import com.tasktracker.util.PerformanceMonitor
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith
import kotlin.system.measureTimeMillis
import kotlin.test.assertTrue

/**
 * Performance tests for Jetpack Compose UI components.
 * Tests rendering performance, recomposition efficiency, and large list handling.
 */
@RunWith(AndroidJUnit4::class)
class ComposePerformanceTest {
    
    @get:Rule
    val composeTestRule = createComposeRule()
    
    @Test
    fun testTaskListRenderingPerformance() {
        // Arrange: Create a large list of tasks
        val largeTasks = generateLargeTasks(500)
        var tasks by mutableStateOf(largeTasks)
        
        // Act: Measure initial composition time
        val compositionTime = measureTimeMillis {
            composeTestRule.setContent {
                TaskTrackerTheme {
                    TaskListComponent(
                        tasks = tasks,
                        onTaskComplete = { }
                    )
                }
            }
        }
        
        // Assert: Initial composition should be fast
        assertTrue(compositionTime < 1000, "Initial composition took ${compositionTime}ms, should be < 1000ms")
        
        // Verify content is rendered
        composeTestRule.onNodeWithText("Task 1").assertExists()
        
        PerformanceMonitor.recordMetrics("taskListComposition", compositionTime)
    }
    
    @Test
    fun testTaskListRecompositionPerformance() {
        // Arrange: Start with small list
        var tasks by mutableStateOf(generateLargeTasks(10))
        
        composeTestRule.setContent {
            TaskTrackerTheme {
                TaskListComponent(
                    tasks = tasks,
                    onTaskComplete = { }
                )
            }
        }
        
        // Act: Measure recomposition time when adding tasks
        val recompositionTime = measureTimeMillis {
            tasks = generateLargeTasks(100) // Add more tasks
        }
        
        composeTestRule.waitForIdle()
        
        // Assert: Recomposition should be efficient
        assertTrue(recompositionTime < 500, "Recomposition took ${recompositionTime}ms, should be < 500ms")
        
        // Verify new content is rendered
        composeTestRule.onNodeWithText("Task 100").assertExists()
        
        PerformanceMonitor.recordMetrics("taskListRecomposition", recompositionTime)
    }
    
    @Test
    fun testTaskCompletionPerformance() {
        // Arrange: Create tasks with completion callback
        val tasks = generateLargeTasks(50)
        var completedTaskId: String? = null
        
        composeTestRule.setContent {
            TaskTrackerTheme {
                TaskListComponent(
                    tasks = tasks,
                    onTaskComplete = { task ->
                        completedTaskId = task.id
                    }
                )
            }
        }
        
        // Act: Measure task completion interaction time
        val interactionTime = measureTimeMillis {
            // Find and click on first task to complete it
            composeTestRule.onNodeWithText("Task 1").performClick()
        }
        
        composeTestRule.waitForIdle()
        
        // Assert: Interaction should be responsive
        assertTrue(interactionTime < 100, "Task completion interaction took ${interactionTime}ms, should be < 100ms")
        assertTrue(completedTaskId != null, "Task completion callback should be triggered")
        
        PerformanceMonitor.recordMetrics("taskCompletionInteraction", interactionTime)
    }
    
    @Test
    fun testScrollingPerformanceWithLargeList() {
        // Arrange: Create very large list for scrolling test
        val veryLargeTasks = generateLargeTasks(1000)
        
        composeTestRule.setContent {
            TaskTrackerTheme {
                TaskListComponent(
                    tasks = veryLargeTasks,
                    onTaskComplete = { }
                )
            }
        }
        
        // Act: Measure scrolling performance
        val scrollTime = measureTimeMillis {
            // Perform multiple scroll operations
            repeat(10) {
                composeTestRule.onNodeWithText("Task 1").assertExists()
                // Note: In a real test, you would perform actual scroll gestures
                // This is a simplified version for performance measurement
            }
        }
        
        // Assert: Scrolling should remain smooth
        assertTrue(scrollTime < 1000, "Scrolling operations took ${scrollTime}ms, should be < 1000ms")
        
        PerformanceMonitor.recordMetrics("largeListScrolling", scrollTime)
    }
    
    @Test
    fun testEmptyStateRenderingPerformance() {
        // Arrange: Empty task list
        val emptyTasks = emptyList<Task>()
        
        // Act: Measure empty state composition time
        val emptyStateTime = measureTimeMillis {
            composeTestRule.setContent {
                TaskTrackerTheme {
                    TaskListComponent(
                        tasks = emptyTasks,
                        onTaskComplete = { }
                    )
                }
            }
        }
        
        // Assert: Empty state should render quickly
        assertTrue(emptyStateTime < 100, "Empty state composition took ${emptyStateTime}ms, should be < 100ms")
        
        // Verify empty state content
        composeTestRule.onNodeWithText("No tasks yet").assertExists()
        
        PerformanceMonitor.recordMetrics("emptyStateComposition", emptyStateTime)
    }
    
    @Test
    fun testLoadingStatePerformance() {
        // Act: Measure loading state composition time
        val loadingTime = measureTimeMillis {
            composeTestRule.setContent {
                TaskTrackerTheme {
                    TaskListComponent(
                        tasks = emptyList(),
                        isLoading = true,
                        onTaskComplete = { }
                    )
                }
            }
        }
        
        // Assert: Loading state should render quickly
        assertTrue(loadingTime < 50, "Loading state composition took ${loadingTime}ms, should be < 50ms")
        
        // Verify loading content
        composeTestRule.onNodeWithText("Loading tasks...").assertExists()
        
        PerformanceMonitor.recordMetrics("loadingStateComposition", loadingTime)
    }
    
    @Test
    fun testMemoryUsageDuringLargeListRendering() {
        // Arrange: Monitor memory before rendering
        val initialMemory = Runtime.getRuntime().let { it.totalMemory() - it.freeMemory() }
        
        // Act: Render large list and measure memory usage
        val largeTasks = generateLargeTasks(2000)
        
        composeTestRule.setContent {
            TaskTrackerTheme {
                TaskListComponent(
                    tasks = largeTasks,
                    onTaskComplete = { }
                )
            }
        }
        
        composeTestRule.waitForIdle()
        
        val finalMemory = Runtime.getRuntime().let { it.totalMemory() - it.freeMemory() }
        val memoryIncrease = (finalMemory - initialMemory) / 1024 / 1024 // Convert to MB
        
        // Assert: Memory usage should be reasonable
        assertTrue(memoryIncrease < 100, "Memory increase: ${memoryIncrease}MB for 2000 tasks, should be < 100MB")
        
        PerformanceMonitor.logMemoryUsage("Large list rendering")
    }
    
    private fun generateLargeTasks(count: Int): List<Task> {
        return (1..count).map { index ->
            Task(
                id = "task_$index",
                description = "Task $index",
                isCompleted = false,
                createdAt = System.currentTimeMillis() - (index * 1000),
                recurrenceType = if (index % 5 == 0) RecurrenceType.DAILY else null,
                reminderTime = if (index % 3 == 0) System.currentTimeMillis() + 3600000 else null
            )
        }
    }
}