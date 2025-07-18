package com.tasktracker.data.local

import androidx.room.Database
import androidx.room.Room
import androidx.room.RoomDatabase
import androidx.room.TypeConverters
import android.content.Context
import com.tasktracker.data.local.entity.TaskEntity

/**
 * Room database for the Task Tracker application.
 * Provides local storage for tasks with offline-first functionality.
 */
@Database(
    entities = [TaskEntity::class],
    version = 1,
    exportSchema = false
)
@TypeConverters(Converters::class)
abstract class TaskDatabase : RoomDatabase() {
    
    abstract fun taskDao(): TaskDao
    
    companion object {
        @Volatile
        private var INSTANCE: TaskDatabase? = null
        
        private const val DATABASE_NAME = "task_tracker_database"
        
        fun getDatabase(context: Context): TaskDatabase {
            return INSTANCE ?: synchronized(this) {
                val instance = Room.databaseBuilder(
                    context.applicationContext,
                    TaskDatabase::class.java,
                    DATABASE_NAME
                )
                .fallbackToDestructiveMigration() // For development - remove in production
                // Performance optimizations
                .setQueryCallback(
                    { sqlQuery, bindArgs ->
                        android.util.Log.d("RoomQuery", "SQL Query: $sqlQuery")
                    },
                    java.util.concurrent.Executors.newSingleThreadExecutor()
                )
                .setJournalMode(RoomDatabase.JournalMode.WRITE_AHEAD_LOGGING) // Better concurrency
                .enableMultiInstanceInvalidation() // For multi-process apps
                .build()
                INSTANCE = instance
                instance
            }
        }
    }
}

/**
 * Type converters for Room database.
 * Currently not needed but prepared for future complex types.
 */
class Converters {
    // Add type converters here if needed for complex data types
}