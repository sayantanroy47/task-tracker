package com.tasktracker.presentation.main

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.tasktracker.domain.model.Task
import com.tasktracker.domain.repository.TaskRepository
import com.tasktracker.presentation.speech.SpeechPermissionHandler
import com.tasktracker.presentation.speech.SpeechRecognitionService
import com.tasktracker.util.PerformanceMonitor
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.catch
import kotlinx.coroutines.flow.distinctUntilChanged
import kotlinx.coroutines.flow.flowOn
import kotlinx.coroutines.launch
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import javax.inject.Inject

@HiltViewModel
class MainViewModel @Inject constructor(
    private val taskRepository: TaskRepository,
    val speechRecognitionService: SpeechRecognitionService,
    val speechPermissionHandler: SpeechPermissionHandler
) : ViewModel() {
    
    private val _uiState = MutableStateFlow(MainUiState())
    val uiState: StateFlow<MainUiState> = _uiState.asStateFlow()
    
    // Performance optimization: Track active jobs for proper cleanup
    private var activeTasksJob: Job? = null
    private var completedTasksJob: Job? = null
    
    init {
        PerformanceMonitor.logMemoryUsage("MainViewModel init")
        loadTasks()
    }
    
    private fun loadTasks() {
        // Performance optimization: Cancel previous job to prevent memory leaks
        activeTasksJob?.cancel()
        
        activeTasksJob = viewModelScope.launch {
            PerformanceMonitor.monitorDatabaseOperation("loadActiveTasks") {
                taskRepository.getActiveTasks()
                    .distinctUntilChanged() // Performance: Only emit when data actually changes
                    .flowOn(Dispatchers.IO) // Performance: Run on IO dispatcher
                    .catch { e ->
                        _uiState.value = _uiState.value.copy(
                            isLoading = false,
                            errorMessage = "Failed to load tasks: ${e.message}"
                        )
                    }
                    .collect { tasks ->
                        _uiState.value = _uiState.value.copy(
                            activeTasks = tasks,
                            isLoading = false
                        )
                        
                        // Performance monitoring for large lists
                        if (tasks.size > 50) {
                            PerformanceMonitor.logMemoryUsage("Active tasks loaded: ${tasks.size}")
                        }
                    }
            }
        }
        
        // Also load completed tasks
        loadCompletedTasks()
    }
    
    private fun loadCompletedTasks() {
        // Performance optimization: Cancel previous job to prevent memory leaks
        completedTasksJob?.cancel()
        
        completedTasksJob = viewModelScope.launch {
            _uiState.value = _uiState.value.copy(isLoadingCompleted = true)
            
            PerformanceMonitor.monitorDatabaseOperation("loadCompletedTasks") {
                taskRepository.getCompletedTasks()
                    .distinctUntilChanged() // Performance: Only emit when data actually changes
                    .flowOn(Dispatchers.IO) // Performance: Run on IO dispatcher
                    .catch { e ->
                        _uiState.value = _uiState.value.copy(
                            isLoadingCompleted = false,
                            errorMessage = "Failed to load completed tasks: ${e.message}"
                        )
                    }
                    .collect { tasks ->
                        _uiState.value = _uiState.value.copy(
                            completedTasks = tasks,
                            isLoadingCompleted = false
                        )
                        
                        // Performance monitoring for large lists
                        if (tasks.size > 100) {
                            PerformanceMonitor.logMemoryUsage("Completed tasks loaded: ${tasks.size}")
                        }
                    }
            }
        }
    }
    
    fun createTask(description: String) {
        createTaskWithReminder(description, null)
    }
    
    fun createTaskWithReminder(description: String, reminderTime: Long?) {
        createTaskWithRecurrence(description, reminderTime, null)
    }
    
    fun createTaskWithRecurrence(description: String, reminderTime: Long?, recurrenceType: com.tasktracker.domain.model.RecurrenceType?) {
        if (description.isBlank()) {
            _uiState.value = _uiState.value.copy(
                inputError = "Task description cannot be empty"
            )
            return
        }
        
        viewModelScope.launch {
            PerformanceMonitor.monitorDatabaseOperation("createTask") {
                try {
                    val task = Task(
                        description = description.trim(),
                        reminderTime = reminderTime,
                        recurrenceType = recurrenceType
                    )
                    taskRepository.insertTask(task)
                    _uiState.value = _uiState.value.copy(
                        inputError = null,
                        showTaskCreatedFeedback = true
                    )
                } catch (e: Exception) {
                    _uiState.value = _uiState.value.copy(
                        inputError = "Failed to create task: ${e.message}"
                    )
                }
            }
        }
    }
    
    fun clearInputError() {
        _uiState.value = _uiState.value.copy(inputError = null)
    }
    
    fun clearTaskCreatedFeedback() {
        _uiState.value = _uiState.value.copy(showTaskCreatedFeedback = false)
    }
    
    fun clearError() {
        _uiState.value = _uiState.value.copy(errorMessage = null)
    }
    
    fun completeTask(task: Task) {
        viewModelScope.launch {
            PerformanceMonitor.monitorDatabaseOperation("completeTask") {
                try {
                    taskRepository.completeTask(task.id)
                    _uiState.value = _uiState.value.copy(
                        recentlyCompletedTask = task,
                        showUndoOption = true
                    )
                } catch (e: Exception) {
                    _uiState.value = _uiState.value.copy(
                        errorMessage = "Failed to complete task: ${e.message}"
                    )
                }
            }
        }
    }
    
    fun undoTaskCompletion() {
        val recentlyCompleted = _uiState.value.recentlyCompletedTask
        if (recentlyCompleted != null) {
            viewModelScope.launch {
                try {
                    // Revert the task to incomplete state
                    val uncompletedTask = recentlyCompleted.copy(
                        isCompleted = false,
                        completedAt = null
                    )
                    taskRepository.updateTask(uncompletedTask)
                    _uiState.value = _uiState.value.copy(
                        recentlyCompletedTask = null,
                        showUndoOption = false
                    )
                } catch (e: Exception) {
                    _uiState.value = _uiState.value.copy(
                        errorMessage = "Failed to undo task completion: ${e.message}"
                    )
                }
            }
        }
    }
    
    fun dismissUndo() {
        _uiState.value = _uiState.value.copy(
            recentlyCompletedTask = null,
            showUndoOption = false
        )
    }
    
    fun deleteCompletedTask(task: Task) {
        viewModelScope.launch {
            try {
                taskRepository.deleteTask(task)
            } catch (e: Exception) {
                _uiState.value = _uiState.value.copy(
                    errorMessage = "Failed to delete completed task: ${e.message}"
                )
            }
        }
    }
    
    fun clearAllCompletedTasks() {
        viewModelScope.launch {
            try {
                taskRepository.deleteAllCompletedTasks()
            } catch (e: Exception) {
                _uiState.value = _uiState.value.copy(
                    errorMessage = "Failed to clear completed tasks: ${e.message}"
                )
            }
        }
    }
    
    fun requestMicrophonePermission() {
        speechPermissionHandler.requestPermission()
    }
    
    override fun onCleared() {
        super.onCleared()
        
        // Performance optimization: Cancel all active jobs to prevent memory leaks
        activeTasksJob?.cancel()
        completedTasksJob?.cancel()
        
        // Clean up speech recognition service
        speechRecognitionService.destroy()
        
        // Log final memory usage
        PerformanceMonitor.logMemoryUsage("MainViewModel onCleared")
    }
}

data class MainUiState(
    val activeTasks: List<Task> = emptyList(),
    val completedTasks: List<Task> = emptyList(),
    val isLoading: Boolean = true,
    val isLoadingCompleted: Boolean = false,
    val errorMessage: String? = null,
    val inputError: String? = null,
    val showTaskCreatedFeedback: Boolean = false,
    val recentlyCompletedTask: Task? = null,
    val showUndoOption: Boolean = false
)