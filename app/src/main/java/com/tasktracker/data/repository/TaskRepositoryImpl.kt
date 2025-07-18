package com.tasktracker.data.repository

import com.tasktracker.data.local.TaskDao
import com.tasktracker.data.local.entity.toDomainModel
import com.tasktracker.data.local.entity.toEntity
import com.tasktracker.domain.model.Task
import com.tasktracker.domain.repository.TaskRepository
import com.tasktracker.presentation.notifications.NotificationService
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map
import javax.inject.Inject
import javax.inject.Singleton

/**
 * Implementation of TaskRepository that uses Room database as the data source.
 * Handles data conversion between domain models and database entities.
 */
@Singleton
class TaskRepositoryImpl @Inject constructor(
    private val taskDao: TaskDao,
    private val notificationService: NotificationService
) : TaskRepository {

    override fun getAllTasks(): Flow<List<Task>> {
        return taskDao.getAllTasks().map { entities ->
            entities.map { it.toDomainModel() }
        }
    }

    override fun getActiveTasks(): Flow<List<Task>> {
        return taskDao.getActiveTasks().map { entities ->
            entities.map { it.toDomainModel() }
        }
    }

    override fun getCompletedTasks(): Flow<List<Task>> {
        return taskDao.getCompletedTasks().map { entities ->
            entities.map { it.toDomainModel() }
        }
    }

    override suspend fun getTaskById(taskId: String): Task? {
        return taskDao.getTaskById(taskId)?.toDomainModel()
    }

    override suspend fun getTasksWithReminders(): List<Task> {
        return taskDao.getTasksWithReminders().map { it.toDomainModel() }
    }

    override suspend fun getRecurringTasks(): List<Task> {
        return taskDao.getRecurringTasks().map { it.toDomainModel() }
    }

    override suspend fun insertTask(task: Task) {
        try {
            taskDao.insertTask(task.toEntity())
            
            // Schedule reminder notification if task has a reminder time
            if (task.hasReminder()) {
                try {
                    notificationService.scheduleTaskReminder(task)
                } catch (e: Exception) {
                    // Log notification scheduling error but don't fail task creation
                    // The task is still created successfully even if notification fails
                }
            }
        } catch (e: Exception) {
            throw TaskStorageException("Failed to create task: ${e.message}", e)
        }
    }

    override suspend fun insertTasks(tasks: List<Task>) {
        taskDao.insertTasks(tasks.map { it.toEntity() })
    }

    override suspend fun updateTask(task: Task) {
        try {
            taskDao.updateTask(task.toEntity())
            
            // Update notification scheduling based on task changes
            if (task.hasReminder() && !task.isCompleted) {
                try {
                    notificationService.scheduleTaskReminder(task)
                } catch (e: Exception) {
                    // Log notification scheduling error but don't fail task update
                }
            } else {
                notificationService.cancelTaskReminder(task.id)
            }
        } catch (e: Exception) {
            throw TaskStorageException("Failed to update task: ${e.message}", e)
        }
    }

    override suspend fun deleteTask(task: Task) {
        taskDao.deleteTask(task.toEntity())
        
        // Cancel any scheduled notifications for this task
        notificationService.cancelTaskReminder(task.id)
    }

    override suspend fun deleteTaskById(taskId: String) {
        taskDao.deleteTaskById(taskId)
        
        // Cancel any scheduled notifications for this task
        notificationService.cancelTaskReminder(taskId)
    }

    override suspend fun completeTask(taskId: String) {
        val task = getTaskById(taskId) ?: return
        
        // Cancel any pending notifications for this task
        notificationService.cancelTaskReminder(taskId)
        
        // Mark the current task as completed
        val completedTask = task.markAsCompleted()
        taskDao.updateTask(completedTask.toEntity()) // Direct DAO call to avoid notification rescheduling
        
        // If it's a recurring task, create the next instance
        if (task.isRecurring()) {
            val nextTask = task.createNextRecurrence()
            nextTask?.let { insertTask(it) }
        }
    }

    override suspend fun deleteAllCompletedTasks() {
        taskDao.deleteAllCompletedTasks()
    }

    override suspend fun getActiveTaskCount(): Int {
        return taskDao.getActiveTaskCount()
    }

    override suspend fun getCompletedTaskCount(): Int {
        return taskDao.getCompletedTaskCount()
    }

    override fun searchTasks(searchQuery: String): Flow<List<Task>> {
        return taskDao.searchTasks(searchQuery).map { entities ->
            entities.map { it.toDomainModel() }
        }
    }
}