package com.tasktracker.data.local.dao

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import androidx.room.Update
import com.tasktracker.data.local.entity.UserProfileEntity
import kotlinx.coroutines.flow.Flow

/**
 * DAO for profile-related database operations
 * Simplified to include only essential profile operations
 */
@Dao
interface ProfileDao {
    
    // User Profile Operations
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertProfile(profile: UserProfileEntity)
    
    @Update
    suspend fun updateProfile(profile: UserProfileEntity)
    
    @Query("SELECT * FROM user_profile WHERE id = :profileId")
    suspend fun getProfile(profileId: String): UserProfileEntity?
    
    @Query("SELECT * FROM user_profile LIMIT 1")
    suspend fun getCurrentProfile(): UserProfileEntity?
    
    @Query("SELECT * FROM user_profile LIMIT 1")
    fun getCurrentProfileFlow(): Flow<UserProfileEntity?>
    
    @Query("DELETE FROM user_profile WHERE id = :profileId")
    suspend fun deleteProfile(profileId: String)
    
    @Query("DELETE FROM user_profile")
    suspend fun deleteAllProfiles()
}