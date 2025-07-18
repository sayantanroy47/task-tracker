package com.tasktracker.presentation.components.glassmorphism

import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.test.assertIsDisplayed
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.compose.ui.test.onNodeWithTag
import androidx.compose.ui.test.performClick
import androidx.compose.ui.unit.dp
import androidx.test.ext.junit.runners.AndroidJUnit4
import com.tasktracker.presentation.theme.TaskTrackerTheme
import com.tasktracker.presentation.theme.GlassmorphismTheme
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith

@RunWith(AndroidJUnit4::class)
class GlassmorphismComponentsTest {
    
    @get:Rule
    val composeTestRule = createComposeRule()
    
    @Test
    fun glassCard_displaysCorrectly() {
        composeTestRule.setContent {
            TaskTrackerTheme {
                GlassCard(
                    modifier = Modifier.testTag("glass_card"),
                    contentPadding = PaddingValues(16.dp)
                ) {
                    // Empty content for testing
                }
            }
        }
        
        composeTestRule.onNodeWithTag("glass_card").assertIsDisplayed()
    }
    
    @Test
    fun glassButton_clickable() {
        var clicked = false
        
        composeTestRule.setContent {
            TaskTrackerTheme {
                GlassButton(
                    onClick = { clicked = true },
                    modifier = Modifier.testTag("glass_button")
                ) {
                    // Empty content for testing
                }
            }
        }
        
        composeTestRule.onNodeWithTag("glass_button").performClick()
        assert(clicked)
    }
    
    @Test
    fun glassTextField_displaysCorrectly() {
        composeTestRule.setContent {
            TaskTrackerTheme {
                GlassTextField(
                    value = "Test text",
                    onValueChange = {},
                    modifier = Modifier.testTag("glass_text_field"),
                    placeholder = "Enter text"
                )
            }
        }
        
        composeTestRule.onNodeWithTag("glass_text_field").assertIsDisplayed()
    }
    
    @Test
    fun glassBottomSheet_displaysCorrectly() {
        composeTestRule.setContent {
            TaskTrackerTheme {
                GlassBottomSheet(
                    modifier = Modifier.testTag("glass_bottom_sheet")
                ) {
                    // Empty content for testing
                }
            }
        }
        
        composeTestRule.onNodeWithTag("glass_bottom_sheet").assertIsDisplayed()
    }
    
    @Test
    fun glassFab_clickable() {
        var clicked = false
        
        composeTestRule.setContent {
            TaskTrackerTheme {
                GlassFab(
                    onClick = { clicked = true },
                    modifier = Modifier.testTag("glass_fab")
                ) {
                    // Empty content for testing
                }
            }
        }
        
        composeTestRule.onNodeWithTag("glass_fab").performClick()
        assert(clicked)
    }
    
    @Test
    fun glassNavigationBar_displaysCorrectly() {
        composeTestRule.setContent {
            TaskTrackerTheme {
                GlassNavigationBar(
                    modifier = Modifier.testTag("glass_nav_bar")
                ) {
                    // Empty content for testing
                }
            }
        }
        
        composeTestRule.onNodeWithTag("glass_nav_bar").assertIsDisplayed()
    }
    
    @Test
    fun glassCard_withCustomTransparency() {
        composeTestRule.setContent {
            TaskTrackerTheme {
                GlassCard(
                    modifier = Modifier.testTag("glass_card_custom"),
                    transparency = 0.3f,
                    elevation = 8.dp,
                    shape = RoundedCornerShape(20.dp)
                ) {
                    // Empty content for testing
                }
            }
        }
        
        composeTestRule.onNodeWithTag("glass_card_custom").assertIsDisplayed()
    }
    
    @Test
    fun glassButton_withCustomShape() {
        composeTestRule.setContent {
            TaskTrackerTheme {
                GlassButton(
                    onClick = {},
                    modifier = Modifier.testTag("glass_button_custom"),
                    shape = RoundedCornerShape(20.dp),
                    contentPadding = PaddingValues(20.dp)
                ) {
                    // Empty content for testing
                }
            }
        }
        
        composeTestRule.onNodeWithTag("glass_button_custom").assertIsDisplayed()
    }
}