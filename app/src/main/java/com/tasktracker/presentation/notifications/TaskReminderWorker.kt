package com.tasktracker.presentation.notifications

import android.content.Context
import androidx.hilt.work.HiltWorker
import androidx.work.CoroutineWorker
import androidx.work.WorkerParameters
import com.tasktracker.domain.repository.TaskRepository
import dagger.assisted.Assisted
import dagger.assisted.AssistedInject
import kotlinx.coroutines.flow.first

@HiltWorker
class TaskReminderWorker @AssistedInject constructor(
    @Assisted context: Context,
    @Assisted workerParams: WorkerParameters,
    private val notificationService: NotificationService,
    private val taskRepository: TaskRepository
) : CoroutineWorker(context, workerParams) {

    override suspend fun doWork(): Result {
        return try {
            val taskId = inputData.getString(NotificationService.EXTRA_TASK_ID)
                ?: return Result.failure()
            val taskDescription = inputData.getString(NotificationService.EXTRA_TASK_DESCRIPTION)
                ?: return Result.failure()
            
            // Check if task still exists and is not completed
            val tasks = taskRepository.getAllTasks().first()
            val task = tasks.find { it.id == taskId }
            
            if (task != null && !task.isCompleted) {
                // Show notification only if task is still active
                notificationService.showTaskReminderNotification(taskId, taskDescription)
                Result.success()
            } else {
                // Task was completed or deleted, no need to show notification
                Result.success()
            }
        } catch (e: Exception) {
            Result.failure()
        }
    }
}