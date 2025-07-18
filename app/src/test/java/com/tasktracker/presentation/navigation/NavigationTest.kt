package com.tasktracker.presentation.navigation

import androidx.compose.ui.test.assertIsDisplayed
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.performClick
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.navigation.compose.rememberNavController
import com.tasktracker.presentation.theme.TaskTrackerTheme
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith

@RunWith(AndroidJUnit4::class)
class NavigationTest {
    
    @get:Rule
    val composeTestRule = createComposeRule()
    
    @Test
    fun taskTrackerNavigation_displaysCorrectly() {
        composeTestRule.setContent {
            TaskTrackerTheme {
                TaskTrackerNavigation()
            }
        }
        
        // Verify navigation is displayed
        composeTestRule.onNodeWithText("Tasks").assertIsDisplayed()
        composeTestRule.onNodeWithText("Analytics").assertIsDisplayed()
        composeTestRule.onNodeWithText("Profile").assertIsDisplayed()
    }
    
    @Test
    fun glassBottomNavigation_displaysNavigationItems() {
        composeTestRule.setContent {
            TaskTrackerTheme {
                val navController = rememberNavController()
                GlassBottomNavigation(
                    currentDestination = null,
                    onNavigate = {}
                )
            }
        }
        
        // Verify all navigation items are displayed
        composeTestRule.onNodeWithText("Tasks").assertIsDisplayed()
        composeTestRule.onNodeWithText("Analytics").assertIsDisplayed()
        composeTestRule.onNodeWithText("Profile").assertIsDisplayed()
    }
    
    @Test
    fun navigationScreens_containsAllScreens() {
        // Verify all screens are defined
        assert(navigationScreens.size == 3)
        assert(navigationScreens.any { it.route == "main" })
        assert(navigationScreens.any { it.route == "analytics" })
        assert(navigationScreens.any { it.route == "profile" })
    }
}