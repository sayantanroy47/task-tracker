package com.tasktracker.testing

import com.tasktracker.domain.model.RecurrenceType
import com.tasktracker.domain.model.Task
import com.tasktracker.data.local.entity.TaskEntity
import com.tasktracker.data.local.entity.toDomainModel
import com.tasktracker.data.local.entity.toEntity
import org.junit.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNotNull
import kotlin.test.assertTrue
import kotlin.test.assertFailsWith

/**
 * Comprehensive bug detection tests that check for edge cases, boundary conditions,
 * and potential issues that could cause crashes or data corruption.
 */
class BugDetectionTest {
    
    @Test
    fun testTaskCreationEdgeCases() {
        // Test empty description
        val emptyTask = Task(description = "")
        assertTrue(emptyTask.description.isEmpty(), "Empty description should be preserved")
        
        // Test very long description
        val longDescription = "A".repeat(10000)
        val longTask = Task(description = longDescription)
        assertEquals(longDescription, longTask.description, "Long description should be preserved")
        
        // Test special characters
        val specialCharsTask = Task(description = "Task with 特殊字符 and émojis 🎉")
        assertNotNull(specialCharsTask.id, "Task with special characters should have valid ID")
        
        // Test null-like values
        val nullLikeTask = Task(description = "null")
        assertEquals("null", nullLikeTask.description, "String 'null' should be preserved")
    }
    
    @Test
    fun testTaskEntityConversionBugs() {
        // Test conversion with null recurrence type
        val taskWithNullRecurrence = Task(
            description = "Test task",
            recurrenceType = null
        )
        val entity = taskWithNullRecurrence.toEntity()
        val backToTask = entity.toDomainModel()
        
        assertEquals(taskWithNullRecurrence.description, backToTask.description)
        assertEquals(taskWithNullRecurrence.recurrenceType, backToTask.recurrenceType)
        
        // Test conversion with all recurrence types
        RecurrenceType.values().forEach { recurrenceType ->
            val taskWithRecurrence = Task(
                description = "Recurring task",
                recurrenceType = recurrenceType
            )
            val convertedEntity = taskWithRecurrence.toEntity()
            val convertedBack = convertedEntity.toDomainModel()
            
            assertEquals(recurrenceType, convertedBack.recurrenceType, 
                "Recurrence type $recurrenceType should be preserved")
        }
    }
    
    @Test
    fun testTimestampBoundaryConditions() {
        // Test with minimum timestamp
        val minTimestampTask = Task(
            description = "Min timestamp",
            createdAt = 0L
        )
        assertTrue(minTimestampTask.createdAt == 0L, "Minimum timestamp should be preserved")
        
        // Test with maximum timestamp
        val maxTimestampTask = Task(
            description = "Max timestamp",
            createdAt = Long.MAX_VALUE
        )
        assertTrue(maxTimestampTask.createdAt == Long.MAX_VALUE, "Maximum timestamp should be preserved")
        
        // Test with negative timestamp (edge case)
        val negativeTimestampTask = Task(
            description = "Negative timestamp",
            createdAt = -1L
        )
        assertTrue(negativeTimestampTask.createdAt == -1L, "Negative timestamp should be preserved")
    }
    
    @Test
    fun testReminderTimeBoundaryConditions() {
        // Test with past reminder time
        val pastReminderTask = Task(
            description = "Past reminder",
            reminderTime = System.currentTimeMillis() - 86400000L // 1 day ago
        )
        assertNotNull(pastReminderTask.reminderTime, "Past reminder time should be preserved")
        
        // Test with far future reminder time
        val futureReminderTask = Task(
            description = "Future reminder",
            reminderTime = System.currentTimeMillis() + (365L * 24 * 60 * 60 * 1000) // 1 year from now
        )
        assertNotNull(futureReminderTask.reminderTime, "Far future reminder time should be preserved")
        
        // Test with null reminder time
        val noReminderTask = Task(
            description = "No reminder",
            reminderTime = null
        )
        assertEquals(null, noReminderTask.reminderTime, "Null reminder time should be preserved")
    }
    
    @Test
    fun testRecurrenceIntervalEdgeCases() {
        // Test with zero interval (edge case)
        val zeroIntervalTask = Task(
            description = "Zero interval",
            recurrenceType = RecurrenceType.DAILY,
            recurrenceInterval = 0
        )
        assertEquals(0, zeroIntervalTask.recurrenceInterval, "Zero interval should be preserved")
        
        // Test with negative interval (edge case)
        val negativeIntervalTask = Task(
            description = "Negative interval",
            recurrenceType = RecurrenceType.WEEKLY,
            recurrenceInterval = -1
        )
        assertEquals(-1, negativeIntervalTask.recurrenceInterval, "Negative interval should be preserved")
        
        // Test with very large interval
        val largeIntervalTask = Task(
            description = "Large interval",
            recurrenceType = RecurrenceType.MONTHLY,
            recurrenceInterval = Int.MAX_VALUE
        )
        assertEquals(Int.MAX_VALUE, largeIntervalTask.recurrenceInterval, "Large interval should be preserved")
    }
    
    @Test
    fun testTaskCompletionStateConsistency() {
        // Test completed task without completion timestamp
        val completedTaskNoTimestamp = Task(
            description = "Completed without timestamp",
            isCompleted = true,
            completedAt = null
        )
        assertTrue(completedTaskNoTimestamp.isCompleted, "Task should be marked as completed")
        assertEquals(null, completedTaskNoTimestamp.completedAt, "Completion timestamp can be null")
        
        // Test incomplete task with completion timestamp (inconsistent state)
        val incompleteTaskWithTimestamp = Task(
            description = "Incomplete with timestamp",
            isCompleted = false,
            completedAt = System.currentTimeMillis()
        )
        assertFalse(incompleteTaskWithTimestamp.isCompleted, "Task should be marked as incomplete")
        assertNotNull(incompleteTaskWithTimestamp.completedAt, "Completion timestamp should be preserved")
    }
    
    @Test
    fun testTaskIdUniqueness() {
        // Create multiple tasks and verify unique IDs
        val tasks = (1..1000).map { Task(description = "Task $it") }
        val ids = tasks.map { it.id }.toSet()
        
        assertEquals(1000, ids.size, "All task IDs should be unique")
        
        // Verify no empty IDs
        tasks.forEach { task ->
            assertTrue(task.id.isNotEmpty(), "Task ID should not be empty")
        }
    }
    
    @Test
    fun testConcurrentTaskCreation() {
        // Simulate concurrent task creation
        val tasks = mutableListOf<Task>()
        val threads = (1..10).map { threadIndex ->
            Thread {
                repeat(100) { taskIndex ->
                    synchronized(tasks) {
                        tasks.add(Task(description = "Thread $threadIndex Task $taskIndex"))
                    }
                }
            }
        }
        
        threads.forEach { it.start() }
        threads.forEach { it.join() }
        
        assertEquals(1000, tasks.size, "Should create 1000 tasks")
        
        // Verify all IDs are unique
        val uniqueIds = tasks.map { it.id }.toSet()
        assertEquals(1000, uniqueIds.size, "All concurrent task IDs should be unique")
    }
    
    @Test
    fun testMemoryLeakPrevention() {
        // Create and discard many tasks to test for memory leaks
        repeat(10000) { index ->
            val task = Task(description = "Memory test task $index")
            // Task goes out of scope and should be garbage collected
        }
        
        // Force garbage collection
        System.gc()
        Thread.sleep(100) // Give GC time to run
        
        val runtime = Runtime.getRuntime()
        val usedMemory = runtime.totalMemory() - runtime.freeMemory()
        val maxMemory = runtime.maxMemory()
        val memoryUsagePercent = (usedMemory.toDouble() / maxMemory.toDouble()) * 100
        
        assertTrue(memoryUsagePercent < 90, "Memory usage should not exceed 90% after creating many tasks")
    }
    
    @Test
    fun testInvalidEnumHandling() {
        // Test with invalid recurrence type string in entity
        val entityWithInvalidRecurrence = TaskEntity(
            id = "test-id",
            description = "Test task",
            isCompleted = false,
            createdAt = System.currentTimeMillis(),
            recurrenceType = "INVALID_TYPE"
        )
        
        // This should handle the invalid enum gracefully
        assertFailsWith<IllegalArgumentException> {
            entityWithInvalidRecurrence.toDomainModel()
        }
    }
    
    @Test
    fun testNullSafetyInEntityConversion() {
        // Test entity with null values where not expected
        val entityWithNulls = TaskEntity(
            id = "",
            description = "",
            isCompleted = false,
            createdAt = 0L,
            recurrenceType = null,
            reminderTime = null,
            completedAt = null
        )
        
        val domainTask = entityWithNulls.toDomainModel()
        assertNotNull(domainTask, "Domain task should not be null")
        assertEquals("", domainTask.id, "Empty ID should be preserved")
        assertEquals("", domainTask.description, "Empty description should be preserved")
    }
    
    @Test
    fun testLargeDatasetHandling() {
        // Test with large number of tasks
        val largeTasks = (1..10000).map { index ->
            Task(
                description = "Large dataset task $index",
                isCompleted = index % 2 == 0,
                reminderTime = if (index % 3 == 0) System.currentTimeMillis() + index * 1000L else null,
                recurrenceType = when (index % 4) {
                    0 -> RecurrenceType.DAILY
                    1 -> RecurrenceType.WEEKLY
                    2 -> RecurrenceType.MONTHLY
                    else -> null
                }
            )
        }
        
        assertEquals(10000, largeTasks.size, "Should create 10000 tasks")
        
        // Test filtering performance
        val startTime = System.currentTimeMillis()
        val completedTasks = largeTasks.filter { it.isCompleted }
        val endTime = System.currentTimeMillis()
        
        assertTrue(endTime - startTime < 1000, "Filtering 10000 tasks should take less than 1 second")
        assertEquals(5000, completedTasks.size, "Should have 5000 completed tasks")
    }
    
    @Test
    fun testStringEncodingIssues() {
        // Test with various character encodings
        val unicodeTask = Task(description = "Unicode: 你好世界 🌍 Здравствуй мир")
        val entity = unicodeTask.toEntity()
        val backToTask = entity.toDomainModel()
        
        assertEquals(unicodeTask.description, backToTask.description, 
            "Unicode characters should be preserved through conversion")
        
        // Test with emoji
        val emojiTask = Task(description = "Emoji test: 🎉🚀💻📱⭐")
        val emojiEntity = emojiTask.toEntity()
        val emojiBackToTask = emojiEntity.toDomainModel()
        
        assertEquals(emojiTask.description, emojiBackToTask.description,
            "Emoji characters should be preserved through conversion")
    }
}