package com.tasktracker.presentation.main

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.tasktracker.domain.model.Task
import com.tasktracker.domain.repository.TaskRepository
import com.tasktracker.presentation.speech.SpeechPermissionHandler
import com.tasktracker.presentation.speech.SpeechRecognitionService
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class MainViewModel @Inject constructor(
    private val taskRepository: TaskRepository,
    val speechRecognitionService: SpeechRecognitionService,
    val speechPermissionHandler: SpeechPermissionHandler
) : ViewModel() {
    
    private val _uiState = MutableStateFlow(MainUiState())
    val uiState: StateFlow<MainUiState> = _uiState.asStateFlow()
    
    init {
        loadTasks()
    }
    
    private fun loadTasks() {
        viewModelScope.launch {
            try {
                taskRepository.getActiveTasks().collect { tasks ->
                    _uiState.value = _uiState.value.copy(
                        activeTasks = tasks,
                        isLoading = false
                    )
                }
            } catch (e: Exception) {
                _uiState.value = _uiState.value.copy(
                    isLoading = false,
                    errorMessage = "Failed to load tasks: ${e.message}"
                )
            }
        }
    }
    
    fun createTask(description: String) {
        createTaskWithReminder(description, null)
    }
    
    fun createTaskWithReminder(description: String, reminderTime: Long?) {
        if (description.isBlank()) {
            _uiState.value = _uiState.value.copy(
                inputError = "Task description cannot be empty"
            )
            return
        }
        
        viewModelScope.launch {
            try {
                val task = Task(
                    description = description.trim(),
                    reminderTime = reminderTime
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
    
    fun requestMicrophonePermission() {
        speechPermissionHandler.requestPermission()
    }
    
    override fun onCleared() {
        super.onCleared()
        speechRecognitionService.destroy()
    }
}

data class MainUiState(
    val activeTasks: List<Task> = emptyList(),
    val isLoading: Boolean = true,
    val errorMessage: String? = null,
    val inputError: String? = null,
    val showTaskCreatedFeedback: Boolean = false,
    val recentlyCompletedTask: Task? = null,
    val showUndoOption: Boolean = false
)