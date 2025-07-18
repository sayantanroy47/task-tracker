package com.tasktracker.di

import android.content.Context
import com.tasktracker.data.local.TaskDao
import com.tasktracker.data.local.TaskDatabase
import com.tasktracker.data.local.dao.AnalyticsDao
import dagger.Module
import dagger.Provides
import dagger.hilt.InstallIn
import dagger.hilt.android.qualifiers.ApplicationContext
import dagger.hilt.components.SingletonComponent
import javax.inject.Singleton

/**
 * Hilt module for providing database-related dependencies.
 */
@Module
@InstallIn(SingletonComponent::class)
object DatabaseModule {
    
    /**
     * Provides the TaskDatabase instance as a singleton.
     */
    @Provides
    @Singleton
    fun provideTaskDatabase(@ApplicationContext context: Context): TaskDatabase {
        return TaskDatabase.getDatabase(context)
    }
    
    /**
     * Provides the TaskDao from the database.
     */
    @Provides
    fun provideTaskDao(database: TaskDatabase): TaskDao {
        return database.taskDao()
    }
    
    /**
     * Provides the AnalyticsDao from the database.
     */
    @Provides
    fun provideAnalyticsDao(database: TaskDatabase): AnalyticsDao {
        return database.analyticsDao()
    }
}