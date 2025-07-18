package com.tasktracker.presentation.notifications

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import com.tasktracker.domain.repository.TaskRepository
import dagger.hilt.android.AndroidEntryPoint
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import javax.inject.Inject

@AndroidEntryPoint
class NotificationActionReceiver : BroadcastReceiver() {
    
    @Inject
    lateinit var taskRepository: TaskRepository
    
    @Inject
    lateinit var notificationService: NotificationService
    
    override fun onReceive(context: Context, intent: Intent) {
        val taskId = intent.getStringExtra(NotificationService.EXTRA_TASK_ID) ?: return
        val taskDescription = intent.getStringExtra(NotificationService.EXTRA_TASK_DESCRIPTION)
        
        when (intent.action) {
            "COMPLETE_TASK" -> {
                handleCompleteTask(taskId)
            }
            "SNOOZE_TASK" -> {
                handleSnoozeTask(taskId, taskDescription ?: "")
            }
            "DISMISS_NOTIFICATION" -> {
                handleDismissNotification(taskId)
            }
        }
    }
    
    private fun handleCompleteTask(taskId: String) {
        CoroutineScope(Dispatchers.IO).launch {
            try {
                taskRepository.completeTask(taskId)
                notificationService.cancelNotification(taskId)
            } catch (e: Exception) {
                // Log error or handle gracefully
            }
        }
    }
    
    private fun handleSnoozeTask(taskId: String, taskDescription: String) {
        CoroutineScope(Dispatchers.IO).launch {
            try {
                val task = taskRepository.getTaskById(taskId)
                if (task != null && !task.isCompleted) {
                    // Snooze for 10 minutes
                    val snoozeTime = System.currentTimeMillis() + (10 * 60 * 1000)
                    val snoozedTask = task.copy(reminderTime = snoozeTime)
                    taskRepository.updateTask(snoozedTask)
                }
                notificationService.cancelNotification(taskId)
            } catch (e: Exception) {
                // Log error or handle gracefully
            }
        }
    }
    
    private fun handleDismissNotification(taskId: String) {
        // Notification was dismissed by user
        // We can track this for analytics or other purposes
        notificationService.cancelNotification(taskId)
    }
}