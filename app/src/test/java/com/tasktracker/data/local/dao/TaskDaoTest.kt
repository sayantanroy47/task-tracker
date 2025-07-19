package com.tasktracker.data.local.dao

import androidx.arch.core.executor.testing.InstantTaskExecutorRule
import androidx.room.Room
import androidx.test.core.app.ApplicationProvider
import androidx.test.ext.junit.runners.AndroidJUnit4
import com.tasktracker.data.local.TaskDatabase
import com.tasktracker.data.local.entity.TaskEntity
import com.tasktracker.domain.model.RecurrenceType
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.test.runTest
import org.junit.After
import org.junit.Assert.*
import org.junit.Before
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith

/**
 * Integration tests for TaskDao
 */
@RunWith(AndroidJUnit4::class)
class TaskDaoTest {

    @get:Rule
    val instantTaskExecutorRule = InstantTaskExecutorRule()

    private lateinit var database: TaskDatabase
    private lateinit var taskDao: TaskDao

    @Before
    fun setup() {
        database = Room.inMemoryDatabaseBuilder(
            ApplicationProvider.getApplicationContext(),
            TaskDatabase::class.java
        ).allowMainThreadQueries().build()
        
        taskDao = database.taskDao()
    }

    @After
    fun tearDown() {
        database.close()
    }

    @Test
    fun insertAndGetTask() = runTest {
        // Given
        val task = TaskEntity(
            id = "test-id",
            description = "Test task",
            isCompleted = false,
            createdAt = System.currentTimeMillis()
        )

        // When
        taskDao.insertTask(task)
        val retrievedTask = taskDao.getTaskById("test-id")

        // Then
        assertNotNull(retrievedTask)
        assertEquals(task.id, retrievedTask!!.id)
        assertEquals(task.description, retrievedTask.description)
        assertEquals(task.isCompleted, retrievedTask.isCompleted)
    }

    @Test
    fun getAllTasksFlow() = runTest {
        // Given
        val tasks = listOf(
            TaskEntity(
                id = "1",
                description = "Task 1",
                isCompleted = false,
                createdAt = System.currentTimeMillis()
            ),
            TaskEntity(
                id = "2",
                description = "Task 2",
                isCompleted = true,
                createdAt = System.currentTimeMillis() + 1000
            )
        )

        // When
        tasks.forEach { taskDao.insertTask(it) }
        val allTasks = taskDao.getAllTasksFlow().first()

        // Then
        assertEquals(2, allTasks.size)
        // Tasks should be ordered by created_at DESC
        assertEquals("Task 2", allTasks[0].description)
        assertEquals("Task 1", allTasks[1].description)
    }

    @Test
    fun getActiveTasks() = runTest {
        // Given
        val tasks = listOf(
            TaskEntity(
                id = "1",
                description = "Active task",
                isCompleted = false,
                createdAt = System.currentTimeMillis()
            ),
            TaskEntity(
                id = "2",
                description = "Completed task",
                isCompleted = true,
                createdAt = System.currentTimeMillis()
            )
        )

        // When
        tasks.forEach { taskDao.insertTask(it) }
        val activeTasks = taskDao.getActiveTasks()

        // Then
        assertEquals(1, activeTasks.size)
        assertEquals("Active task", activeTasks[0].description)
        assertFalse(activeTasks[0].isCompleted)
    }

    @Test
    fun getCompletedTasks() = runTest {
        // Given
        val tasks = listOf(
            TaskEntity(
                id = "1",
                description = "Active task",
                isCompleted = false,
                createdAt = System.currentTimeMillis()
            ),
            TaskEntity(
                id = "2",
                description = "Completed task",
                isCompleted = true,
                completedAt = System.currentTimeMillis(),
                createdAt = System.currentTimeMillis()
            )
        )

        // When
        tasks.forEach { taskDao.insertTask(it) }
        val completedTasks = taskDao.getCompletedTasks()

        // Then
        assertEquals(1, completedTasks.size)
        assertEquals("Completed task", completedTasks[0].description)
        assertTrue(completedTasks[0].isCompleted)
    }

    @Test
    fun updateTask() = runTest {
        // Given
        val originalTask = TaskEntity(
            id = "test-id",
            description = "Original description",
            isCompleted = false,
            createdAt = System.currentTimeMillis()
        )
        taskDao.insertTask(originalTask)

        // When
        val updatedTask = originalTask.copy(
            description = "Updated description",
            isCompleted = true,
            completedAt = System.currentTimeMillis()
        )
        taskDao.updateTask(updatedTask)

        // Then
        val retrievedTask = taskDao.getTaskById("test-id")
        assertNotNull(retrievedTask)
        assertEquals("Updated description", retrievedTask!!.description)
        assertTrue(retrievedTask.isCompleted)
        assertNotNull(retrievedTask.completedAt)
    }

    @Test
    fun deleteTask() = runTest {
        // Given
        val task = TaskEntity(
            id = "test-id",
            description = "Task to delete",
            isCompleted = false,
            createdAt = System.currentTimeMillis()
        )
        taskDao.insertTask(task)

        // When
        taskDao.deleteTask(task)
        val retrievedTask = taskDao.getTaskById("test-id")

        // Then
        assertNull(retrievedTask)
    }

    @Test
    fun deleteTaskById() = runTest {
        // Given
        val task = TaskEntity(
            id = "test-id",
            description = "Task to delete",
            isCompleted = false,
            createdAt = System.currentTimeMillis()
        )
        taskDao.insertTask(task)

        // When
        taskDao.deleteTaskById("test-id")
        val retrievedTask = taskDao.getTaskById("test-id")

        // Then
        assertNull(retrievedTask)
    }

    @Test
    fun insertTaskWithReminder() = runTest {
        // Given
        val reminderTime = System.currentTimeMillis() + 3600000 // 1 hour from now
        val task = TaskEntity(
            id = "reminder-task",
            description = "Task with reminder",
            isCompleted = false,
            reminderTime = reminderTime,
            createdAt = System.currentTimeMillis()
        )

        // When
        taskDao.insertTask(task)
        val retrievedTask = taskDao.getTaskById("reminder-task")

        // Then
        assertNotNull(retrievedTask)
        assertEquals(reminderTime, retrievedTask!!.reminderTime)
    }

    @Test
    fun insertRecurringTask() = runTest {
        // Given
        val task = TaskEntity(
            id = "recurring-task",
            description = "Daily recurring task",
            isCompleted = false,
            recurrenceType = RecurrenceType.DAILY,
            createdAt = System.currentTimeMillis()
        )

        // When
        taskDao.insertTask(task)
        val retrievedTask = taskDao.getTaskById("recurring-task")

        // Then
        assertNotNull(retrievedTask)
        assertEquals(RecurrenceType.DAILY, retrievedTask!!.recurrenceType)
    }

    @Test
    fun taskOrderingByCreatedAt() = runTest {
        // Given
        val now = System.currentTimeMillis()
        val tasks = listOf(
            TaskEntity(
                id = "1",
                description = "Oldest task",
                isCompleted = false,
                createdAt = now - 2000
            ),
            TaskEntity(
                id = "2",
                description = "Middle task",
                isCompleted = false,
                createdAt = now - 1000
            ),
            TaskEntity(
                id = "3",
                description = "Newest task",
                isCompleted = false,
                createdAt = now
            )
        )

        // When
        tasks.forEach { taskDao.insertTask(it) }
        val allTasks = taskDao.getAllTasksFlow().first()

        // Then
        assertEquals(3, allTasks.size)
        // Should be ordered by created_at DESC (newest first)
        assertEquals("Newest task", allTasks[0].description)
        assertEquals("Middle task", allTasks[1].description)
        assertEquals("Oldest task", allTasks[2].description)
    }

    @Test
    fun replaceTaskOnConflict() = runTest {
        // Given
        val originalTask = TaskEntity(
            id = "same-id",
            description = "Original task",
            isCompleted = false,
            createdAt = System.currentTimeMillis()
        )
        taskDao.insertTask(originalTask)

        // When - Insert task with same ID but different data
        val replacementTask = TaskEntity(
            id = "same-id",
            description = "Replacement task",
            isCompleted = true,
            createdAt = System.currentTimeMillis()
        )
        taskDao.insertTask(replacementTask)

        // Then
        val allTasks = taskDao.getAllTasks()
        assertEquals(1, allTasks.size) // Should still be only one task
        assertEquals("Replacement task", allTasks[0].description)
        assertTrue(allTasks[0].isCompleted)
    }
}