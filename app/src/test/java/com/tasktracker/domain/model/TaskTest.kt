package com.tasktracker.domain.model

import org.junit.Assert.*
import org.junit.Test

class TaskTest {

    @Test
    fun `task creation with default values`() {
        val task = Task(description = "Test task")
        
        assertNotNull(task.id)
        assertEquals("Test task", task.description)
        assertFalse(task.isCompleted)
        assertTrue(task.createdAt > 0)
        assertNull(task.reminderTime)
        assertNull(task.recurrenceType)
        assertEquals(1, task.recurrenceInterval)
        assertNull(task.completedAt)
    }

    @Test
    fun `task validation with valid description`() {
        val task = Task(description = "Valid task")
        assertTrue(task.isValid())
    }

    @Test
    fun `task validation with empty description`() {
        val task = Task(description = "")
        assertFalse(task.isValid())
    }

    @Test
    fun `task validation with blank description`() {
        val task = Task(description = "   ")
        assertFalse(task.isValid())
    }

    @Test
    fun `hasReminder returns true for future reminder`() {
        val futureTime = System.currentTimeMillis() + 60000 // 1 minute from now
        val task = Task(description = "Test", reminderTime = futureTime)
        assertTrue(task.hasReminder())
    }

    @Test
    fun `hasReminder returns false for past reminder`() {
        val pastTime = System.currentTimeMillis() - 60000 // 1 minute ago
        val task = Task(description = "Test", reminderTime = pastTime)
        assertFalse(task.hasReminder())
    }

    @Test
    fun `hasReminder returns false for null reminder`() {
        val task = Task(description = "Test", reminderTime = null)
        assertFalse(task.hasReminder())
    }

    @Test
    fun `isRecurring returns true when recurrence type is set`() {
        val task = Task(description = "Test", recurrenceType = RecurrenceType.DAILY)
        assertTrue(task.isRecurring())
    }

    @Test
    fun `isRecurring returns false when recurrence type is null`() {
        val task = Task(description = "Test", recurrenceType = null)
        assertFalse(task.isRecurring())
    }

    @Test
    fun `markAsCompleted sets completion status and timestamp`() {
        val task = Task(description = "Test")
        val completedTask = task.markAsCompleted()
        
        assertTrue(completedTask.isCompleted)
        assertNotNull(completedTask.completedAt)
        assertTrue(completedTask.completedAt!! > task.createdAt)
    }

    @Test
    fun `createNextRecurrence returns null for non-recurring task`() {
        val task = Task(description = "Test")
        assertNull(task.createNextRecurrence())
    }

    @Test
    fun `createNextRecurrence creates new instance for daily recurring task`() {
        val reminderTime = System.currentTimeMillis() + 60000
        val task = Task(
            description = "Daily task",
            recurrenceType = RecurrenceType.DAILY,
            reminderTime = reminderTime
        )
        
        val nextTask = task.createNextRecurrence()
        
        assertNotNull(nextTask)
        assertNotEquals(task.id, nextTask!!.id)
        assertEquals(task.description, nextTask.description)
        assertFalse(nextTask.isCompleted)
        assertNull(nextTask.completedAt)
        assertEquals(task.recurrenceType, nextTask.recurrenceType)
        assertTrue(nextTask.reminderTime!! > task.reminderTime!!)
    }

    @Test
    fun `createNextRecurrence creates new instance for weekly recurring task`() {
        val reminderTime = System.currentTimeMillis() + 60000
        val task = Task(
            description = "Weekly task",
            recurrenceType = RecurrenceType.WEEKLY,
            reminderTime = reminderTime
        )
        
        val nextTask = task.createNextRecurrence()
        
        assertNotNull(nextTask)
        assertNotEquals(task.id, nextTask!!.id)
        assertEquals(task.description, nextTask.description)
        assertFalse(nextTask.isCompleted)
        assertEquals(task.recurrenceType, nextTask.recurrenceType)
        assertTrue(nextTask.reminderTime!! > task.reminderTime!!)
    }

    @Test
    fun `createNextRecurrence creates new instance for monthly recurring task`() {
        val reminderTime = System.currentTimeMillis() + 60000
        val task = Task(
            description = "Monthly task",
            recurrenceType = RecurrenceType.MONTHLY,
            reminderTime = reminderTime
        )
        
        val nextTask = task.createNextRecurrence()
        
        assertNotNull(nextTask)
        assertNotEquals(task.id, nextTask!!.id)
        assertEquals(task.description, nextTask.description)
        assertFalse(nextTask.isCompleted)
        assertEquals(task.recurrenceType, nextTask.recurrenceType)
        assertTrue(nextTask.reminderTime!! > task.reminderTime!!)
    }

    @Test
    fun `createNextRecurrence handles null reminder time`() {
        val task = Task(
            description = "Recurring task without reminder",
            recurrenceType = RecurrenceType.DAILY,
            reminderTime = null
        )
        
        val nextTask = task.createNextRecurrence()
        
        assertNotNull(nextTask)
        assertNull(nextTask!!.reminderTime)
    }
}