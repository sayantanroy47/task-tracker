package com.tasktracker.performance

import com.tasktracker.data.local.TaskDao
import com.tasktracker.data.local.entity.TaskEntity
import com.tasktracker.data.repository.TaskRepositoryImpl
import com.tasktracker.domain.model.RecurrenceType
import com.tasktracker.domain.model.Task
import com.tasktracker.util.PerformanceMonitor
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.flowOf
import kotlinx.coroutines.runBlocking
import kotlinx.coroutines.test.runTest
import org.junit.Before
import org.junit.Test
import org.mockito.Mock
import org.mockito.MockitoAnnotations
import org.mockito.kotlin.whenever
import kotlin.system.measureTimeMillis
import kotlin.test.assertTrue

/**
 * Performance tests for critical user flows in the Task Tracker app.
 * Tests database operations, large list handling, and memory usage.
 */
class PerformanceTest {
    
    @Mock
    private lateinit var mockTaskDao: TaskDao
    
    private lateinit var taskRepository: TaskRepositoryImpl
    
    @Before
    fun setup() {
        MockitoAnnotations.openMocks(this)
        taskRepository = TaskRepositoryImpl(mockTaskDao)
    }
    
    @Test
    fun `test large task list loading performance`() = runTest {
        // Arrange: Create a large list of tasks (1000 items)
        val largeTasks = generateLargeTasks(1000)
        whenever(mockTaskDao.getActiveTasks()).thenReturn(flowOf(largeTasks))
        
        // Act: Measure time to load tasks
        val loadTime = measureTimeMillis {
            val tasks = taskRepository.getActiveTasks().first()
            assertTrue(tasks.size == 1000, "Should load all 1000 tasks")
        }
        
        // Assert: Loading should complete within reasonable time (< 500ms)
        assertTrue(loadTime < 500, "Loading 1000 tasks took ${loadTime}ms, should be < 500ms")
        
        PerformanceMonitor.recordMetrics("loadLargeTasks", loadTime)
    }
    
    @Test
    fun `test task creation performance`() = runTest {
        // Arrange
        val task = Task(description = "Test task")
        val taskEntity = TaskEntity(
            id = task.id,
            description = task.description,
            isCompleted = task.isCompleted,
            createdAt = task.createdAt
        )
        
        // Act: Measure task creation time
        val creationTime = measureTimeMillis {
            runBlocking {
                taskRepository.insertTask(task)
            }
        }
        
        // Assert: Task creation should be fast (< 50ms)
        assertTrue(creationTime < 50, "Task creation took ${creationTime}ms, should be < 50ms")
        
        PerformanceMonitor.recordMetrics("createTask", creationTime)
    }
    
    @Test
    fun `test bulk task operations performance`() = runTest {
        // Arrange: Create multiple tasks for bulk operations
        val tasks = generateLargeTasks(100)
        whenever(mockTaskDao.getActiveTasks()).thenReturn(flowOf(tasks))
        
        // Act: Measure bulk completion time
        val bulkTime = measureTimeMillis {
            runBlocking {
                // Simulate bulk task completion
                tasks.forEach { task ->
                    taskRepository.completeTask(task.id)
                }
            }
        }
        
        // Assert: Bulk operations should be efficient
        val averageTimePerTask = bulkTime / tasks.size
        assertTrue(averageTimePerTask < 10, "Average time per task completion: ${averageTimePerTask}ms, should be < 10ms")
        
        PerformanceMonitor.recordMetrics("bulkTaskCompletion", bulkTime)
    }
    
    @Test
    fun `test database query optimization`() = runTest {
        // Arrange: Create tasks with different completion states
        val activeTasks = generateLargeTasks(500, isCompleted = false)
        val completedTasks = generateLargeTasks(500, isCompleted = true)
        
        whenever(mockTaskDao.getActiveTasks()).thenReturn(flowOf(activeTasks))
        whenever(mockTaskDao.getCompletedTasks()).thenReturn(flowOf(completedTasks))
        
        // Act: Measure query performance for filtered results
        val activeQueryTime = measureTimeMillis {
            val tasks = taskRepository.getActiveTasks().first()
            assertTrue(tasks.size == 500, "Should return 500 active tasks")
        }
        
        val completedQueryTime = measureTimeMillis {
            val tasks = taskRepository.getCompletedTasks().first()
            assertTrue(tasks.size == 500, "Should return 500 completed tasks")
        }
        
        // Assert: Filtered queries should be fast
        assertTrue(activeQueryTime < 100, "Active tasks query took ${activeQueryTime}ms, should be < 100ms")
        assertTrue(completedQueryTime < 100, "Completed tasks query took ${completedQueryTime}ms, should be < 100ms")
        
        PerformanceMonitor.recordMetrics("activeTasksQuery", activeQueryTime)
        PerformanceMonitor.recordMetrics("completedTasksQuery", completedQueryTime)
    }
    
    @Test
    fun `test memory usage with large datasets`() = runTest {
        // Arrange: Create a very large dataset
        val veryLargeTasks = generateLargeTasks(5000)
        whenever(mockTaskDao.getActiveTasks()).thenReturn(flowOf(veryLargeTasks))
        
        // Act: Load large dataset and monitor memory
        val initialMemory = Runtime.getRuntime().let { it.totalMemory() - it.freeMemory() }
        
        val tasks = taskRepository.getActiveTasks().first()
        
        val finalMemory = Runtime.getRuntime().let { it.totalMemory() - it.freeMemory() }
        val memoryIncrease = (finalMemory - initialMemory) / 1024 / 1024 // Convert to MB
        
        // Assert: Memory increase should be reasonable for 5000 tasks
        assertTrue(memoryIncrease < 50, "Memory increase: ${memoryIncrease}MB for 5000 tasks, should be < 50MB")
        assertTrue(tasks.size == 5000, "Should load all 5000 tasks")
        
        PerformanceMonitor.logMemoryUsage("Large dataset test")
    }
    
    @Test
    fun `test recurring task generation performance`() = runTest {
        // Arrange: Create recurring tasks
        val recurringTasks = (1..100).map { index ->
            TaskEntity(
                id = "recurring_$index",
                description = "Recurring task $index",
                isCompleted = false,
                createdAt = System.currentTimeMillis(),
                recurrenceType = RecurrenceType.DAILY.name
            )
        }
        
        whenever(mockTaskDao.getRecurringTasks()).thenReturn(recurringTasks)
        
        // Act: Measure recurring task processing time
        val processingTime = measureTimeMillis {
            runBlocking {
                // Simulate processing recurring tasks
                recurringTasks.forEach { task ->
                    // Simulate task completion and next instance creation
                    taskRepository.completeTask(task.id)
                }
            }
        }
        
        // Assert: Recurring task processing should be efficient
        val averageTimePerTask = processingTime / recurringTasks.size
        assertTrue(averageTimePerTask < 20, "Average recurring task processing: ${averageTimePerTask}ms, should be < 20ms")
        
        PerformanceMonitor.recordMetrics("recurringTaskProcessing", processingTime)
    }
    
    @Test
    fun `test search performance with large dataset`() = runTest {
        // Arrange: Create large dataset for search
        val searchableTasks = generateSearchableTasks(2000)
        whenever(mockTaskDao.searchTasks("important")).thenReturn(flowOf(searchableTasks.filter { 
            it.description.contains("important", ignoreCase = true) 
        }))
        
        // Act: Measure search performance
        val searchTime = measureTimeMillis {
            val results = taskRepository.searchTasks("important").first()
            assertTrue(results.isNotEmpty(), "Search should return results")
        }
        
        // Assert: Search should be fast even with large dataset
        assertTrue(searchTime < 200, "Search took ${searchTime}ms, should be < 200ms")
        
        PerformanceMonitor.recordMetrics("taskSearch", searchTime)
    }
    
    private fun generateLargeTasks(count: Int, isCompleted: Boolean = false): List<TaskEntity> {
        return (1..count).map { index ->
            TaskEntity(
                id = "task_$index",
                description = "Task $index - ${if (isCompleted) "completed" else "active"}",
                isCompleted = isCompleted,
                createdAt = System.currentTimeMillis() - (index * 1000),
                completedAt = if (isCompleted) System.currentTimeMillis() else null
            )
        }
    }
    
    private fun generateSearchableTasks(count: Int): List<TaskEntity> {
        val keywords = listOf("important", "urgent", "meeting", "call", "email", "project", "review")
        return (1..count).map { index ->
            val keyword = keywords[index % keywords.size]
            TaskEntity(
                id = "search_task_$index",
                description = "Task $index with $keyword content",
                isCompleted = false,
                createdAt = System.currentTimeMillis() - (index * 1000)
            )
        }
    }
}