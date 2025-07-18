package com.tasktracker.data.repository

import com.tasktracker.data.local.TaskDao
import com.tasktracker.data.local.entity.TaskEntity
import com.tasktracker.data.local.entity.toDomainModel
import com.tasktracker.data.local.entity.toEntity
import com.tasktracker.domain.model.RecurrenceType
import com.tasktracker.domain.model.Task
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.flowOf
import kotlinx.coroutines.test.runTest
import org.junit.Assert.*
import org.junit.Before
import org.junit.Test
import org.mockito.Mock
import org.mockito.MockitoAnnotations
import org.mockito.kotlin.*

class TaskRepositoryImplTest {

    @Mock
    private lateinit var taskDao: TaskDao

    private lateinit var repository: TaskRepositoryImpl

    @Before
    fun setup() {
        MockitoAnnotations.openMocks(this)
        repository = TaskRepositoryImpl(taskDao)
    }

    @Test
    fun `getAllTasks returns mapped domain models`() = runTest {
        val taskEntities = listOf(
            TaskEntity(
                id = "1",
                description = "Task 1",
                isCompleted = false,
                createdAt = 1000L
            ),
            TaskEntity(
                id = "2",
                description = "Task 2",
                isCompleted = true,
                createdAt = 2000L,
                completedAt = 2500L
            )
        )
        whenever(taskDao.getAllTasks()).thenReturn(flowOf(taskEntities))

        val result = repository.getAllTasks().first()

        assertEquals(2, result.size)
        assertEquals("1", result[0].id)
        assertEquals("Task 1", result[0].description)
        assertFalse(result[0].isCompleted)
        assertEquals("2", result[1].id)
        assertEquals("Task 2", result[1].description)
        assertTrue(result[1].isCompleted)
    }

    @Test
    fun `getActiveTasks returns only incomplete tasks`() = runTest {
        val activeTaskEntities = listOf(
            TaskEntity(
                id = "active1",
                description = "Active Task 1",
                isCompleted = false,
                createdAt = 1000L
            )
        )
        whenever(taskDao.getActiveTasks()).thenReturn(flowOf(activeTaskEntities))

        val result = repository.getActiveTasks().first()

        assertEquals(1, result.size)
        assertEquals("active1", result[0].id)
        assertFalse(result[0].isCompleted)
    }

    @Test
    fun `getCompletedTasks returns only completed tasks`() = runTest {
        val completedTaskEntities = listOf(
            TaskEntity(
                id = "completed1",
                description = "Completed Task 1",
                isCompleted = true,
                createdAt = 1000L,
                completedAt = 1500L
            )
        )
        whenever(taskDao.getCompletedTasks()).thenReturn(flowOf(completedTaskEntities))

        val result = repository.getCompletedTasks().first()

        assertEquals(1, result.size)
        assertEquals("completed1", result[0].id)
        assertTrue(result[0].isCompleted)
    }

    @Test
    fun `getTaskById returns mapped domain model when task exists`() = runTest {
        val taskEntity = TaskEntity(
            id = "test-id",
            description = "Test Task",
            isCompleted = false,
            createdAt = 1000L
        )
        whenever(taskDao.getTaskById("test-id")).thenReturn(taskEntity)

        val result = repository.getTaskById("test-id")

        assertNotNull(result)
        assertEquals("test-id", result!!.id)
        assertEquals("Test Task", result.description)
    }

    @Test
    fun `getTaskById returns null when task does not exist`() = runTest {
        whenever(taskDao.getTaskById("non-existent")).thenReturn(null)

        val result = repository.getTaskById("non-existent")

        assertNull(result)
    }

    @Test
    fun `insertTask converts domain model to entity and calls dao`() = runTest {
        val task = Task(
            id = "new-task",
            description = "New Task",
            isCompleted = false,
            createdAt = 1000L
        )

        repository.insertTask(task)

        verify(taskDao).insertTask(task.toEntity())
    }

    @Test
    fun `updateTask converts domain model to entity and calls dao`() = runTest {
        val task = Task(
            id = "update-task",
            description = "Updated Task",
            isCompleted = true,
            createdAt = 1000L,
            completedAt = 1500L
        )

        repository.updateTask(task)

        verify(taskDao).updateTask(task.toEntity())
    }

    @Test
    fun `deleteTask converts domain model to entity and calls dao`() = runTest {
        val task = Task(
            id = "delete-task",
            description = "Task to Delete",
            isCompleted = false,
            createdAt = 1000L
        )

        repository.deleteTask(task)

        verify(taskDao).deleteTask(task.toEntity())
    }

    @Test
    fun `deleteTaskById calls dao with correct id`() = runTest {
        repository.deleteTaskById("task-to-delete")

        verify(taskDao).deleteTaskById("task-to-delete")
    }

    @Test
    fun `completeTask marks task as completed and updates it`() = runTest {
        val task = Task(
            id = "complete-task",
            description = "Task to Complete",
            isCompleted = false,
            createdAt = 1000L
        )
        val taskEntity = task.toEntity()
        whenever(taskDao.getTaskById("complete-task")).thenReturn(taskEntity)

        repository.completeTask("complete-task")

        verify(taskDao).updateTask(argThat { 
            this.id == "complete-task" && this.isCompleted && this.completedAt != null 
        })
    }

    @Test
    fun `completeTask creates next recurring task when task is recurring`() = runTest {
        val recurringTask = Task(
            id = "recurring-task",
            description = "Daily Task",
            isCompleted = false,
            createdAt = 1000L,
            reminderTime = 2000L,
            recurrenceType = RecurrenceType.DAILY
        )
        val taskEntity = recurringTask.toEntity()
        whenever(taskDao.getTaskById("recurring-task")).thenReturn(taskEntity)

        repository.completeTask("recurring-task")

        // Verify the original task is marked as completed
        verify(taskDao).updateTask(argThat { 
            this.id == "recurring-task" && this.isCompleted 
        })
        
        // Verify a new recurring task is created
        verify(taskDao).insertTask(argThat { 
            this.id != "recurring-task" && 
            this.description == "Daily Task" && 
            !this.isCompleted &&
            this.recurrenceType == "DAILY"
        })
    }

    @Test
    fun `completeTask does not create next task for non-recurring task`() = runTest {
        val nonRecurringTask = Task(
            id = "non-recurring-task",
            description = "One-time Task",
            isCompleted = false,
            createdAt = 1000L,
            recurrenceType = null
        )
        val taskEntity = nonRecurringTask.toEntity()
        whenever(taskDao.getTaskById("non-recurring-task")).thenReturn(taskEntity)

        repository.completeTask("non-recurring-task")

        // Verify only one update call (for completion) and no insert call
        verify(taskDao, times(1)).updateTask(any())
        verify(taskDao, never()).insertTask(any())
    }

    @Test
    fun `completeTask does nothing when task does not exist`() = runTest {
        whenever(taskDao.getTaskById("non-existent")).thenReturn(null)

        repository.completeTask("non-existent")

        verify(taskDao, never()).updateTask(any())
        verify(taskDao, never()).insertTask(any())
    }

    @Test
    fun `getTasksWithReminders returns mapped domain models`() = runTest {
        val taskEntities = listOf(
            TaskEntity(
                id = "reminder-task",
                description = "Task with Reminder",
                isCompleted = false,
                createdAt = 1000L,
                reminderTime = 2000L
            )
        )
        whenever(taskDao.getTasksWithReminders()).thenReturn(taskEntities)

        val result = repository.getTasksWithReminders()

        assertEquals(1, result.size)
        assertEquals("reminder-task", result[0].id)
        assertEquals(2000L, result[0].reminderTime)
    }

    @Test
    fun `getRecurringTasks returns mapped domain models`() = runTest {
        val taskEntities = listOf(
            TaskEntity(
                id = "recurring-task",
                description = "Recurring Task",
                isCompleted = false,
                createdAt = 1000L,
                recurrenceType = "WEEKLY"
            )
        )
        whenever(taskDao.getRecurringTasks()).thenReturn(taskEntities)

        val result = repository.getRecurringTasks()

        assertEquals(1, result.size)
        assertEquals("recurring-task", result[0].id)
        assertEquals(RecurrenceType.WEEKLY, result[0].recurrenceType)
    }

    @Test
    fun `searchTasks returns mapped domain models`() = runTest {
        val taskEntities = listOf(
            TaskEntity(
                id = "search-result",
                description = "Matching Task",
                isCompleted = false,
                createdAt = 1000L
            )
        )
        whenever(taskDao.searchTasks("matching")).thenReturn(flowOf(taskEntities))

        val result = repository.searchTasks("matching").first()

        assertEquals(1, result.size)
        assertEquals("search-result", result[0].id)
        assertEquals("Matching Task", result[0].description)
    }

    @Test
    fun `getActiveTaskCount returns count from dao`() = runTest {
        whenever(taskDao.getActiveTaskCount()).thenReturn(5)

        val result = repository.getActiveTaskCount()

        assertEquals(5, result)
    }

    @Test
    fun `getCompletedTaskCount returns count from dao`() = runTest {
        whenever(taskDao.getCompletedTaskCount()).thenReturn(3)

        val result = repository.getCompletedTaskCount()

        assertEquals(3, result)
    }

    @Test
    fun `deleteAllCompletedTasks calls dao method`() = runTest {
        repository.deleteAllCompletedTasks()

        verify(taskDao).deleteAllCompletedTasks()
    }

    @Test
    fun `insertTasks converts all domain models to entities and calls dao`() = runTest {
        val tasks = listOf(
            Task(id = "task1", description = "Task 1", createdAt = 1000L),
            Task(id = "task2", description = "Task 2", createdAt = 2000L)
        )

        repository.insertTasks(tasks)

        verify(taskDao).insertTasks(argThat { 
            this.size == 2 && 
            this[0].id == "task1" && 
            this[1].id == "task2" 
        })
    }
}