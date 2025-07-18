package com.tasktracker.presentation.focus

import com.tasktracker.domain.model.FocusMode
import com.tasktracker.domain.model.FocusSession
import com.tasktracker.domain.model.FocusSessionState
import com.tasktracker.domain.model.FocusSettings
import com.tasktracker.domain.model.Task
import com.tasktracker.domain.repository.FocusRepository
import com.tasktracker.domain.repository.TaskRepository
import io.mockk.coEvery
import io.mockk.coVerify
import io.mockk.mockk
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.flow.flowOf
import kotlinx.coroutines.test.StandardTestDispatcher
import kotlinx.coroutines.test.advanceUntilIdle
import kotlinx.coroutines.test.runTest
import kotlinx.coroutines.test.setMain
import org.junit.Before
import org.junit.Test
import java.time.Duration
import java.time.Instant

@OptIn(ExperimentalCoroutinesApi::class)
class FocusModeTest {
    
    private lateinit var focusRepository: FocusRepository
    private lateinit var taskRepository: TaskRepository
    private lateinit var viewModel: FocusModeViewModel
    
    private val testDispatcher = StandardTestDispatcher()
    
    @Before
    fun setup() {
        Dispatchers.setMain(testDispatcher)
        
        focusRepository = mockk(relaxed = true)
        taskRepository = mockk(relaxed = true)
        
        // Setup default mock responses
        coEvery { focusRepository.getFocusSettings() } returns FocusSettings()
        coEvery { focusRepository.getFocusStats() } returns mockk(relaxed = true)
        coEvery { focusRepository.getCurrentFocusSession() } returns null
        coEvery { focusRepository.getCurrentFocusSessionFlow() } returns flowOf(null)
        coEvery { focusRepository.getFocusStatsFlow() } returns flowOf(mockk(relaxed = true))
        coEvery { taskRepository.getAllTasksFlow() } returns flowOf(emptyList())
        
        viewModel = FocusModeViewModel(focusRepository, taskRepository)
    }
    
    @Test
    fun `startFocusSession creates new session`() = runTest {
        val mockSession = FocusSession(
            startTime = Instant.now(),
            plannedDuration = Duration.ofMinutes(25),
            mode = FocusMode.POMODORO
        )
        
        coEvery { focusRepository.startFocusSession(FocusMode.POMODORO, null) } returns mockSession
        
        viewModel.startFocusSession(FocusMode.POMODORO)
        advanceUntilIdle()
        
        coVerify { focusRepository.startFocusSession(FocusMode.POMODORO, null) }
        assert(viewModel.uiState.value.sessionState == FocusSessionState.ACTIVE)
    }
    
    @Test
    fun `pauseFocusSession pauses active session`() = runTest {
        val activeSession = FocusSession(
            id = "test-session",
            startTime = Instant.now(),
            plannedDuration = Duration.ofMinutes(25),
            mode = FocusMode.POMODORO
        )
        
        val pausedSession = activeSession.copy(isPaused = true, pausedAt = Instant.now())
        
        // Setup initial state with active session
        coEvery { focusRepository.getCurrentFocusSession() } returns activeSession
        viewModel = FocusModeViewModel(focusRepository, taskRepository)
        advanceUntilIdle()
        
        coEvery { focusRepository.pauseFocusSession("test-session") } returns pausedSession
        
        viewModel.pauseFocusSession()
        advanceUntilIdle()
        
        coVerify { focusRepository.pauseFocusSession("test-session") }
        assert(viewModel.uiState.value.sessionState == FocusSessionState.PAUSED)
    }
    
    @Test
    fun `resumeFocusSession resumes paused session`() = runTest {
        val pausedSession = FocusSession(
            id = "test-session",
            startTime = Instant.now(),
            plannedDuration = Duration.ofMinutes(25),
            mode = FocusMode.POMODORO,
            isPaused = true,
            pausedAt = Instant.now()
        )
        
        val resumedSession = pausedSession.copy(isPaused = false, pausedAt = null)
        
        // Setup initial state with paused session
        coEvery { focusRepository.getCurrentFocusSession() } returns pausedSession
        viewModel = FocusModeViewModel(focusRepository, taskRepository)
        advanceUntilIdle()
        
        coEvery { focusRepository.resumeFocusSession("test-session") } returns resumedSession
        
        viewModel.resumeFocusSession()
        advanceUntilIdle()
        
        coVerify { focusRepository.resumeFocusSession("test-session") }
        assert(viewModel.uiState.value.sessionState == FocusSessionState.ACTIVE)
    }
    
    @Test
    fun `completeFocusSession completes active session`() = runTest {
        val activeSession = FocusSession(
            id = "test-session",
            startTime = Instant.now(),
            plannedDuration = Duration.ofMinutes(25),
            mode = FocusMode.POMODORO
        )
        
        val completedSession = activeSession.copy(isCompleted = true)
        
        // Setup initial state with active session
        coEvery { focusRepository.getCurrentFocusSession() } returns activeSession
        viewModel = FocusModeViewModel(focusRepository, taskRepository)
        advanceUntilIdle()
        
        coEvery { focusRepository.completeFocusSession("test-session", 0, null) } returns completedSession
        
        viewModel.completeFocusSession()
        advanceUntilIdle()
        
        coVerify { focusRepository.completeFocusSession("test-session", 0, null) }
        assert(viewModel.uiState.value.sessionState == FocusSessionState.COMPLETED)
    }
    
    @Test
    fun `recordDistraction adds distraction to session`() = runTest {
        val activeSession = FocusSession(
            id = "test-session",
            startTime = Instant.now(),
            plannedDuration = Duration.ofMinutes(25),
            mode = FocusMode.POMODORO
        )
        
        val sessionWithDistraction = activeSession.copy(distractionCount = 1)
        
        // Setup initial state with active session
        coEvery { focusRepository.getCurrentFocusSession() } returns activeSession
        viewModel = FocusModeViewModel(focusRepository, taskRepository)
        advanceUntilIdle()
        
        coEvery { focusRepository.addDistractionToSession("test-session") } returns sessionWithDistraction
        
        viewModel.recordDistraction()
        advanceUntilIdle()
        
        coVerify { focusRepository.addDistractionToSession("test-session") }
    }
    
    @Test
    fun `updateFocusSettings updates settings`() = runTest {
        val newSettings = FocusSettings(
            defaultMode = FocusMode.DEEP_WORK,
            enableBreaks = false
        )
        
        viewModel.updateFocusSettings(newSettings)
        advanceUntilIdle()
        
        coVerify { focusRepository.updateFocusSettings(newSettings) }
        assert(viewModel.uiState.value.focusSettings == newSettings)
    }
    
    @Test
    fun `filterTasksForFocusMode filters tasks correctly`() = runTest {
        val tasks = listOf(
            Task(id = "1", description = "Task 1", isCompleted = false),
            Task(id = "2", description = "Task 2", isCompleted = true),
            Task(id = "3", description = "Task 3", isCompleted = false)
        )
        
        val activeSession = FocusSession(
            startTime = Instant.now(),
            plannedDuration = Duration.ofMinutes(25),
            mode = FocusMode.DEEP_WORK
        )
        
        coEvery { taskRepository.getAllTasksFlow() } returns flowOf(tasks)
        coEvery { focusRepository.getCurrentFocusSessionFlow() } returns flowOf(activeSession)
        
        viewModel = FocusModeViewModel(focusRepository, taskRepository)
        advanceUntilIdle()
        
        // Should filter out completed tasks in focus mode
        val filteredTasks = viewModel.uiState.value.filteredTasks
        assert(filteredTasks.size == 2)
        assert(filteredTasks.none { it.isCompleted })
    }
    
    @Test
    fun `uiState properties return correct values`() = runTest {
        val activeSession = FocusSession(
            startTime = Instant.now(),
            plannedDuration = Duration.ofMinutes(25),
            mode = FocusMode.POMODORO
        )
        
        coEvery { focusRepository.getCurrentFocusSession() } returns activeSession
        viewModel = FocusModeViewModel(focusRepository, taskRepository)
        advanceUntilIdle()
        
        val uiState = viewModel.uiState.value
        
        assert(uiState.isSessionActive)
        assert(!uiState.isSessionPaused)
        assert(!uiState.isOnBreak)
        assert(!uiState.canStartSession)
        assert(uiState.canPauseSession)
        assert(!uiState.canResumeSession)
    }
}