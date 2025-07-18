package com.tasktracker.presentation.components

import androidx.compose.ui.test.assertIsDisplayed
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.compose.ui.test.onNodeWithContentDescription
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.performTouchInput
import androidx.compose.ui.test.swipeRight
import androidx.test.ext.junit.runners.AndroidJUnit4
import com.tasktracker.domain.model.RecurrenceType
import com.tasktracker.domain.model.Task
import com.tasktracker.presentation.theme.TaskTrackerTheme
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith

@RunWith(AndroidJUnit4::class)
class TaskItemComponentTest {

    @get:Rule
    val composeTestRule = createComposeRule()

    @Test
    fun taskItemComponent_displaysTaskDescription() {
        val task = Task(
            id = "1",
            description = "Test task description"
        )

        composeTestRule.setContent {
            TaskTrackerTheme {
                TaskItemComponent(task = task)
            }
        }

        composeTestRule.onNodeWithText("Test task description").assertIsDisplayed()
    }

    @Test
    fun taskItemComponent_displaysCreatedTime() {
        val task = Task(
            id = "1",
            description = "Test task",
            createdAt = System.currentTimeMillis() - 60000 // 1 minute ago
        )

        composeTestRule.setContent {
            TaskTrackerTheme {
                TaskItemComponent(task = task)
            }
        }

        // Should display "1m ago" or similar
        composeTestRule.onNodeWithText("1m ago").assertIsDisplayed()
    }

    @Test
    fun taskItemComponent_displaysReminderIndicator() {
        val task = Task(
            id = "1",
            description = "Task with reminder",
            reminderTime = System.currentTimeMillis() + 3600000 // 1 hour from now
        )

        composeTestRule.setContent {
            TaskTrackerTheme {
                TaskItemComponent(task = task)
            }
        }

        composeTestRule.onNodeWithContentDescription("Has reminder").assertIsDisplayed()
    }

    @Test
    fun taskItemComponent_displaysRecurrenceIndicator() {
        val task = Task(
            id = "1",
            description = "Recurring task",
            recurrenceType = RecurrenceType.DAILY
        )

        composeTestRule.setContent {
            TaskTrackerTheme {
                TaskItemComponent(task = task)
            }
        }

        composeTestRule.onNodeWithContentDescription("Recurring task").assertIsDisplayed()
        composeTestRule.onNodeWithText("Daily").assertIsDisplayed()
    }

    @Test
    fun taskItemComponent_displaysReminderTime() {
        val task = Task(
            id = "1",
            description = "Task with reminder",
            reminderTime = System.currentTimeMillis() + 3600000 // 1 hour from now
        )

        composeTestRule.setContent {
            TaskTrackerTheme {
                TaskItemComponent(task = task)
            }
        }

        // Should display reminder time
        composeTestRule.onNodeWithText("Reminder: 1h").assertIsDisplayed()
    }

    @Test
    fun taskItemComponent_displaysAllRecurrenceTypes() {
        val dailyTask = Task(
            id = "1",
            description = "Daily task",
            recurrenceType = RecurrenceType.DAILY
        )
        val weeklyTask = Task(
            id = "2",
            description = "Weekly task",
            recurrenceType = RecurrenceType.WEEKLY
        )
        val monthlyTask = Task(
            id = "3",
            description = "Monthly task",
            recurrenceType = RecurrenceType.MONTHLY
        )

        // Test daily
        composeTestRule.setContent {
            TaskTrackerTheme {
                TaskItemComponent(task = dailyTask)
            }
        }
        composeTestRule.onNodeWithText("Daily").assertIsDisplayed()

        // Test weekly
        composeTestRule.setContent {
            TaskTrackerTheme {
                TaskItemComponent(task = weeklyTask)
            }
        }
        composeTestRule.onNodeWithText("Weekly").assertIsDisplayed()

        // Test monthly
        composeTestRule.setContent {
            TaskTrackerTheme {
                TaskItemComponent(task = monthlyTask)
            }
        }
        composeTestRule.onNodeWithText("Monthly").assertIsDisplayed()
    }

    @Test
    fun taskItemComponent_handlesLongDescription() {
        val task = Task(
            id = "1",
            description = "This is a very long task description that should be truncated when it exceeds the maximum number of lines allowed in the task item component"
        )

        composeTestRule.setContent {
            TaskTrackerTheme {
                TaskItemComponent(task = task)
            }
        }

        // Should display the description (even if truncated)
        composeTestRule.onNodeWithText(task.description, substring = true).assertIsDisplayed()
    }

    @Test
    fun taskItemComponent_doesNotDisplayPastReminder() {
        val task = Task(
            id = "1",
            description = "Task with past reminder",
            reminderTime = System.currentTimeMillis() - 3600000 // 1 hour ago
        )

        composeTestRule.setContent {
            TaskTrackerTheme {
                TaskItemComponent(task = task)
            }
        }

        // Should not display reminder time for past reminders
        composeTestRule.onNodeWithText("Reminder:", substring = true).assertDoesNotExist()
    }

    @Test
    fun taskItemComponent_doesNotDisplayIndicatorsForSimpleTask() {
        val task = Task(
            id = "1",
            description = "Simple task"
        )

        composeTestRule.setContent {
            TaskTrackerTheme {
                TaskItemComponent(task = task)
            }
        }

        composeTestRule.onNodeWithContentDescription("Has reminder").assertDoesNotExist()
        composeTestRule.onNodeWithContentDescription("Recurring task").assertDoesNotExist()
    }

    @Test
    fun taskItemComponent_displaysJustNowForRecentTasks() {
        val task = Task(
            id = "1",
            description = "Recent task",
            createdAt = System.currentTimeMillis() - 30000 // 30 seconds ago
        )

        composeTestRule.setContent {
            TaskTrackerTheme {
                TaskItemComponent(task = task)
            }
        }

        composeTestRule.onNodeWithText("Just now").assertIsDisplayed()
    }

    @Test
    fun taskItemComponent_callsOnTaskCompleteWhenSwipedRight() {
        val task = Task(
            id = "1",
            description = "Swipe test task"
        )
        var completedTask: Task? = null

        composeTestRule.setContent {
            TaskTrackerTheme {
                TaskItemComponent(
                    task = task,
                    onTaskComplete = { completedTask = it }
                )
            }
        }

        // Perform swipe right gesture
        composeTestRule.onNodeWithText("Swipe test task")
            .performTouchInput {
                swipeRight()
            }

        // Verify the callback was called with the correct task
        assert(completedTask == task)
    }

    @Test
    fun taskItemComponent_displaysSwipeBackground() {
        val task = Task(
            id = "1",
            description = "Background test task"
        )

        composeTestRule.setContent {
            TaskTrackerTheme {
                TaskItemComponent(task = task)
            }
        }

        // The swipe background should contain a check icon (though it may not be visible until swiping)
        composeTestRule.onNodeWithContentDescription("Complete task").assertExists()
    }
}