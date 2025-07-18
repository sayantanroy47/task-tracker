package com.tasktracker.domain.repository

import com.tasktracker.domain.model.Task
import kotlinx.coroutines.flow.Flow

/**
 * Repository interface for task data operations.
 * Provides a clean API for the domain layer to interact with task data.
 */
interface TaskRepository {
    
    /**
     * Get all tasks as a reactive stream.
     */
    fun getAllTasks(): Flow<List<Task>>
    
    /**
     * Get all active (incomplete) tasks as a reactive stream.
     */
    fun getActiveTasks(): Flow<List<Task>>
    
    /**
     * Get all completed tasks as a reactive stream.
     */
    fun getCompletedTasks(): Flow<List<Task>>
    
    /**
     * Get a specific task by ID.
     */
    suspend fun getTaskById(taskId: String): Task?
    
    /**
     * Get all tasks that have reminders set and are not completed.
     */
    suspend fun getTasksWithReminders(): List<Task>
    
    /**
     * Get all recurring tasks that are not completed.
     */
    suspend fun getRecurringTasks(): List<Task>
    
    /**
     * Insert a new task.
     */
    suspend fun insertTask(task: Task)
    
    /**
     * Insert multiple tasks.
     */
    suspend fun insertTasks(tasks: List<Task>)
    
    /**
     * Update an existing task.
     */
    suspend fun updateTask(task: Task)
    
    /**
     * Delete a specific task.
     */
    suspend fun deleteTask(task: Task)
    
    /**
     * Delete a task by ID.
     */
    suspend fun deleteTaskById(taskId: String)
    
    /**
     * Complete a task by ID with automatic timestamp and recurring task creation.
     */
    suspend fun completeTask(taskId: String)
    
    /**
     * Delete all completed tasks (for cleanup).
     */
    suspend fun deleteAllCompletedTasks()
    
    /**
     * Get count of active tasks.
     */
    suspend fun getActiveTaskCount(): Int
    
    /**
     * Get count of completed tasks.
     */
    suspend fun getCompletedTaskCount(): Int
    
    /**
     * Search tasks by description.
     */
    fun searchTasks(searchQuery: String): Flow<List<Task>>
}