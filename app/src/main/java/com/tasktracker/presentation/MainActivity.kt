package com.tasktracker.presentation

import android.content.Intent
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.tooling.preview.Preview
import com.tasktracker.presentation.main.MainScreen
import com.tasktracker.presentation.notifications.NotificationPermissionHandler
import com.tasktracker.presentation.notifications.NotificationService
import com.tasktracker.presentation.speech.SpeechPermissionHandler
import com.tasktracker.presentation.theme.TaskTrackerTheme
import dagger.hilt.android.AndroidEntryPoint
import javax.inject.Inject

@AndroidEntryPoint
class MainActivity : ComponentActivity() {
    
    @Inject
    lateinit var speechPermissionHandler: SpeechPermissionHandler
    
    @Inject
    lateinit var notificationPermissionHandler: NotificationPermissionHandler
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // Initialize permission handlers
        speechPermissionHandler.initialize(this)
        notificationPermissionHandler.initialize(this)
        
        setContent {
            TaskTrackerTheme {
                Surface(
                    modifier = Modifier.fillMaxSize(),
                    color = MaterialTheme.colorScheme.background
                ) {
                    MainScreen(
                        highlightedTaskId = getHighlightedTaskId()
                    )
                }
            }
        }
    }
    
    override fun onNewIntent(intent: Intent?) {
        super.onNewIntent(intent)
        setIntent(intent)
        // Handle new intent when app is already running
        handleNotificationIntent(intent)
    }
    
    private fun getHighlightedTaskId(): String? {
        return if (intent?.action == "OPEN_TASK") {
            intent.getStringExtra(NotificationService.EXTRA_TASK_ID)
        } else {
            null
        }
    }
    
    private fun handleNotificationIntent(intent: Intent?) {
        if (intent?.action == "OPEN_TASK") {
            val taskId = intent.getStringExtra(NotificationService.EXTRA_TASK_ID)
            // Handle task highlighting - this would typically involve navigation
            // For now, we'll pass it to the MainScreen
        }
    }
}

@Preview(showBackground = true)
@Composable
fun MainActivityPreview() {
    TaskTrackerTheme {
        Surface(
            modifier = Modifier.fillMaxSize(),
            color = MaterialTheme.colorScheme.background
        ) {
            MainScreen()
        }
    }
}