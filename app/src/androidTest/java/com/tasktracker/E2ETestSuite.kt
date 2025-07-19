package com.tasktracker

import com.tasktracker.e2e.AnalyticsE2ETest
import com.tasktracker.e2e.FocusModeE2ETest
import com.tasktracker.e2e.TaskManagementE2ETest
import org.junit.runner.RunWith
import org.junit.runners.Suite

/**
 * Test suite for all End-to-End tests
 */
@RunWith(Suite::class)
@Suite.SuiteClasses(
    // Core Feature E2E Tests
    TaskManagementE2ETest::class,
    FocusModeE2ETest::class,
    AnalyticsE2ETest::class
)
class E2ETestSuite