package com.tasktracker

import com.tasktracker.data.local.dao.TaskDaoTest
import com.tasktracker.integration.DatabaseMigrationTest
import com.tasktracker.integration.TaskRepositoryIntegrationTest
import org.junit.runner.RunWith
import org.junit.runners.Suite

/**
 * Test suite for all integration tests
 */
@RunWith(Suite::class)
@Suite.SuiteClasses(
    // Database Integration Tests
    TaskDaoTest::class,
    DatabaseMigrationTest::class,
    
    // Repository Integration Tests
    TaskRepositoryIntegrationTest::class
)
class IntegrationTestSuite