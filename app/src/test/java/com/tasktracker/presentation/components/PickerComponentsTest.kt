package com.tasktracker.presentation.components

import androidx.compose.ui.test.assertIsDisplayed
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.performClick
import androidx.test.ext.junit.runners.AndroidJUnit4
import com.tasktracker.domain.model.RecurrenceType
import com.tasktracker.presentation.theme.TaskTrackerTheme
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith

@RunWith(AndroidJUnit4::class)
class PickerComponentsTest {
    
    @get:Rule
    val composeTestRule = createComposeRule()
    
    @Test
    fun reminderTimePicker_displaysCorrectly() {
        composeTestRule.setContent {
            TaskTrackerTheme {
                ReminderTimePicker(
                    onTimeSelected = {},
                    onDismiss = {}
                )
            }
        }
        
        // Verify dialog elements are displayed
        composeTestRule.onNodeWithText("Set Reminder Time").assertIsDisplayed()
        composeTestRule.onNodeWithText("Set").assertIsDisplayed()
        composeTestRule.onNodeWithText("Cancel").assertIsDisplayed()
    }
    
    @Test
    fun reminderTimePicker_callsOnDismiss() {
        var dismissed = false
        
        composeTestRule.setContent {
            TaskTrackerTheme {
                ReminderTimePicker(
                    onTimeSelected = {},
                    onDismiss = { dismissed = true }
                )
            }
        }
        
        // Click cancel button
        composeTestRule.onNodeWithText("Cancel").performClick()
        
        // Verify callback was called
        assert(dismissed)
    }
    
    @Test
    fun recurrencePicker_displaysCorrectly() {
        composeTestRule.setContent {
            TaskTrackerTheme {
                RecurrencePicker(
                    currentRecurrence = null,
                    onRecurrenceSelected = {},
                    onDismiss = {}
                )
            }
        }
        
        // Verify dialog elements are displayed
        composeTestRule.onNodeWithText("Set Recurrence").assertIsDisplayed()
        composeTestRule.onNodeWithText("None").assertIsDisplayed()
        composeTestRule.onNodeWithText("Daily").assertIsDisplayed()
        composeTestRule.onNodeWithText("Weekly").assertIsDisplayed()
        composeTestRule.onNodeWithText("Monthly").assertIsDisplayed()
    }
    
    @Test
    fun recurrencePicker_callsOnDismiss() {
        var dismissed = false
        
        composeTestRule.setContent {
            TaskTrackerTheme {
                RecurrencePicker(
                    currentRecurrence = null,
                    onRecurrenceSelected = {},
                    onDismiss = { dismissed = true }
                )
            }
        }
        
        // Click cancel button
        composeTestRule.onNodeWithText("Cancel").performClick()
        
        // Verify callback was called
        assert(dismissed)
    }
    
    @Test
    fun reminderTimeDisplay_displaysCorrectly() {
        val reminderTime = System.currentTimeMillis() + 3600000 // 1 hour from now
        
        composeTestRule.setContent {
            TaskTrackerTheme {
                ReminderTimeDisplay(
                    reminderTime = reminderTime,
                    onClearReminder = {}
                )
            }
        }
        
        // Verify reminder display elements
        composeTestRule.onNodeWithText("Reminder:", substring = true).assertIsDisplayed()
        composeTestRule.onNodeWithText("Clear").assertIsDisplayed()
    }
    
    @Test
    fun recurrenceDisplay_displaysCorrectly() {
        composeTestRule.setContent {
            TaskTrackerTheme {
                RecurrenceDisplay(
                    recurrenceType = RecurrenceType.DAILY,
                    onClearRecurrence = {}
                )
            }
        }
        
        // Verify recurrence display elements
        composeTestRule.onNodeWithText("Recurrence: Daily").assertIsDisplayed()
        composeTestRule.onNodeWithText("Clear").assertIsDisplayed()
    }
    
    @Test
    fun reminderTimeDisplay_callsOnClear() {
        var cleared = false
        val reminderTime = System.currentTimeMillis() + 3600000
        
        composeTestRule.setContent {
            TaskTrackerTheme {
                ReminderTimeDisplay(
                    reminderTime = reminderTime,
                    onClearReminder = { cleared = true }
                )
            }
        }
        
        // Click clear button
        composeTestRule.onNodeWithText("Clear").performClick()
        
        // Verify callback was called
        assert(cleared)
    }
    
    @Test
    fun recurrenceDisplay_callsOnClear() {
        var cleared = false
        
        composeTestRule.setContent {
            TaskTrackerTheme {
                RecurrenceDisplay(
                    recurrenceType = RecurrenceType.WEEKLY,
                    onClearRecurrence = { cleared = true }
                )
            }
        }
        
        // Click clear button
        composeTestRule.onNodeWithText("Clear").performClick()
        
        // Verify callback was called
        assert(cleared)
    }
}