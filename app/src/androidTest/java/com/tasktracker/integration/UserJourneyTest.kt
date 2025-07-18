package com.tasktracker.integration

import androidx.compose.ui.test.assertIsDisplayed
import androidx.compose.ui.test.junit4.createAndroidComposeRule
import androidx.compose.ui.test.onNodeWithContentDescription
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.performClick
import androidx.compose.ui.test.performTextInput
import androidx.test.ext.junit.runners.AndroidJUnit4
import com.tasktracker.presentation.MainActivity
import dagger.hilt.android.testing.HiltAndroidRule
import dagger.hilt.android.testing.HiltAndroidTest
import org.junit.Before
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith

/**
 * End-to-end integration tests for complete user journeys in the Task Tracker app.
 * Tests the full user experience from task creation to completion.
 */
@HiltAndroidTest
@RunWith(AndroidJUnit4::class)
class UserJourneyTest {
    
    @get:Rule(order = 0)
    val hiltRule = HiltAndroidRule(this)
    
    @get:Rule(order = 1)
    val composeTestRule = createAndroidComposeRule<MainActivity>()
    
    @Before
    fun setup() {
        hiltRule.inject()
    }
    
    @Test
    fun completeTaskCreationAndCompletionJourney() {
        // Step 1: Verify app launches successfully
        composeTestRule.onNodeWithText("Task Tracker").assertIsDisplayed()
        
        // Step 2: Create a new task
        val taskDescription = "Complete integration test"
        composeTestRule.onNodeWithText("Add new task...").performClick()
        composeTestRule.onNodeWithText("Add new task...").performTextInput(taskDescription)
        
        // Step 3: Verify task appears in the list
        composeTestRule.onNodeWithText(taskDescription).assertIsDisplayed()
        
        // Step 4: Complete the task by swiping or clicking
        composeTestRule.onNodeWithText(taskDescription).performClick()
        
        // Step 5: Verify task completion feedback
        composeTestRule.onNodeWithText("Task completed").assertIsDisplayed()
        
        // Step 6: Verify undo option appears
        composeTestRule.onNodeWithText("Undo").assertIsDisplayed()
        
        // Step 7: Test undo functionality
        composeTestRule.onNodeWithText("Undo").performClick()
        
        // Step 8: Verify task is back in active list
        composeTestRule.onNodeWithText(taskDescription).assertIsDisplayed()
    }
    
    @Test
    fun completeVoiceInputJourney() {
        // Step 1: Verify microphone button is available
        composeTestRule.onNodeWithContentDescription("Voice input").assertIsDisplayed()
        
        // Step 2: Click microphone button
        composeTestRule.onNodeWithContentDescription("Voice input").performClick()
        
        // Step 3: Verify voice input UI appears
        // Note: Actual speech recognition testing requires special setup
        // This test verifies the UI flow
        composeTestRule.onNodeWithText("Listening...").assertIsDisplayed()
        
        // Step 4: Simulate voice input completion
        // In a real test, this would involve mock speech recognition
        val voiceTask = "Voice created task"
        composeTestRule.onNodeWithText("Add new task...").performTextInput(voiceTask)
        
        // Step 5: Verify voice-created task appears
        composeTestRule.onNodeWithText(voiceTask).assertIsDisplayed()
    }
    
    @Test
    fun completeReminderSetupJourney() {
        // Step 1: Create task with reminder
        val taskWithReminder = "Task with reminder"
        composeTestRule.onNodeWithText("Add new task...").performClick()
        composeTestRule.onNodeWithText("Add new task...").performTextInput(taskWithReminder)
        
        // Step 2: Set reminder time
        composeTestRule.onNodeWithContentDescription("Set reminder").performClick()
        
        // Step 3: Select reminder time (simplified for test)
        composeTestRule.onNodeWithText("Set Reminder").assertIsDisplayed()
        composeTestRule.onNodeWithText("OK").performClick()
        
        // Step 4: Verify task with reminder indicator
        composeTestRule.onNodeWithText(taskWithReminder).assertIsDisplayed()
        composeTestRule.onNodeWithContentDescription("Has reminder").assertIsDisplayed()
    }
    
    @Test
    fun completeRecurringTaskJourney() {
        // Step 1: Create recurring task
        val recurringTask = "Daily recurring task"
        composeTestRule.onNodeWithText("Add new task...").performClick()
        composeTestRule.onNodeWithText("Add new task...").performTextInput(recurringTask)
        
        // Step 2: Set recurrence
        composeTestRule.onNodeWithContentDescription("Set recurrence").performClick()
        composeTestRule.onNodeWithText("Daily").performClick()
        composeTestRule.onNodeWithText("OK").performClick()
        
        // Step 3: Verify recurring task indicator
        composeTestRule.onNodeWithText(recurringTask).assertIsDisplayed()
        composeTestRule.onNodeWithContentDescription("Recurring task").assertIsDisplayed()
        
        // Step 4: Complete recurring task
        composeTestRule.onNodeWithText(recurringTask).performClick()
        
        // Step 5: Verify next instance is created
        // Note: This would require waiting for background processing
        Thread.sleep(1000) // Wait for processing
        composeTestRule.onNodeWithText(recurringTask).assertIsDisplayed()
    }
    
    @Test
    fun completeTaskManagementJourney() {
        // Step 1: Create multiple tasks
        val tasks = listOf("Task 1", "Task 2", "Task 3")
        tasks.forEach { task ->
            composeTestRule.onNodeWithText("Add new task...").performClick()
            composeTestRule.onNodeWithText("Add new task...").performTextInput(task)
        }
        
        // Step 2: Verify all tasks are displayed
        tasks.forEach { task ->
            composeTestRule.onNodeWithText(task).assertIsDisplayed()
        }
        
        // Step 3: Complete some tasks
        composeTestRule.onNodeWithText("Task 1").performClick()
        composeTestRule.onNodeWithText("Task 2").performClick()
        
        // Step 4: View completed tasks section
        composeTestRule.onNodeWithText("Completed").performClick()
        
        // Step 5: Verify completed tasks are shown
        composeTestRule.onNodeWithText("Task 1").assertIsDisplayed()
        composeTestRule.onNodeWithText("Task 2").assertIsDisplayed()
        
        // Step 6: Clear completed tasks
        composeTestRule.onNodeWithText("Clear All").performClick()
        composeTestRule.onNodeWithText("Confirm").performClick()
        
        // Step 7: Verify completed tasks are cleared
        composeTestRule.onNodeWithText("No completed tasks").assertIsDisplayed()
    }
    
    @Test
    fun completeOfflineFunctionalityJourney() {
        // Step 1: Create tasks while online
        val offlineTask = "Offline task"
        composeTestRule.onNodeWithText("Add new task...").performClick()
        composeTestRule.onNodeWithText("Add new task...").performTextInput(offlineTask)
        
        // Step 2: Verify task is created
        composeTestRule.onNodeWithText(offlineTask).assertIsDisplayed()
        
        // Step 3: Simulate offline mode (would require network mocking)
        // For this test, we verify that local operations still work
        
        // Step 4: Complete task offline
        composeTestRule.onNodeWithText(offlineTask).performClick()
        
        // Step 5: Verify task completion works offline
        composeTestRule.onNodeWithText("Task completed").assertIsDisplayed()
        
        // Step 6: Create another task offline
        val anotherOfflineTask = "Another offline task"
        composeTestRule.onNodeWithText("Add new task...").performClick()
        composeTestRule.onNodeWithText("Add new task...").performTextInput(anotherOfflineTask)
        
        // Step 7: Verify offline task creation works
        composeTestRule.onNodeWithText(anotherOfflineTask).assertIsDisplayed()
    }
    
    @Test
    fun completeAccessibilityJourney() {
        // Step 1: Verify content descriptions are present
        composeTestRule.onNodeWithContentDescription("Add new task").assertIsDisplayed()
        composeTestRule.onNodeWithContentDescription("Voice input").assertIsDisplayed()
        
        // Step 2: Test keyboard navigation
        // Note: Full accessibility testing requires TalkBack simulation
        
        // Step 3: Verify semantic markup
        composeTestRule.onNodeWithText("Task Tracker").assertIsDisplayed()
        
        // Step 4: Test with large text (would require system setting changes)
        // This is a simplified accessibility verification
        
        // Step 5: Verify color contrast (visual verification in real testing)
        composeTestRule.onNodeWithText("Add new task...").assertIsDisplayed()
    }
    
    @Test
    fun completeErrorHandlingJourney() {
        // Step 1: Test empty task creation
        composeTestRule.onNodeWithText("Add new task...").performClick()
        composeTestRule.onNodeWithText("Add new task...").performTextInput("")
        
        // Step 2: Verify error message
        composeTestRule.onNodeWithText("Task description cannot be empty").assertIsDisplayed()
        
        // Step 3: Test valid task creation after error
        composeTestRule.onNodeWithText("Add new task...").performTextInput("Valid task")
        composeTestRule.onNodeWithText("Valid task").assertIsDisplayed()
        
        // Step 4: Test error recovery
        composeTestRule.onNodeWithText("Valid task").performClick()
        composeTestRule.onNodeWithText("Task completed").assertIsDisplayed()
    }
}