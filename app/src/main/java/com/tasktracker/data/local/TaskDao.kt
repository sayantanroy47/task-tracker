package com.tasktracker.data.local

import androidx.paging.PagingSource
import androidx.room.*
import com.tasktracker.data.local.entity.TaskEntity
import kotlinx.coroutines.flow.Flow

/**
 * Data Access Object for Task operations in Room database.
 * Provides reactive data streams using Flow for UI updates.
 * Optimized for performance with proper indexing and pagination support.
 */
@Dao
interface TaskDao {
    
    /**
     * Get all tasks ordered by creation date (newest first).
     */
    @Query("SELECT * FROM tasks ORDER BY created_at DESC")
    fun getAllTasks(): Flow<List<TaskEntity>>
    
    /**
     * Get all active (incomplete) tasks ordered by creation date.
     */
    @Query("SELECT * FROM tasks WHERE is_completed = 0 ORDER BY created_at DESC")
    fun getActiveTasks(): Flow<List<TaskEntity>>
    
    /**
     * Get all completed tasks ordered by completion date (newest first).
     */
    @Query("SELECT * FROM tasks WHERE is_completed = 1 ORDER BY completed_at DESC")
    fun getCompletedTasks(): Flow<List<TaskEntity>>
    
    /**
     * Get a specific task by ID.
     */
    @Query("SELECT * FROM tasks WHERE id = :taskId")
    suspend fun getTaskById(taskId: String): TaskEntity?
    
    /**
     * Get all tasks that have reminders set and are not completed.
     */
    @Query("SELECT * FROM tasks WHERE reminder_time IS NOT NULL AND is_completed = 0")
    suspend fun getTasksWithReminders(): List<TaskEntity>
    
    /**
     * Get all recurring tasks that are not completed.
     */
    @Query("SELECT * FROM tasks WHERE recurrence_type IS NOT NULL AND is_completed = 0")
    suspend fun getRecurringTasks(): List<TaskEntity>
    
    /**
     * Insert a new task.
     */
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertTask(task: TaskEntity)
    
    /**
     * Insert multiple tasks.
     */
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertTasks(tasks: List<TaskEntity>)
    
    /**
     * Update an existing task.
     */
    @Update
    suspend fun updateTask(task: TaskEntity)
    
    /**
     * Delete a specific task.
     */
    @Delete
    suspend fun deleteTask(task: TaskEntity)
    
    /**
     * Delete a task by ID.
     */
    @Query("DELETE FROM tasks WHERE id = :taskId")
    suspend fun deleteTaskById(taskId: String)
    
    /**
     * Mark a task as completed by ID.
     */
    @Query("UPDATE tasks SET is_completed = 1, completed_at = :completedAt WHERE id = :taskId")
    suspend fun markTaskCompleted(taskId: String, completedAt: Long)
    
    /**
     * Delete all completed tasks (for cleanup).
     */
    @Query("DELETE FROM tasks WHERE is_completed = 1")
    suspend fun deleteAllCompletedTasks()
    
    /**
     * Get count of active tasks.
     */
    @Query("SELECT COUNT(*) FROM tasks WHERE is_completed = 0")
    suspend fun getActiveTaskCount(): Int
    
    /**
     * Get count of completed tasks.
     */
    @Query("SELECT COUNT(*) FROM tasks WHERE is_completed = 1")
    suspend fun getCompletedTaskCount(): Int
    
    /**
     * Search tasks by description (case-insensitive).
     */
    @Query("SELECT * FROM tasks WHERE description LIKE '%' || :searchQuery || '%' ORDER BY created_at DESC")
    fun searchTasks(searchQuery: String): Flow<List<TaskEntity>>
    
    // Performance-optimized queries for large datasets
    
    /**
     * Get active tasks with pagination support for large lists.
     */
    @Query("SELECT * FROM tasks WHERE is_completed = 0 ORDER BY created_at DESC")
    fun getActiveTasksPaged(): PagingSource<Int, TaskEntity>
    
    /**
     * Get completed tasks with pagination support.
     */
    @Query("SELECT * FROM tasks WHERE is_completed = 1 ORDER BY completed_at DESC")
    fun getCompletedTasksPaged(): PagingSource<Int, TaskEntity>
    
    /**
     * Get active tasks with limit for performance (used for quick previews).
     */
    @Query("SELECT * FROM tasks WHERE is_completed = 0 ORDER BY created_at DESC LIMIT :limit")
    suspend fun getActiveTasksLimited(limit: Int = 50): List<TaskEntity>
    
    /**
     * Get completed tasks with limit for performance.
     */
    @Query("SELECT * FROM tasks WHERE is_completed = 1 ORDER BY completed_at DESC LIMIT :limit")
    suspend fun getCompletedTasksLimited(limit: Int = 50): List<TaskEntity>
    
    /**
     * Get tasks due for reminders in the next hour (optimized for notification worker).
     */
    @Query("""
        SELECT * FROM tasks 
        WHERE is_completed = 0 
        AND reminder_time IS NOT NULL 
        AND reminder_time BETWEEN :startTime AND :endTime
        ORDER BY reminder_time ASC
    """)
    suspend fun getTasksDueForReminders(startTime: Long, endTime: Long): List<TaskEntity>
    
    /**
     * Bulk update task completion status (for performance).
     */
    @Query("UPDATE tasks SET is_completed = :isCompleted, completed_at = :completedAt WHERE id IN (:taskIds)")
    suspend fun bulkUpdateTaskCompletion(taskIds: List<String>, isCompleted: Boolean, completedAt: Long?)
    
    /**
     * Delete old completed tasks (cleanup operation).
     */
    @Query("DELETE FROM tasks WHERE is_completed = 1 AND completed_at < :cutoffTime")
    suspend fun deleteOldCompletedTasks(cutoffTime: Long): Int
}