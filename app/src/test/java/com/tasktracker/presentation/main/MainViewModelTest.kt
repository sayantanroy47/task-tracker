package com.tasktracker.presentation.main

import com.tasktracker.domain.model.Task
import com.tasktracker.domain.repository.TaskRepository
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.flow.flowOf
import kotlinx.coroutines.test.StandardTestDispatcher
import kotlinx.coroutines.test.advanceUntilIdle
import kotlinx.coroutines.test.resetMain
import kotlinx.coroutines.test.runTest
import kotlinx.coroutines.test.setMain
import org.junit.After
import org.junit.Before
import org.junit.Test
import org.mockito.Mock
import org.mockito.MockitoAnnotations
import org.mockito.kotlin.verify
import org.mockito.kotlin.whenever
import com.google.common.truth.Truth.assertThat

@OptIn(ExperimentalCoroutinesApi::class)
class MainViewModelTest {

    @Mock
    private lateinit var taskRepository: TaskRepository

    private lateinit var viewModel: MainViewModel
    private val testDispatcher = StandardTestDispatcher()

    @Before
    fun setup() {
        MockitoAnnotations.openMocks(this)
        Dispatchers.setMain(testDispatcher)
        
        // Mock repository to return empty list initially
        whenever(taskRepository.getActiveTasks()).thenReturn(flowOf(emptyList()))
        
        viewModel = MainViewModel(taskRepository)
    }

    @After
    fun tearDown() {
        Dispatchers.resetMain()
    }

    @Test
    fun `createTask with valid description creates task successfully`() = runTest {
        // Given
        val taskDescription = "Test task"
        
        // When
        viewModel.createTask(taskDescription)
        advanceUntilIdle()
        
        // Then
        verify(taskRepository).insertTask(org.mockito.kotlin.any())
        assertThat(viewModel.uiState.value.inputError).isNull()
        assertThat(viewModel.uiState.value.showTaskCreatedFeedback).isTrue()
    }

    @Test
    fun `createTask with empty description shows error`() = runTest {
        // Given
        val taskDescription = ""
        
        // When
        viewModel.createTask(taskDescription)
        advanceUntilIdle()
        
        // Then
        assertThat(viewModel.uiState.value.inputError).isEqualTo("Task description cannot be empty")
        assertThat(viewModel.uiState.value.showTaskCreatedFeedback).isFalse()
    }

    @Test
    fun `createTask with blank description shows error`() = runTest {
        // Given
        val taskDescription = "   "
        
        // When
        viewModel.createTask(taskDescription)
        advanceUntilIdle()
        
        // Then
        assertThat(viewModel.uiState.value.inputError).isEqualTo("Task description cannot be empty")
        assertThat(viewModel.uiState.value.showTaskCreatedFeedback).isFalse()
    }

    @Test
    fun `createTask trims whitespace from description`() = runTest {
        // Given
        val taskDescription = "  Test task  "
        
        // When
        viewModel.createTask(taskDescription)
        advanceUntilIdle()
        
        // Then
        verify(taskRepository).insertTask(org.mockito.kotlin.argThat { task ->
            task.description == "Test task"
        })
    }

    @Test
    fun `clearInputError clears input error state`() = runTest {
        // Given
        viewModel.createTask("") // This will set an error
        advanceUntilIdle()
        assertThat(viewModel.uiState.value.inputError).isNotNull()
        
        // When
        viewModel.clearInputError()
        
        // Then
        assertThat(viewModel.uiState.value.inputError).isNull()
    }

    @Test
    fun `clearTaskCreatedFeedback clears feedback state`() = runTest {
        // Given
        viewModel.createTask("Test task") // This will set feedback
        advanceUntilIdle()
        assertThat(viewModel.uiState.value.showTaskCreatedFeedback).isTrue()
        
        // When
        viewModel.clearTaskCreatedFeedback()
        
        // Then
        assertThat(viewModel.uiState.value.showTaskCreatedFeedback).isFalse()
    }

    @Test
    fun `loadTasks updates UI state with active tasks`() = runTest {
        // Given
        val tasks = listOf(
            Task(id = "1", description = "Task 1"),
            Task(id = "2", description = "Task 2")
        )
        whenever(taskRepository.getActiveTasks()).thenReturn(flowOf(tasks))
        
        // When
        viewModel = MainViewModel(taskRepository) // Recreate to trigger init
        advanceUntilIdle()
        
        // Then
        assertThat(viewModel.uiState.value.activeTasks).isEqualTo(tasks)
        assertThat(viewModel.uiState.value.isLoading).isFalse()
    }

    @Test
    fun `repository error during task creation shows error message`() = runTest {
        // Given
        val taskDescription = "Test task"
        whenever(taskRepository.insertTask(org.mockito.kotlin.any()))
            .thenThrow(RuntimeException("Database error"))
        
        // When
        viewModel.createTask(taskDescription)
        advanceUntilIdle()
        
        // Then
        assertThat(viewModel.uiState.value.inputError).contains("Failed to create task")
        assertThat(viewModel.uiState.value.showTaskCreatedFeedback).isFalse()
    }

    @Test
    fun `completeTask marks task as completed and shows undo option`() = runTest {
        // Given
        val task = Task(id = "1", description = "Test task")
        
        // When
        viewModel.completeTask(task)
        advanceUntilIdle()
        
        // Then
        verify(taskRepository).completeTask(task.id)
        assertThat(viewModel.uiState.value.recentlyCompletedTask).isEqualTo(task)
        assertThat(viewModel.uiState.value.showUndoOption).isTrue()
    }

    @Test
    fun `undoTaskCompletion reverts task completion`() = runTest {
        // Given
        val task = Task(id = "1", description = "Test task", isCompleted = true)
        viewModel.completeTask(task)
        advanceUntilIdle()
        
        // When
        viewModel.undoTaskCompletion()
        advanceUntilIdle()
        
        // Then
        verify(taskRepository).updateTask(org.mockito.kotlin.argThat { updatedTask ->
            !updatedTask.isCompleted && updatedTask.completedAt == null
        })
        assertThat(viewModel.uiState.value.recentlyCompletedTask).isNull()
        assertThat(viewModel.uiState.value.showUndoOption).isFalse()
    }

    @Test
    fun `dismissUndo clears undo state`() = runTest {
        // Given
        val task = Task(id = "1", description = "Test task")
        viewModel.completeTask(task)
        advanceUntilIdle()
        assertThat(viewModel.uiState.value.showUndoOption).isTrue()
        
        // When
        viewModel.dismissUndo()
        
        // Then
        assertThat(viewModel.uiState.value.recentlyCompletedTask).isNull()
        assertThat(viewModel.uiState.value.showUndoOption).isFalse()
    }

    @Test
    fun `completeTask error shows error message`() = runTest {
        // Given
        val task = Task(id = "1", description = "Test task")
        whenever(taskRepository.completeTask(task.id))
            .thenThrow(RuntimeException("Database error"))
        
        // When
        viewModel.completeTask(task)
        advanceUntilIdle()
        
        // Then
        assertThat(viewModel.uiState.value.errorMessage).contains("Failed to complete task")
        assertThat(viewModel.uiState.value.showUndoOption).isFalse()
    }

    @Test
    fun `undoTaskCompletion with no recently completed task does nothing`() = runTest {
        // Given - no recently completed task
        assertThat(viewModel.uiState.value.recentlyCompletedTask).isNull()
        
        // When
        viewModel.undoTaskCompletion()
        advanceUntilIdle()
        
        // Then
        verify(taskRepository, org.mockito.kotlin.never()).updateTask(org.mockito.kotlin.any())
    }

    @Test
    fun `undoTaskCompletion error shows error message`() = runTest {
        // Given
        val task = Task(id = "1", description = "Test task")
        viewModel.completeTask(task)
        advanceUntilIdle()
        whenever(taskRepository.updateTask(org.mockito.kotlin.any()))
            .thenThrow(RuntimeException("Database error"))
        
        // When
        viewModel.undoTaskCompletion()
        advanceUntilIdle()
        
        // Then
        assertThat(viewModel.uiState.value.errorMessage).contains("Failed to undo task completion")
    }
}