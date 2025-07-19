package com.tasktracker.presentation.components

import androidx.compose.ui.test.*
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.test.ext.junit.runners.AndroidJUnit4
import com.tasktracker.domain.model.RecurrenceType
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith

/**
 * Unit tests for TaskInputComponent
 */
@RunWith(AndroidJUnit4::class)
class TaskInputComponentTest {

    @get:Rule
    val composeTestRule = createComposeRule()

    @Test
    fun taskInputComponent_displaysCorrectly() {
        // Given
        var createdTask: String? = null
        
        // When
        composeTestRule.setContent {
            TaskInputComponent(
                onCreateTask = { description -> createdTask = description }
            )
        }

        // Then
        composeTestRule
            .onNodeWithContentDescription("Task input field")
            .assertIsDisplayed()

        composeTestRule
            .onNodeWithContentDescription("Add task")
            .assertIsDisplayed()
    }

    @Test
    fun taskInputComponent_createsTaskOnSubmit() {
        // Given
        var createdTask: String? = null
        val taskDescription = "Test task"
        
        composeTestRule.setContent {
            TaskInputComponent(
                onCreateTask = { description -> createdTask = description }
            )
        }

        // When
        composeTestRule
            .onNodeWithContentDescription("Task input field")
            .performTextInput(taskDescription)

        composeTestRule
            .onNodeWithContentDescription("Add task")
            .performClick()

        // Then
        assert(createdTask == taskDescription)
    }

    @Test
    fun taskInputComponent_showsErrorMessage() {
        // Given
        val errorMessage = "Task description is required"
        
        composeTestRule.setContent {
            TaskInputComponent(
                inputError = errorMessage
            )
        }

        // Then
        composeTestRule
            .onNodeWithText(errorMessage)
            .assertIsDisplayed()
    }

    @Test
    fun taskInputComponent_showsTaskCreatedFeedback() {
        // Given
        composeTestRule.setContent {
            TaskInputComponent(
                showTaskCreatedFeedback = true
            )
        }

        // Then
        composeTestRule
            .onNodeWithText("Task created successfully!")
            .assertIsDisplayed()
    }

    @Test
    fun taskInputComponent_clearsInputAfterCreation() {
        // Given
        var createdTask: String? = null
        val taskDescription = "Test task"
        
        composeTestRule.setContent {
            TaskInputComponent(
                onCreateTask = { description -> createdTask = description }
            )
        }

        // When
        composeTestRule
            .onNodeWithContentDescription("Task input field")
            .performTextInput(taskDescription)

        composeTestRule
            .onNodeWithContentDescription("Add task")
            .performClick()

        // Then
        composeTestRule
            .onNodeWithContentDescription("Task input field")
            .assertTextEquals("")
    }

    @Test
    fun taskInputComponent_handlesReminderSelection() {
        // Given
        var taskWithReminder: Pair<String, Long?>? = null
        
        composeTestRule.setContent {
            TaskInputComponent(
                onCreateTaskWithReminder = { description, reminderTime -> 
                    taskWithReminder = description to reminderTime 
                }
            )
        }

        // When
        composeTestRule
            .onNodeWithContentDescription("Task input field")
            .performTextInput("Task with reminder")

        composeTestRule
            .onNodeWithContentDescription("Set reminder")
            .performClick()

        // Select reminder time (assuming picker is displayed)
        composeTestRule
            .onNodeWithText("1 hour")
            .performClick()

        composeTestRule
            .onNodeWithText("Set Reminder")
            .performClick()

        composeTestRule
            .onNodeWithContentDescription("Add task")
            .performClick()

        // Then
        assert(taskWithReminder != null)
        assert(taskWithReminder!!.first == "Task with reminder")
        assert(taskWithReminder!!.second != null)
    }

    @Test
    fun taskInputComponent_handlesRecurrenceSelection() {
        // Given
        var taskWithRecurrence: Triple<String, Long?, RecurrenceType?>? = null
        
        composeTestRule.setContent {
            TaskInputComponent(
                onCreateTaskWithRecurrence = { description, reminderTime, recurrenceType -> 
                    taskWithRecurrence = Triple(description, reminderTime, recurrenceType)
                }
            )
        }

        // When
        composeTestRule
            .onNodeWithContentDescription("Task input field")
            .performTextInput("Recurring task")

        composeTestRule
            .onNodeWithContentDescription("Set recurrence")
            .performClick()

        composeTestRule
            .onNodeWithText("Daily")
            .performClick()

        composeTestRule
            .onNodeWithText("Set Recurrence")
            .performClick()

        composeTestRule
            .onNodeWithContentDescription("Add task")
            .performClick()

        // Then
        assert(taskWithRecurrence != null)
        assert(taskWithRecurrence!!.first == "Recurring task")
        assert(taskWithRecurrence!!.third == RecurrenceType.DAILY)
    }

    @Test
    fun taskInputComponent_preventsEmptyTaskCreation() {
        // Given
        var createdTask: String? = null
        var errorCleared = false
        
        composeTestRule.setContent {
            TaskInputComponent(
                onCreateTask = { description -> createdTask = description },
                onClearInputError = { errorCleared = true }
            )
        }

        // When - Try to create empty task
        composeTestRule
            .onNodeWithContentDescription("Add task")
            .performClick()

        // Then - Should not create task
        assert(createdTask == null)
    }

    @Test
    fun taskInputComponent_handlesVoiceInput() {
        // Given
        var createdTask: String? = null
        
        composeTestRule.setContent {
            TaskInputComponent(
                onCreateTask = { description -> createdTask = description }
            )
        }

        // When
        composeTestRule
            .onNodeWithContentDescription("Voice input")
            .performClick()

        // Simulate voice input result
        composeTestRule
            .onNodeWithContentDescription("Task input field")
            .performTextInput("Voice input task")

        composeTestRule
            .onNodeWithContentDescription("Add task")
            .performClick()

        // Then
        assert(createdTask == "Voice input task")
    }

    @Test
    fun taskInputComponent_showsInputValidation() {
        // Given
        composeTestRule.setContent {
            TaskInputComponent()
        }

        // When - Input very long text
        val longText = "a".repeat(1000)
        composeTestRule
            .onNodeWithContentDescription("Task input field")
            .performTextInput(longText)

        // Then - Should show validation message
        composeTestRule
            .onNodeWithText("Task description is too long")
            .assertIsDisplayed()
    }
}