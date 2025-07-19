package com.tasktracker.di

import com.tasktracker.data.repository.ProfileRepositoryImpl
import com.tasktracker.data.repository.TaskRepositoryImpl
import com.tasktracker.domain.repository.ProfileRepository
import com.tasktracker.domain.repository.TaskRepository
import dagger.Binds
import dagger.Module
import dagger.hilt.InstallIn
import dagger.hilt.components.SingletonComponent
import javax.inject.Singleton

/**
 * Hilt module for providing repository dependencies.
 */
@Module
@InstallIn(SingletonComponent::class)
abstract class RepositoryModule {
    
    /**
     * Binds the TaskRepositoryImpl to the TaskRepository interface.
     */
    @Binds
    @Singleton
    abstract fun bindTaskRepository(
        taskRepositoryImpl: TaskRepositoryImpl
    ): TaskRepository
    
    /**
     * Binds the ProfileRepositoryImpl to the ProfileRepository interface.
     */
    @Binds
    @Singleton
    abstract fun bindProfileRepository(
        profileRepositoryImpl: ProfileRepositoryImpl
    ): ProfileRepository
}