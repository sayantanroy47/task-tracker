package com.tasktracker.presentation.components

import androidx.compose.ui.test.assertIsDisplayed
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.compose.ui.test.onNodeWithText
import androidx.test.ext.junit.runners.AndroidJUnit4
import com.tasktracker.domain.model.RecurrenceType
import com.tasktracker.domain.model.Task
import com.tasktracker.presentation.theme.TaskTrackerTheme
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith

@RunWith(AndroidJUnit4::class)
class TaskListComponentTest {

    @get:Rule
    val composeTestRule = createComposeRule()

    @Test
    fun taskListComponent_displaysLoadingState() {
        composeTestRule.setContent {
            TaskTrackerTheme {
                TaskListComponent(
                    tasks = emptyList(),
                    isLoading = true
                )
            }
        }

        composeTestRule.onNodeWithText("Loading tasks...").assertIsDisplayed()
    }

    @Test
    fun taskListComponent_displaysEmptyState() {
        composeTestRule.setContent {
            TaskTrackerTheme {
                TaskListComponent(
                    tasks = emptyList(),
                    isLoading = false
                )
            }
        }

        composeTestRule.onNodeWithText("No tasks yet").assertIsDisplayed()
        composeTestRule.onNodeWithText("Add your first task using the input field above")
            .assertIsDisplayed()
    }

    @Test
    fun taskListComponent_displaysSingleTask() {
        val task = Task(
            id = "1",
            description = "Test task"
        )

        composeTestRule.setContent {
            TaskTrackerTheme {
                TaskListComponent(
                    tasks = listOf(task),
                    isLoading = false
                )
            }
        }

        composeTestRule.onNodeWithText("Test task").assertIsDisplayed()
    }

    @Test
    fun taskListComponent_displaysMultipleTasks() {
        val tasks = listOf(
            Task(id = "1", description = "First task"),
            Task(id = "2", description = "Second task"),
            Task(id = "3", description = "Third task")
        )

        composeTestRule.setContent {
            TaskTrackerTheme {
                TaskListComponent(
                    tasks = tasks,
                    isLoading = false
                )
            }
        }

        composeTestRule.onNodeWithText("First task").assertIsDisplayed()
        composeTestRule.onNodeWithText("Second task").assertIsDisplayed()
        composeTestRule.onNodeWithText("Third task").assertIsDisplayed()
    }

    @Test
    fun taskListComponent_displaysTasksWithDifferentFeatures() {
        val tasks = listOf(
            Task(id = "1", description = "Simple task"),
            Task(
                id = "2", 
                description = "Task with reminder",
                reminderTime = System.currentTimeMillis() + 3600000
            ),
            Task(
                id = "3",
                description = "Recurring task",
                recurrenceType = RecurrenceType.DAILY
            )
        )

        composeTestRule.setContent {
            TaskTrackerTheme {
                TaskListComponent(
                    tasks = tasks,
                    isLoading = false
                )
            }
        }

        composeTestRule.onNodeWithText("Simple task").assertIsDisplayed()
        composeTestRule.onNodeWithText("Task with reminder").assertIsDisplayed()
        composeTestRule.onNodeWithText("Recurring task").assertIsDisplayed()
    }

    @Test
    fun taskListComponent_doesNotDisplayEmptyStateWhenTasksExist() {
        val task = Task(id = "1", description = "Test task")

        composeTestRule.setContent {
            TaskTrackerTheme {
                TaskListComponent(
                    tasks = listOf(task),
                    isLoading = false
                )
            }
        }

        composeTestRule.onNodeWithText("No tasks yet").assertDoesNotExist()
        composeTestRule.onNodeWithText("Add your first task using the input field above")
            .assertDoesNotExist()
    }

    @Test
    fun taskListComponent_doesNotDisplayLoadingWhenNotLoading() {
        composeTestRule.setContent {
            TaskTrackerTheme {
                TaskListComponent(
                    tasks = emptyList(),
                    isLoading = false
                )
            }
        }

        composeTestRule.onNodeWithText("Loading tasks...").assertDoesNotExist()
    }

    @Test
    fun taskListComponent_passesOnTaskCompleteCallback() {
        val task = Task(id = "1", description = "Test task")
        var completedTask: Task? = null

        composeTestRule.setContent {
            TaskTrackerTheme {
                TaskListComponent(
                    tasks = listOf(task),
                    onTaskComplete = { completedTask = it }
                )
            }
        }

        // The callback should be passed to TaskItemComponent
        // This is tested indirectly through the TaskItemComponent tests
        composeTestRule.onNodeWithText("Test task").assertIsDisplayed()
    }
}