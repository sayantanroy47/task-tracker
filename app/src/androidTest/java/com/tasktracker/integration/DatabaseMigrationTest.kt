package com.tasktracker.integration

import androidx.room.Room
import androidx.room.testing.MigrationTestHelper
import androidx.sqlite.db.framework.FrameworkSQLiteOpenHelperFactory
import androidx.test.core.app.ApplicationProvider
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import com.tasktracker.data.local.TaskDatabase
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith
import java.io.IOException

/**
 * Integration tests for database migrations
 */
@RunWith(AndroidJUnit4::class)
class DatabaseMigrationTest {

    private val TEST_DB = "migration-test"

    @get:Rule
    val helper: MigrationTestHelper = MigrationTestHelper(
        InstrumentationRegistry.getInstrumentation(),
        TaskDatabase::class.java.canonicalName,
        FrameworkSQLiteOpenHelperFactory()
    )

    @Test
    @Throws(IOException::class)
    fun migrateAll() {
        // Create earliest version of the database
        helper.createDatabase(TEST_DB, 1).apply {
            close()
        }

        // Open latest version of the database. Room will validate the schema
        // once all migrations execute.
        Room.databaseBuilder(
            InstrumentationRegistry.getInstrumentation().targetContext,
            TaskDatabase::class.java,
            TEST_DB
        ).build().apply {
            openHelper.writableDatabase
            close()
        }
    }

    @Test
    @Throws(IOException::class)
    fun testDatabaseCreation() {
        // Create the database with the latest schema
        val db = Room.inMemoryDatabaseBuilder(
            ApplicationProvider.getApplicationContext(),
            TaskDatabase::class.java
        ).build()

        // Verify that the database was created successfully
        val taskDao = db.taskDao()
        val profileDao = db.profileDao()
        val analyticsDao = db.analyticsDao()

        // Test basic operations to ensure tables exist
        val tasks = taskDao.getAllTasks()
        val profile = profileDao.getCurrentProfile()
        
        // Clean up
        db.close()
    }

    @Test
    fun testDatabaseIntegrity() {
        val db = Room.inMemoryDatabaseBuilder(
            ApplicationProvider.getApplicationContext(),
            TaskDatabase::class.java
        ).build()

        // Test that all DAOs are accessible and functional
        val taskDao = db.taskDao()
        val profileDao = db.profileDao()
        val analyticsDao = db.analyticsDao()

        // Verify DAOs are not null
        assert(taskDao != null)
        assert(profileDao != null)
        assert(analyticsDao != null)

        db.close()
    }
}