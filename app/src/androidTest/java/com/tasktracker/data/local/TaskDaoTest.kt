package com.tasktracker.data.local

import androidx.arch.core.executor.testing.InstantTaskExecutorRule
import androidx.room.Room
import androidx.test.core.app.ApplicationProvider
import androidx.test.ext.junit.runners.AndroidJUnit4
import com.tasktracker.data.local.entity.TaskEntity
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.test.runTest
import org.junit.After
import org.junit.Assert.*
import org.junit.Before
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith

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
    fun teardown() {
        database.close()
    }

    @Test
    fun insertTask_and_getTaskById() = runTest {
        val task = TaskEntity(
            id = "test-id",
            description = "Test task",
            isCompleted = false,
            createdAt = System.currentTimeMillis()
        )

        taskDao.insertTask(task)
        val retrievedTask = taskDao.getTaskById("test-id")

        assertNotNull(retrievedTask)
        assertEquals(task.id, retrievedTask!!.id)
        assertEquals(task.description, retrievedTask.description)
        assertEquals(task.isCompleted, retrievedTask.isCompleted)
    }

    @Test
    fun getAllTasks_returnsTasksOrderedByCreatedAt() = runTest {
        val task1 = TaskEntity(
            id = "task1",
            description = "First task",
            isCompleted = false,
            createdAt = 1000L
        )
        val task2 = TaskEntity(
            id = "task2",
            description = "Second task",
            isCompleted = false,
            createdAt = 2000L
        )

        taskDao.insertTask(task1)
        taskDao.insertTask(task2)

        val tasks = taskDao.getAllTasks().first()
        assertEquals(2, tasks.size)
        // Should be ordered by created_at DESC (newest first)
        assertEquals("task2", tasks[0].id)
        assertEquals("task1", tasks[1].id)
    }

    @Test
    fun getActiveTasks_returnsOnlyIncompleteTasks() = runTest {
        val activeTask = TaskEntity(
            id = "active",
            description = "Active task",
            isCompleted = false,
            createdAt = System.currentTimeMillis()
        )
        val completedTask = TaskEntity(
            id = "completed",
            description = "Completed task",
            isCompleted = true,
            createdAt = System.currentTimeMillis(),
            completedAt = System.currentTimeMillis()
        )

        taskDao.insertTask(activeTask)
        taskDao.insertTask(completedTask)

        val activeTasks = taskDao.getActiveTasks().first()
        assertEquals(1, activeTasks.size)
        assertEquals("active", activeTasks[0].id)
        assertFalse(activeTasks[0].isCompleted)
    }

    @Test
    fun getCompletedTasks_returnsOnlyCompletedTasks() = runTest {
        val activeTask = TaskEntity(
            id = "active",
            description = "Active task",
            isCompleted = false,
            createdAt = System.currentTimeMillis()
        )
        val completedTask = TaskEntity(
            id = "completed",
            description = "Completed task",
            isCompleted = true,
            createdAt = System.currentTimeMillis(),
            completedAt = System.currentTimeMillis()
        )

        taskDao.insertTask(activeTask)
        taskDao.insertTask(completedTask)

        val completedTasks = taskDao.getCompletedTasks().first()
        assertEquals(1, completedTasks.size)
        assertEquals("completed", completedTasks[0].id)
        assertTrue(completedTasks[0].isCompleted)
    }

    @Test
    fun markTaskCompleted_updatesTaskStatus() = runTest {
        val task = TaskEntity(
            id = "test-task",
            description = "Test task",
            isCompleted = false,
            createdAt = System.currentTimeMillis()
        )

        taskDao.insertTask(task)
        val completedAt = System.currentTimeMillis()
        taskDao.markTaskCompleted("test-task", completedAt)

        val updatedTask = taskDao.getTaskById("test-task")
        assertNotNull(updatedTask)
        assertTrue(updatedTask!!.isCompleted)
        assertEquals(completedAt, updatedTask.completedAt)
    }

    @Test
    fun deleteTaskById_removesTask() = runTest {
        val task = TaskEntity(
            id = "to-delete",
            description = "Task to delete",
            isCompleted = false,
            createdAt = System.currentTimeMillis()
        )

        taskDao.insertTask(task)
        taskDao.deleteTaskById("to-delete")

        val deletedTask = taskDao.getTaskById("to-delete")
        assertNull(deletedTask)
    }

    @Test
    fun getTasksWithReminders_returnsOnlyTasksWithReminders() = runTest {
        val taskWithReminder = TaskEntity(
            id = "reminder-task",
            description = "Task with reminder",
            isCompleted = false,
            createdAt = System.currentTimeMillis(),
            reminderTime = System.currentTimeMillis() + 60000
        )
        val taskWithoutReminder = TaskEntity(
            id = "no-reminder-task",
            description = "Task without reminder",
            isCompleted = false,
            createdAt = System.currentTimeMillis()
        )

        taskDao.insertTask(taskWithReminder)
        taskDao.insertTask(taskWithoutReminder)

        val tasksWithReminders = taskDao.getTasksWithReminders()
        assertEquals(1, tasksWithReminders.size)
        assertEquals("reminder-task", tasksWithReminders[0].id)
        assertNotNull(tasksWithReminders[0].reminderTime)
    }

    @Test
    fun getRecurringTasks_returnsOnlyRecurringTasks() = runTest {
        val recurringTask = TaskEntity(
            id = "recurring-task",
            description = "Recurring task",
            isCompleted = false,
            createdAt = System.currentTimeMillis(),
            recurrenceType = "DAILY"
        )
        val nonRecurringTask = TaskEntity(
            id = "non-recurring-task",
            description = "Non-recurring task",
            isCompleted = false,
            createdAt = System.currentTimeMillis()
        )

        taskDao.insertTask(recurringTask)
        taskDao.insertTask(nonRecurringTask)

        val recurringTasks = taskDao.getRecurringTasks()
        assertEquals(1, recurringTasks.size)
        assertEquals("recurring-task", recurringTasks[0].id)
        assertNotNull(recurringTasks[0].recurrenceType)
    }

    @Test
    fun searchTasks_returnsMatchingTasks() = runTest {
        val task1 = TaskEntity(
            id = "task1",
            description = "Buy groceries",
            isCompleted = false,
            createdAt = System.currentTimeMillis()
        )
        val task2 = TaskEntity(
            id = "task2",
            description = "Call doctor",
            isCompleted = false,
            createdAt = System.currentTimeMillis()
        )

        taskDao.insertTask(task1)
        taskDao.insertTask(task2)

        val searchResults = taskDao.searchTasks("groceries").first()
        assertEquals(1, searchResults.size)
        assertEquals("task1", searchResults[0].id)
    }

    @Test
    fun getActiveTaskCount_returnsCorrectCount() = runTest {
        val activeTask1 = TaskEntity(
            id = "active1",
            description = "Active task 1",
            isCompleted = false,
            createdAt = System.currentTimeMillis()
        )
        val activeTask2 = TaskEntity(
            id = "active2",
            description = "Active task 2",
            isCompleted = false,
            createdAt = System.currentTimeMillis()
        )
        val completedTask = TaskEntity(
            id = "completed",
            description = "Completed task",
            isCompleted = true,
            createdAt = System.currentTimeMillis(),
            completedAt = System.currentTimeMillis()
        )

        taskDao.insertTask(activeTask1)
        taskDao.insertTask(activeTask2)
        taskDao.insertTask(completedTask)

        val activeCount = taskDao.getActiveTaskCount()
        assertEquals(2, activeCount)
    }

    @Test
    fun deleteAllCompletedTasks_removesOnlyCompletedTasks() = runTest {
        val activeTask = TaskEntity(
            id = "active",
            description = "Active task",
            isCompleted = false,
            createdAt = System.currentTimeMillis()
        )
        val completedTask = TaskEntity(
            id = "completed",
            description = "Completed task",
            isCompleted = true,
            createdAt = System.currentTimeMillis(),
            completedAt = System.currentTimeMillis()
        )

        taskDao.insertTask(activeTask)
        taskDao.insertTask(completedTask)

        taskDao.deleteAllCompletedTasks()

        val allTasks = taskDao.getAllTasks().first()
        assertEquals(1, allTasks.size)
        assertEquals("active", allTasks[0].id)
        assertFalse(allTasks[0].isCompleted)
    }
}