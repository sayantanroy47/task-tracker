package com.tasktracker.presentation.components

import androidx.compose.ui.test.assertIsDisplayed
import androidx.compose.ui.test.assertIsEnabled
import androidx.compose.ui.test.assertIsNotEnabled
import androidx.compose.ui.test.assertTextContains
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.compose.ui.test.onNodeWithContentDescription
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.performClick
import androidx.compose.ui.test.performTextInput
import androidx.test.ext.junit.runners.AndroidJUnit4
import com.tasktracker.presentation.theme.TaskTrackerTheme
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith

@RunWith(AndroidJUnit4::class)
class TaskInputComponentTest {

    @get:Rule
    val composeTestRule = createComposeRule()

    @Test
    fun taskInputComponent_displaysCorrectly() {
        composeTestRule.setContent {
            TaskTrackerTheme {
                TaskInputComponent()
            }
        }

        // Verify input field is displayed
        composeTestRule.onNodeWithText("Add new task...").assertIsDisplayed()
        
        // Verify add button is displayed but disabled initially
        composeTestRule.onNodeWithContentDescription("Create task").assertIsDisplayed()
        composeTestRule.onNodeWithContentDescription("Create task").assertIsNotEnabled()
    }

    @Test
    fun taskInputComponent_enablesButtonWhenTextEntered() {
        composeTestRule.setContent {
            TaskTrackerTheme {
                TaskInputComponent()
            }
        }

        // Enter text in the input field
        composeTestRule.onNodeWithText("Add new task...")
            .performTextInput("Test task")

        // Verify button is now enabled
        composeTestRule.onNodeWithContentDescription("Create task").assertIsEnabled()
    }

    @Test
    fun taskInputComponent_callsOnCreateTaskWhenButtonClicked() {
        var createdTask = ""
        
        composeTestRule.setContent {
            TaskTrackerTheme {
                TaskInputComponent(
                    onCreateTask = { task -> createdTask = task }
                )
            }
        }

        // Enter text and click button
        composeTestRule.onNodeWithText("Add new task...")
            .performTextInput("Test task")
        
        composeTestRule.onNodeWithContentDescription("Create task")
            .performClick()

        // Verify callback was called with correct text
        assert(createdTask == "Test task")
    }

    @Test
    fun taskInputComponent_displaysInputError() {
        composeTestRule.setContent {
            TaskTrackerTheme {
                TaskInputComponent(
                    inputError = "Task description cannot be empty"
                )
            }
        }

        // Verify error message is displayed
        composeTestRule.onNodeWithText("Task description cannot be empty")
            .assertIsDisplayed()
    }

    @Test
    fun taskInputComponent_displaysSuccessFeedback() {
        composeTestRule.setContent {
            TaskTrackerTheme {
                TaskInputComponent(
                    showTaskCreatedFeedback = true
                )
            }
        }

        // Verify success message is displayed
        composeTestRule.onNodeWithText("Task created successfully!")
            .assertIsDisplayed()
        
        // Verify success icon is displayed
        composeTestRule.onNodeWithContentDescription("Task created")
            .assertIsDisplayed()
    }

    @Test
    fun taskInputComponent_clearsErrorWhenUserTypes() {
        var errorCleared = false
        
        composeTestRule.setContent {
            TaskTrackerTheme {
                TaskInputComponent(
                    inputError = "Task description cannot be empty",
                    onClearInputError = { errorCleared = true }
                )
            }
        }

        // Type in the input field
        composeTestRule.onNodeWithText("Add new task...")
            .performTextInput("Test")

        // Verify error clear callback was called
        assert(errorCleared)
    }

    @Test
    fun taskInputComponent_doesNotCallOnCreateTaskForEmptyInput() {
        var taskCreated = false
        
        composeTestRule.setContent {
            TaskTrackerTheme {
                TaskInputComponent(
                    onCreateTask = { taskCreated = true }
                )
            }
        }

        // Try to click button without entering text (should be disabled)
        composeTestRule.onNodeWithContentDescription("Create task")
            .assertIsNotEnabled()

        // Verify callback was not called
        assert(!taskCreated)
    }

    @Test
    fun taskInputComponent_trimsWhitespaceFromInput() {
        var createdTask = ""
        
        composeTestRule.setContent {
            TaskTrackerTheme {
                TaskInputComponent(
                    onCreateTask = { task -> createdTask = task }
                )
            }
        }

        // Enter text with whitespace
        composeTestRule.onNodeWithText("Add new task...")
            .performTextInput("  Test task  ")
        
        composeTestRule.onNodeWithContentDescription("Create task")
            .performClick()

        // Verify whitespace was trimmed
        assert(createdTask == "Test task")
    }
}