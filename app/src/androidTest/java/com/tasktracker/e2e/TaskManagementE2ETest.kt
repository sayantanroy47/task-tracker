package com.tasktracker.e2e

import androidx.compose.ui.test.*
import androidx.compose.ui.test.junit4.createAndroidComposeRule
import androidx.test.ext.junit.runners.AndroidJUnit4
import com.tasktracker.presentation.MainActivity
import dagger.hilt.android.testing.HiltAndroidRule
import dagger.hilt.android.testing.HiltAndroidTest
import org.junit.Before
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith

/**
 * End-to-End tests for task management functionality
 */
@HiltAndroidTest
@RunWith(AndroidJUnit4::class)
class TaskManagementE2ETest {

    @get:Rule(order = 0)
    val hiltRule = HiltAndroidRule(this)

    @get:Rule(order = 1)
    val composeTestRule = createAndroidComposeRule<MainActivity>()

    @Before
    fun setup() {
        hiltRule.inject()
    }

    @Test
    fun createAndCompleteTaskFlow() {
        // Given - App is launched and main screen is visible
        composeTestRule.waitForIdle()

        // When - User creates a new task
        val taskDescription = "Buy groceries for dinner"
        
        // Find and interact with task input field
        composeTestRule
            .onNodeWithContentDescription("Task input field")
            .performTextInput(taskDescription)

        // Click add task button
        composeTestRule
            .onNodeWithContentDescription("Add task")
            .performClick()

        // Then - Task should appear in the list
        composeTestRule
            .onNodeWithText(taskDescription)
            .assertIsDisplayed()

        // When - User completes the task
        composeTestRule
            .onNodeWithText(taskDescription)
            .performClick()

        // Then - Task should be marked as completed
        composeTestRule
            .onNodeWithContentDescription("Completed task: $taskDescription")
            .assertIsDisplayed()
    }

    @Test
    fun createTaskWithReminderFlow() {
        composeTestRule.waitForIdle()

        // When - User creates a task with reminder
        val taskDescription = "Call dentist appointment"
        
        composeTestRule
            .onNodeWithContentDescription("Task input field")
            .performTextInput(taskDescription)

        // Open reminder picker
        composeTestRule
            .onNodeWithContentDescription("Set reminder")
            .performClick()

        // Select a reminder time (assuming time picker is displayed)
        composeTestRule
            .onNodeWithText("1 hour")
            .performClick()

        // Confirm reminder
        composeTestRule
            .onNodeWithText("Set Reminder")
            .performClick()

        // Add the task
        composeTestRule
            .onNodeWithContentDescription("Add task")
            .performClick()

        // Then - Task with reminder should be created
        composeTestRule
            .onNodeWithText(taskDescription)
            .assertIsDisplayed()

        composeTestRule
            .onNodeWithContentDescription("Has reminder")
            .assertIsDisplayed()
    }

    @Test
    fun createRecurringTaskFlow() {
        composeTestRule.waitForIdle()

        // When - User creates a recurring task
        val taskDescription = "Daily exercise routine"
        
        composeTestRule
            .onNodeWithContentDescription("Task input field")
            .performTextInput(taskDescription)

        // Open recurrence picker
        composeTestRule
            .onNodeWithContentDescription("Set recurrence")
            .performClick()

        // Select daily recurrence
        composeTestRule
            .onNodeWithText("Daily")
            .performClick()

        // Confirm recurrence
        composeTestRule
            .onNodeWithText("Set Recurrence")
            .performClick()

        // Add the task
        composeTestRule
            .onNodeWithContentDescription("Add task")
            .performClick()

        // Then - Recurring task should be created
        composeTestRule
            .onNodeWithText(taskDescription)
            .assertIsDisplayed()

        composeTestRule
            .onNodeWithContentDescription("Recurring task")
            .assertIsDisplayed()
    }

    @Test
    fun filterTasksFlow() {
        composeTestRule.waitForIdle()

        // Given - Create some tasks (active and completed)
        val activeTasks = listOf("Active task 1", "Active task 2")
        val completedTasks = listOf("Completed task 1")

        // Create active tasks
        activeTasks.forEach { taskDescription ->
            composeTestRule
                .onNodeWithContentDescription("Task input field")
                .performTextClearance()
            
            composeTestRule
                .onNodeWithContentDescription("Task input field")
                .performTextInput(taskDescription)
            
            composeTestRule
                .onNodeWithContentDescription("Add task")
                .performClick()
        }

        // Create and complete a task
        composeTestRule
            .onNodeWithContentDescription("Task input field")
            .performTextClearance()
        
        composeTestRule
            .onNodeWithContentDescription("Task input field")
            .performTextInput(completedTasks[0])
        
        composeTestRule
            .onNodeWithContentDescription("Add task")
            .performClick()
        
        composeTestRule
            .onNodeWithText(completedTasks[0])
            .performClick() // Complete the task

        // When - Filter by active tasks
        composeTestRule
            .onNodeWithText("Active")
            .performClick()

        // Then - Only active tasks should be visible
        activeTasks.forEach { taskDescription ->
            composeTestRule
                .onNodeWithText(taskDescription)
                .assertIsDisplayed()
        }

        // Completed task should not be visible
        composeTestRule
            .onNodeWithText(completedTasks[0])
            .assertDoesNotExist()

        // When - Filter by completed tasks
        composeTestRule
            .onNodeWithText("Completed")
            .performClick()

        // Then - Only completed tasks should be visible
        composeTestRule
            .onNodeWithText(completedTasks[0])
            .assertIsDisplayed()

        // Active tasks should not be visible
        activeTasks.forEach { taskDescription ->
            composeTestRule
                .onNodeWithText(taskDescription)
                .assertDoesNotExist()
        }

        // When - Show all tasks
        composeTestRule
            .onNodeWithText("All")
            .performClick()

        // Then - All tasks should be visible
        (activeTasks + completedTasks).forEach { taskDescription ->
            composeTestRule
                .onNodeWithText(taskDescription)
                .assertIsDisplayed()
        }
    }

    @Test
    fun searchTasksFlow() {
        composeTestRule.waitForIdle()

        // Given - Create tasks with different descriptions
        val tasks = listOf(
            "Buy groceries",
            "Call dentist",
            "Buy birthday gift",
            "Schedule meeting"
        )

        tasks.forEach { taskDescription ->
            composeTestRule
                .onNodeWithContentDescription("Task input field")
                .performTextClearance()
            
            composeTestRule
                .onNodeWithContentDescription("Task input field")
                .performTextInput(taskDescription)
            
            composeTestRule
                .onNodeWithContentDescription("Add task")
                .performClick()
        }

        // When - Search for tasks containing "buy"
        composeTestRule
            .onNodeWithContentDescription("Search tasks")
            .performTextInput("buy")

        // Then - Only tasks containing "buy" should be visible
        composeTestRule
            .onNodeWithText("Buy groceries")
            .assertIsDisplayed()
        
        composeTestRule
            .onNodeWithText("Buy birthday gift")
            .assertIsDisplayed()

        // Tasks not containing "buy" should not be visible
        composeTestRule
            .onNodeWithText("Call dentist")
            .assertDoesNotExist()
        
        composeTestRule
            .onNodeWithText("Schedule meeting")
            .assertDoesNotExist()

        // When - Clear search
        composeTestRule
            .onNodeWithContentDescription("Clear search")
            .performClick()

        // Then - All tasks should be visible again
        tasks.forEach { taskDescription ->
            composeTestRule
                .onNodeWithText(taskDescription)
                .assertIsDisplayed()
        }
    }

    @Test
    fun deleteTaskFlow() {
        composeTestRule.waitForIdle()

        // Given - Create a task
        val taskDescription = "Task to be deleted"
        
        composeTestRule
            .onNodeWithContentDescription("Task input field")
            .performTextInput(taskDescription)
        
        composeTestRule
            .onNodeWithContentDescription("Add task")
            .performClick()

        // Verify task exists
        composeTestRule
            .onNodeWithText(taskDescription)
            .assertIsDisplayed()

        // When - Delete the task (long press or swipe)
        composeTestRule
            .onNodeWithText(taskDescription)
            .performTouchInput { swipeLeft() }

        // Confirm deletion if dialog appears
        composeTestRule
            .onNodeWithText("Delete")
            .performClick()

        // Then - Task should be removed
        composeTestRule
            .onNodeWithText(taskDescription)
            .assertDoesNotExist()
    }

    @Test
    fun navigationBetweenScreensFlow() {
        composeTestRule.waitForIdle()

        // Given - App starts on main screen
        composeTestRule
            .onNodeWithContentDescription("Tasks")
            .assertIsDisplayed()

        // When - Navigate to Analytics screen
        composeTestRule
            .onNodeWithText("Analytics")
            .performClick()

        // Then - Analytics screen should be displayed
        composeTestRule
            .onNodeWithContentDescription("Analytics screen")
            .assertIsDisplayed()

        // When - Navigate to Profile screen
        composeTestRule
            .onNodeWithText("Profile")
            .performClick()

        // Then - Profile screen should be displayed
        composeTestRule
            .onNodeWithContentDescription("Profile screen")
            .assertIsDisplayed()

        // When - Navigate to Focus screen
        composeTestRule
            .onNodeWithText("Focus")
            .performClick()

        // Then - Focus screen should be displayed
        composeTestRule
            .onNodeWithContentDescription("Focus screen")
            .assertIsDisplayed()

        // When - Navigate back to Tasks screen
        composeTestRule
            .onNodeWithText("Tasks")
            .performClick()

        // Then - Tasks screen should be displayed
        composeTestRule
            .onNodeWithContentDescription("Tasks")
            .assertIsDisplayed()
    }

    @Test
    fun taskPersistenceAcrossAppRestartFlow() {
        composeTestRule.waitForIdle()

        // Given - Create a task
        val taskDescription = "Persistent task"
        
        composeTestRule
            .onNodeWithContentDescription("Task input field")
            .performTextInput(taskDescription)
        
        composeTestRule
            .onNodeWithContentDescription("Add task")
            .performClick()

        // Verify task is created
        composeTestRule
            .onNodeWithText(taskDescription)
            .assertIsDisplayed()

        // When - Simulate app restart by recreating activity
        composeTestRule.activityRule.scenario.recreate()
        composeTestRule.waitForIdle()

        // Then - Task should still be visible after restart
        composeTestRule
            .onNodeWithText(taskDescription)
            .assertIsDisplayed()
    }

    @Test
    fun errorHandlingFlow() {
        composeTestRule.waitForIdle()

        // When - Try to create task with empty description
        composeTestRule
            .onNodeWithContentDescription("Add task")
            .performClick()

        // Then - Error message should be displayed
        composeTestRule
            .onNodeWithText("Task description cannot be empty")
            .assertIsDisplayed()

        // When - Dismiss error
        composeTestRule
            .onNodeWithContentDescription("Dismiss error")
            .performClick()

        // Then - Error should be dismissed
        composeTestRule
            .onNodeWithText("Task description cannot be empty")
            .assertDoesNotExist()
    }
}