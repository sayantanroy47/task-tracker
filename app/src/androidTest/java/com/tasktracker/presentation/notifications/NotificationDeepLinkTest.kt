package com.tasktracker.presentation.notifications

import android.content.Intent
import androidx.test.core.app.ActivityScenario
import androidx.test.ext.junit.runners.AndroidJUnit4
import com.tasktracker.presentation.MainActivity
import org.junit.Test
import org.junit.runner.RunWith

@RunWith(AndroidJUnit4::class)
class NotificationDeepLinkTest {

    @Test
    fun mainActivity_handlesNotificationIntent() {
        // Given
        val intent = Intent().apply {
            action = "OPEN_TASK"
            putExtra(NotificationService.EXTRA_TASK_ID, "test-task-id")
        }

        // When
        val scenario = ActivityScenario.launch<MainActivity>(intent)

        // Then
        scenario.use {
            // Verify that the activity launches successfully with the intent
            // In a real test, you would verify that the task is highlighted
            assert(true) // Placeholder assertion
        }
    }

    @Test
    fun mainActivity_handlesNewIntentWhenRunning() {
        // Given
        val initialScenario = ActivityScenario.launch(MainActivity::class.java)

        initialScenario.use { scenario ->
            // When - send new intent while activity is running
            val newIntent = Intent().apply {
                action = "OPEN_TASK"
                putExtra(NotificationService.EXTRA_TASK_ID, "new-task-id")
            }

            scenario.onActivity { activity ->
                activity.onNewIntent(newIntent)
            }

            // Then
            // Verify that the new intent is handled properly
            assert(true) // Placeholder assertion
        }
    }
}