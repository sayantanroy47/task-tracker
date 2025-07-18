package com.tasktracker.presentation.components

import androidx.compose.ui.test.assertIsDisplayed
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.performClick
import androidx.test.ext.junit.runners.AndroidJUnit4
import com.tasktracker.presentation.theme.TaskTrackerTheme
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith

@RunWith(AndroidJUnit4::class)
class ReminderTimePickerTest {

    @get:Rule
    val composeTestRule = createComposeRule()

    @Test
    fun reminderTimeDisplay_showsFormattedTime() {
        val reminderTime = System.currentTimeMillis() + 3600000 // 1 hour from now

        composeTestRule.setContent {
            TaskTrackerTheme {
                ReminderTimeDisplay(
                    reminderTime = reminderTime,
                    onClearReminder = {}
                )
            }
        }

        composeTestRule.onNodeWithText("Reminder set for:").assertIsDisplayed()
        composeTestRule.onNodeWithText("Clear").assertIsDisplayed()
    }

    @Test
    fun reminderTimeDisplay_callsClearCallback() {
        val reminderTime = System.currentTimeMillis() + 3600000
        var clearCalled = false

        composeTestRule.setContent {
            TaskTrackerTheme {
                ReminderTimeDisplay(
                    reminderTime = reminderTime,
                    onClearReminder = { clearCalled = true }
                )
            }
        }

        composeTestRule.onNodeWithText("Clear").performClick()

        assert(clearCalled) { "Clear callback should be called when Clear button is clicked" }
    }

    @Test
    fun reminderTimeDisplay_doesNotShowWhenReminderTimeIsNull() {
        composeTestRule.setContent {
            TaskTrackerTheme {
                ReminderTimeDisplay(
                    reminderTime = null,
                    onClearReminder = {}
                )
            }
        }

        composeTestRule.onNodeWithText("Reminder set for:").assertDoesNotExist()
        composeTestRule.onNodeWithText("Clear").assertDoesNotExist()
    }
}