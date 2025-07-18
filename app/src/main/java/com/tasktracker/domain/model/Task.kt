package com.tasktracker.domain.model

import java.util.UUID

/**
 * Domain model representing a task in the task tracker application.
 * 
 * @param id Unique identifier for the task
 * @param description The task description entered by the user
 * @param isCompleted Whether the task has been completed
 * @param createdAt Timestamp when the task was created (milliseconds since epoch)
 * @param reminderTime Optional timestamp for when to remind the user (milliseconds since epoch)
 * @param recurrenceType Optional recurrence pattern for the task
 * @param recurrenceInterval Interval for recurrence (default 1, e.g., every 1 day/week/month)
 * @param completedAt Optional timestamp when the task was completed (milliseconds since epoch)
 */
data class Task(
    val id: String = UUID.randomUUID().toString(),
    val description: String,
    val isCompleted: Boolean = false,
    val createdAt: Long = System.currentTimeMillis(),
    val reminderTime: Long? = null,
    val recurrenceType: RecurrenceType? = null,
    val recurrenceInterval: Int = 1,
    val completedAt: Long? = null
) {
    /**
     * Validates that the task has a non-empty description.
     */
    fun isValid(): Boolean {
        return description.isNotBlank()
    }
    
    /**
     * Checks if this task has a reminder set.
     */
    fun hasReminder(): Boolean {
        return reminderTime != null && reminderTime > System.currentTimeMillis()
    }
    
    /**
     * Checks if this task is recurring.
     */
    fun isRecurring(): Boolean {
        return recurrenceType != null
    }
    
    /**
     * Creates a copy of this task marked as completed.
     */
    fun markAsCompleted(): Task {
        return copy(
            isCompleted = true,
            completedAt = System.currentTimeMillis()
        )
    }
    
    /**
     * Creates the next instance of a recurring task.
     * Returns null if this task is not recurring.
     */
    fun createNextRecurrence(): Task? {
        if (!isRecurring() || recurrenceType == null) return null
        
        val nextReminderTime = reminderTime?.let { currentReminder ->
            when (recurrenceType) {
                RecurrenceType.DAILY -> currentReminder + (24 * 60 * 60 * 1000L * recurrenceInterval)
                RecurrenceType.WEEKLY -> currentReminder + (7 * 24 * 60 * 60 * 1000L * recurrenceInterval)
                RecurrenceType.MONTHLY -> {
                    // Approximate monthly recurrence (30 days)
                    currentReminder + (30 * 24 * 60 * 60 * 1000L * recurrenceInterval)
                }
            }
        }
        
        return copy(
            id = UUID.randomUUID().toString(),
            isCompleted = false,
            createdAt = System.currentTimeMillis(),
            reminderTime = nextReminderTime,
            completedAt = null
        )
    }
}