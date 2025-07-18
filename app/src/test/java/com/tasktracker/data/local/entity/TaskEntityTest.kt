package com.tasktracker.data.local.entity

import com.tasktracker.domain.model.RecurrenceType
import com.tasktracker.domain.model.Task
import org.junit.Assert.*
import org.junit.Test

class TaskEntityTest {

    @Test
    fun `toDomainModel converts TaskEntity to Task correctly`() {
        val taskEntity = TaskEntity(
            id = "test-id",
            description = "Test task",
            isCompleted = false,
            createdAt = 1000L,
            reminderTime = 2000L,
            recurrenceType = "DAILY",
            recurrenceInterval = 2,
            completedAt = null
        )

        val domainTask = taskEntity.toDomainModel()

        assertEquals(taskEntity.id, domainTask.id)
        assertEquals(taskEntity.description, domainTask.description)
        assertEquals(taskEntity.isCompleted, domainTask.isCompleted)
        assertEquals(taskEntity.createdAt, domainTask.createdAt)
        assertEquals(taskEntity.reminderTime, domainTask.reminderTime)
        assertEquals(RecurrenceType.DAILY, domainTask.recurrenceType)
        assertEquals(taskEntity.recurrenceInterval, domainTask.recurrenceInterval)
        assertEquals(taskEntity.completedAt, domainTask.completedAt)
    }

    @Test
    fun `toDomainModel handles null recurrenceType correctly`() {
        val taskEntity = TaskEntity(
            id = "test-id",
            description = "Test task",
            isCompleted = false,
            createdAt = 1000L,
            recurrenceType = null
        )

        val domainTask = taskEntity.toDomainModel()

        assertNull(domainTask.recurrenceType)
    }

    @Test
    fun `toEntity converts Task to TaskEntity correctly`() {
        val domainTask = Task(
            id = "test-id",
            description = "Test task",
            isCompleted = true,
            createdAt = 1000L,
            reminderTime = 2000L,
            recurrenceType = RecurrenceType.WEEKLY,
            recurrenceInterval = 3,
            completedAt = 3000L
        )

        val taskEntity = domainTask.toEntity()

        assertEquals(domainTask.id, taskEntity.id)
        assertEquals(domainTask.description, taskEntity.description)
        assertEquals(domainTask.isCompleted, taskEntity.isCompleted)
        assertEquals(domainTask.createdAt, taskEntity.createdAt)
        assertEquals(domainTask.reminderTime, taskEntity.reminderTime)
        assertEquals("WEEKLY", taskEntity.recurrenceType)
        assertEquals(domainTask.recurrenceInterval, taskEntity.recurrenceInterval)
        assertEquals(domainTask.completedAt, taskEntity.completedAt)
    }

    @Test
    fun `toEntity handles null recurrenceType correctly`() {
        val domainTask = Task(
            id = "test-id",
            description = "Test task",
            isCompleted = false,
            createdAt = 1000L,
            recurrenceType = null
        )

        val taskEntity = domainTask.toEntity()

        assertNull(taskEntity.recurrenceType)
    }

    @Test
    fun `conversion roundtrip preserves data integrity`() {
        val originalTask = Task(
            id = "roundtrip-test",
            description = "Roundtrip test task",
            isCompleted = true,
            createdAt = 1000L,
            reminderTime = 2000L,
            recurrenceType = RecurrenceType.MONTHLY,
            recurrenceInterval = 1,
            completedAt = 3000L
        )

        val convertedTask = originalTask.toEntity().toDomainModel()

        assertEquals(originalTask.id, convertedTask.id)
        assertEquals(originalTask.description, convertedTask.description)
        assertEquals(originalTask.isCompleted, convertedTask.isCompleted)
        assertEquals(originalTask.createdAt, convertedTask.createdAt)
        assertEquals(originalTask.reminderTime, convertedTask.reminderTime)
        assertEquals(originalTask.recurrenceType, convertedTask.recurrenceType)
        assertEquals(originalTask.recurrenceInterval, convertedTask.recurrenceInterval)
        assertEquals(originalTask.completedAt, convertedTask.completedAt)
    }
}