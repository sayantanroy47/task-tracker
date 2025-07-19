package com.tasktracker.presentation.viewmodel

import androidx.arch.core.executor.testing.InstantTaskExecutorRule
import com.tasktracker.domain.model.Task
import com.tasktracker.domain.repository.TaskRepository
import com.tasktracker.presentation.task.TaskViewModel
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.flow.flowOf
import kotlinx.coroutines.test.*
import org.junit.After
import org.junit.Assert.*
import org.junit.Before
import org.junit.Rule
import org.junit.Test
import org.mockito.Mock
import org.mockito.MockitoAnnotations
import org.mockito.kotlin.verify
import org.mockito.kotlin.whenever

/**
 * Unit tests for TaskViewModel
 */
@ExperimentalCoroutinesApi
class TaskViewModelTest {

    @get:Rule
    val instantTaskExecutorRule = InstantTaskExecutorRule()

    private val testDispatcher = UnconfinedTestDispatcher()

    @Mock
    private lateinit var taskRepository: TaskRepository

    private lateinit var viewModel: TaskViewModel

    @Before
    fun setup() {
        MockitoAnnotations.openMocks(this)
        Dispatchers.setMain(testDispatcher)
        
        // Setup default repository behavior
        whenever(taskRepository.getAllTasks()).thenReturn(flowOf(emptyList()))
        
        viewModel = TaskViewModel(taskRepository)
    }

    @After
    fun tearDown() {
        Dispatchers.resetMain()
    }

    @Test
    fun `initial state has empty task list`() {
        // Given - ViewModel is initialized
        
        // When - Check initial state
        val uiState = viewModel.uiState.value
        
        // Then
        assertTrue(uiState.tasks.isEmpty())
        assertTrue(uiState.filteredTasks.isEmpty())
        assertEquals("", uiState.newTaskDescription)
        assertFalse(uiState.isLoading)
        assertNull(uiState.error)
    }

    @Test
    fun `addTask creates new task and clears input`() = runTest {
        // Given
        val taskDescription = "New test task"
        
        // When
        viewModel.updateTaskDescription(taskDescription)
        viewModel.addTask()
        
        // Then
        verify(taskRepository).insertTask(
            Task(description = taskDescription)
        )
        assertEquals("", viewModel.uiState.value.newTaskDescription)
    }

    @Test
    fun `updateTaskDescription updates UI state`() {
        // Given
        val description = "Test description"
        
        // When
        viewModel.updateTaskDescription(description)
        
        // Then
        assertEquals(description, viewModel.uiState.value.newTaskDescription)
    }

    @Test
    fun `completeTask updates task completion status`() = runTest {
        // Given
        val taskId = "test-task-id"
        val task = Task(id = taskId, description = "Test task", isCompleted = false)
        whenever(taskRepository.getTaskById(taskId)).thenReturn(task)
        
        // When
        viewModel.completeTask(taskId)
        
        // Then
        verify(taskRepository).updateTask(
            task.copy(
                isCompleted = true,
                completedAt = System.currentTimeMillis()
            )
        )
    }

    @Test
    fun `deleteTask removes task from repository`() = runTest {
        // Given
        val taskId = "test-task-id"
        
        // When
        viewModel.deleteTask(taskId)
        
        // Then
        verify(taskRepository).deleteTask(taskId)
    }

    @Test
    fun `filterTasks by ALL shows all tasks`() {
        // Given
        val tasks = listOf(
            Task(id = "1", description = "Active task", isCompleted = false),
            Task(id = "2", description = "Completed task", isCompleted = true)
        )
        whenever(taskRepository.getAllTasks()).thenReturn(flowOf(tasks))
        
        // When
        viewModel.filterTasks(TaskFilter.ALL)
        
        // Then
        val filteredTasks = viewModel.uiState.value.filteredTasks
        assertEquals(2, filteredTasks.size)
    }

    @Test
    fun `filterTasks by ACTIVE shows only active tasks`() {
        // Given
        val tasks = listOf(
            Task(id = "1", description = "Active task", isCompleted = false),
            Task(id = "2", description = "Completed task", isCompleted = true)
        )
        whenever(taskRepository.getAllTasks()).thenReturn(flowOf(tasks))
        
        // When
        viewModel.filterTasks(TaskFilter.ACTIVE)
        
        // Then
        val filteredTasks = viewModel.uiState.value.filteredTasks
        assertEquals(1, filteredTasks.size)
        assertFalse(filteredTasks[0].isCompleted)
    }

    @Test
    fun `filterTasks by COMPLETED shows only completed tasks`() {
        // Given
        val tasks = listOf(
            Task(id = "1", description = "Active task", isCompleted = false),
            Task(id = "2", description = "Completed task", isCompleted = true)
        )
        whenever(taskRepository.getAllTasks()).thenReturn(flowOf(tasks))
        
        // When
        viewModel.filterTasks(TaskFilter.COMPLETED)
        
        // Then
        val filteredTasks = viewModel.uiState.value.filteredTasks
        assertEquals(1, filteredTasks.size)
        assertTrue(filteredTasks[0].isCompleted)
    }

    @Test
    fun `searchTasks updates filtered tasks with search results`() = runTest {
        // Given
        val searchQuery = "test"
        val searchResults = listOf(
            Task(id = "1", description = "Test task 1"),
            Task(id = "2", description = "Test task 2")
        )
        whenever(taskRepository.searchTasks(searchQuery)).thenReturn(flowOf(searchResults))
        
        // When
        viewModel.searchTasks(searchQuery)
        
        // Then
        val filteredTasks = viewModel.uiState.value.filteredTasks
        assertEquals(2, filteredTasks.size)
        assertTrue(filteredTasks.all { it.description.contains("Test") })
    }

    @Test
    fun `clearSearch resets to all tasks`() {
        // Given
        val allTasks = listOf(
            Task(id = "1", description = "Task 1"),
            Task(id = "2", description = "Task 2"),
            Task(id = "3", description = "Task 3")
        )
        whenever(taskRepository.getAllTasks()).thenReturn(flowOf(allTasks))
        
        // When
        viewModel.clearSearch()
        
        // Then
        val filteredTasks = viewModel.uiState.value.filteredTasks
        assertEquals(3, filteredTasks.size)
    }

    @Test
    fun `error handling sets error state`() = runTest {
        // Given
        val errorMessage = "Database error"
        whenever(taskRepository.getAllTasks()).thenThrow(RuntimeException(errorMessage))
        
        // When
        viewModel.loadTasks()
        
        // Then
        val uiState = viewModel.uiState.value
        assertNotNull(uiState.error)
        assertTrue(uiState.error!!.contains(errorMessage))
        assertFalse(uiState.isLoading)
    }

    @Test
    fun `clearError resets error state`() {
        // Given - Set an error state first
        viewModel.setError("Test error")
        
        // When
        viewModel.clearError()
        
        // Then
        assertNull(viewModel.uiState.value.error)
    }
}