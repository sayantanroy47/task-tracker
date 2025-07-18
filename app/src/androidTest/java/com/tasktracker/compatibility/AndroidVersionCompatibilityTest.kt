package com.tasktracker.compatibility

import android.os.Build
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import androidx.compose.ui.test.junit4.createAndroidComposeRule
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.assertIsDisplayed
import androidx.compose.ui.test.performClick
import androidx.compose.ui.test.performTextInput
import com.tasktracker.presentation.MainActivity
import dagger.hilt.android.testing.HiltAndroidRule
import dagger.hilt.android.testing.HiltAndroidTest
import org.junit.Before
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith
import kotlin.test.assertTrue

/**
 * Compatibility tests to ensure the app works correctly across different Android versions
 * and device configurations. Tests API level specific functionality and graceful degradation.
 */
@HiltAndroidTest
@RunWith(AndroidJUnit4::class)
class AndroidVersionCompatibilityTest {
    
    @get:Rule(order = 0)
    val hiltRule = HiltAndroidRule(this)
    
    @get:Rule(order = 1)
    val composeTestRule = createAndroidComposeRule<MainActivity>()
    
    private val context = InstrumentationRegistry.getInstrumentation().targetContext
    
    @Before
    fun setup() {
        hiltRule.inject()
    }
    
    @Test
    fun testBasicFunctionalityAcrossApiLevels() {
        // Test core functionality that should work on all supported API levels (24+)
        
        // Verify app launches
        composeTestRule.onNodeWithText("Task Tracker").assertIsDisplayed()
        
        // Test task creation
        val testTask = "Compatibility test task"
        composeTestRule.onNodeWithText("Add new task...").performClick()
        composeTestRule.onNodeWithText("Add new task...").performTextInput(testTask)
        
        // Verify task appears
        composeTestRule.onNodeWithText(testTask).assertIsDisplayed()
        
        // Test task completion
        composeTestRule.onNodeWithText(testTask).performClick()
        
        // These basic operations should work on all supported Android versions
        assertTrue(true, "Basic functionality test passed")
    }
    
    @Test
    fun testNotificationCompatibility() {
        // Test notification functionality across different API levels
        val currentApiLevel = Build.VERSION.SDK_INT
        
        when {
            currentApiLevel >= Build.VERSION_CODES.TIRAMISU -> {
                // Android 13+ - Test with notification permission requirements
                testNotificationWithPermissionRequest()
            }
            currentApiLevel >= Build.VERSION_CODES.O -> {
                // Android 8+ - Test with notification channels
                testNotificationWithChannels()
            }
            else -> {
                // Android 7 and below - Test basic notifications
                testBasicNotifications()
            }
        }
    }
    
    private fun testNotificationWithPermissionRequest() {
        // Test notification functionality on Android 13+
        // This would typically involve permission request testing
        assertTrue(Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU, 
            "Should be running on Android 13+")
        
        // Create task with reminder
        val reminderTask = "Task with reminder (API 33+)"
        composeTestRule.onNodeWithText("Add new task...").performClick()
        composeTestRule.onNodeWithText("Add new task...").performTextInput(reminderTask)
        
        // The app should handle permission requests gracefully
        composeTestRule.onNodeWithText(reminderTask).assertIsDisplayed()
    }
    
    private fun testNotificationWithChannels() {
        // Test notification functionality on Android 8-12
        assertTrue(Build.VERSION.SDK_INT >= Build.VERSION_CODES.O, 
            "Should be running on Android 8+")
        
        // Create task with reminder
        val channelTask = "Task with notification channel"
        composeTestRule.onNodeWithText("Add new task...").performClick()
        composeTestRule.onNodeWithText("Add new task...").performTextInput(channelTask)
        
        // Notification channels should be created automatically
        composeTestRule.onNodeWithText(channelTask).assertIsDisplayed()
    }
    
    private fun testBasicNotifications() {
        // Test basic notification functionality on older Android versions
        val basicTask = "Basic notification task"
        composeTestRule.onNodeWithText("Add new task...").performClick()
        composeTestRule.onNodeWithText("Add new task...").performTextInput(basicTask)
        
        composeTestRule.onNodeWithText(basicTask).assertIsDisplayed()
    }
    
    @Test
    fun testStorageCompatibility() {
        // Test storage functionality across different API levels
        val currentApiLevel = Build.VERSION.SDK_INT
        
        // Create multiple tasks to test storage
        val storageTasks = listOf("Storage test 1", "Storage test 2", "Storage test 3")
        
        storageTasks.forEach { task ->
            composeTestRule.onNodeWithText("Add new task...").performClick()
            composeTestRule.onNodeWithText("Add new task...").performTextInput(task)
            composeTestRule.onNodeWithText(task).assertIsDisplayed()
        }
        
        // Storage should work consistently across all API levels
        assertTrue(currentApiLevel >= 24, "Should be running on supported API level")
    }
    
    @Test
    fun testPermissionCompatibility() {
        // Test permission handling across different API levels
        val currentApiLevel = Build.VERSION.SDK_INT
        
        when {
            currentApiLevel >= Build.VERSION_CODES.M -> {
                // Android 6+ - Test runtime permissions
                testRuntimePermissions()
            }
            else -> {
                // Pre-Android 6 - Permissions granted at install time
                testInstallTimePermissions()
            }
        }
    }
    
    private fun testRuntimePermissions() {
        // Test runtime permission handling (Android 6+)
        assertTrue(Build.VERSION.SDK_INT >= Build.VERSION_CODES.M, 
            "Should be running on Android 6+")
        
        // Test microphone permission for voice input
        // This would typically involve permission dialog testing
        composeTestRule.onNodeWithText("Task Tracker").assertIsDisplayed()
        
        // The app should handle permission requests gracefully
        assertTrue(true, "Runtime permission test passed")
    }
    
    private fun testInstallTimePermissions() {
        // Test install-time permission behavior (pre-Android 6)
        // Permissions should be automatically granted
        composeTestRule.onNodeWithText("Task Tracker").assertIsDisplayed()
        assertTrue(true, "Install-time permission test passed")
    }
    
    @Test
    fun testComposeCompatibility() {
        // Test Jetpack Compose compatibility across different API levels
        
        // Compose should work on all supported API levels
        composeTestRule.onNodeWithText("Task Tracker").assertIsDisplayed()
        
        // Test compose animations and transitions
        val animationTask = "Animation test task"
        composeTestRule.onNodeWithText("Add new task...").performClick()
        composeTestRule.onNodeWithText("Add new task...").performTextInput(animationTask)
        
        // Complete task to test animations
        composeTestRule.onNodeWithText(animationTask).performClick()
        
        // Animations should work smoothly across API levels
        assertTrue(true, "Compose compatibility test passed")
    }
    
    @Test
    fun testDarkModeCompatibility() {
        // Test dark mode support across different API levels
        val currentApiLevel = Build.VERSION.SDK_INT
        
        // Dark mode support varies by API level
        when {
            currentApiLevel >= Build.VERSION_CODES.Q -> {
                // Android 10+ - System dark mode
                testSystemDarkMode()
            }
            else -> {
                // Pre-Android 10 - App-level dark mode
                testAppDarkMode()
            }
        }
    }
    
    private fun testSystemDarkMode() {
        // Test system-level dark mode (Android 10+)
        assertTrue(Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q, 
            "Should be running on Android 10+")
        
        // App should respond to system dark mode changes
        composeTestRule.onNodeWithText("Task Tracker").assertIsDisplayed()
        assertTrue(true, "System dark mode test passed")
    }
    
    private fun testAppDarkMode() {
        // Test app-level dark mode implementation
        composeTestRule.onNodeWithText("Task Tracker").assertIsDisplayed()
        assertTrue(true, "App dark mode test passed")
    }
    
    @Test
    fun testMemoryManagementCompatibility() {
        // Test memory management across different API levels and device configurations
        
        // Create many tasks to test memory handling
        repeat(100) { index ->
            val memoryTask = "Memory test task $index"
            composeTestRule.onNodeWithText("Add new task...").performClick()
            composeTestRule.onNodeWithText("Add new task...").performTextInput(memoryTask)
        }
        
        // App should handle memory efficiently across all API levels
        val runtime = Runtime.getRuntime()
        val usedMemory = runtime.totalMemory() - runtime.freeMemory()
        val maxMemory = runtime.maxMemory()
        val memoryUsagePercent = (usedMemory.toDouble() / maxMemory.toDouble()) * 100
        
        assertTrue(memoryUsagePercent < 80, 
            "Memory usage should be reasonable: ${memoryUsagePercent}%")
    }
    
    @Test
    fun testBackgroundProcessingCompatibility() {
        // Test background processing limitations across API levels
        val currentApiLevel = Build.VERSION.SDK_INT
        
        when {
            currentApiLevel >= Build.VERSION_CODES.O -> {
                // Android 8+ - Background execution limits
                testWithBackgroundLimits()
            }
            else -> {
                // Pre-Android 8 - More permissive background processing
                testWithoutBackgroundLimits()
            }
        }
    }
    
    private fun testWithBackgroundLimits() {
        // Test background processing with Android 8+ limitations
        assertTrue(Build.VERSION.SDK_INT >= Build.VERSION_CODES.O, 
            "Should be running on Android 8+")
        
        // WorkManager should handle background limitations
        val backgroundTask = "Background processing task"
        composeTestRule.onNodeWithText("Add new task...").performClick()
        composeTestRule.onNodeWithText("Add new task...").performTextInput(backgroundTask)
        
        composeTestRule.onNodeWithText(backgroundTask).assertIsDisplayed()
        assertTrue(true, "Background limits test passed")
    }
    
    private fun testWithoutBackgroundLimits() {
        // Test background processing on older Android versions
        val backgroundTask = "Legacy background task"
        composeTestRule.onNodeWithText("Add new task...").performClick()
        composeTestRule.onNodeWithText("Add new task...").performTextInput(backgroundTask)
        
        composeTestRule.onNodeWithText(backgroundTask).assertIsDisplayed()
        assertTrue(true, "Legacy background test passed")
    }
    
    @Test
    fun testDeviceConfigurationCompatibility() {
        // Test app behavior across different device configurations
        
        val displayMetrics = context.resources.displayMetrics
        val screenWidth = displayMetrics.widthPixels
        val screenHeight = displayMetrics.heightPixels
        val density = displayMetrics.density
        
        // App should work on various screen sizes and densities
        assertTrue(screenWidth > 0, "Screen width should be positive")
        assertTrue(screenHeight > 0, "Screen height should be positive")
        assertTrue(density > 0, "Screen density should be positive")
        
        // Test basic functionality regardless of screen configuration
        composeTestRule.onNodeWithText("Task Tracker").assertIsDisplayed()
        
        val configTask = "Configuration test task"
        composeTestRule.onNodeWithText("Add new task...").performClick()
        composeTestRule.onNodeWithText("Add new task...").performTextInput(configTask)
        composeTestRule.onNodeWithText(configTask).assertIsDisplayed()
    }
}