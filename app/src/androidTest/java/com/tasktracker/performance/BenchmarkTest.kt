package com.tasktracker.performance

import androidx.benchmark.junit4.BenchmarkRule
import androidx.benchmark.junit4.measureRepeated
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import com.tasktracker.data.local.TaskDatabase
import com.tasktracker.data.local.entity.TaskEntity
import com.tasktracker.domain.model.RecurrenceType
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.runBlocking
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith

/**
 * Benchmark tests for critical performance paths in the Task Tracker app.
 * These tests measure actual performance on device hardware.
 */
@RunWith(AndroidJUnit4::class)
class BenchmarkTest {
    
    @get:Rule
    val benchmarkRule = BenchmarkRule()
    
    private val context = InstrumentationRegistry.getInstrumentation().targetContext
    private val database = TaskDatabase.getDatabase(context)
    private val taskDao = database.taskDao()
    
    @Test
    fun benchmarkTaskInsertion() {
        benchmarkRule.measureRepeated {
            runBlocking {
                val task = TaskEntity(
                    id = "benchmark_${System.nanoTime()}",
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
        // Setup: Insert test data
        runBlocking {
            val tasks = (1..100).map { index ->
                TaskEntity(
                    id = "query_test_$index",
                    description = "Query test task $index",
                    isCompleted = false,
                    createdAt = System.currentTimeMillis() - (index * 1000)
                )
            }
            taskDao.insertTasks(tasks)
        }
        
        // Benchmark: Query active tasks
        benchmarkRule.measureRepeated {
            runBlocking {
                taskDao.getActiveTasks().first()
            }
        }
    }
    
    @Test
    fun benchmarkTaskCompletion() {
        // Setup: Insert test task
        val testTask = TaskEntity(
            id = "completion_test",
            description = "Completion test task",
            isCompleted = false,
            createdAt = System.currentTimeMillis()
        )
        
        runBlocking {
            taskDao.insertTask(testTask)
        }
        
        // Benchmark: Task completion
        benchmarkRule.measureRepeated {
            runBlocking {
                taskDao.markTaskCompleted(testTask.id, System.currentTimeMillis())
                // Reset for next iteration
                taskDao.updateTask(testTask.copy(isCompleted = false, completedAt = null))
            }
        }
    }
    
    @Test
    fun benchmarkBulkOperations() {
        benchmarkRule.measureRepeated {
            runBlocking {
                // Create bulk tasks
                val bulkTasks = (1..50).map { index ->
                    TaskEntity(
                        id = "bulk_${System.nanoTime()}_$index",
                        description = "Bulk task $index",
                        isCompleted = false,
                        createdAt = System.currentTimeMillis()
                    )
                }
                
                // Insert all at once
                taskDao.insertTasks(bulkTasks)
                
                // Bulk complete
                val taskIds = bulkTasks.map { it.id }
                taskDao.bulkUpdateTaskCompletion(taskIds, true, System.currentTimeMillis())
            }
        }
    }
    
    @Test
    fun benchmarkSearchQuery() {
        // Setup: Insert searchable tasks
        runBlocking {
            val searchTasks = (1..200).map { index ->
                TaskEntity(
                    id = "search_$index",
                    description = "Searchable task $index with important keyword",
                    isCompleted = false,
                    createdAt = System.currentTimeMillis()
                )
            }
            taskDao.insertTasks(searchTasks)
        }
        
        // Benchmark: Search operation
        benchmarkRule.measureRepeated {
            runBlocking {
                taskDao.searchTasks("important").first()
            }
        }
    }
    
    @Test
    fun benchmarkRecurringTaskProcessing() {
        // Setup: Insert recurring tasks
        runBlocking {
            val recurringTasks = (1..20).map { index ->
                TaskEntity(
                    id = "recurring_$index",
                    description = "Recurring task $index",
                    isCompleted = false,
                    createdAt = System.currentTimeMillis(),
                    recurrenceType = RecurrenceType.DAILY.name
                )
            }
            taskDao.insertTasks(recurringTasks)
        }
        
        // Benchmark: Process recurring tasks
        benchmarkRule.measureRepeated {
            runBlocking {
                val recurringTasks = taskDao.getRecurringTasks()
                recurringTasks.forEach { task ->
                    // Simulate completion and next instance creation
                    taskDao.markTaskCompleted(task.id, System.currentTimeMillis())
                    
                    // Create next instance
                    val nextTask = task.copy(
                        id = "${task.id}_next_${System.nanoTime()}",
                        isCompleted = false,
                        completedAt = null,
                        createdAt = System.currentTimeMillis() + 86400000 // Next day
                    )
                    taskDao.insertTask(nextTask)
                }
            }
        }
    }
}