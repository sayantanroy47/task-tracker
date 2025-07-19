package com.tasktracker.integration

import androidx.arch.core.executor.testing.InstantTaskExecutorRule
import androidx.room.Room
import androidx.test.core.app.ApplicationProvider
import androidx.test.ext.junit.runners.AndroidJUnit4
import com.tasktracker.data.local.TaskDatabase
import com.tasktracker.data.local.dao.TaskDao
import com.tasktracker.data.repository.TaskRepositoryImpl
import com.tasktracker.domain.model.RecurrenceType
import com.tasktracker.domain.model.Task
import com.tasktracker.presentation.notifications.NotificationService
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.test.runTest
import org.junit.After
import org.junit.Assert.*
import org.junit.Before
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith
import org.mockito.Mock
import org.mockito.MockitoAnnotations

/**
 * Integration tests for TaskRepository with real database
 */
@RunWith(AndroidJUnit4::class)
class TaskRepositoryIntegrationTest {

    @get:Rule
    val instantTaskExecutorRule = InstantTaskExecutorRule()

    private lateinit var database: TaskDatabase
    private lateinit var taskDao: TaskDao
    private lateinit var repository: TaskRepositoryImpl

    @Mock
    private lateinit var notificationService: NotificationService

    @Before
    fun setup() {
        MockitoAnnotations.openMocks(this)
        
        database = Room.inMemoryDatabaseBuilder(
            ApplicationProvider.getApplicationContext(),
            TaskDatabase::class.java
        ).allowMainThreadQueries().build()
        
        taskDao = database.taskDao()
        repository = TaskRepositoryImpl(taskDao, notificationService)
    }

    @After
    fun tearDown() {
        database.close()
    }

    @Test
    fun fullTaskLifecycle() = runTest {
        // Create task
        val task = Task(
            id = "lifecycle-test",
            description = "Test task lifecycle"
        )
        repository.insertTask(task)

        // Verify task was created
        val allTasks = repository.getAllTasks().first()
        assertEquals(1, allTasks.size)
        assertEquals(task.description, allTasks[0].description)
        assertFalse(allTasks[0].isCompleted)

        // Update task to completed
        val completedTask = task.copy(
            isCompleted = true,
            completedAt = System.currentTimeMillis()
        )
        repository.updateTask(completedTask)

        // Verify task was updated
        val activeTasks = repository.getActiveTasks().first()
        val completedTasks = repository.getCompletedTasks().first()
        assertEquals(0, activeTasks.size)
        assertEquals(1, completedTasks.size)
        assertTrue(completedTasks[0].isCompleted)

        // Delete task
        repository.deleteTask(task.id)

        // Verify task was deleted
        val finalTasks = repository.getAllTasks().first()
        assertEquals(0, finalTasks.size)
    }

    @Test
    fun taskWithReminderIntegration() = runTest {
        // Given
        val reminderTime = System.currentTimeMillis() + 3600000 // 1 hour from now
        val task = Task(
            id = "reminder-test",
            description = "Task with reminder",
            reminderTime = reminderTime
        )

        // When
        repository.insertTask(task)

        // Then
        val tasksWithReminders = repository.getTasksWithReminders()
        assertEquals(1, tasksWithReminders.size)
        assertEquals(reminderTime, tasksWithReminders[0].reminderTime)
        assertTrue(tasksWithReminders[0].hasReminder())
    }

    @Test
    fun recurringTaskIntegration() = runTest {
        // Given
        val task = Task(
            id = "recurring-test",
            description = "Daily recurring task",
            recurrenceType = RecurrenceType.DAILY
        )

        // When
        repository.insertTask(task)

        // Then
        val recurringTasks = repository.getRecurringTasks()
        assertEquals(1, recurringTasks.size)
        assertEquals(RecurrenceType.DAILY, recurringTasks[0].recurrenceType)
        assertTrue(recurringTasks[0].isRecurring())
    }

    @Test
    fun multipleTasksFiltering() = runTest {
        // Given
        val tasks = listOf(
            Task(id = "1", description = "Active task 1", isCompleted = false),
            Task(id = "2", description = "Active task 2", isCompleted = false),
            Task(id = "3", description = "Completed task 1", isCompleted = true, completedAt = System.currentTimeMillis()),
            Task(id = "4", description = "Completed task 2", isCompleted = true, completedAt = System.currentTimeMillis())
        )

        // When
        tasks.forEach { repository.insertTask(it) }

        // Then
        val allTasks = repository.getAllTasks().first()
        val activeTasks = repository.getActiveTasks().first()
        val completedTasks = repository.getCompletedTasks().first()

        assertEquals(4, allTasks.size)
        assertEquals(2, activeTasks.size)
        assertEquals(2, completedTasks.size)

        assertTrue(activeTasks.all { !it.isCompleted })
        assertTrue(completedTasks.all { it.isCompleted })
    }

    @Test
    fun searchTasksIntegration() = runTest {
        // Given
        val tasks = listOf(
            Task(id = "1", description = "Buy groceries"),
            Task(id = "2", description = "Call dentist"),
            Task(id = "3", description = "Buy birthday gift"),
            Task(id = "4", description = "Schedule meeting")
        )
        tasks.forEach { repository.insertTask(it) }

        // When
        val searchResults = repository.searchTasks("buy").first()

        // Then
        assertEquals(2, searchResults.size)
        assertTrue(searchResults.all { it.description.contains("buy", ignoreCase = true) })
    }

    @Test
    fun batchTaskOperations() = runTest {
        // Given
        val tasks = (1..10).map { i ->
            Task(
                id = "batch-$i",
                description = "Batch task $i",
                isCompleted = i % 2 == 0 // Even numbered tasks are completed
            )
        }

        // When
        repository.insertTasks(tasks)

        // Then
        val allTasks = repository.getAllTasks().first()
        val activeTasks = repository.getActiveTasks().first()
        val completedTasks = repository.getCompletedTasks().first()

        assertEquals(10, allTasks.size)
        assertEquals(5, activeTasks.size) // Odd numbered tasks (1,3,5,7,9)
        assertEquals(5, completedTasks.size) // Even numbered tasks (2,4,6,8,10)
    }

    @Test
    fun deleteCompletedTasksIntegration() = runTest {
        // Given
        val tasks = listOf(
            Task(id = "1", description = "Active task", isCompleted = false),
            Task(id = "2", description = "Completed task 1", isCompleted = true, completedAt = System.currentTimeMillis()),
            Task(id = "3", description = "Completed task 2", isCompleted = true, completedAt = System.currentTimeMillis())
        )
        tasks.forEach { repository.insertTask(it) }

        // When
        repository.deleteAllCompletedTasks()

        // Then
        val remainingTasks = repository.getAllTasks().first()
        assertEquals(1, remainingTasks.size)
        assertEquals("Active task", remainingTasks[0].description)
        assertFalse(remainingTasks[0].isCompleted)
    }

    @Test
    fun taskPersistenceAcrossRepositoryInstances() = runTest {
        // Given
        val task = Task(
            id = "persistence-test",
            description = "Test persistence"
        )
        repository.insertTask(task)

        // When - Create new repository instance with same database
        val newRepository = TaskRepositoryImpl(taskDao, notificationService)
        val retrievedTasks = newRepository.getAllTasks().first()

        // Then
        assertEquals(1, retrievedTasks.size)
        assertEquals(task.description, retrievedTasks[0].description)
        assertEquals(task.id, retrievedTasks[0].id)
    }

    @Test
    fun concurrentTaskOperations() = runTest {
        // Given
        val task1 = Task(id = "concurrent-1", description = "Concurrent task 1")
        val task2 = Task(id = "concurrent-2", description = "Concurrent task 2")

        // When - Perform concurrent operations
        repository.insertTask(task1)
        repository.insertTask(task2)
        repository.updateTask(task1.copy(isCompleted = true))

        // Then
        val allTasks = repository.getAllTasks().first()
        assertEquals(2, allTasks.size)
        
        val task1Result = allTasks.find { it.id == "concurrent-1" }
        val task2Result = allTasks.find { it.id == "concurrent-2" }
        
        assertNotNull(task1Result)
        assertNotNull(task2Result)
        assertTrue(task1Result!!.isCompleted)
        assertFalse(task2Result!!.isCompleted)
    }
}