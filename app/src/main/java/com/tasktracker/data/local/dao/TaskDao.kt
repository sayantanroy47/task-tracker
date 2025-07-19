package com.tasktracker.data.local.dao

import androidx.room.Dao
import androidx.room.Delete
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import androidx.room.Update
import com.tasktracker.data.local.entity.TaskEntity
import kotlinx.coroutines.flow.Flow

/**
 * DAO for task-related database operations
 */
@Dao
interface TaskDao {
    
    @Query("SELECT * FROM tasks ORDER BY created_at DESC")
    fun getAllTasksFlow(): Flow<List<TaskEntity>>
    
    @Query("SELECT * FROM tasks ORDER BY created_at DESC")
    suspend fun getAllTasks(): List<TaskEntity>
    
    @Query("SELECT * FROM tasks WHERE is_completed = 0 ORDER BY created_at ASC")
    suspend fun getActiveTasks(): List<TaskEntity>
    
    @Query("SELECT * FROM tasks WHERE is_completed = 1 ORDER BY completed_at DESC")
    suspend fun getCompletedTasks(): List<TaskEntity>
    
    @Query("SELECT * FROM tasks WHERE id = :taskId")
    suspend fun getTaskById(taskId: String): TaskEntity?
    
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertTask(task: TaskEntity)
    
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertTasks(tasks: List<TaskEntity>)
    
    @Update
    suspend fun updateTask(task: TaskEntity)
    
    @Delete
    suspend fun deleteTask(task: TaskEntity)
    
    @Query("DELETE FROM tasks WHERE id = :taskId")
    suspend fun deleteTaskById(taskId: String)
    
    @Query("UPDATE tasks SET is_completed = 1, completed_at = :completedAt WHERE id = :taskId")
    suspend fun markTaskCompleted(taskId: String, completedAt: Long)
    
    @Query("UPDATE tasks SET is_completed = 0, completed_at = NULL WHERE id = :taskId")
    suspend fun markTaskIncomplete(taskId: String)
    
    @Query("SELECT COUNT(*) FROM tasks WHERE is_completed = 0")
    suspend fun getActiveTaskCount(): Int
    
    @Query("SELECT COUNT(*) FROM tasks WHERE is_completed = 1")
    suspend fun getCompletedTaskCount(): Int
    
    @Query("DELETE FROM tasks WHERE is_completed = 1 AND completed_at < :cutoffTime")
    suspend fun deleteOldCompletedTasks(cutoffTime: Long)
}