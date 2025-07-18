package com.tasktracker.presentation.main

import androidx.compose.ui.test.assertIsDisplayed
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.compose.ui.test.onNodeWithText
import androidx.test.ext.junit.runners.AndroidJUnit4
import com.tasktracker.presentation.theme.TaskTrackerTheme
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith

@RunWith(AndroidJUnit4::class)
class MainScreenTest {

    @get:Rule
    val composeTestRule = createComposeRule()

    @Test
    fun mainScreen_displaysTitle() {
        composeTestRule.setContent {
            TaskTrackerTheme {
                MainScreen()
            }
        }

        composeTestRule
            .onNodeWithText("Task Tracker")
            .assertIsDisplayed()
    }

    @Test
    fun mainScreen_rendersInLightTheme() {
        composeTestRule.setContent {
            TaskTrackerTheme(darkTheme = false) {
                MainScreen()
            }
        }

        composeTestRule
            .onNodeWithText("Task Tracker")
            .assertIsDisplayed()
    }

    @Test
    fun mainScreen_rendersInDarkTheme() {
        composeTestRule.setContent {
            TaskTrackerTheme(darkTheme = true) {
                MainScreen()
            }
        }

        composeTestRule
            .onNodeWithText("Task Tracker")
            .assertIsDisplayed()
    }
}