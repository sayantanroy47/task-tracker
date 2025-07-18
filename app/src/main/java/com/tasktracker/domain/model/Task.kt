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
            calculateNextReminderTime(currentReminder, recurrenceType, recurrenceInterval)
        }
        
        return copy(
            id = UUID.randomUUID().toString(),
            isCompleted = false,
            createdAt = System.currentTimeMillis(),
            reminderTime = nextReminderTime,
            completedAt = null
        )
    }
    
    /**
     * Calculates the next reminder time based on recurrence pattern.
     * Handles edge cases like month-end dates for monthly recurrence.
     */
    private fun calculateNextReminderTime(
        currentTime: Long,
        recurrenceType: RecurrenceType,
        interval: Int
    ): Long {
        val calendar = java.util.Calendar.getInstance().apply {
            timeInMillis = currentTime
        }
        
        when (recurrenceType) {
            RecurrenceType.DAILY -> {
                calendar.add(java.util.Calendar.DAY_OF_MONTH, interval)
            }
            RecurrenceType.WEEKLY -> {
                calendar.add(java.util.Calendar.WEEK_OF_YEAR, interval)
            }
            RecurrenceType.MONTHLY -> {
                val originalDay = calendar.get(java.util.Calendar.DAY_OF_MONTH)
                calendar.add(java.util.Calendar.MONTH, interval)
                
                // Handle month-end edge cases (e.g., Jan 31 -> Feb 28/29)
                val maxDayInNewMonth = calendar.getActualMaximum(java.util.Calendar.DAY_OF_MONTH)
                if (originalDay > maxDayInNewMonth) {
                    calendar.set(java.util.Calendar.DAY_OF_MONTH, maxDayInNewMonth)
                } else {
                    calendar.set(java.util.Calendar.DAY_OF_MONTH, originalDay)
                }
            }
        }
        
        return calendar.timeInMillis
    }
}