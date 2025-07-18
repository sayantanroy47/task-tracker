package com.tasktracker.data.local

import androidx.room.Database
import androidx.room.Room
import androidx.room.RoomDatabase
import android.content.Context
import com.tasktracker.data.local.entity.TaskEntity
import com.tasktracker.data.local.entity.DailyAnalyticsEntity
import com.tasktracker.data.local.entity.ProductivityInsightEntity
import com.tasktracker.data.local.entity.AchievementEntity
import com.tasktracker.data.local.entity.FocusSessionEntity
import com.tasktracker.data.local.entity.CategoryAnalyticsEntity
import com.tasktracker.data.local.entity.ProductivityPatternEntity
import com.tasktracker.data.local.entity.MoodCorrelationEntity
import com.tasktracker.data.local.entity.StreakDataEntity
import com.tasktracker.data.local.entity.ProfileProductivityPatternEntity
import com.tasktracker.data.local.entity.UserProfileEntity
import com.tasktracker.data.local.dao.AnalyticsDao
import com.tasktracker.data.local.dao.ProfileDao
import com.tasktracker.data.local.dao.TaskDao

/**
 * Room database for the Task Tracker application.
 * Provides local storage for tasks with offline-first functionality.
 */
@Database(
    entities = [
        TaskEntity::class,
        DailyAnalyticsEntity::class,
        ProductivityInsightEntity::class,
        AchievementEntity::class,
        FocusSessionEntity::class,
        CategoryAnalyticsEntity::class,
        ProductivityPatternEntity::class,
        MoodCorrelationEntity::class,
        StreakDataEntity::class,
        ProfileProductivityPatternEntity::class,
        UserProfileEntity::class
    ],
    version = 3,
    exportSchema = false
)
abstract class TaskDatabase : RoomDatabase() {
    
    abstract fun taskDao(): TaskDao
    abstract fun analyticsDao(): AnalyticsDao
    abstract fun profileDao(): ProfileDao
    
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

