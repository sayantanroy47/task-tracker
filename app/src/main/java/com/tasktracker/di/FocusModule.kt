package com.tasktracker.di

import com.tasktracker.data.local.dao.AnalyticsDao
import com.tasktracker.data.repository.FocusRepositoryImpl
import com.tasktracker.domain.repository.FocusRepository
import dagger.Module
import dagger.Provides
import dagger.hilt.InstallIn
import dagger.hilt.components.SingletonComponent
import javax.inject.Singleton

/**
 * Hilt module for providing focus-related dependencies.
 */
@Module
@InstallIn(SingletonComponent::class)
object FocusModule {
    
    /**
     * Provides the FocusRepository implementation as a singleton.
     */
    @Provides
    @Singleton
    fun provideFocusRepository(
        analyticsDao: AnalyticsDao
    ): FocusRepository {
        return FocusRepositoryImpl(analyticsDao)
    }
}