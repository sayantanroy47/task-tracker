package com.tasktracker.domain.model

import org.junit.Assert.*
import org.junit.Test
import java.util.UUID

/**
 * Unit tests for Task domain model
 */
class TaskTest {

    @Test
    fun `task creation with default values`() {
        val task = Task(
            id = "test-id",
            description = "Test task"
        )

        assertEquals("test-id", task.id)
        assertEquals("Test task", task.description)
        assertFalse(task.isCompleted)
        assertNull(task.reminderTime)
        assertNull(task.recurrenceType)
        assertNull(task.completedAt)
        assertTrue(task.createdAt > 0)
    }

    @Test
    fun `task completion updates completedAt timestamp`() {
        val task = Task(
            id = "test-id",
            description = "Test task"
        )

        val completedTask = task.copy(
            isCompleted = true,
            completedAt = System.currentTimeMillis()
        )

        assertTrue(completedTask.isCompleted)
        assertNotNull(completedTask.completedAt)
        assertTrue(completedTask.completedAt!! > task.createdAt)
    }

    @Test
    fun `task with reminder has reminder time`() {
        val reminderTime = System.currentTimeMillis() + 3600000 // 1 hour from now
        val task = Task(
            id = "test-id",
            description = "Test task with reminder",
            reminderTime = reminderTime
        )

        assertTrue(task.hasReminder())
        assertEquals(reminderTime, task.reminderTime)
    }

    @Test
    fun `task with recurrence is recurring`() {
        val task = Task(
            id = "test-id",
            description = "Recurring task",
            recurrenceType = RecurrenceType.DAILY
        )

        assertTrue(task.isRecurring())
        assertEquals(RecurrenceType.DAILY, task.recurrenceType)
    }

    @Test
    fun `task without reminder returns false for hasReminder`() {
        val task = Task(
            id = "test-id",
            description = "Task without reminder"
        )

        assertFalse(task.hasReminder())
        assertNull(task.reminderTime)
    }

    @Test
    fun `task without recurrence returns false for isRecurring`() {
        val task = Task(
            id = "test-id",
            description = "Non-recurring task"
        )

        assertFalse(task.isRecurring())
        assertNull(task.recurrenceType)
    }

    @Test
    fun `task id generation is unique`() {
        val task1 = Task(description = "Task 1")
        val task2 = Task(description = "Task 2")

        assertNotEquals(task1.id, task2.id)
        assertTrue(task1.id.isNotEmpty())
        assertTrue(task2.id.isNotEmpty())
    }

    @Test
    fun `task equality based on id`() {
        val id = UUID.randomUUID().toString()
        val task1 = Task(id = id, description = "Task 1")
        val task2 = Task(id = id, description = "Task 2")

        assertEquals(task1, task2) // Same ID means same task
    }

    @Test
    fun `task copy preserves original values`() {
        val originalTask = Task(
            id = "original-id",
            description = "Original description",
            isCompleted = false,
            reminderTime = 123456789L,
            recurrenceType = RecurrenceType.WEEKLY
        )

        val copiedTask = originalTask.copy(description = "Updated description")

        assertEquals(originalTask.id, copiedTask.id)
        assertEquals("Updated description", copiedTask.description)
        assertEquals(originalTask.isCompleted, copiedTask.isCompleted)
        assertEquals(originalTask.reminderTime, copiedTask.reminderTime)
        assertEquals(originalTask.recurrenceType, copiedTask.recurrenceType)
        assertEquals(originalTask.createdAt, copiedTask.createdAt)
    }
}