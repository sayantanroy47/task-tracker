package com.tasktracker.data.local.dao

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import androidx.room.Update
import com.tasktracker.data.local.entity.AdaptiveRecommendationEntity
import com.tasktracker.data.local.entity.AppUsageSessionEntity
import com.tasktracker.data.local.entity.CustomGoalEntity
import com.tasktracker.data.local.entity.FeatureUsageEntity
import com.tasktracker.data.local.entity.LearningModelEntity
import com.tasktracker.data.local.entity.PersonalInsightEntity
import com.tasktracker.data.local.entity.PreferencesHistoryEntity
import com.tasktracker.data.local.entity.ProductivityPatternEntity
import com.tasktracker.data.local.entity.ProfileBackupEntity
import com.tasktracker.data.local.entity.ProfileHealthCheckEntity
import com.tasktracker.data.local.entity.UserBehaviorEntity
import com.tasktracker.data.local.entity.UserProfileEntity
import kotlinx.coroutines.flow.Flow

/**
 * DAO for profile-related database operations
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
    
    // Personal Insights Operations
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertPersonalInsight(insight: PersonalInsightEntity)
    
    @Query("SELECT * FROM personal_insights ORDER BY createdAt DESC")
    suspend fun getAllPersonalInsights(): List<PersonalInsightEntity>
    
    @Query("SELECT * FROM personal_insights WHERE isRead = 0 ORDER BY createdAt DESC")
    suspend fun getUnreadInsights(): List<PersonalInsightEntity>
    
    @Query("SELECT * FROM personal_insights ORDER BY createdAt DESC")
    fun getPersonalInsightsFlow(): Flow<List<PersonalInsightEntity>>
    
    @Query("UPDATE personal_insights SET isRead = 1 WHERE id = :insightId")
    suspend fun markInsightAsRead(insightId: String)
    
    @Query("DELETE FROM personal_insights WHERE id = :insightId")
    suspend fun deleteInsight(insightId: String)
    
    @Query("DELETE FROM personal_insights WHERE createdAt < :cutoffTime")
    suspend fun deleteOldInsights(cutoffTime: Long)
    
    // Custom Goals Operations
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertCustomGoal(goal: CustomGoalEntity)
    
    @Update
    suspend fun updateCustomGoal(goal: CustomGoalEntity)
    
    @Query("SELECT * FROM custom_goals ORDER BY createdAt DESC")
    suspend fun getAllCustomGoals(): List<CustomGoalEntity>
    
    @Query("SELECT * FROM custom_goals WHERE isCompleted = 0 ORDER BY deadline ASC")
    suspend fun getActiveCustomGoals(): List<CustomGoalEntity>
    
    @Query("SELECT * FROM custom_goals ORDER BY createdAt DESC")
    fun getCustomGoalsFlow(): Flow<List<CustomGoalEntity>>
    
    @Query("UPDATE custom_goals SET isCompleted = 1 WHERE id = :goalId")
    suspend fun completeCustomGoal(goalId: String)
    
    @Query("DELETE FROM custom_goals WHERE id = :goalId")
    suspend fun deleteCustomGoal(goalId: String)
    
    // User Behavior Operations
    @Insert
    suspend fun insertUserBehavior(behavior: UserBehaviorEntity)
    
    @Query("SELECT * FROM user_behavior WHERE timestamp >= :startTime ORDER BY timestamp DESC")
    suspend fun getUserBehaviorSince(startTime: Long): List<UserBehaviorEntity>
    
    @Query("SELECT action, COUNT(*) as count FROM user_behavior WHERE timestamp >= :startTime GROUP BY action ORDER BY count DESC")
    suspend fun getBehaviorPatterns(startTime: Long): List<BehaviorPatternResult>
    
    @Query("DELETE FROM user_behavior WHERE timestamp < :cutoffTime")
    suspend fun deleteOldBehaviorData(cutoffTime: Long)
    
    // Feature Usage Operations
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertFeatureUsage(usage: FeatureUsageEntity)
    
    @Query("SELECT * FROM feature_usage ORDER BY usageCount DESC")
    suspend fun getAllFeatureUsage(): List<FeatureUsageEntity>
    
    @Query("SELECT * FROM feature_usage ORDER BY usageCount DESC LIMIT :limit")
    suspend fun getMostUsedFeatures(limit: Int): List<FeatureUsageEntity>
    
    @Query("UPDATE feature_usage SET usageCount = usageCount + 1, lastUsed = :timestamp WHERE featureName = :featureName")
    suspend fun incrementFeatureUsage(featureName: String, timestamp: Long)
    
    // App Usage Sessions Operations
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertAppUsageSession(session: AppUsageSessionEntity)
    
    @Update
    suspend fun updateAppUsageSession(session: AppUsageSessionEntity)
    
    @Query("SELECT * FROM app_usage_sessions WHERE startTime >= :startTime ORDER BY startTime DESC")
    suspend fun getAppUsageSessionsSince(startTime: Long): List<AppUsageSessionEntity>
    
    @Query("SELECT AVG(duration) FROM app_usage_sessions WHERE startTime >= :startTime")
    suspend fun getAverageSessionDuration(startTime: Long): Double?
    
    @Query("SELECT SUM(duration) FROM app_usage_sessions WHERE startTime >= :startTime")
    suspend fun getTotalUsageTime(startTime: Long): Long?
    
    // Learning Model Operations
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertLearningModel(model: LearningModelEntity)
    
    @Query("SELECT * FROM learning_model WHERE modelType = :modelType")
    suspend fun getLearningModel(modelType: String): LearningModelEntity?
    
    @Query("SELECT * FROM learning_model ORDER BY lastTrained DESC")
    suspend fun getAllLearningModels(): List<LearningModelEntity>
    
    // Adaptive Recommendations Operations
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertAdaptiveRecommendation(recommendation: AdaptiveRecommendationEntity)
    
    @Query("SELECT * FROM adaptive_recommendations WHERE expiresAt IS NULL OR expiresAt > :currentTime ORDER BY confidence DESC")
    suspend fun getActiveRecommendations(currentTime: Long): List<AdaptiveRecommendationEntity>
    
    @Query("UPDATE adaptive_recommendations SET isApplied = 1, userFeedback = :feedback WHERE id = :recommendationId")
    suspend fun applyRecommendation(recommendationId: String, feedback: String)
    
    @Query("DELETE FROM adaptive_recommendations WHERE expiresAt IS NOT NULL AND expiresAt <= :currentTime")
    suspend fun deleteExpiredRecommendations(currentTime: Long)
    
    // Profile Backup Operations
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertProfileBackup(backup: ProfileBackupEntity)
    
    @Query("SELECT * FROM profile_backups ORDER BY createdAt DESC")
    suspend fun getAllProfileBackups(): List<ProfileBackupEntity>
    
    @Query("SELECT * FROM profile_backups ORDER BY createdAt DESC LIMIT 1")
    suspend fun getLatestProfileBackup(): ProfileBackupEntity?
    
    @Query("DELETE FROM profile_backups WHERE backupId = :backupId")
    suspend fun deleteProfileBackup(backupId: String)
    
    // Profile Health Operations
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertProfileHealthCheck(healthCheck: ProfileHealthCheckEntity)
    
    @Query("SELECT * FROM profile_health_checks ORDER BY checkTime DESC LIMIT 1")
    suspend fun getLatestHealthCheck(): ProfileHealthCheckEntity?
    
    @Query("SELECT * FROM profile_health_checks ORDER BY checkTime DESC LIMIT :limit")
    suspend fun getRecentHealthChecks(limit: Int): List<ProfileHealthCheckEntity>
    
    // Preferences History Operations
    @Insert
    suspend fun insertPreferencesHistory(history: PreferencesHistoryEntity)
    
    @Query("SELECT * FROM preferences_history ORDER BY timestamp DESC LIMIT :limit")
    suspend fun getPreferencesHistory(limit: Int): List<PreferencesHistoryEntity>
    
    @Query("DELETE FROM preferences_history WHERE timestamp < :cutoffTime")
    suspend fun deleteOldPreferencesHistory(cutoffTime: Long)
    
    // Productivity Patterns Operations
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertProductivityPattern(pattern: ProductivityPatternEntity)
    
    @Query("SELECT * FROM productivity_patterns WHERE isActive = 1 ORDER BY confidence DESC")
    suspend fun getActiveProductivityPatterns(): List<ProductivityPatternEntity>
    
    @Query("SELECT * FROM productivity_patterns WHERE patternType = :type AND isActive = 1 ORDER BY confidence DESC")
    suspend fun getProductivityPatternsByType(type: String): List<ProductivityPatternEntity>
    
    @Query("UPDATE productivity_patterns SET isActive = 0 WHERE patternId = :patternId")
    suspend fun deactivateProductivityPattern(patternId: String)
    
    // Cleanup Operations
    @Query("DELETE FROM user_behavior WHERE timestamp < :cutoffTime")
    suspend fun cleanupOldUserBehavior(cutoffTime: Long)
    
    @Query("DELETE FROM app_usage_sessions WHERE startTime < :cutoffTime")
    suspend fun cleanupOldUsageSessions(cutoffTime: Long)
    
    @Query("DELETE FROM personal_insights WHERE createdAt < :cutoffTime AND isRead = 1")
    suspend fun cleanupOldReadInsights(cutoffTime: Long)
    
    // Analytics Queries
    @Query("""
        SELECT 
            COUNT(*) as totalSessions,
            AVG(duration) as avgDuration,
            SUM(duration) as totalDuration,
            MAX(duration) as maxDuration
        FROM app_usage_sessions 
        WHERE startTime >= :startTime
    """)
    suspend fun getUsageAnalytics(startTime: Long): UsageAnalyticsResult
    
    @Query("""
        SELECT 
            COUNT(DISTINCT DATE(startTime/1000, 'unixepoch')) as activeDays,
            AVG(tasksCompleted) as avgTasksPerSession,
            SUM(tasksCompleted) as totalTasksCompleted
        FROM app_usage_sessions 
        WHERE startTime >= :startTime
    """)
    suspend fun getProductivityAnalytics(startTime: Long): ProductivityAnalyticsResult
}

/**
 * Result class for behavior pattern queries
 */
data class BehaviorPatternResult(
    val action: String,
    val count: Int
)

/**
 * Result class for usage analytics queries
 */
data class UsageAnalyticsResult(
    val totalSessions: Int,
    val avgDuration: Double,
    val totalDuration: Long,
    val maxDuration: Long
)

/**
 * Result class for productivity analytics queries
 */
data class ProductivityAnalyticsResult(
    val activeDays: Int,
    val avgTasksPerSession: Double,
    val totalTasksCompleted: Int
)