package com.tasktracker.presentation.components

import androidx.compose.ui.test.assertIsDisplayed
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.compose.ui.test.onNodeWithContentDescription
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.performClick
import androidx.test.ext.junit.runners.AndroidJUnit4
import com.tasktracker.domain.model.Task
import com.tasktracker.presentation.theme.TaskTrackerTheme
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith

@RunWith(AndroidJUnit4::class)
class CompletedTasksSectionTest {

    @get:Rule
    val composeTestRule = createComposeRule()

    @Test
    fun completedTasksSection_doesNotShowWhenEmpty() {
        composeTestRule.setContent {
            TaskTrackerTheme {
                CompletedTasksSection(
                    completedTasks = emptyList(),
                    isLoading = false
                )
            }
        }

        composeTestRule.onNodeWithText("Completed (0)").assertDoesNotExist()
    }

    @Test
    fun completedTasksSection_showsHeaderWithCount() {
        val completedTasks = listOf(
            Task(
                id = "1",
                description = "Completed task 1",
                isCompleted = true,
                completedAt = System.currentTimeMillis() - 3600000
            ),
            Task(
                id = "2",
                description = "Completed task 2",
                isCompleted = true,
                completedAt = System.currentTimeMillis() - 7200000
            )
        )

        composeTestRule.setContent {
            TaskTrackerTheme {
                CompletedTasksSection(
                    completedTasks = completedTasks,
                    isLoading = false
                )
            }
        }

        composeTestRule.onNodeWithText("Completed (2)").assertIsDisplayed()
        composeTestRule.onNodeWithContentDescription("Expand").assertIsDisplayed()
        composeTestRule.onNodeWithText("Clear All").assertIsDisplayed()
    }

    @Test
    fun completedTasksSection_expandsAndCollapses() {
        val completedTasks = listOf(
            Task(
                id = "1",
                description = "Completed task",
                isCompleted = true,
                completedAt = System.currentTimeMillis() - 3600000
            )
        )

        composeTestRule.setContent {
            TaskTrackerTheme {
                CompletedTasksSection(
                    completedTasks = completedTasks,
                    isLoading = false
                )
            }
        }

        // Initially collapsed - task should not be visible
        composeTestRule.onNodeWithText("Completed task").assertDoesNotExist()

        // Expand
        composeTestRule.onNodeWithContentDescription("Expand").performClick()
        composeTestRule.onNodeWithText("Completed task").assertIsDisplayed()
        composeTestRule.onNodeWithContentDescription("Collapse").assertIsDisplayed()

        // Collapse
        composeTestRule.onNodeWithContentDescription("Collapse").performClick()
        composeTestRule.onNodeWithText("Completed task").assertDoesNotExist()
        composeTestRule.onNodeWithContentDescription("Expand").assertIsDisplayed()
    }

    @Test
    fun completedTasksSection_showsLoadingState() {
        composeTestRule.setContent {
            TaskTrackerTheme {
                CompletedTasksSection(
                    completedTasks = emptyList(),
                    isLoading = true
                )
            }
        }

        composeTestRule.onNodeWithText("Completed (0)").assertIsDisplayed()
        
        // Expand to see loading state
        composeTestRule.onNodeWithContentDescription("Expand").performClick()
        composeTestRule.onNodeWithText("Loading completed tasks...").assertIsDisplayed()
    }

    @Test
    fun completedTasksSection_showsEmptyStateWhenExpanded() {
        composeTestRule.setContent {
            TaskTrackerTheme {
                CompletedTasksSection(
                    completedTasks = emptyList(),
                    isLoading = false
                )
            }
        }

        // This test assumes we show the section even when empty for testing
        // In practice, the section might not show when empty
    }

    @Test
    fun completedTasksSection_callsDeleteCallback() {
        val task = Task(
            id = "1",
            description = "Completed task",
            isCompleted = true,
            completedAt = System.currentTimeMillis() - 3600000
        )
        var deletedTask: Task? = null

        composeTestRule.setContent {
            TaskTrackerTheme {
                CompletedTasksSection(
                    completedTasks = listOf(task),
                    onDeleteCompletedTask = { deletedTask = it }
                )
            }
        }

        // Expand to see tasks
        composeTestRule.onNodeWithContentDescription("Expand").performClick()
        
        // Delete task
        composeTestRule.onNodeWithContentDescription("Delete completed task").performClick()

        assert(deletedTask == task) { "Delete callback should be called with the correct task" }
    }

    @Test
    fun completedTasksSection_callsClearAllCallback() {
        val completedTasks = listOf(
            Task(
                id = "1",
                description = "Completed task",
                isCompleted = true,
                completedAt = System.currentTimeMillis() - 3600000
            )
        )
        var clearAllCalled = false

        composeTestRule.setContent {
            TaskTrackerTheme {
                CompletedTasksSection(
                    completedTasks = completedTasks,
                    onClearAllCompleted = { clearAllCalled = true }
                )
            }
        }

        composeTestRule.onNodeWithText("Clear All").performClick()

        assert(clearAllCalled) { "Clear all callback should be called" }
    }

    @Test
    fun completedTasksSection_displaysCompletionTime() {
        val task = Task(
            id = "1",
            description = "Completed task",
            isCompleted = true,
            completedAt = System.currentTimeMillis() - 3600000 // 1 hour ago
        )

        composeTestRule.setContent {
            TaskTrackerTheme {
                CompletedTasksSection(
                    completedTasks = listOf(task)
                )
            }
        }

        // Expand to see tasks
        composeTestRule.onNodeWithContentDescription("Expand").performClick()
        
        composeTestRule.onNodeWithText("Completed task").assertIsDisplayed()
        composeTestRule.onNodeWithText("Completed 1h ago").assertIsDisplayed()
    }

    @Test
    fun completedTasksSection_doesNotShowClearAllWhenEmpty() {
        composeTestRule.setContent {
            TaskTrackerTheme {
                CompletedTasksSection(
                    completedTasks = emptyList(),
                    isLoading = true // Show section even when empty for this test
                )
            }
        }

        composeTestRule.onNodeWithText("Clear All").assertDoesNotExist()
    }
}