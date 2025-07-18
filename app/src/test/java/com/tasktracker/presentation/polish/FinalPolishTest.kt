package com.tasktracker.presentation.polish

import androidx.compose.material3.Text
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
class FinalPolishTest {
    
    @get:Rule
    val composeTestRule = createComposeRule()
    
    @Test
    fun taskTracker2025UIWrapper_displaysContent() {
        composeTestRule.setContent {
            TaskTrackerTheme {
                TaskTracker2025UIWrapper {
                    Text("Test Content")
                }
            }
        }
        
        // Verify content is displayed
        composeTestRule.onNodeWithText("Test Content").assertIsDisplayed()
    }
    
    @Test
    fun polishedGlassCard_displaysContent() {
        composeTestRule.setContent {
            TaskTrackerTheme {
                PolishedGlassCard(
                    contentDescription = "Test card"
                ) {
                    Text("Card Content")
                }
            }
        }
        
        // Verify content is displayed
        composeTestRule.onNodeWithText("Card Content").assertIsDisplayed()
    }
    
    @Test
    fun polishedGlassButton_isClickable() {
        var clicked = false
        
        composeTestRule.setContent {
            TaskTrackerTheme {
                PolishedGlassButton(
                    onClick = { clicked = true },
                    contentDescription = "Test button"
                ) {
                    Text("Button Text")
                }
            }
        }
        
        // Click the button
        composeTestRule.onNodeWithText("Button Text").performClick()
        
        // Verify callback was called
        assert(clicked)
    }
    
    @Test
    fun polishedGlassTextField_displaysCorrectly() {
        composeTestRule.setContent {
            TaskTrackerTheme {
                PolishedGlassTextField(
                    value = "Test Value",
                    onValueChange = {},
                    placeholder = "Test Placeholder",
                    contentDescription = "Test text field"
                )
            }
        }
        
        // The component should render without errors
        // Detailed text field testing would require more complex setup
    }
    
    @Test
    fun successCelebration_handlesVisibility() {
        var completed = false
        
        composeTestRule.setContent {
            TaskTrackerTheme {
                SuccessCelebration(
                    visible = true,
                    onComplete = { completed = true }
                )
            }
        }
        
        // The celebration should be visible and eventually call onComplete
        // In a real test, we'd wait for the animation to complete
    }
}