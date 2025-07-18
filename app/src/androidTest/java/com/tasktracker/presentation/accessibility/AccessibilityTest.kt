package com.tasktracker.presentation.accessibility

import androidx.compose.ui.test.assertHasClickAction
import androidx.compose.ui.test.assertIsDisplayed
import androidx.compose.ui.test.hasContentDescription
import androidx.compose.ui.test.hasText
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.compose.ui.test.onNodeWithContentDescription
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.performClick
import androidx.test.ext.junit.runners.AndroidJUnit4
import com.tasktracker.domain.model.RecurrenceType
import com.tasktracker.domain.model.Task
import com.tasktracker.presentation.components.TaskInputComponent
import com.tasktracker.presentation.components.TaskItemComponent
import com.tasktracker.presentation.components.TaskListComponent
import com.tasktracker.presentation.theme.TaskTrackerTheme
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith

@RunWith(AndroidJUnit4::class)
class AccessibilityTest {

    @get:Rule
    val composeTestRule = createComposeRule()

    @Test
    fun taskItemComponent_hasProperContentDescription() {
        val task = Task(
            id = "1",
            description = "Buy groceries",
            recurrenceType = RecurrenceType.DAILY,
            reminderTime = System.currentTimeMillis() + 3600000
        )

        composeTestRule.setContent {
            TaskTrackerTheme {
                TaskItemComponent(task = task)
            }
        }

        // Verify the task card has comprehensive content description
        composeTestRule.onNode(
            hasContentDescription("Task: Buy groceries, has reminder, recurring daily, created just now, swipe right to complete")
        ).assertIsDisplayed()
    }

    @Test
    fun taskItemComponent_iconsHaveContentDescriptions() {
        val task = Task(
            id = "1",
            description = "Task with features",
            recurrenceType = RecurrenceType.WEEKLY,
            reminderTime = System.currentTimeMillis() + 3600000
        )

        composeTestRule.setContent {
            TaskTrackerTheme {
                TaskItemComponent(task = task)
            }
        }

        // Verify reminder icon has content description
        composeTestRule.onNodeWithContentDescription("Has reminder").assertIsDisplayed()
        
        // Verify recurrence icon has content description
        composeTestRule.onNodeWithContentDescription("Recurring task").assertIsDisplayed()
    }

    @Test
    fun taskInputComponent_hasAccessibleInputField() {
        composeTestRule.setContent {
            TaskTrackerTheme {
                TaskInputComponent()
            }
        }

        // Verify input field is accessible
        composeTestRule.onNodeWithText("Add new task...").assertIsDisplayed()
        
        // Verify buttons have content descriptions
        composeTestRule.onNodeWithContentDescription("Create task").assertIsDisplayed()
        composeTestRule.onNodeWithContentDescription("Set reminder").assertIsDisplayed()
        composeTestRule.onNodeWithContentDescription("Set recurrence").assertIsDisplayed()
    }

    @Test
    fun taskInputComponent_buttonsHaveClickActions() {
        composeTestRule.setContent {
            TaskTrackerTheme {
                TaskInputComponent()
            }
        }

        // Verify buttons are clickable for accessibility services
        composeTestRule.onNodeWithContentDescription("Create task").assertHasClickAction()
        composeTestRule.onNodeWithContentDescription("Set reminder").assertHasClickAction()
        composeTestRule.onNodeWithContentDescription("Set recurrence").assertHasClickAction()
    }

    @Test
    fun completedTaskItem_hasProperAccessibilityInfo() {
        val completedTask = Task(
            id = "1",
            description = "Completed task",
            isCompleted = true,
            completedAt = System.currentTimeMillis() - 3600000
        )

        composeTestRule.setContent {
            TaskTrackerTheme {
                TaskItemComponent(task = completedTask)
            }
        }

        // Verify completed task has proper content description
        composeTestRule.onNodeWithContentDescription("Completed task").assertIsDisplayed()
    }

    @Test
    fun taskListComponent_emptyStateIsAccessible() {
        composeTestRule.setContent {
            TaskTrackerTheme {
                TaskListComponent(
                    tasks = emptyList(),
                    isLoading = false
                )
            }
        }

        // Verify empty state has accessible text
        composeTestRule.onNodeWithText("No tasks yet").assertIsDisplayed()
        composeTestRule.onNodeWithText("Add your first task using the input field above").assertIsDisplayed()
    }

    @Test
    fun taskListComponent_loadingStateIsAccessible() {
        composeTestRule.setContent {
            TaskTrackerTheme {
                TaskListComponent(
                    tasks = emptyList(),
                    isLoading = true
                )
            }
        }

        // Verify loading state has accessible text
        composeTestRule.onNodeWithText("Loading tasks...").assertIsDisplayed()
    }

    @Test
    fun swipeBackground_hasAccessibleIcon() {
        val task = Task(id = "1", description = "Swipe test task")

        composeTestRule.setContent {
            TaskTrackerTheme {
                TaskItemComponent(task = task)
            }
        }

        // Verify swipe background icon has content description
        composeTestRule.onNodeWithContentDescription("Complete task").assertExists()
    }

    @Test
    fun taskItemComponent_supportsLargeText() {
        val task = Task(
            id = "1",
            description = "This is a very long task description that should scale properly with large text settings and remain readable for users with visual impairments"
        )

        composeTestRule.setContent {
            TaskTrackerTheme {
                TaskItemComponent(task = task)
            }
        }

        // Verify long text is displayed (would scale with system text size)
        composeTestRule.onNode(hasText(task.description, substring = true)).assertIsDisplayed()
    }

    @Test
    fun taskInputComponent_errorStateIsAccessible() {
        composeTestRule.setContent {
            TaskTrackerTheme {
                TaskInputComponent(
                    inputError = "Task description cannot be empty"
                )
            }
        }

        // Verify error message is accessible
        composeTestRule.onNodeWithText("Task description cannot be empty").assertIsDisplayed()
    }

    @Test
    fun taskInputComponent_successFeedbackIsAccessible() {
        composeTestRule.setContent {
            TaskTrackerTheme {
                TaskInputComponent(
                    showTaskCreatedFeedback = true
                )
            }
        }

        // Verify success feedback is accessible
        composeTestRule.onNodeWithText("Task created successfully!").assertIsDisplayed()
        composeTestRule.onNodeWithContentDescription("Task created").assertIsDisplayed()
    }
}