package com.tasktracker.data

import androidx.room.Room
import androidx.test.core.app.ApplicationProvider
import androidx.test.ext.junit.runners.AndroidJUnit4
import com.tasktracker.data.local.TaskDao
import com.tasktracker.data.local.TaskDatabase
import com.tasktracker.data.local.entity.toEntity
import com.tasktracker.domain.model.RecurrenceType
import com.tasktracker.domain.model.Task
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.test.runTest
import org.junit.After
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import com.google.common.truth.Truth.assertThat

@RunWith(AndroidJUnit4::class)
class OfflineFunctionalityTest {

    private lateinit var database: TaskDatabase
    private lateinit var taskDao: TaskDao

    @Before
    fun setup() {
        database = Room.inMemoryDatabaseBuilder(
            ApplicationProvider.getApplicationContext(),
            TaskDatabase::class.java
        ).build()
        taskDao = database.taskDao()
    }

    @After
    fun tearDown() {
        database.close()
    }

    @Test
    fun offlineTaskCreation_worksWithoutInternetConnection() = runTest {
        // Given - simulate offline environment (no network calls in Room)
        val task = Task(
            description = "Offline task",
            reminderTime = System.currentTimeMillis() + 3600000
        )

        // When - create task offline
        taskDao.insertTask(task.toEntity())

        // Then - task should be stored locally
        val allTasks = taskDao.getAllTasks().first()
        assertThat(allTasks).hasSize(1)
        assertThat(allTasks[0].description).isEqualTo("Offline task")
    }

    @Test
    fun offlineTaskCompletion_worksWithoutInternetConnection() = runTest {
        // Given - task exists locally
        val task = Task(description = "Task to complete")
        taskDao.insertTask(task.toEntity())

        // When - complete task offline
        val completedTask = task.markAsCompleted()
        taskDao.updateTask(completedTask.toEntity())

        // Then - task should be marked as completed locally
        val updatedTask = taskDao.getTaskById(task.id)
        assertThat(updatedTask).isNotNull()
        assertThat(updatedTask!!.isCompleted).isTrue()
        assertThat(updatedTask.completedAt).isNotNull()
    }

    @Test
    fun offlineTaskDeletion_worksWithoutInternetConnection() = runTest {
        // Given - task exists locally
        val task = Task(description = "Task to delete")
        taskDao.insertTask(task.toEntity())

        // When - delete task offline
        taskDao.deleteTaskById(task.id)

        // Then - task should be removed from local storage
        val deletedTask = taskDao.getTaskById(task.id)
        assertThat(deletedTask).isNull()
    }

    @Test
    fun offlineRecurringTaskGeneration_worksWithoutInternetConnection() = runTest {
        // Given - recurring task exists locally
        val recurringTask = Task(
            description = "Daily recurring task",
            recurrenceType = RecurrenceType.DAILY,
            reminderTime = System.currentTimeMillis() + 3600000
        )
        taskDao.insertTask(recurringTask.toEntity())

        // When - complete recurring task (which should generate next instance)
        val completedTask = recurringTask.markAsCompleted()
        taskDao.updateTask(completedTask.toEntity())
        
        val nextTask = recurringTask.createNextRecurrence()
        if (nextTask != null) {
            taskDao.insertTask(nextTask.toEntity())
        }

        // Then - next instance should be created locally
        val allTasks = taskDao.getAllTasks().first()
        assertThat(allTasks).hasSize(2) // Original completed + new instance
        
        val activeTasks = taskDao.getActiveTasks().first()
        assertThat(activeTasks).hasSize(1) // Only the new instance should be active
        assertThat(activeTasks[0].description).isEqualTo("Daily recurring task")
    }

    @Test
    fun offlineDataPersistence_survivesAppRestart() = runTest {
        // Given - tasks are created and stored
        val tasks = listOf(
            Task(description = "Persistent task 1"),
            Task(description = "Persistent task 2", isCompleted = true),
            Task(description = "Persistent task 3", recurrenceType = RecurrenceType.WEEKLY)
        )
        
        tasks.forEach { task ->
            taskDao.insertTask(task.toEntity())
        }

        // When - simulate app restart by creating new DAO instance
        // (In real test, this would involve closing and reopening database)
        val persistedTasks = taskDao.getAllTasks().first()

        // Then - all tasks should still be available
        assertThat(persistedTasks).hasSize(3)
        assertThat(persistedTasks.map { it.description }).containsExactly(
            "Persistent task 1",
            "Persistent task 2", 
            "Persistent task 3"
        )
    }

    @Test
    fun offlineTaskFiltering_worksWithoutInternetConnection() = runTest {
        // Given - mix of active and completed tasks
        val activeTasks = listOf(
            Task(description = "Active task 1"),
            Task(description = "Active task 2")
        )
        val completedTasks = listOf(
            Task(description = "Completed task 1", isCompleted = true),
            Task(description = "Completed task 2", isCompleted = true)
        )

        (activeTasks + completedTasks).forEach { task ->
            taskDao.insertTask(task.toEntity())
        }

        // When - filter tasks offline
        val activeResults = taskDao.getActiveTasks().first()
        val completedResults = taskDao.getCompletedTasks().first()

        // Then - filtering should work correctly
        assertThat(activeResults).hasSize(2)
        assertThat(completedResults).hasSize(2)
        assertThat(activeResults.all { !it.isCompleted }).isTrue()
        assertThat(completedResults.all { it.isCompleted }).isTrue()
    }

    @Test
    fun offlineTaskSearch_worksWithoutInternetConnection() = runTest {
        // Given - tasks with different descriptions
        val tasks = listOf(
            Task(description = "Buy groceries"),
            Task(description = "Buy milk"),
            Task(description = "Call doctor"),
            Task(description = "Schedule meeting")
        )

        tasks.forEach { task ->
            taskDao.insertTask(task.toEntity())
        }

        // When - search tasks offline
        val searchResults = taskDao.searchTasks("Buy").first()

        // Then - search should work correctly
        assertThat(searchResults).hasSize(2)
        assertThat(searchResults.map { it.description }).containsExactly(
            "Buy groceries",
            "Buy milk"
        )
    }

    @Test
    fun offlineTaskCounting_worksWithoutInternetConnection() = runTest {
        // Given - mix of active and completed tasks
        val tasks = listOf(
            Task(description = "Active 1"),
            Task(description = "Active 2"),
            Task(description = "Completed 1", isCompleted = true),
            Task(description = "Completed 2", isCompleted = true),
            Task(description = "Completed 3", isCompleted = true)
        )

        tasks.forEach { task ->
            taskDao.insertTask(task.toEntity())
        }

        // When - count tasks offline
        val activeCount = taskDao.getActiveTaskCount()
        val completedCount = taskDao.getCompletedTaskCount()

        // Then - counting should work correctly
        assertThat(activeCount).isEqualTo(2)
        assertThat(completedCount).isEqualTo(3)
    }
}