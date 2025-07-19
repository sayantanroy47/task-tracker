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
 * End-to-End tests for Analytics functionality
 */
@HiltAndroidTest
@RunWith(AndroidJUnit4::class)
class AnalyticsE2ETest {

    @get:Rule(order = 0)
    val hiltRule = HiltAndroidRule(this)

    @get:Rule(order = 1)
    val composeTestRule = createAndroidComposeRule<MainActivity>()

    @Before
    fun setup() {
        hiltRule.inject()
    }

    @Test
    fun viewTaskCompletionAnalyticsFlow() {
        composeTestRule.waitForIdle()

        // Given - Create and complete some tasks
        val tasks = listOf("Task 1", "Task 2", "Task 3")
        
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
            
            // Complete the task
            composeTestRule
                .onNodeWithText(taskDescription)
                .performClick()
        }

        // When - Navigate to Analytics screen
        composeTestRule
            .onNodeWithText("Analytics")
            .performClick()

        // Then - Analytics screen should display task completion data
        composeTestRule
            .onNodeWithContentDescription("Analytics screen")
            .assertIsDisplayed()

        composeTestRule
            .onNodeWithText("Tasks Completed")
            .assertIsDisplayed()

        composeTestRule
            .onNodeWithText("3")
            .assertIsDisplayed()

        // Completion rate should be displayed
        composeTestRule
            .onNodeWithText("Completion Rate")
            .assertIsDisplayed()

        composeTestRule
            .onNodeWithText("100%")
            .assertIsDisplayed()
    }

    @Test
    fun viewProductivityTrendsFlow() {
        composeTestRule.waitForIdle()

        // Given - Generate some activity data by creating tasks over time
        repeat(5) { i ->
            composeTestRule
                .onNodeWithContentDescription("Task input field")
                .performTextClearance()
            
            composeTestRule
                .onNodeWithContentDescription("Task input field")
                .performTextInput("Trend task $i")
            
            composeTestRule
                .onNodeWithContentDescription("Add task")
                .performClick()
            
            composeTestRule
                .onNodeWithText("Trend task $i")
                .performClick() // Complete task
        }

        // When - Navigate to Analytics and view trends
        composeTestRule
            .onNodeWithText("Analytics")
            .performClick()

        composeTestRule
            .onNodeWithText("Productivity Trends")
            .performClick()

        // Then - Productivity trends should be displayed
        composeTestRule
            .onNodeWithContentDescription("Productivity chart")
            .assertIsDisplayed()

        composeTestRule
            .onNodeWithText("Daily Average")
            .assertIsDisplayed()

        composeTestRule
            .onNodeWithText("Weekly Trend")
            .assertIsDisplayed()
    }

    @Test
    fun viewFocusTimeAnalyticsFlow() {
        composeTestRule.waitForIdle()

        // Given - Complete a focus session first
        composeTestRule
            .onNodeWithText("Focus")
            .performClick()

        composeTestRule
            .onNodeWithText("Pomodoro")
            .performClick()

        composeTestRule
            .onNodeWithContentDescription("Start focus session")
            .performClick()

        // Skip to end of session
        composeTestRule
            .onNodeWithContentDescription("Skip to end")
            .performClick()

        // When - Navigate to Analytics
        composeTestRule
            .onNodeWithText("Analytics")
            .performClick()

        composeTestRule
            .onNodeWithText("Focus Analytics")
            .performClick()

        // Then - Focus analytics should be displayed
        composeTestRule
            .onNodeWithText("Total Focus Time")
            .assertIsDisplayed()

        composeTestRule
            .onNodeWithText("Focus Sessions")
            .assertIsDisplayed()

        composeTestRule
            .onNodeWithText("Average Session")
            .assertIsDisplayed()

        // Should show the completed session data
        composeTestRule
            .onNodeWithText("25 min")
            .assertIsDisplayed()
    }

    @Test
    fun viewStreakAnalyticsFlow() {
        composeTestRule.waitForIdle()

        // Given - Create and complete tasks to build a streak
        repeat(3) { day ->
            composeTestRule
                .onNodeWithContentDescription("Task input field")
                .performTextClearance()
            
            composeTestRule
                .onNodeWithContentDescription("Task input field")
                .performTextInput("Daily task $day")
            
            composeTestRule
                .onNodeWithContentDescription("Add task")
                .performClick()
            
            composeTestRule
                .onNodeWithText("Daily task $day")
                .performClick()
        }

        // When - Navigate to Analytics
        composeTestRule
            .onNodeWithText("Analytics")
            .performClick()

        composeTestRule
            .onNodeWithText("Streaks")
            .performClick()

        // Then - Streak information should be displayed
        composeTestRule
            .onNodeWithText("Current Streak")
            .assertIsDisplayed()

        composeTestRule
            .onNodeWithText("Longest Streak")
            .assertIsDisplayed()

        composeTestRule
            .onNodeWithText("Streak Calendar")
            .assertIsDisplayed()

        // Should show current streak
        composeTestRule
            .onNodeWithText("1 day")
            .assertIsDisplayed()
    }

    @Test
    fun filterAnalyticsByTimeRangeFlow() {
        composeTestRule.waitForIdle()

        // Given - Create some historical data
        repeat(10) { i ->
            composeTestRule
                .onNodeWithContentDescription("Task input field")
                .performTextClearance()
            
            composeTestRule
                .onNodeWithContentDescription("Task input field")
                .performTextInput("Historical task $i")
            
            composeTestRule
                .onNodeWithContentDescription("Add task")
                .performClick()
            
            if (i % 2 == 0) {
                composeTestRule
                    .onNodeWithText("Historical task $i")
                    .performClick()
            }
        }

        // When - Navigate to Analytics
        composeTestRule
            .onNodeWithText("Analytics")
            .performClick()

        // Test different time range filters
        val timeRanges = listOf("Today", "This Week", "This Month", "All Time")

        timeRanges.forEach { range ->
            // Select time range
            composeTestRule
                .onNodeWithContentDescription("Time range selector")
                .performClick()

            composeTestRule
                .onNodeWithText(range)
                .performClick()

            // Verify analytics update for the selected range
            composeTestRule
                .onNodeWithText("Tasks Completed")
                .assertIsDisplayed()

            composeTestRule
                .onNodeWithText("Completion Rate")
                .assertIsDisplayed()

            // Data should be filtered by the selected range
            composeTestRule
                .onNodeWithContentDescription("Analytics for $range")
                .assertIsDisplayed()
        }
    }

    @Test
    fun exportAnalyticsDataFlow() {
        composeTestRule.waitForIdle()

        // Given - Generate some analytics data
        repeat(5) { i ->
            composeTestRule
                .onNodeWithContentDescription("Task input field")
                .performTextClearance()
            
            composeTestRule
                .onNodeWithContentDescription("Task input field")
                .performTextInput("Export task $i")
            
            composeTestRule
                .onNodeWithContentDescription("Add task")
                .performClick()
            
            composeTestRule
                .onNodeWithText("Export task $i")
                .performClick()
        }

        // When - Navigate to Analytics and export data
        composeTestRule
            .onNodeWithText("Analytics")
            .performClick()

        composeTestRule
            .onNodeWithContentDescription("Export analytics")
            .performClick()

        // Select export format
        composeTestRule
            .onNodeWithText("CSV")
            .performClick()

        composeTestRule
            .onNodeWithText("Export")
            .performClick()

        // Then - Export confirmation should be displayed
        composeTestRule
            .onNodeWithText("Analytics exported successfully")
            .assertIsDisplayed()

        composeTestRule
            .onNodeWithText("Share")
            .assertIsDisplayed()
    }

    @Test
    fun viewCategoryAnalyticsFlow() {
        composeTestRule.waitForIdle()

        // Given - Create tasks with different categories (if supported)
        val categorizedTasks = listOf(
            "Work: Complete project",
            "Personal: Buy groceries",
            "Health: Go to gym",
            "Work: Team meeting"
        )

        categorizedTasks.forEach { taskDescription ->
            composeTestRule
                .onNodeWithContentDescription("Task input field")
                .performTextClearance()
            
            composeTestRule
                .onNodeWithContentDescription("Task input field")
                .performTextInput(taskDescription)
            
            composeTestRule
                .onNodeWithContentDescription("Add task")
                .performClick()
            
            composeTestRule
                .onNodeWithText(taskDescription)
                .performClick()
        }

        // When - Navigate to Analytics and view categories
        composeTestRule
            .onNodeWithText("Analytics")
            .performClick()

        composeTestRule
            .onNodeWithText("Categories")
            .performClick()

        // Then - Category breakdown should be displayed
        composeTestRule
            .onNodeWithText("Task Categories")
            .assertIsDisplayed()

        composeTestRule
            .onNodeWithContentDescription("Category chart")
            .assertIsDisplayed()

        // Should show different categories
        composeTestRule
            .onNodeWithText("Work")
            .assertIsDisplayed()

        composeTestRule
            .onNodeWithText("Personal")
            .assertIsDisplayed()

        composeTestRule
            .onNodeWithText("Health")
            .assertIsDisplayed()
    }

    @Test
    fun refreshAnalyticsDataFlow() {
        composeTestRule.waitForIdle()

        // Given - Navigate to Analytics screen
        composeTestRule
            .onNodeWithText("Analytics")
            .performClick()

        // When - Pull to refresh analytics
        composeTestRule
            .onNodeWithContentDescription("Analytics screen")
            .performTouchInput {
                swipeDown()
            }

        // Then - Loading indicator should appear and disappear
        composeTestRule
            .onNodeWithContentDescription("Loading analytics")
            .assertIsDisplayed()

        composeTestRule.waitForIdle()

        composeTestRule
            .onNodeWithContentDescription("Loading analytics")
            .assertDoesNotExist()

        // Analytics data should be refreshed
        composeTestRule
            .onNodeWithText("Tasks Completed")
            .assertIsDisplayed()
    }

    @Test
    fun viewDetailedTaskAnalyticsFlow() {
        composeTestRule.waitForIdle()

        // Given - Create tasks with different completion times
        val tasks = listOf("Quick task", "Medium task", "Long task")
        
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
            
            // Simulate different completion times
            Thread.sleep(100)
            
            composeTestRule
                .onNodeWithText(taskDescription)
                .performClick()
        }

        // When - Navigate to detailed analytics
        composeTestRule
            .onNodeWithText("Analytics")
            .performClick()

        composeTestRule
            .onNodeWithText("Detailed View")
            .performClick()

        // Then - Detailed analytics should be displayed
        composeTestRule
            .onNodeWithText("Task Details")
            .assertIsDisplayed()

        composeTestRule
            .onNodeWithText("Completion Times")
            .assertIsDisplayed()

        composeTestRule
            .onNodeWithText("Task Distribution")
            .assertIsDisplayed()

        // Should show individual task information
        tasks.forEach { taskDescription ->
            composeTestRule
                .onNodeWithText(taskDescription)
                .assertIsDisplayed()
        }
    }

    @Test
    fun compareAnalyticsPeriodsFlow() {
        composeTestRule.waitForIdle()

        // Given - Generate analytics data
        repeat(8) { i ->
            composeTestRule
                .onNodeWithContentDescription("Task input field")
                .performTextClearance()
            
            composeTestRule
                .onNodeWithContentDescription("Task input field")
                .performTextInput("Compare task $i")
            
            composeTestRule
                .onNodeWithContentDescription("Add task")
                .performClick()
            
            composeTestRule
                .onNodeWithText("Compare task $i")
                .performClick()
        }

        // When - Navigate to Analytics and compare periods
        composeTestRule
            .onNodeWithText("Analytics")
            .performClick()

        composeTestRule
            .onNodeWithText("Compare")
            .performClick()

        // Select periods to compare
        composeTestRule
            .onNodeWithText("This Week")
            .performClick()

        composeTestRule
            .onNodeWithText("vs")
            .assertIsDisplayed()

        composeTestRule
            .onNodeWithText("Last Week")
            .performClick()

        // Then - Comparison should be displayed
        composeTestRule
            .onNodeWithText("Period Comparison")
            .assertIsDisplayed()

        composeTestRule
            .onNodeWithText("Improvement")
            .assertIsDisplayed()

        composeTestRule
            .onNodeWithContentDescription("Comparison chart")
            .assertIsDisplayed()
    }
}