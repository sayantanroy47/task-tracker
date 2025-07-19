package com.tasktracker.domain.usecase

import com.tasktracker.domain.model.RecurrenceType
import com.tasktracker.domain.model.Task
import com.tasktracker.domain.repository.TaskRepository
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
 * Unit tests for Task Use Cases
 */
class TaskUseCaseTest {

    @Mock
    private lateinit var taskRepository: TaskRepository

    private lateinit var createTaskUseCase: CreateTaskUseCase
    private lateinit var completeTaskUseCase: CompleteTaskUseCase
    private lateinit var deleteTaskUseCase: DeleteTaskUseCase
    private lateinit var getTasksUseCase: GetTasksUseCase

    @Before
    fun setup() {
        MockitoAnnotations.openMocks(this)
        createTaskUseCase = CreateTaskUseCase(taskRepository)
        completeTaskUseCase = CompleteTaskUseCase(taskRepository)
        deleteTaskUseCase = DeleteTaskUseCase(taskRepository)
        getTasksUseCase = GetTasksUseCase(taskRepository)
    }

    @Test
    fun `createTaskUseCase creates task with valid description`() = runTest {
        // Given
        val description = "Valid task description"

        // When
        val result = createTaskUseCase.execute(description)

        // Then
        assertTrue(result.isSuccess)
        verify(taskRepository).insertTask(
            Task(description = description)
        )
    }

    @Test
    fun `createTaskUseCase fails with empty description`() = runTest {
        // Given
        val description = ""

        // When
        val result = createTaskUseCase.execute(description)

        // Then
        assertTrue(result.isFailure)
        assertEquals("Task description cannot be empty", result.exceptionOrNull()?.message)
    }

    @Test
    fun `createTaskUseCase fails with too long description`() = runTest {
        // Given
        val description = "a".repeat(1001) // Assuming max length is 1000

        // When
        val result = createTaskUseCase.execute(description)

        // Then
        assertTrue(result.isFailure)
        assertEquals("Task description is too long", result.exceptionOrNull()?.message)
    }

    @Test
    fun `createTaskUseCase creates task with reminder`() = runTest {
        // Given
        val description = "Task with reminder"
        val reminderTime = System.currentTimeMillis() + 3600000

        // When
        val result = createTaskUseCase.execute(description, reminderTime)

        // Then
        assertTrue(result.isSuccess)
        verify(taskRepository).insertTask(
            Task(
                description = description,
                reminderTime = reminderTime
            )
        )
    }

    @Test
    fun `createTaskUseCase creates recurring task`() = runTest {
        // Given
        val description = "Recurring task"
        val recurrenceType = RecurrenceType.DAILY

        // When
        val result = createTaskUseCase.execute(description, null, recurrenceType)

        // Then
        assertTrue(result.isSuccess)
        verify(taskRepository).insertTask(
            Task(
                description = description,
                recurrenceType = recurrenceType
            )
        )
    }

    @Test
    fun `completeTaskUseCase completes existing task`() = runTest {
        // Given
        val taskId = "existing-task-id"
        val existingTask = Task(
            id = taskId,
            description = "Existing task",
            isCompleted = false
        )
        whenever(taskRepository.getTaskById(taskId)).thenReturn(existingTask)

        // When
        val result = completeTaskUseCase.execute(taskId)

        // Then
        assertTrue(result.isSuccess)
        verify(taskRepository).updateTask(
            existingTask.copy(
                isCompleted = true,
                completedAt = System.currentTimeMillis()
            )
        )
    }

    @Test
    fun `completeTaskUseCase fails for non-existing task`() = runTest {
        // Given
        val taskId = "non-existing-task-id"
        whenever(taskRepository.getTaskById(taskId)).thenReturn(null)

        // When
        val result = completeTaskUseCase.execute(taskId)

        // Then
        assertTrue(result.isFailure)
        assertEquals("Task not found", result.exceptionOrNull()?.message)
    }

    @Test
    fun `completeTaskUseCase fails for already completed task`() = runTest {
        // Given
        val taskId = "completed-task-id"
        val completedTask = Task(
            id = taskId,
            description = "Already completed task",
            isCompleted = true,
            completedAt = System.currentTimeMillis()
        )
        whenever(taskRepository.getTaskById(taskId)).thenReturn(completedTask)

        // When
        val result = completeTaskUseCase.execute(taskId)

        // Then
        assertTrue(result.isFailure)
        assertEquals("Task is already completed", result.exceptionOrNull()?.message)
    }

    @Test
    fun `deleteTaskUseCase deletes existing task`() = runTest {
        // Given
        val taskId = "task-to-delete"
        val existingTask = Task(id = taskId, description = "Task to delete")
        whenever(taskRepository.getTaskById(taskId)).thenReturn(existingTask)

        // When
        val result = deleteTaskUseCase.execute(taskId)

        // Then
        assertTrue(result.isSuccess)
        verify(taskRepository).deleteTask(taskId)
    }

    @Test
    fun `deleteTaskUseCase fails for non-existing task`() = runTest {
        // Given
        val taskId = "non-existing-task"
        whenever(taskRepository.getTaskById(taskId)).thenReturn(null)

        // When
        val result = deleteTaskUseCase.execute(taskId)

        // Then
        assertTrue(result.isFailure)
        assertEquals("Task not found", result.exceptionOrNull()?.message)
    }

    @Test
    fun `getTasksUseCase returns all tasks`() = runTest {
        // Given
        val tasks = listOf(
            Task(id = "1", description = "Task 1"),
            Task(id = "2", description = "Task 2")
        )
        whenever(taskRepository.getAllTasks()).thenReturn(flowOf(tasks))

        // When
        val result = getTasksUseCase.execute().first()

        // Then
        assertEquals(tasks, result)
    }

    @Test
    fun `getTasksUseCase returns active tasks only`() = runTest {
        // Given
        val activeTasks = listOf(
            Task(id = "1", description = "Active task 1", isCompleted = false),
            Task(id = "2", description = "Active task 2", isCompleted = false)
        )
        whenever(taskRepository.getActiveTasks()).thenReturn(flowOf(activeTasks))

        // When
        val result = getTasksUseCase.execute(activeOnly = true).first()

        // Then
        assertEquals(activeTasks, result)
    }

    @Test
    fun `getTasksUseCase returns completed tasks only`() = runTest {
        // Given
        val completedTasks = listOf(
            Task(id = "1", description = "Completed task 1", isCompleted = true),
            Task(id = "2", description = "Completed task 2", isCompleted = true)
        )
        whenever(taskRepository.getCompletedTasks()).thenReturn(flowOf(completedTasks))

        // When
        val result = getTasksUseCase.execute(completedOnly = true).first()

        // Then
        assertEquals(completedTasks, result)
    }
}

/**
 * Use case for creating tasks
 */
class CreateTaskUseCase(private val taskRepository: TaskRepository) {
    suspend fun execute(
        description: String,
        reminderTime: Long? = null,
        recurrenceType: RecurrenceType? = null
    ): Result<Task> {
        return try {
            when {
                description.isBlank() -> Result.failure(Exception("Task description cannot be empty"))
                description.length > 1000 -> Result.failure(Exception("Task description is too long"))
                else -> {
                    val task = Task(
                        description = description.trim(),
                        reminderTime = reminderTime,
                        recurrenceType = recurrenceType
                    )
                    taskRepository.insertTask(task)
                    Result.success(task)
                }
            }
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
}

/**
 * Use case for completing tasks
 */
class CompleteTaskUseCase(private val taskRepository: TaskRepository) {
    suspend fun execute(taskId: String): Result<Task> {
        return try {
            val task = taskRepository.getTaskById(taskId)
                ?: return Result.failure(Exception("Task not found"))
            
            if (task.isCompleted) {
                return Result.failure(Exception("Task is already completed"))
            }
            
            val completedTask = task.copy(
                isCompleted = true,
                completedAt = System.currentTimeMillis()
            )
            
            taskRepository.updateTask(completedTask)
            Result.success(completedTask)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
}

/**
 * Use case for deleting tasks
 */
class DeleteTaskUseCase(private val taskRepository: TaskRepository) {
    suspend fun execute(taskId: String): Result<Unit> {
        return try {
            val task = taskRepository.getTaskById(taskId)
                ?: return Result.failure(Exception("Task not found"))
            
            taskRepository.deleteTask(taskId)
            Result.success(Unit)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
}

/**
 * Use case for getting tasks
 */
class GetTasksUseCase(private val taskRepository: TaskRepository) {
    fun execute(
        activeOnly: Boolean = false,
        completedOnly: Boolean = false
    ) = when {
        activeOnly -> taskRepository.getActiveTasks()
        completedOnly -> taskRepository.getCompletedTasks()
        else -> taskRepository.getAllTasks()
    }
}