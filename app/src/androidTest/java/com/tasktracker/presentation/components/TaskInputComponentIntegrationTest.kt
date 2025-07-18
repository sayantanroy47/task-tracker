package com.tasktracker.presentation.components

import androidx.compose.ui.test.assertIsDisplayed
import androidx.compose.ui.test.assertIsEnabled
import androidx.compose.ui.test.assertIsNotEnabled
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.compose.ui.test.onNodeWithContentDescription
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.performClick
import androidx.compose.ui.test.performImeAction
import androidx.compose.ui.test.performTextInput
import androidx.test.ext.junit.runners.AndroidJUnit4
import com.tasktracker.presentation.theme.TaskTrackerTheme
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith

@RunWith(AndroidJUnit4::class)
class TaskInputComponentIntegrationTest {

    @get:Rule
    val composeTestRule = createComposeRule()

    @Test
    fun taskInputComponent_completeTaskCreationFlow() {
        var createdTask = ""
        var feedbackCleared = false
        
        composeTestRule.setContent {
            TaskTrackerTheme {
                TaskInputComponent(
                    onCreateTask = { task -> createdTask = task },
                    onClearTaskCreatedFeedback = { feedbackCleared = true }
                )
            }
        }

        // Step 1: Verify initial state
        composeTestRule.onNodeWithText("Add new task...").assertIsDisplayed()
        composeTestRule.onNodeWithContentDescription("Create task").assertIsNotEnabled()

        // Step 2: Enter task description
        composeTestRule.onNodeWithText("Add new task...")
            .performTextInput("Buy groceries")

        // Step 3: Verify button is enabled
        composeTestRule.onNodeWithContentDescription("Create task").assertIsEnabled()

        // Step 4: Create task by clicking button
        composeTestRule.onNodeWithContentDescription("Create task")
            .performClick()

        // Step 5: Verify task was created
        assert(createdTask == "Buy groceries")
    }

    @Test
    fun taskInputComponent_createTaskWithEnterKey() {
        var createdTask = ""
        
        composeTestRule.setContent {
            TaskTrackerTheme {
                TaskInputComponent(
                    onCreateTask = { task -> createdTask = task }
                )
            }
        }

        // Enter task description
        composeTestRule.onNodeWithText("Add new task...")
            .performTextInput("Complete project")

        // Press enter key
        composeTestRule.onNodeWithText("Complete project")
            .performImeAction()

        // Verify task was created
        assert(createdTask == "Complete project")
    }

    @Test
    fun taskInputComponent_errorHandlingFlow() {
        var errorCleared = false
        
        composeTestRule.setContent {
            TaskTrackerTheme {
                TaskInputComponent(
                    inputError = "Task description cannot be empty",
                    onClearInputError = { errorCleared = true }
                )
            }
        }

        // Verify error is displayed
        composeTestRule.onNodeWithText("Task description cannot be empty")
            .assertIsDisplayed()

        // Start typing to clear error
        composeTestRule.onNodeWithText("Add new task...")
            .performTextInput("New task")

        // Verify error clear callback was called
        assert(errorCleared)
    }

    @Test
    fun taskInputComponent_successFeedbackFlow() {
        composeTestRule.setContent {
            TaskTrackerTheme {
                TaskInputComponent(
                    showTaskCreatedFeedback = true
                )
            }
        }

        // Verify success feedback is displayed
        composeTestRule.onNodeWithText("Task created successfully!")
            .assertIsDisplayed()
        composeTestRule.onNodeWithContentDescription("Task created")
            .assertIsDisplayed()
    }

    @Test
    fun taskInputComponent_keyboardInteractions() {
        var createdTask = ""
        
        composeTestRule.setContent {
            TaskTrackerTheme {
                TaskInputComponent(
                    onCreateTask = { task -> createdTask = task }
                )
            }
        }

        // Test that input field accepts text input
        composeTestRule.onNodeWithText("Add new task...")
            .performTextInput("Test keyboard input")

        // Test IME action (Done/Enter key)
        composeTestRule.onNodeWithText("Test keyboard input")
            .performImeAction()

        // Verify task creation
        assert(createdTask == "Test keyboard input")
    }

    @Test
    fun taskInputComponent_focusManagement() {
        composeTestRule.setContent {
            TaskTrackerTheme {
                TaskInputComponent()
            }
        }

        // Verify input field can receive focus and text input
        composeTestRule.onNodeWithText("Add new task...")
            .performTextInput("Focus test")

        // Verify text was entered (input field maintained focus)
        composeTestRule.onNodeWithText("Focus test").assertIsDisplayed()
    }

    @Test
    fun taskInputComponent_visualFeedbackStates() {
        composeTestRule.setContent {
            TaskTrackerTheme {
                TaskInputComponent()
            }
        }

        // Test disabled state
        composeTestRule.onNodeWithContentDescription("Create task").assertIsNotEnabled()

        // Enter text to enable button
        composeTestRule.onNodeWithText("Add new task...")
            .performTextInput("Enable button test")

        // Test enabled state
        composeTestRule.onNodeWithContentDescription("Create task").assertIsEnabled()
    }
}