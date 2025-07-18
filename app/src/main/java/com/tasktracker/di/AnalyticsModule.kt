package com.tasktracker.di

import com.tasktracker.data.local.TaskDao
import com.tasktracker.data.local.dao.AnalyticsDao
import com.tasktracker.data.repository.AnalyticsRepositoryImpl
import com.tasktracker.domain.repository.AnalyticsRepository
import dagger.Module
import dagger.Provides
import dagger.hilt.InstallIn
import dagger.hilt.components.SingletonComponent
import javax.inject.Singleton

/**
 * Hilt module for providing analytics-related dependencies.
 */
@Module
@InstallIn(SingletonComponent::class)
object AnalyticsModule {
    
    /**
     * Provides the AnalyticsRepository implementation as a singleton.
     */
    @Provides
    @Singleton
    fun provideAnalyticsRepository(
        analyticsDao: AnalyticsDao,
        taskDao: TaskDao
    ): AnalyticsRepository {
        return AnalyticsRepositoryImpl(analyticsDao, taskDao)
    }
}