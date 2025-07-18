package com.tasktracker.presentation.notifications

import android.content.Context
import androidx.work.ListenableWorker
import androidx.work.WorkerParameters
import androidx.work.workDataOf
import com.tasktracker.domain.model.Task
import com.tasktracker.domain.repository.TaskRepository
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.flow.flowOf
import kotlinx.coroutines.test.runTest
import org.junit.Before
import org.junit.Test
import org.mockito.Mock
import org.mockito.MockitoAnnotations
import org.mockito.kotlin.never
import org.mockito.kotlin.verify
import org.mockito.kotlin.whenever
import com.google.common.truth.Truth.assertThat

@OptIn(ExperimentalCoroutinesApi::class)
class TaskReminderWorkerTest {

    @Mock
    private lateinit var context: Context

    @Mock
    private lateinit var workerParams: WorkerParameters

    @Mock
    private lateinit var notificationService: NotificationService

    @Mock
    private lateinit var taskRepository: TaskRepository

    private lateinit var worker: TaskReminderWorker

    @Before
    fun setup() {
        MockitoAnnotations.openMocks(this)
    }

    @Test
    fun `doWork shows notification for active task`() = runTest {
        // Given
        val taskId = "test-task"
        val taskDescription = "Test task description"
        val task = Task(id = taskId, description = taskDescription, isCompleted = false)
        
        val inputData = workDataOf(
            NotificationService.EXTRA_TASK_ID to taskId,
            NotificationService.EXTRA_TASK_DESCRIPTION to taskDescription
        )
        whenever(workerParams.inputData).thenReturn(inputData)
        whenever(taskRepository.getAllTasks()).thenReturn(flowOf(listOf(task)))
        
        worker = TaskReminderWorker(context, workerParams, notificationService, taskRepository)

        // When
        val result = worker.doWork()

        // Then
        assertThat(result).isEqualTo(ListenableWorker.Result.success())
        verify(notificationService).showTaskReminderNotification(taskId, taskDescription)
    }

    @Test
    fun `doWork does not show notification for completed task`() = runTest {
        // Given
        val taskId = "test-task"
        val taskDescription = "Test task description"
        val task = Task(id = taskId, description = taskDescription, isCompleted = true)
        
        val inputData = workDataOf(
            NotificationService.EXTRA_TASK_ID to taskId,
            NotificationService.EXTRA_TASK_DESCRIPTION to taskDescription
        )
        whenever(workerParams.inputData).thenReturn(inputData)
        whenever(taskRepository.getAllTasks()).thenReturn(flowOf(listOf(task)))
        
        worker = TaskReminderWorker(context, workerParams, notificationService, taskRepository)

        // When
        val result = worker.doWork()

        // Then
        assertThat(result).isEqualTo(ListenableWorker.Result.success())
        verify(notificationService, never()).showTaskReminderNotification(taskId, taskDescription)
    }

    @Test
    fun `doWork does not show notification for deleted task`() = runTest {
        // Given
        val taskId = "test-task"
        val taskDescription = "Test task description"
        
        val inputData = workDataOf(
            NotificationService.EXTRA_TASK_ID to taskId,
            NotificationService.EXTRA_TASK_DESCRIPTION to taskDescription
        )
        whenever(workerParams.inputData).thenReturn(inputData)
        whenever(taskRepository.getAllTasks()).thenReturn(flowOf(emptyList()))
        
        worker = TaskReminderWorker(context, workerParams, notificationService, taskRepository)

        // When
        val result = worker.doWork()

        // Then
        assertThat(result).isEqualTo(ListenableWorker.Result.success())
        verify(notificationService, never()).showTaskReminderNotification(taskId, taskDescription)
    }

    @Test
    fun `doWork returns failure when task ID is missing`() = runTest {
        // Given
        val inputData = workDataOf(
            NotificationService.EXTRA_TASK_DESCRIPTION to "Test description"
            // Missing EXTRA_TASK_ID
        )
        whenever(workerParams.inputData).thenReturn(inputData)
        
        worker = TaskReminderWorker(context, workerParams, notificationService, taskRepository)

        // When
        val result = worker.doWork()

        // Then
        assertThat(result).isEqualTo(ListenableWorker.Result.failure())
        verify(notificationService, never()).showTaskReminderNotification(
            org.mockito.kotlin.any(), 
            org.mockito.kotlin.any()
        )
    }

    @Test
    fun `doWork returns failure when task description is missing`() = runTest {
        // Given
        val inputData = workDataOf(
            NotificationService.EXTRA_TASK_ID to "test-task"
            // Missing EXTRA_TASK_DESCRIPTION
        )
        whenever(workerParams.inputData).thenReturn(inputData)
        
        worker = TaskReminderWorker(context, workerParams, notificationService, taskRepository)

        // When
        val result = worker.doWork()

        // Then
        assertThat(result).isEqualTo(ListenableWorker.Result.failure())
        verify(notificationService, never()).showTaskReminderNotification(
            org.mockito.kotlin.any(), 
            org.mockito.kotlin.any()
        )
    }
}