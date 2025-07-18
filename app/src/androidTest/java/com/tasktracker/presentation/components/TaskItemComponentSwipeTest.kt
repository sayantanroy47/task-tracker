package com.tasktracker.presentation.components

import androidx.compose.ui.test.assertIsDisplayed
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.compose.ui.test.onNodeWithContentDescription
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.performTouchInput
import androidx.compose.ui.test.swipeRight
import androidx.test.ext.junit.runners.AndroidJUnit4
import com.tasktracker.domain.model.Task
import com.tasktracker.presentation.theme.TaskTrackerTheme
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith

@RunWith(AndroidJUnit4::class)
class TaskItemComponentSwipeTest {

    @get:Rule
    val composeTestRule = createComposeRule()

    @Test
    fun taskItemComponent_swipeRightTriggersCompletion() {
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

        // Verify task is displayed
        composeTestRule.onNodeWithText("Swipe test task").assertIsDisplayed()

        // Perform swipe right gesture
        composeTestRule.onNodeWithText("Swipe test task")
            .performTouchInput {
                swipeRight()
            }

        // Wait for the swipe animation to complete
        composeTestRule.waitForIdle()

        // Verify the callback was called with the correct task
        assert(completedTask == task) {
            "Expected task to be completed, but callback was not called"
        }
    }

    @Test
    fun taskItemComponent_displaysSwipeBackgroundIcon() {
        val task = Task(
            id = "1",
            description = "Background test task"
        )

        composeTestRule.setContent {
            TaskTrackerTheme {
                TaskItemComponent(task = task)
            }
        }

        // The check icon should exist in the swipe background
        composeTestRule.onNodeWithContentDescription("Complete task").assertExists()
    }

    @Test
    fun taskItemComponent_swipeBackgroundAppearsOnSwipe() {
        val task = Task(
            id = "1",
            description = "Swipe background test"
        )

        composeTestRule.setContent {
            TaskTrackerTheme {
                TaskItemComponent(task = task)
            }
        }

        // Start swiping to reveal background
        composeTestRule.onNodeWithText("Swipe background test")
            .performTouchInput {
                // Perform partial swipe to reveal background without completing
                swipeRight(endX = centerX + 100f)
            }

        // The background should be visible during swipe
        composeTestRule.onNodeWithContentDescription("Complete task").assertIsDisplayed()
    }
}