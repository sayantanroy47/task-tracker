package com.tasktracker.performance

import androidx.benchmark.junit4.BenchmarkRule
import androidx.benchmark.junit4.measureRepeated
import androidx.room.Room
import androidx.test.core.app.ApplicationProvider
import androidx.test.ext.junit.runners.AndroidJUnit4
import com.tasktracker.data.local.TaskDatabase
import com.tasktracker.data.local.entity.TaskEntity
import com.tasktracker.domain.model.RecurrenceType
import kotlinx.coroutines.runBlocking
import org.junit.After
import org.junit.Before
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith

/**
 * Performance tests for critical app operations
 */
@RunWith(AndroidJUnit4::class)
class PerformanceTest {

    @get:Rule
    val benchmarkRule = BenchmarkRule()

    private lateinit var database: TaskDatabase

    @Before
    fun setup() {
        database = Room.inMemoryDatabaseBuilder(
            ApplicationProvider.getApplicationContext(),
            TaskDatabase::class.java
        ).allowMainThreadQueries().build()
    }

    @After
    fun tearDown() {
        database.close()
    }

    @Test
    fun benchmarkTaskInsertion() {
        val taskDao = database.taskDao()
        
        benchmarkRule.measureRepeated {
            runBlocking {
                val task = TaskEntity(
                    id = "benchmark-${System.nanoTime()}",
                    description = "Benchmark task",
                    isCompleted = false,
                    createdAt = System.currentTimeMillis()
                )
                taskDao.insertTask(task)
            }
        }
    }

    @Test
    fun benchmarkTaskQuery() {
        val taskDao = database.taskDao()
        
        // Setup: Insert test data
        runBlocking {
            repeat(100) { i ->
                val task = TaskEntity(
                    id = "query-test-$i",
                    description = "Query test task $i",
                    isCompleted = i % 2 == 0,
                    createdAt = System.currentTimeMillis() - i * 1000
                )
                taskDao.insertTask(task)
            }
        }

        benchmarkRule.measureRepeated {
            runBlocking {
                taskDao.getAllTasks()
            }
        }
    }

    @Test
    fun benchmarkTaskUpdate() {
        val taskDao = database.taskDao()
        
        // Setup: Insert a task to update
        val taskId = "update-benchmark"
        runBlocking {
            val task = TaskEntity(
                id = taskId,
                description = "Task to update",
                isCompleted = false,
                createdAt = System.currentTimeMillis()
            )
            taskDao.insertTask(task)
        }

        benchmarkRule.measureRepeated {
            runBlocking {
                val task = taskDao.getTaskById(taskId)!!
                val updatedTask = task.copy(
                    description = "Updated task ${System.nanoTime()}",
                    isCompleted = !task.isCompleted
                )
                taskDao.updateTask(updatedTask)
            }
        }
    }

    @Test
    fun benchmarkComplexQuery() {
        val taskDao = database.taskDao()
        
        // Setup: Insert diverse test data
        runBlocking {
            repeat(1000) { i ->
                val task = TaskEntity(
                    id = "complex-$i",
                    description = "Complex query task $i",
                    isCompleted = i % 3 == 0,
                    reminderTime = if (i % 5 == 0) System.currentTimeMillis() + i * 1000 else null,
                    recurrenceType = when (i % 4) {
                        0 -> RecurrenceType.DAILY
                        1 -> RecurrenceType.WEEKLY
                        2 -> RecurrenceType.MONTHLY
                        else -> null
                    },
                    createdAt = System.currentTimeMillis() - i * 1000
                )
                taskDao.insertTask(task)
            }
        }

        benchmarkRule.measureRepeated {
            runBlocking {
                // Simulate complex filtering
                val allTasks = taskDao.getAllTasks()
                val activeTasks = taskDao.getActiveTasks()
                val completedTasks = taskDao.getCompletedTasks()
                
                // Simulate in-memory filtering
                allTasks.filter { it.reminderTime != null }
                allTasks.filter { it.recurrenceType != null }
            }
        }
    }

    @Test
    fun benchmarkBatchInsertion() {
        val taskDao = database.taskDao()
        
        benchmarkRule.measureRepeated {
            runBlocking {
                // Simulate batch insertion of 50 tasks
                repeat(50) { i ->
                    val task = TaskEntity(
                        id = "batch-${System.nanoTime()}-$i",
                        description = "Batch task $i",
                        isCompleted = false,
                        createdAt = System.currentTimeMillis()
                    )
                    taskDao.insertTask(task)
                }
            }
        }
    }

    @Test
    fun benchmarkTaskDeletion() {
        val taskDao = database.taskDao()
        
        benchmarkRule.measureRepeated {
            runBlocking {
                // Setup: Insert task to delete
                val taskId = "delete-${System.nanoTime()}"
                val task = TaskEntity(
                    id = taskId,
                    description = "Task to delete",
                    isCompleted = false,
                    createdAt = System.currentTimeMillis()
                )
                taskDao.insertTask(task)
                
                // Benchmark: Delete the task
                taskDao.deleteTaskById(taskId)
            }
        }
    }

    @Test
    fun benchmarkDatabaseTransaction() {
        val taskDao = database.taskDao()
        
        benchmarkRule.measureRepeated {
            runBlocking {
                database.runInTransaction {
                    // Simulate a complex transaction
                    repeat(10) { i ->
                        val task = TaskEntity(
                            id = "transaction-${System.nanoTime()}-$i",
                            description = "Transaction task $i",
                            isCompleted = false,
                            createdAt = System.currentTimeMillis()
                        )
                        runBlocking { taskDao.insertTask(task) }
                    }
                    
                    // Update some tasks
                    val tasks = runBlocking { taskDao.getAllTasks() }
                    tasks.take(5).forEach { task ->
                        val updatedTask = task.copy(isCompleted = true)
                        runBlocking { taskDao.updateTask(updatedTask) }
                    }
                }
            }
        }
    }

    @Test
    fun benchmarkMemoryUsage() {
        val taskDao = database.taskDao()
        
        // Setup: Insert large dataset
        runBlocking {
            repeat(5000) { i ->
                val task = TaskEntity(
                    id = "memory-test-$i",
                    description = "Memory test task $i with longer description to test memory usage patterns",
                    isCompleted = i % 2 == 0,
                    reminderTime = if (i % 3 == 0) System.currentTimeMillis() + i * 1000 else null,
                    recurrenceType = if (i % 4 == 0) RecurrenceType.DAILY else null,
                    createdAt = System.currentTimeMillis() - i * 1000
                )
                taskDao.insertTask(task)
            }
        }

        benchmarkRule.measureRepeated {
            runBlocking {
                // Simulate memory-intensive operations
                val allTasks = taskDao.getAllTasks()
                
                // Process tasks in memory
                val groupedTasks = allTasks.groupBy { it.isCompleted }
                val sortedTasks = allTasks.sortedBy { it.createdAt }
                val filteredTasks = allTasks.filter { it.description.contains("test") }
                
                // Simulate data transformation
                val taskSummaries = allTasks.map { task ->
                    mapOf(
                        "id" to task.id,
                        "description" to task.description,
                        "completed" to task.isCompleted,
                        "hasReminder" to (task.reminderTime != null),
                        "isRecurring" to (task.recurrenceType != null)
                    )
                }
            }
        }
    }
}