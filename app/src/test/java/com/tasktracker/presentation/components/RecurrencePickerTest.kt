package com.tasktracker.presentation.components

import androidx.compose.ui.test.assertIsDisplayed
import androidx.compose.ui.test.assertIsSelected
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
class RecurrencePickerTest {

    @get:Rule
    val composeTestRule = createComposeRule()

    @Test
    fun recurrencePicker_displaysAllOptions() {
        composeTestRule.setContent {
            TaskTrackerTheme {
                RecurrencePicker(
                    currentRecurrence = null,
                    onRecurrenceSelected = {},
                    onDismiss = {}
                )
            }
        }

        composeTestRule.onNodeWithText("Task Recurrence").assertIsDisplayed()
        composeTestRule.onNodeWithText("No recurrence").assertIsDisplayed()
        composeTestRule.onNodeWithText("Daily").assertIsDisplayed()
        composeTestRule.onNodeWithText("Weekly").assertIsDisplayed()
        composeTestRule.onNodeWithText("Monthly").assertIsDisplayed()
        composeTestRule.onNodeWithText("OK").assertIsDisplayed()
        composeTestRule.onNodeWithText("Cancel").assertIsDisplayed()
    }

    @Test
    fun recurrencePicker_selectsCurrentRecurrence() {
        composeTestRule.setContent {
            TaskTrackerTheme {
                RecurrencePicker(
                    currentRecurrence = RecurrenceType.DAILY,
                    onRecurrenceSelected = {},
                    onDismiss = {}
                )
            }
        }

        // Daily should be selected initially
        composeTestRule.onNodeWithText("Daily").assertIsSelected()
    }

    @Test
    fun recurrencePicker_callsOnRecurrenceSelected() {
        var selectedRecurrence: RecurrenceType? = null

        composeTestRule.setContent {
            TaskTrackerTheme {
                RecurrencePicker(
                    currentRecurrence = null,
                    onRecurrenceSelected = { selectedRecurrence = it },
                    onDismiss = {}
                )
            }
        }

        composeTestRule.onNodeWithText("Weekly").performClick()
        composeTestRule.onNodeWithText("OK").performClick()

        assert(selectedRecurrence == RecurrenceType.WEEKLY) {
            "Expected RecurrenceType.WEEKLY but got $selectedRecurrence"
        }
    }

    @Test
    fun recurrencePicker_callsOnDismiss() {
        var dismissCalled = false

        composeTestRule.setContent {
            TaskTrackerTheme {
                RecurrencePicker(
                    currentRecurrence = null,
                    onRecurrenceSelected = {},
                    onDismiss = { dismissCalled = true }
                )
            }
        }

        composeTestRule.onNodeWithText("Cancel").performClick()

        assert(dismissCalled) { "onDismiss should be called when Cancel is clicked" }
    }

    @Test
    fun recurrenceDisplay_showsRecurrenceType() {
        composeTestRule.setContent {
            TaskTrackerTheme {
                RecurrenceDisplay(
                    recurrenceType = RecurrenceType.WEEKLY,
                    onClearRecurrence = {}
                )
            }
        }

        composeTestRule.onNodeWithText("Recurring task:").assertIsDisplayed()
        composeTestRule.onNodeWithText("Repeats weekly").assertIsDisplayed()
        composeTestRule.onNodeWithText("Clear").assertIsDisplayed()
    }

    @Test
    fun recurrenceDisplay_callsClearCallback() {
        var clearCalled = false

        composeTestRule.setContent {
            TaskTrackerTheme {
                RecurrenceDisplay(
                    recurrenceType = RecurrenceType.DAILY,
                    onClearRecurrence = { clearCalled = true }
                )
            }
        }

        composeTestRule.onNodeWithText("Clear").performClick()

        assert(clearCalled) { "Clear callback should be called when Clear button is clicked" }
    }

    @Test
    fun recurrenceDisplay_doesNotShowWhenRecurrenceTypeIsNull() {
        composeTestRule.setContent {
            TaskTrackerTheme {
                RecurrenceDisplay(
                    recurrenceType = null,
                    onClearRecurrence = {}
                )
            }
        }

        composeTestRule.onNodeWithText("Recurring task:").assertDoesNotExist()
        composeTestRule.onNodeWithText("Clear").assertDoesNotExist()
    }
}