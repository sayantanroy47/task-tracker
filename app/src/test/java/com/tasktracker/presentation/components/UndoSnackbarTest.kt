package com.tasktracker.presentation.components

import androidx.compose.ui.test.assertIsDisplayed
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.performClick
import androidx.test.ext.junit.runners.AndroidJUnit4
import com.tasktracker.domain.model.Task
import com.tasktracker.presentation.theme.TaskTrackerTheme
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith

@RunWith(AndroidJUnit4::class)
class UndoSnackbarTest {

    @get:Rule
    val composeTestRule = createComposeRule()

    @Test
    fun undoSnackbar_displaysTaskDescription() {
        val task = Task(
            id = "1",
            description = "Test task"
        )

        composeTestRule.setContent {
            TaskTrackerTheme {
                UndoSnackbar(
                    task = task,
                    onUndo = {},
                    onDismiss = {}
                )
            }
        }

        composeTestRule.onNodeWithText("Task \"Test task\" completed").assertIsDisplayed()
    }

    @Test
    fun undoSnackbar_displaysUndoButton() {
        val task = Task(id = "1", description = "Test task")

        composeTestRule.setContent {
            TaskTrackerTheme {
                UndoSnackbar(
                    task = task,
                    onUndo = {},
                    onDismiss = {}
                )
            }
        }

        composeTestRule.onNodeWithText("UNDO").assertIsDisplayed()
    }

    @Test
    fun undoSnackbar_displaysDismissButton() {
        val task = Task(id = "1", description = "Test task")

        composeTestRule.setContent {
            TaskTrackerTheme {
                UndoSnackbar(
                    task = task,
                    onUndo = {},
                    onDismiss = {}
                )
            }
        }

        composeTestRule.onNodeWithText("DISMISS").assertIsDisplayed()
    }

    @Test
    fun undoSnackbar_callsOnUndoWhenUndoButtonClicked() {
        val task = Task(id = "1", description = "Test task")
        var undoCalled = false

        composeTestRule.setContent {
            TaskTrackerTheme {
                UndoSnackbar(
                    task = task,
                    onUndo = { undoCalled = true },
                    onDismiss = {}
                )
            }
        }

        composeTestRule.onNodeWithText("UNDO").performClick()

        assert(undoCalled) { "onUndo callback should be called when UNDO button is clicked" }
    }

    @Test
    fun undoSnackbar_callsOnDismissWhenDismissButtonClicked() {
        val task = Task(id = "1", description = "Test task")
        var dismissCalled = false

        composeTestRule.setContent {
            TaskTrackerTheme {
                UndoSnackbar(
                    task = task,
                    onUndo = {},
                    onDismiss = { dismissCalled = true }
                )
            }
        }

        composeTestRule.onNodeWithText("DISMISS").performClick()

        assert(dismissCalled) { "onDismiss callback should be called when DISMISS button is clicked" }
    }

    @Test
    fun undoSnackbar_truncatesLongTaskDescription() {
        val task = Task(
            id = "1",
            description = "This is a very long task description that should be truncated in the snackbar display"
        )

        composeTestRule.setContent {
            TaskTrackerTheme {
                UndoSnackbar(
                    task = task,
                    onUndo = {},
                    onDismiss = {}
                )
            }
        }

        // The text should be displayed (even if truncated)
        composeTestRule.onNodeWithText("Task \"${task.description}\" completed", substring = true)
            .assertIsDisplayed()
    }
}