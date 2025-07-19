package com.tasktracker.data.repository

import com.tasktracker.data.local.dao.TaskDao
import com.tasktracker.data.local.entity.TaskEntity
import com.tasktracker.domain.model.RecurrenceType
import com.tasktracker.domain.model.Task
import com.tasktracker.presentation.notifications.NotificationService
import kotlinx.coroutines.flow.flowOf
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.test.runTest
import org.junit.Assert.*
import org.junit.Before
import org.junit.Test
import org.mockito.Mock
import org.mockito.MockitoAnnotations
import org.mockito.kotlin.verify
import org.mockito.kotlin.whenever

/**
 * Unit tests for TaskRepositoryImpl
 */
class TaskRepositoryImplTest {

    @Mock
    private lateinit var taskDao: TaskDao

    @Mock
    private lateinit var notificationService: NotificationService

    private lateinit var repository: TaskRepositoryImpl

    @Before
    fun setup() {
        MockitoAnnotations.openMocks(this)
        repository = TaskRepositoryImpl(taskDao, notificationService)
    }

    @Test
    fun `getAllTasks returns mapped domain models`() = runTest {
        // Given
        val taskEntities = listOf(
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
                createdAt = System.currentTimeMillis()
            )
        )
        whenever(taskDao.getAllTasksFlow()).thenReturn(flowOf(taskEntities))

        // When
        val result = repository.getAllTasks().first()

        // Then
        assertEquals(2, result.size)
        assertEquals("Task 1", result[0].description)
        assertEquals("Task 2", result[1].description)
        assertFalse(result[0].isCompleted)
        assertTrue(result[1].isCompleted)
    }

    @Test
    fun `getActiveTasks filters out completed tasks`() = runTest {
        // Given
        val taskEntities = listOf(
            TaskEntity(
                id = "1",
                description = "Active Task",
                isCompleted = false,
                createdAt = System.currentTimeMillis()
            ),
            TaskEntity(
                id = "2",
                description = "Completed Task",
                isCompleted = true,
                createdAt = System.currentTimeMillis()
            )
        )
        whenever(taskDao.getAllTasksFlow()).thenReturn(flowOf(taskEntities))

        // When
        val result = repository.getActiveTasks().first()

        // Then
        assertEquals(1, result.size)
        assertEquals("Active Task", result[0].description)
        assertFalse(result[0].isCompleted)
    }

    @Test
    fun `getCompletedTasks filters out active tasks`() = runTest {
        // Given
        val taskEntities = listOf(
            TaskEntity(
                id = "1",
                description = "Active Task",
                isCompleted = false,
                createdAt = System.currentTimeMillis()
            ),
            TaskEntity(
                id = "2",
                description = "Completed Task",
                isCompleted = true,
                createdAt = System.currentTimeMillis()
            )
        )
        whenever(taskDao.getAllTasksFlow()).thenReturn(flowOf(taskEntities))

        // When
        val result = repository.getCompletedTasks().first()

        // Then
        assertEquals(1, result.size)
        assertEquals("Completed Task", result[0].description)
        assertTrue(result[0].isCompleted)
    }

    @Test
    fun `insertTask calls dao with mapped entity`() = runTest {
        // Given
        val task = Task(
            id = "test-id",
            description = "Test task"
        )

        // When
        repository.insertTask(task)

        // Then
        verify(taskDao).insertTask(
            TaskEntity(
                id = task.id,
                description = task.description,
                isCompleted = task.isCompleted,
                reminderTime = task.reminderTime,
                recurrenceType = task.recurrenceType,
                completedAt = task.completedAt,
                createdAt = task.createdAt
            )
        )
    }

    @Test
    fun `updateTask calls dao with mapped entity`() = runTest {
        // Given
        val task = Task(
            id = "test-id",
            description = "Updated task",
            isCompleted = true
        )

        // When
        repository.updateTask(task)

        // Then
        verify(taskDao).updateTask(
            TaskEntity(
                id = task.id,
                description = task.description,
                isCompleted = task.isCompleted,
                reminderTime = task.reminderTime,
                recurrenceType = task.recurrenceType,
                completedAt = task.completedAt,
                createdAt = task.createdAt
            )
        )
    }

    @Test
    fun `deleteTask calls dao with task id`() = runTest {
        // Given
        val taskId = "test-id"

        // When
        repository.deleteTask(taskId)

        // Then
        verify(taskDao).deleteTaskById(taskId)
    }

    @Test
    fun `getTasksWithReminders filters tasks with reminder time`() = runTest {
        // Given
        val taskEntities = listOf(
            TaskEntity(
                id = "1",
                description = "Task with reminder",
                isCompleted = false,
                reminderTime = System.currentTimeMillis() + 3600000,
                createdAt = System.currentTimeMillis()
            ),
            TaskEntity(
                id = "2",
                description = "Task without reminder",
                isCompleted = false,
                reminderTime = null,
                createdAt = System.currentTimeMillis()
            )
        )
        whenever(taskDao.getAllTasks()).thenReturn(taskEntities)

        // When
        val result = repository.getTasksWithReminders()

        // Then
        assertEquals(1, result.size)
        assertEquals("Task with reminder", result[0].description)
        assertNotNull(result[0].reminderTime)
    }

    @Test
    fun `getRecurringTasks filters tasks with recurrence type`() = runTest {
        // Given
        val taskEntities = listOf(
            TaskEntity(
                id = "1",
                description = "Recurring task",
                isCompleted = false,
                recurrenceType = RecurrenceType.DAILY,
                createdAt = System.currentTimeMillis()
            ),
            TaskEntity(
                id = "2",
                description = "One-time task",
                isCompleted = false,
                recurrenceType = null,
                createdAt = System.currentTimeMillis()
            )
        )
        whenever(taskDao.getAllTasks()).thenReturn(taskEntities)

        // When
        val result = repository.getRecurringTasks()

        // Then
        assertEquals(1, result.size)
        assertEquals("Recurring task", result[0].description)
        assertEquals(RecurrenceType.DAILY, result[0].recurrenceType)
    }

    @Test
    fun `searchTasks filters tasks by description`() = runTest {
        // Given
        val taskEntities = listOf(
            TaskEntity(
                id = "1",
                description = "Buy groceries",
                isCompleted = false,
                createdAt = System.currentTimeMillis()
            ),
            TaskEntity(
                id = "2",
                description = "Call dentist",
                isCompleted = false,
                createdAt = System.currentTimeMillis()
            ),
            TaskEntity(
                id = "3",
                description = "Buy birthday gift",
                isCompleted = false,
                createdAt = System.currentTimeMillis()
            )
        )
        whenever(taskDao.getAllTasksFlow()).thenReturn(flowOf(taskEntities))

        // When
        val result = repository.searchTasks("buy").first()

        // Then
        assertEquals(2, result.size)
        assertTrue(result.all { it.description.contains("buy", ignoreCase = true) })
    }
}