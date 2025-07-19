package com.tasktracker

import com.tasktracker.data.local.entity.TaskEntityTest
import com.tasktracker.data.repository.TaskRepositoryImplTest
import com.tasktracker.domain.model.TaskTest
import com.tasktracker.presentation.components.TaskInputComponentTest
import com.tasktracker.presentation.viewmodel.TaskViewModelTest
import com.tasktracker.util.PerformanceMonitorTest
import org.junit.runner.RunWith
import org.junit.runners.Suite

/**
 * Test suite for all unit tests
 */
@RunWith(Suite::class)
@Suite.SuiteClasses(
    // Domain Model Tests
    TaskTest::class,
    
    // Data Layer Tests
    TaskEntityTest::class,
    TaskRepositoryImplTest::class,
    
    // Presentation Layer Tests
    TaskViewModelTest::class,
    TaskInputComponentTest::class,
    
    // Utility Tests
    PerformanceMonitorTest::class
)
class UnitTestSuite