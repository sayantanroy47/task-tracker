package com.tasktracker

import androidx.compose.ui.test.assertIsDisplayed
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.compose.ui.test.onNodeWithContentDescription
import androidx.compose.ui.test.onNodeWithText
import androidx.test.ext.junit.runners.AndroidJUnit4
import com.tasktracker.presentation.main.MainScreen
import com.tasktracker.presentation.navigation.TaskTrackerNavigation
import com.tasktracker.presentation.theme.TaskTrackerTheme
import com.tasktracker.presentation.theme.GlassmorphismTheme
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith

/**
 * Comprehensive integration test for the Task Tracker 2025 UI system
 */
@RunWith(AndroidJUnit4::class)
class ComprehensiveIntegrationTest {
    
    @get:Rule
    val composeTestRule = createComposeRule()
    
    @Test
    fun mainScreen_displaysWithGlassmorphismTheme() {
        composeTestRule.setContent {
            TaskTrackerTheme {
                GlassmorphismTheme {
                    MainScreen()
                }
            }
        }
        
        // Verify main screen elements are displayed
        composeTestRule.onNodeWithContentDescription("Create task").assertIsDisplayed()
        composeTestRule.onNodeWithContentDescription("Set reminder").assertIsDisplayed()
        composeTestRule.onNodeWithContentDescription("Set recurrence").assertIsDisplayed()
    }
    
    @Test
    fun taskTrackerNavigation_displaysAllScreens() {
        composeTestRule.setContent {
            TaskTrackerTheme {
                GlassmorphismTheme {
                    TaskTrackerNavigation()
                }
            }
        }
        
        // Verify navigation elements are displayed
        composeTestRule.onNodeWithText("Tasks").assertIsDisplayed()
        composeTestRule.onNodeWithText("Analytics").assertIsDisplayed()
        composeTestRule.onNodeWithText("Profile").assertIsDisplayed()
    }
    
    @Test
    fun glassmorphismTheme_rendersWithoutErrors() {
        composeTestRule.setContent {
            TaskTrackerTheme {
                GlassmorphismTheme {
                    // Empty content to test theme rendering
                }
            }
        }
        
        // If we reach here without exceptions, the theme renders correctly
        assert(true)
    }
    
    @Test
    fun taskTrackerTheme_rendersWithoutErrors() {
        composeTestRule.setContent {
            TaskTrackerTheme {
                // Empty content to test theme rendering
            }
        }
        
        // If we reach here without exceptions, the theme renders correctly
        assert(true)
    }
}