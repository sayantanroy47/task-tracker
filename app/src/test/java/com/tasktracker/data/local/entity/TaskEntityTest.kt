package com.tasktracker.data.local.entity

import com.tasktracker.domain.model.RecurrenceType
import com.tasktracker.domain.model.Task
import org.junit.Assert.*
import org.junit.Test

/**
 * Unit tests for TaskEntity and its conversion functions
 */
class TaskEntityTest {

    @Test
    fun `taskEntity creation with required fields`() {
        // Given
        val entity = TaskEntity(
            id = "test-id",
            description = "Test task",
            isCompleted = false,
            createdAt = System.currentTimeMillis()
        )

        // Then
        assertEquals("test-id", entity.id)
        assertEquals("Test task", entity.description)
        assertFalse(entity.isCompleted)
        assertNull(entity.reminderTime)
        assertNull(entity.recurrenceType)
        assertNull(entity.completedAt)
        assertTrue(entity.createdAt > 0)
    }

    @Test
    fun `taskEntity with all fields`() {
        // Given
        val now = System.currentTimeMillis()
        val entity = TaskEntity(
            id = "full-test-id",
            description = "Full test task",
            isCompleted = true,
            reminderTime = now + 3600000,
            recurrenceType = RecurrenceType.WEEKLY,
            completedAt = now,
            createdAt = now - 1000
        )

        // Then
        assertEquals("full-test-id", entity.id)
        assertEquals("Full test task", entity.description)
        assertTrue(entity.isCompleted)
        assertEquals(now + 3600000, entity.reminderTime)
        assertEquals(RecurrenceType.WEEKLY, entity.recurrenceType)
        assertEquals(now, entity.completedAt)
        assertEquals(now - 1000, entity.createdAt)
    }

    @Test
    fun `task to entity conversion`() {
        // Given
        val task = Task(
            id = "domain-id",
            description = "Domain task",
            isCompleted = true,
            reminderTime = 123456789L,
            recurrenceType = RecurrenceType.DAILY,
            completedAt = 987654321L,
            createdAt = 111111111L
        )

        // When
        val entity = task.toEntity()

        // Then
        assertEquals(task.id, entity.id)
        assertEquals(task.description, entity.description)
        assertEquals(task.isCompleted, entity.isCompleted)
        assertEquals(task.reminderTime, entity.reminderTime)
        assertEquals(task.recurrenceType, entity.recurrenceType)
        assertEquals(task.completedAt, entity.completedAt)
        assertEquals(task.createdAt, entity.createdAt)
    }

    @Test
    fun `entity to domain model conversion`() {
        // Given
        val entity = TaskEntity(
            id = "entity-id",
            description = "Entity task",
            isCompleted = false,
            reminderTime = 555555555L,
            recurrenceType = RecurrenceType.MONTHLY,
            completedAt = null,
            createdAt = 222222222L
        )

        // When
        val task = entity.toDomainModel()

        // Then
        assertEquals(entity.id, task.id)
        assertEquals(entity.description, task.description)
        assertEquals(entity.isCompleted, task.isCompleted)
        assertEquals(entity.reminderTime, task.reminderTime)
        assertEquals(entity.recurrenceType, task.recurrenceType)
        assertEquals(entity.completedAt, task.completedAt)
        assertEquals(entity.createdAt, task.createdAt)
    }

    @Test
    fun `round trip conversion preserves data`() {
        // Given
        val originalTask = Task(
            id = "round-trip-id",
            description = "Round trip task",
            isCompleted = true,
            reminderTime = 777777777L,
            recurrenceType = RecurrenceType.WEEKLY,
            completedAt = 888888888L,
            createdAt = 666666666L
        )

        // When
        val entity = originalTask.toEntity()
        val convertedTask = entity.toDomainModel()

        // Then
        assertEquals(originalTask, convertedTask)
    }

    @Test
    fun `entity with null optional fields converts correctly`() {
        // Given
        val entity = TaskEntity(
            id = "minimal-id",
            description = "Minimal task",
            isCompleted = false,
            reminderTime = null,
            recurrenceType = null,
            completedAt = null,
            createdAt = System.currentTimeMillis()
        )

        // When
        val task = entity.toDomainModel()

        // Then
        assertEquals(entity.id, task.id)
        assertEquals(entity.description, task.description)
        assertEquals(entity.isCompleted, task.isCompleted)
        assertNull(task.reminderTime)
        assertNull(task.recurrenceType)
        assertNull(task.completedAt)
        assertEquals(entity.createdAt, task.createdAt)
    }

    @Test
    fun `task with null optional fields converts correctly`() {
        // Given
        val task = Task(
            id = "minimal-domain-id",
            description = "Minimal domain task",
            isCompleted = false,
            reminderTime = null,
            recurrenceType = null,
            completedAt = null,
            createdAt = System.currentTimeMillis()
        )

        // When
        val entity = task.toEntity()

        // Then
        assertEquals(task.id, entity.id)
        assertEquals(task.description, entity.description)
        assertEquals(task.isCompleted, entity.isCompleted)
        assertNull(entity.reminderTime)
        assertNull(entity.recurrenceType)
        assertNull(entity.completedAt)
        assertEquals(task.createdAt, entity.createdAt)
    }

    @Test
    fun `entity equality based on id`() {
        // Given
        val entity1 = TaskEntity(
            id = "same-id",
            description = "Task 1",
            isCompleted = false,
            createdAt = System.currentTimeMillis()
        )
        val entity2 = TaskEntity(
            id = "same-id",
            description = "Task 2",
            isCompleted = true,
            createdAt = System.currentTimeMillis()
        )

        // Then
        assertEquals(entity1, entity2) // Same ID means same entity
    }

    @Test
    fun `entity copy preserves original values`() {
        // Given
        val originalEntity = TaskEntity(
            id = "copy-id",
            description = "Original description",
            isCompleted = false,
            reminderTime = 123456789L,
            recurrenceType = RecurrenceType.DAILY,
            completedAt = null,
            createdAt = 111111111L
        )

        // When
        val copiedEntity = originalEntity.copy(
            description = "Updated description",
            isCompleted = true
        )

        // Then
        assertEquals(originalEntity.id, copiedEntity.id)
        assertEquals("Updated description", copiedEntity.description)
        assertTrue(copiedEntity.isCompleted)
        assertEquals(originalEntity.reminderTime, copiedEntity.reminderTime)
        assertEquals(originalEntity.recurrenceType, copiedEntity.recurrenceType)
        assertEquals(originalEntity.completedAt, copiedEntity.completedAt)
        assertEquals(originalEntity.createdAt, copiedEntity.createdAt)
    }

    @Test
    fun `entity handles all recurrence types`() {
        // Given
        val recurrenceTypes = RecurrenceType.values()

        recurrenceTypes.forEach { recurrenceType ->
            // When
            val entity = TaskEntity(
                id = "recurrence-test-${recurrenceType.name}",
                description = "Task with ${recurrenceType.name} recurrence",
                isCompleted = false,
                recurrenceType = recurrenceType,
                createdAt = System.currentTimeMillis()
            )

            // Then
            assertEquals(recurrenceType, entity.recurrenceType)
            
            // Test conversion
            val task = entity.toDomainModel()
            assertEquals(recurrenceType, task.recurrenceType)
        }
    }
}