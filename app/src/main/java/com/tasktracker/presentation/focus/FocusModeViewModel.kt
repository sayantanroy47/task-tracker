package com.tasktracker.presentation.focus

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.tasktracker.domain.model.FocusMode
import com.tasktracker.domain.model.FocusSession
import com.tasktracker.domain.model.FocusSessionState
import com.tasktracker.domain.model.FocusSettings
import com.tasktracker.domain.model.FocusStats
import com.tasktracker.domain.model.Task
import com.tasktracker.domain.model.TaskPriority
import com.tasktracker.domain.repository.FocusRepository
import com.tasktracker.domain.repository.TaskRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.catch
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.launch
import java.time.Duration
import java.time.Instant
import javax.inject.Inject

/**
 * ViewModel for focus mode functionality
 */
@HiltViewModel
class FocusModeViewModel @Inject constructor(
    private val focusRepository: FocusRepository,
    private val taskRepository: TaskRepository
) : ViewModel() {
    
    private val _uiState = MutableStateFlow(FocusModeUiState())
    val uiState: StateFlow<FocusModeUiState> = _uiState.asStateFlow()
    
    private var sessionTimerJob: Job? = null
    private var breakTimerJob: Job? = null
    
    init {
        loadFocusData()
        observeFocusSession()
    }
    
    /**
     * Load initial focus mode data
     */
    private fun loadFocusData() {
        viewModelScope.launch {
            try {
                val settings = focusRepository.getFocusSettings()
                val stats = focusRepository.getFocusStats()
                val currentSession = focusRepository.getCurrentFocusSession()
                
                _uiState.value = _uiState.value.copy(
                    focusSettings = settings,
                    focusStats = stats,
                    currentSession = currentSession,
                    sessionState = if (currentSession != null) {
                        when {
                            currentSession.isCompleted -> FocusSessionState.COMPLETED
                            currentSession.isPaused -> FocusSessionState.PAUSED
                            else -> FocusSessionState.ACTIVE
                        }
                    } else FocusSessionState.INACTIVE,
                    isLoading = false
                )
                
                // Start timer if there's an active session
                if (currentSession != null && !currentSession.isCompleted && !currentSession.isPaused) {
                    startSessionTimer()
                }
                
            } catch (e: Exception) {
                _uiState.value = _uiState.value.copy(
                    error = e.message ?: "Failed to load focus data",
                    isLoading = false
                )
            }
        }
    }
    
    /**
     * Observe focus session changes
     */
    private fun observeFocusSession() {
        viewModelScope.launch {
            combine(
                focusRepository.getCurrentFocusSessionFlow(),
                focusRepository.getFocusStatsFlow(),
                taskRepository.getAllTasksFlow()
            ) { session, stats, tasks ->
                Triple(session, stats, tasks)
            }
            .catch { e ->
                _uiState.value = _uiState.value.copy(
                    error = e.message ?: "Failed to observe focus session"
                )
            }
            .collect { (session, stats, tasks) ->
                _uiState.value = _uiState.value.copy(
                    currentSession = session,
                    focusStats = stats,
                    filteredTasks = filterTasksForFocusMode(tasks, session)
                )
            }
        }
    }
    
    /**
     * Start a new focus session
     */
    fun startFocusSession(mode: FocusMode, customDuration: Duration? = null) {
        viewModelScope.launch {
            try {
                _uiState.value = _uiState.value.copy(sessionState = FocusSessionState.PREPARING)
                
                val session = focusRepository.startFocusSession(
                    mode = mode,
                    customDuration = customDuration?.toMinutes()
                )
                
                _uiState.value = _uiState.value.copy(
                    currentSession = session,
                    sessionState = FocusSessionState.ACTIVE,
                    error = null
                )
                
                startSessionTimer()
                
            } catch (e: Exception) {
                _uiState.value = _uiState.value.copy(
                    error = e.message ?: "Failed to start focus session",
                    sessionState = FocusSessionState.INACTIVE
                )
            }
        }
    }
    
    /**
     * Pause the current focus session
     */
    fun pauseFocusSession() {
        viewModelScope.launch {
            try {
                val sessionId = _uiState.value.currentSession?.id ?: return@launch
                val pausedSession = focusRepository.pauseFocusSession(sessionId)
                
                if (pausedSession != null) {
                    _uiState.value = _uiState.value.copy(
                        currentSession = pausedSession,
                        sessionState = FocusSessionState.PAUSED
                    )
                    stopSessionTimer()
                }
                
            } catch (e: Exception) {
                _uiState.value = _uiState.value.copy(
                    error = e.message ?: "Failed to pause focus session"
                )
            }
        }
    }
    
    /**
     * Resume the current focus session
     */
    fun resumeFocusSession() {
        viewModelScope.launch {
            try {
                val sessionId = _uiState.value.currentSession?.id ?: return@launch
                val resumedSession = focusRepository.resumeFocusSession(sessionId)
                
                if (resumedSession != null) {
                    _uiState.value = _uiState.value.copy(
                        currentSession = resumedSession,
                        sessionState = FocusSessionState.ACTIVE
                    )
                    startSessionTimer()
                }
                
            } catch (e: Exception) {
                _uiState.value = _uiState.value.copy(
                    error = e.message ?: "Failed to resume focus session"
                )
            }
        }
    }
    
    /**
     * Complete the current focus session
     */
    fun completeFocusSession(tasksCompleted: Int = 0, notes: String? = null) {
        viewModelScope.launch {
            try {
                val sessionId = _uiState.value.currentSession?.id ?: return@launch
                val completedSession = focusRepository.completeFocusSession(sessionId, tasksCompleted, notes)
                
                if (completedSession != null) {
                    _uiState.value = _uiState.value.copy(
                        currentSession = completedSession,
                        sessionState = FocusSessionState.COMPLETED,
                        showCompletionCelebration = true
                    )
                    stopSessionTimer()
                    
                    // Auto-hide celebration after 3 seconds
                    viewModelScope.launch {
                        delay(3000)
                        _uiState.value = _uiState.value.copy(showCompletionCelebration = false)
                    }
                }
                
            } catch (e: Exception) {
                _uiState.value = _uiState.value.copy(
                    error = e.message ?: "Failed to complete focus session"
                )
            }
        }
    }
    
    /**
     * Cancel the current focus session
     */
    fun cancelFocusSession() {
        viewModelScope.launch {
            try {
                val sessionId = _uiState.value.currentSession?.id ?: return@launch
                val cancelled = focusRepository.cancelFocusSession(sessionId)
                
                if (cancelled) {
                    _uiState.value = _uiState.value.copy(
                        currentSession = null,
                        sessionState = FocusSessionState.INACTIVE
                    )
                    stopSessionTimer()
                }
                
            } catch (e: Exception) {
                _uiState.value = _uiState.value.copy(
                    error = e.message ?: "Failed to cancel focus session"
                )
            }
        }
    }
    
    /**
     * Record a distraction during the session
     */
    fun recordDistraction() {
        viewModelScope.launch {
            try {
                val sessionId = _uiState.value.currentSession?.id ?: return@launch
                val updatedSession = focusRepository.addDistractionToSession(sessionId)
                
                if (updatedSession != null) {
                    _uiState.value = _uiState.value.copy(currentSession = updatedSession)
                }
                
            } catch (e: Exception) {
                _uiState.value = _uiState.value.copy(
                    error = e.message ?: "Failed to record distraction"
                )
            }
        }
    }
    
    /**
     * Update focus settings
     */
    fun updateFocusSettings(settings: FocusSettings) {
        viewModelScope.launch {
            try {
                focusRepository.updateFocusSettings(settings)
                _uiState.value = _uiState.value.copy(focusSettings = settings)
                
            } catch (e: Exception) {
                _uiState.value = _uiState.value.copy(
                    error = e.message ?: "Failed to update focus settings"
                )
            }
        }
    }
    
    /**
     * Start break timer
     */
    fun startBreak() {
        viewModelScope.launch {
            try {
                val sessionId = _uiState.value.currentSession?.id ?: return@launch
                val breakStarted = focusRepository.startBreak(sessionId)
                
                if (breakStarted) {
                    _uiState.value = _uiState.value.copy(sessionState = FocusSessionState.BREAK)
                    startBreakTimer()
                }
                
            } catch (e: Exception) {
                _uiState.value = _uiState.value.copy(
                    error = e.message ?: "Failed to start break"
                )
            }
        }
    }
    
    /**
     * End break and return to focus
     */
    fun endBreak() {
        viewModelScope.launch {
            try {
                val sessionId = _uiState.value.currentSession?.id ?: return@launch
                val breakEnded = focusRepository.endBreak(sessionId)
                
                if (breakEnded) {
                    _uiState.value = _uiState.value.copy(sessionState = FocusSessionState.ACTIVE)
                    stopBreakTimer()
                    startSessionTimer()
                }
                
            } catch (e: Exception) {
                _uiState.value = _uiState.value.copy(
                    error = e.message ?: "Failed to end break"
                )
            }
        }
    }
    
    /**
     * Clear error state
     */
    fun clearError() {
        _uiState.value = _uiState.value.copy(error = null)
    }
    
    /**
     * Start the session timer
     */
    private fun startSessionTimer() {
        stopSessionTimer() // Stop any existing timer
        
        sessionTimerJob = viewModelScope.launch {
            while (true) {
                delay(1000) // Update every second
                
                val currentSession = _uiState.value.currentSession
                if (currentSession != null && !currentSession.isCompleted && !currentSession.isPaused) {
                    val remainingTime = currentSession.getRemainingTime()
                    
                    _uiState.value = _uiState.value.copy(
                        remainingTime = remainingTime,
                        elapsedTime = currentSession.getElapsedTime()
                    )
                    
                    // Check if session is complete
                    if (remainingTime <= Duration.ZERO) {
                        // Auto-complete session or start break
                        if (currentSession.mode.supportsBreaks() && _uiState.value.focusSettings.autoStartBreaks) {
                            startBreak()
                        } else {
                            completeFocusSession()
                        }
                        break
                    }
                } else {
                    break
                }
            }
        }
    }
    
    /**
     * Stop the session timer
     */
    private fun stopSessionTimer() {
        sessionTimerJob?.cancel()
        sessionTimerJob = null
    }
    
    /**
     * Start the break timer
     */
    private fun startBreakTimer() {
        stopBreakTimer() // Stop any existing timer
        
        val currentSession = _uiState.value.currentSession ?: return
        val breakDuration = Duration.ofMinutes(
            focusRepository.getBreakDuration(currentSession.mode)
        )
        
        breakTimerJob = viewModelScope.launch {
            val breakStartTime = Instant.now()
            
            while (true) {
                delay(1000) // Update every second
                
                val elapsed = Duration.between(breakStartTime, Instant.now())
                val remaining = breakDuration.minus(elapsed)
                
                _uiState.value = _uiState.value.copy(
                    breakTimeRemaining = remaining
                )
                
                if (remaining <= Duration.ZERO) {
                    // Break is over, return to focus
                    endBreak()
                    break
                }
            }
        }
    }
    
    /**
     * Stop the break timer
     */
    private fun stopBreakTimer() {
        breakTimerJob?.cancel()
        breakTimerJob = null
    }
    
    /**
     * Filter tasks based on current focus mode
     */
    private fun filterTasksForFocusMode(tasks: List<Task>, session: FocusSession?): List<Task> {
        if (session == null) return tasks
        
        val filter = com.tasktracker.domain.model.FocusFilter(
            mode = session.mode,
            hideCompletedTasks = _uiState.value.focusSettings.hideCompletedTasks,
            minimumPriority = TaskPriority.MEDIUM, // This would come from task metadata
            showOnlyDueTasks = false
        )
        
        return tasks.filter { task ->
            filter.shouldShowTask(task, TaskPriority.MEDIUM, false)
        }
    }
    
    override fun onCleared() {
        super.onCleared()
        stopSessionTimer()
        stopBreakTimer()
    }
}

/**
 * UI state for focus mode
 */
data class FocusModeUiState(
    val isLoading: Boolean = true,
    val currentSession: FocusSession? = null,
    val sessionState: FocusSessionState = FocusSessionState.INACTIVE,
    val focusSettings: FocusSettings = FocusSettings(),
    val focusStats: FocusStats = FocusStats(),
    val filteredTasks: List<Task> = emptyList(),
    val remainingTime: Duration = Duration.ZERO,
    val elapsedTime: Duration = Duration.ZERO,
    val breakTimeRemaining: Duration = Duration.ZERO,
    val showCompletionCelebration: Boolean = false,
    val error: String? = null
) {
    val isSessionActive: Boolean
        get() = sessionState == FocusSessionState.ACTIVE
    
    val isSessionPaused: Boolean
        get() = sessionState == FocusSessionState.PAUSED
    
    val isOnBreak: Boolean
        get() = sessionState == FocusSessionState.BREAK
    
    val canStartSession: Boolean
        get() = sessionState == FocusSessionState.INACTIVE
    
    val canPauseSession: Boolean
        get() = sessionState == FocusSessionState.ACTIVE
    
    val canResumeSession: Boolean
        get() = sessionState == FocusSessionState.PAUSED
    
    val progressPercentage: Float
        get() = if (currentSession != null && remainingTime > Duration.ZERO) {
            val totalMinutes = currentSession.plannedDuration.toMinutes().toFloat()
            val elapsedMinutes = elapsedTime.toMinutes().toFloat()
            (elapsedMinutes / totalMinutes).coerceIn(0f, 1f)
        } else 0f
}