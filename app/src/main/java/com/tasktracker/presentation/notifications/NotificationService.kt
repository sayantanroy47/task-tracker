package com.tasktracker.presentation.notifications

import android.Manifest
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.core.content.ContextCompat
import androidx.work.ExistingWorkPolicy
import androidx.work.OneTimeWorkRequestBuilder
import androidx.work.WorkManager
import androidx.work.workDataOf
import com.tasktracker.R
import com.tasktracker.domain.model.Task
import com.tasktracker.presentation.MainActivity
import dagger.hilt.android.qualifiers.ApplicationContext
import java.util.concurrent.TimeUnit
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class NotificationService @Inject constructor(
    @ApplicationContext private val context: Context
) {
    private val notificationManager = NotificationManagerCompat.from(context)
    private val workManager = WorkManager.getInstance(context)
    
    companion object {
        const val CHANNEL_ID_REMINDERS = "task_reminders"
        const val CHANNEL_ID_GENERAL = "general_notifications"
        const val NOTIFICATION_ID_BASE = 1000
        const val EXTRA_TASK_ID = "task_id"
        const val EXTRA_TASK_DESCRIPTION = "task_description"
    }
    
    init {
        createNotificationChannels()
    }
    
    private fun createNotificationChannels() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            // Reminder notifications channel
            val reminderChannel = NotificationChannel(
                CHANNEL_ID_REMINDERS,
                "Task Reminders",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Notifications for task reminders"
                enableVibration(true)
                setShowBadge(true)
            }
            
            // General notifications channel
            val generalChannel = NotificationChannel(
                CHANNEL_ID_GENERAL,
                "General Notifications",
                NotificationManager.IMPORTANCE_DEFAULT
            ).apply {
                description = "General app notifications"
                setShowBadge(true)
            }
            
            val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            manager.createNotificationChannel(reminderChannel)
            manager.createNotificationChannel(generalChannel)
        }
    }
    
    fun scheduleTaskReminder(task: Task) {
        val reminderTime = task.reminderTime ?: return
        val currentTime = System.currentTimeMillis()
        
        if (reminderTime <= currentTime) {
            return // Don't schedule past reminders
        }
        
        val delay = reminderTime - currentTime
        val workRequest = OneTimeWorkRequestBuilder<TaskReminderWorker>()
            .setInitialDelay(delay, TimeUnit.MILLISECONDS)
            .setInputData(
                workDataOf(
                    EXTRA_TASK_ID to task.id,
                    EXTRA_TASK_DESCRIPTION to task.description
                )
            )
            .addTag("reminder_${task.id}")
            .build()
        
        workManager.enqueueUniqueWork(
            "reminder_${task.id}",
            ExistingWorkPolicy.REPLACE,
            workRequest
        )
    }
    
    fun cancelTaskReminder(taskId: String) {
        workManager.cancelUniqueWork("reminder_$taskId")
    }
    
    fun showTaskReminderNotification(taskId: String, taskDescription: String) {
        if (!hasNotificationPermission()) {
            return
        }
        
        // Main intent to open the app and highlight the task
        val mainIntent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
            putExtra(EXTRA_TASK_ID, taskId)
            action = "OPEN_TASK"
        }
        
        val mainPendingIntent = PendingIntent.getActivity(
            context,
            taskId.hashCode(),
            mainIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        
        // Complete task action
        val completeIntent = Intent(context, NotificationActionReceiver::class.java).apply {
            action = "COMPLETE_TASK"
            putExtra(EXTRA_TASK_ID, taskId)
            putExtra(EXTRA_TASK_DESCRIPTION, taskDescription)
        }
        
        val completePendingIntent = PendingIntent.getBroadcast(
            context,
            (taskId + "_complete").hashCode(),
            completeIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        
        // Snooze task action
        val snoozeIntent = Intent(context, NotificationActionReceiver::class.java).apply {
            action = "SNOOZE_TASK"
            putExtra(EXTRA_TASK_ID, taskId)
            putExtra(EXTRA_TASK_DESCRIPTION, taskDescription)
        }
        
        val snoozePendingIntent = PendingIntent.getBroadcast(
            context,
            (taskId + "_snooze").hashCode(),
            snoozeIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        
        val notification = NotificationCompat.Builder(context, CHANNEL_ID_REMINDERS)
            .setSmallIcon(R.drawable.ic_notification)
            .setContentTitle("Task Reminder")
            .setContentText(taskDescription)
            .setStyle(
                NotificationCompat.BigTextStyle()
                    .bigText("Don't forget: $taskDescription")
            )
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setAutoCancel(true)
            .setContentIntent(mainPendingIntent)
            .setCategory(NotificationCompat.CATEGORY_REMINDER)
            .addAction(
                R.drawable.ic_check,
                "Complete",
                completePendingIntent
            )
            .addAction(
                R.drawable.ic_snooze,
                "Snooze 10m",
                snoozePendingIntent
            )
            .setDeleteIntent(createDismissIntent(taskId))
            .build()
        
        val notificationId = NOTIFICATION_ID_BASE + taskId.hashCode()
        notificationManager.notify(notificationId, notification)
    }
    
    private fun createDismissIntent(taskId: String): PendingIntent {
        val dismissIntent = Intent(context, NotificationActionReceiver::class.java).apply {
            action = "DISMISS_NOTIFICATION"
            putExtra(EXTRA_TASK_ID, taskId)
        }
        
        return PendingIntent.getBroadcast(
            context,
            (taskId + "_dismiss").hashCode(),
            dismissIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
    }
    
    fun hasNotificationPermission(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            ContextCompat.checkSelfPermission(
                context,
                Manifest.permission.POST_NOTIFICATIONS
            ) == PackageManager.PERMISSION_GRANTED
        } else {
            notificationManager.areNotificationsEnabled()
        }
    }
    
    fun cancelAllNotifications() {
        notificationManager.cancelAll()
    }
    
    fun cancelNotification(taskId: String) {
        val notificationId = NOTIFICATION_ID_BASE + taskId.hashCode()
        notificationManager.cancel(notificationId)
    }
}