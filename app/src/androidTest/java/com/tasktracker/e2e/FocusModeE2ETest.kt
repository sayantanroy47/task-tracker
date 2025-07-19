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
 * End-to-End tests for Focus Mode functionality
 */
@HiltAndroidTest
@RunWith(AndroidJUnit4::class)
class FocusModeE2ETest {

    @get:Rule(order = 0)
    val hiltRule = HiltAndroidRule(this)

    @get:Rule(order = 1)
    val composeTestRule = createAndroidComposeRule<MainActivity>()

    @Before
    fun setup() {
        hiltRule.inject()
    }

    @Test
    fun startPomodoroFocusSessionFlow() {
        composeTestRule.waitForIdle()

        // Given - Navigate to Focus screen
        composeTestRule
            .onNodeWithText("Focus")
            .performClick()

        composeTestRule
            .onNodeWithContentDescription("Focus screen")
            .assertIsDisplayed()

        // When - Select Pomodoro mode
        composeTestRule
            .onNodeWithText("Pomodoro")
            .performClick()

        // Start focus session
        composeTestRule
            .onNodeWithContentDescription("Start focus session")
            .performClick()

        // Then - Focus session should be active
        composeTestRule
            .onNodeWithContentDescription("Focus timer")
            .assertIsDisplayed()

        composeTestRule
            .onNodeWithText("25:00")
            .assertIsDisplayed()

        // Focus session controls should be visible
        composeTestRule
            .onNodeWithContentDescription("Pause focus session")
            .assertIsDisplayed()

        composeTestRule
            .onNodeWithContentDescription("Stop focus session")
            .assertIsDisplayed()
    }

    @Test
    fun pauseAndResumeFocusSessionFlow() {
        composeTestRule.waitForIdle()

        // Given - Start a focus session
        composeTestRule
            .onNodeWithText("Focus")
            .performClick()

        composeTestRule
            .onNodeWithText("Pomodoro")
            .performClick()

        composeTestRule
            .onNodeWithContentDescription("Start focus session")
            .performClick()

        // When - Pause the session
        composeTestRule
            .onNodeWithContentDescription("Pause focus session")
            .performClick()

        // Then - Session should be paused
        composeTestRule
            .onNodeWithContentDescription("Resume focus session")
            .assertIsDisplayed()

        composeTestRule
            .onNodeWithText("Paused")
            .assertIsDisplayed()

        // When - Resume the session
        composeTestRule
            .onNodeWithContentDescription("Resume focus session")
            .performClick()

        // Then - Session should be active again
        composeTestRule
            .onNodeWithContentDescription("Pause focus session")
            .assertIsDisplayed()

        composeTestRule
            .onNodeWithText("Paused")
            .assertDoesNotExist()
    }

    @Test
    fun stopFocusSessionFlow() {
        composeTestRule.waitForIdle()

        // Given - Start a focus session
        composeTestRule
            .onNodeWithText("Focus")
            .performClick()

        composeTestRule
            .onNodeWithText("Deep Work")
            .performClick()

        composeTestRule
            .onNodeWithContentDescription("Start focus session")
            .performClick()

        // When - Stop the session
        composeTestRule
            .onNodeWithContentDescription("Stop focus session")
            .performClick()

        // Confirm stopping
        composeTestRule
            .onNodeWithText("Stop Session")
            .performClick()

        // Then - Session should be stopped
        composeTestRule
            .onNodeWithContentDescription("Start focus session")
            .assertIsDisplayed()

        composeTestRule
            .onNodeWithContentDescription("Focus timer")
            .assertDoesNotExist()
    }

    @Test
    fun focusModeSelectionFlow() {
        composeTestRule.waitForIdle()

        // Given - Navigate to Focus screen
        composeTestRule
            .onNodeWithText("Focus")
            .performClick()

        // When - Test different focus modes
        val focusModes = listOf("Pomodoro", "Deep Work", "Quick Focus")

        focusModes.forEach { mode ->
            // Select focus mode
            composeTestRule
                .onNodeWithText(mode)
                .performClick()

            // Verify mode is selected
            composeTestRule
                .onNodeWithText(mode)
                .assertIsSelected()

            // Verify mode-specific settings are displayed
            when (mode) {
                "Pomodoro" -> {
                    composeTestRule
                        .onNodeWithText("25 min work")
                        .assertIsDisplayed()
                    composeTestRule
                        .onNodeWithText("5 min break")
                        .assertIsDisplayed()
                }
                "Deep Work" -> {
                    composeTestRule
                        .onNodeWithText("90 min focus")
                        .assertIsDisplayed()
                }
                "Quick Focus" -> {
                    composeTestRule
                        .onNodeWithText("15 min focus")
                        .assertIsDisplayed()
                }
            }
        }
    }

    @Test
    fun focusSessionWithTasksFlow() {
        composeTestRule.waitForIdle()

        // Given - Create some tasks first
        composeTestRule
            .onNodeWithText("Tasks")
            .performClick()

        val tasks = listOf("Focus task 1", "Focus task 2", "Focus task 3")
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

        // Navigate to Focus screen
        composeTestRule
            .onNodeWithText("Focus")
            .performClick()

        // When - Start focus session
        composeTestRule
            .onNodeWithText("Pomodoro")
            .performClick()

        composeTestRule
            .onNodeWithContentDescription("Start focus session")
            .performClick()

        // Then - Available tasks should be displayed
        composeTestRule
            .onNodeWithText("Available Tasks")
            .assertIsDisplayed()

        tasks.forEach { taskDescription ->
            composeTestRule
                .onNodeWithText(taskDescription)
                .assertIsDisplayed()
        }

        // When - Complete a task during focus session
        composeTestRule
            .onNodeWithText(tasks[0])
            .performClick()

        // Then - Task should be marked as completed
        composeTestRule
            .onNodeWithContentDescription("Completed: ${tasks[0]}")
            .assertIsDisplayed()
    }

    @Test
    fun breakTimeFlow() {
        composeTestRule.waitForIdle()

        // Given - Navigate to Focus screen and start Pomodoro
        composeTestRule
            .onNodeWithText("Focus")
            .performClick()

        composeTestRule
            .onNodeWithText("Pomodoro")
            .performClick()

        composeTestRule
            .onNodeWithContentDescription("Start focus session")
            .performClick()

        // When - Simulate focus session completion (skip to end)
        composeTestRule
            .onNodeWithContentDescription("Skip to break")
            .performClick()

        // Then - Break timer should start
        composeTestRule
            .onNodeWithText("Break Time!")
            .assertIsDisplayed()

        composeTestRule
            .onNodeWithText("5:00")
            .assertIsDisplayed()

        composeTestRule
            .onNodeWithContentDescription("Break timer")
            .assertIsDisplayed()

        // Break controls should be available
        composeTestRule
            .onNodeWithContentDescription("Skip break")
            .assertIsDisplayed()

        composeTestRule
            .onNodeWithContentDescription("End break")
            .assertIsDisplayed()
    }

    @Test
    fun focusStatisticsFlow() {
        composeTestRule.waitForIdle()

        // Given - Complete a focus session
        composeTestRule
            .onNodeWithText("Focus")
            .performClick()

        composeTestRule
            .onNodeWithText("Quick Focus")
            .performClick()

        composeTestRule
            .onNodeWithContentDescription("Start focus session")
            .performClick()

        // Skip to end of session
        composeTestRule
            .onNodeWithContentDescription("Skip to end")
            .performClick()

        // When - Check focus statistics
        composeTestRule
            .onNodeWithText("Statistics")
            .performClick()

        // Then - Focus statistics should be displayed
        composeTestRule
            .onNodeWithText("Total Focus Time")
            .assertIsDisplayed()

        composeTestRule
            .onNodeWithText("Sessions Completed")
            .assertIsDisplayed()

        composeTestRule
            .onNodeWithText("Average Session Length")
            .assertIsDisplayed()

        // Statistics should show the completed session
        composeTestRule
            .onNodeWithText("1")
            .assertIsDisplayed() // Sessions completed
    }

    @Test
    fun distractionTrackingFlow() {
        composeTestRule.waitForIdle()

        // Given - Start a focus session
        composeTestRule
            .onNodeWithText("Focus")
            .performClick()

        composeTestRule
            .onNodeWithText("Deep Work")
            .performClick()

        composeTestRule
            .onNodeWithContentDescription("Start focus session")
            .performClick()

        // When - Record a distraction
        composeTestRule
            .onNodeWithContentDescription("Record distraction")
            .performClick()

        // Select distraction type
        composeTestRule
            .onNodeWithText("Phone notification")
            .performClick()

        composeTestRule
            .onNodeWithText("Record")
            .performClick()

        // Then - Distraction should be recorded
        composeTestRule
            .onNodeWithText("Distractions: 1")
            .assertIsDisplayed()

        // When - Record another distraction
        composeTestRule
            .onNodeWithContentDescription("Record distraction")
            .performClick()

        composeTestRule
            .onNodeWithText("Social media")
            .performClick()

        composeTestRule
            .onNodeWithText("Record")
            .performClick()

        // Then - Distraction count should increase
        composeTestRule
            .onNodeWithText("Distractions: 2")
            .assertIsDisplayed()
    }

    @Test
    fun focusSessionNotificationsFlow() {
        composeTestRule.waitForIdle()

        // Given - Start a focus session
        composeTestRule
            .onNodeWithText("Focus")
            .performClick()

        composeTestRule
            .onNodeWithText("Pomodoro")
            .performClick()

        composeTestRule
            .onNodeWithContentDescription("Start focus session")
            .performClick()

        // When - Minimize app (simulate going to background)
        composeTestRule.activityRule.scenario.moveToState(
            androidx.lifecycle.Lifecycle.State.STARTED
        )

        // Wait for notification to appear (simulated)
        Thread.sleep(1000)

        // When - Return to app
        composeTestRule.activityRule.scenario.moveToState(
            androidx.lifecycle.Lifecycle.State.RESUMED
        )

        // Then - Focus session should still be running
        composeTestRule
            .onNodeWithContentDescription("Focus timer")
            .assertIsDisplayed()

        composeTestRule
            .onNodeWithContentDescription("Pause focus session")
            .assertIsDisplayed()
    }

    @Test
    fun customFocusTimerFlow() {
        composeTestRule.waitForIdle()

        // Given - Navigate to Focus screen
        composeTestRule
            .onNodeWithText("Focus")
            .performClick()

        // When - Open custom timer settings
        composeTestRule
            .onNodeWithContentDescription("Custom timer")
            .performClick()

        // Set custom duration
        composeTestRule
            .onNodeWithContentDescription("Focus duration")
            .performTextClearance()

        composeTestRule
            .onNodeWithContentDescription("Focus duration")
            .performTextInput("30")

        composeTestRule
            .onNodeWithText("Start Custom Session")
            .performClick()

        // Then - Custom focus session should start
        composeTestRule
            .onNodeWithText("30:00")
            .assertIsDisplayed()

        composeTestRule
            .onNodeWithContentDescription("Focus timer")
            .assertIsDisplayed()
    }
}