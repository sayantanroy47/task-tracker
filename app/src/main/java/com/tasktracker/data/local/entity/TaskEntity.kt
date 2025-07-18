package com.tasktracker.data.local.entity

import androidx.room.ColumnInfo
import androidx.room.Entity
import androidx.room.Index
import androidx.room.PrimaryKey
import com.tasktracker.domain.model.RecurrenceType
import com.tasktracker.domain.model.Task

/**
 * Room entity representing a task in the local database.
 * This is the data layer representation that maps to the database table.
 */
@Entity(
    tableName = "tasks",
    indices = [
        Index(value = ["is_completed"]),
        Index(value = ["reminder_time"]),
        Index(value = ["created_at"])
    ]
)
data class TaskEntity(
    @PrimaryKey
    val id: String,
    
    @ColumnInfo(name = "description")
    val description: String,
    
    @ColumnInfo(name = "is_completed")
    val isCompleted: Boolean = false,
    
    @ColumnInfo(name = "created_at")
    val createdAt: Long,
    
    @ColumnInfo(name = "reminder_time")
    val reminderTime: Long? = null,
    
    @ColumnInfo(name = "recurrence_type")
    val recurrenceType: String? = null,
    
    @ColumnInfo(name = "recurrence_interval")
    val recurrenceInterval: Int = 1,
    
    @ColumnInfo(name = "completed_at")
    val completedAt: Long? = null
)

/**
 * Extension functions to convert between domain model and entity
 */
fun TaskEntity.toDomainModel(): Task {
    return Task(
        id = id,
        description = description,
        isCompleted = isCompleted,
        createdAt = createdAt,
        reminderTime = reminderTime,
        recurrenceType = recurrenceType?.let { RecurrenceType.valueOf(it) },
        recurrenceInterval = recurrenceInterval,
        completedAt = completedAt
    )
}

fun Task.toEntity(): TaskEntity {
    return TaskEntity(
        id = id,
        description = description,
        isCompleted = isCompleted,
        createdAt = createdAt,
        reminderTime = reminderTime,
        recurrenceType = recurrenceType?.name,
        recurrenceInterval = recurrenceInterval,
        completedAt = completedAt
    )
}