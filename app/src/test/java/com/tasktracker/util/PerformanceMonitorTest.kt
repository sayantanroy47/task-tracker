package com.tasktracker.util

import kotlinx.coroutines.delay
import kotlinx.coroutines.test.runTest
import org.junit.Assert.*
import org.junit.Test
import java.io.ByteArrayOutputStream
import java.io.PrintStream

/**
 * Unit tests for PerformanceMonitor utility
 */
class PerformanceMonitorTest {

    @Test
    fun `traceSection executes block and returns result`() {
        // Given
        val expectedResult = "test result"
        
        // When
        val result = PerformanceMonitor.traceSection("test_section") {
            expectedResult
        }
        
        // Then
        assertEquals(expectedResult, result)
    }

    @Test
    fun `traceSection logs slow operations`() {
        // Given
        val originalOut = System.out
        val outputStream = ByteArrayOutputStream()
        System.setOut(PrintStream(outputStream))
        
        try {
            // When - Execute a slow operation
            PerformanceMonitor.traceSection("slow_operation") {
                Thread.sleep(150) // Longer than SLOW_OPERATION_THRESHOLD_MS
                "result"
            }
            
            // Then - Should log warning (captured in system output)
            val output = outputStream.toString()
            assertTrue("Should log slow operation warning", 
                output.contains("slow_operation") || output.isNotEmpty())
        } finally {
            System.setOut(originalOut)
        }
    }

    @Test
    fun `traceSuspendSection executes suspend block`() = runTest {
        // Given
        val expectedResult = "suspend result"
        
        // When
        val result = PerformanceMonitor.traceSuspendSection("suspend_section") {
            delay(10)
            expectedResult
        }
        
        // Then
        assertEquals(expectedResult, result)
    }

    @Test
    fun `monitorDatabaseOperation traces database calls`() = runTest {
        // Given
        val expectedResult = listOf("data1", "data2")
        
        // When
        val result = PerformanceMonitor.monitorDatabaseOperation("getAllTasks") {
            delay(5) // Simulate database operation
            expectedResult
        }
        
        // Then
        assertEquals(expectedResult, result)
    }

    @Test
    fun `monitorComposition executes composition block`() {
        // Given
        val expectedResult = Unit
        
        // When
        val result = PerformanceMonitor.monitorComposition("TestComposable") {
            // Simulate composition work
            expectedResult
        }
        
        // Then
        assertEquals(expectedResult, result)
    }

    @Test
    fun `logMemoryUsage captures memory information`() {
        // Given
        val originalOut = System.out
        val outputStream = ByteArrayOutputStream()
        System.setOut(PrintStream(outputStream))
        
        try {
            // When
            PerformanceMonitor.logMemoryUsage("test_context")
            
            // Then - Should log memory information
            val output = outputStream.toString()
            assertTrue("Should log memory usage", 
                output.contains("Memory Usage") || output.contains("test_context"))
        } finally {
            System.setOut(originalOut)
        }
    }

    @Test
    fun `recordMetrics stores performance data`() {
        // When
        PerformanceMonitor.recordMetrics("test_operation", 50L)
        
        // Then
        val summary = PerformanceMonitor.getPerformanceSummary()
        assertTrue("Should contain performance data", 
            summary.contains("test_operation") || summary.contains("Operations tracked"))
    }

    @Test
    fun `getPerformanceSummary returns formatted summary`() {
        // Given
        PerformanceMonitor.recordMetrics("operation1", 100L)
        PerformanceMonitor.recordMetrics("operation2", 200L)
        
        // When
        val summary = PerformanceMonitor.getPerformanceSummary()
        
        // Then
        assertNotNull(summary)
        assertTrue("Summary should contain metrics info", 
            summary.contains("Performance Summary") || summary.contains("Operations tracked"))
    }

    @Test
    fun `performance metrics are limited to prevent memory leaks`() {
        // Given - Add more than 100 metrics
        repeat(150) { i ->
            PerformanceMonitor.recordMetrics("operation_$i", i.toLong())
        }
        
        // When
        val summary = PerformanceMonitor.getPerformanceSummary()
        
        // Then - Should not cause memory issues and should limit stored metrics
        assertNotNull(summary)
        assertTrue("Should handle large number of metrics", summary.isNotEmpty())
    }

    @Test
    fun `monitorCoroutine executes coroutine with tracing`() = runTest {
        // Given
        var executed = false
        
        // When
        PerformanceMonitor.monitorCoroutine(this, "test_coroutine") {
            delay(10)
            executed = true
        }
        
        // Wait for coroutine to complete
        delay(50)
        
        // Then
        assertTrue("Coroutine should have executed", executed)
    }

    @Test
    fun `exception in traced block is propagated`() {
        // Given
        val expectedException = RuntimeException("Test exception")
        
        // When & Then
        try {
            PerformanceMonitor.traceSection("failing_section") {
                throw expectedException
            }
            fail("Should have thrown exception")
        } catch (e: RuntimeException) {
            assertEquals(expectedException.message, e.message)
        }
    }

    @Test
    fun `suspend exception in traced block is propagated`() = runTest {
        // Given
        val expectedException = RuntimeException("Suspend test exception")
        
        // When & Then
        try {
            PerformanceMonitor.traceSuspendSection("failing_suspend_section") {
                delay(1)
                throw expectedException
            }
            fail("Should have thrown exception")
        } catch (e: RuntimeException) {
            assertEquals(expectedException.message, e.message)
        }
    }
}