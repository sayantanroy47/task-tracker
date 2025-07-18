package com.tasktracker.domain.repository

import com.tasktracker.domain.model.CustomGoal
import com.tasktracker.domain.model.PersonalInsight
import com.tasktracker.domain.model.ProfileCustomizations
import com.tasktracker.domain.model.UserGoals
import com.tasktracker.domain.model.UserPreferences
import com.tasktracker.domain.model.UserProfile
import com.tasktracker.domain.model.UserStatistics
import kotlinx.coroutines.flow.Flow

/**
 * Repository interface for user profile operations
 */
interface ProfileRepository {
    
    // Profile Management
    suspend fun createProfile(): UserProfile
    suspend fun getProfile(): UserProfile?
    suspend fun updateProfile(profile: UserProfile): UserProfile
    suspend fun deleteProfile(): Boolean
    fun getProfileFlow(): Flow<UserProfile?>
    
    // Preferences Management
    suspend fun getPreferences(): UserPreferences
    suspend fun updatePreferences(preferences: UserPreferences)
    suspend fun resetPreferencesToDefault()
    fun getPreferencesFlow(): Flow<UserPreferences>
    
    // Statistics Management
    suspend fun getStatistics(): UserStatistics
    suspend fun updateStatistics(statistics: UserStatistics)
    suspend fun incrementTaskCreated()
    suspend fun incrementTaskCompleted()
    suspend fun addFocusTime(duration: java.time.Duration)
    suspend fun updateStreak(newStreak: Int)
    suspend fun recalculateStatistics()
    fun getStatisticsFlow(): Flow<UserStatistics>
    
    // Personal Insights
    suspend fun generatePersonalInsights(): List<PersonalInsight>
    suspend fun getPersonalInsights(): List<PersonalInsight>
    suspend fun getUnreadInsights(): List<PersonalInsight>
    suspend fun markInsightAsRead(insightId: String)
    suspend fun dismissInsight(insightId: String)
    suspend fun addCustomInsight(insight: PersonalInsight)
    fun getInsightsFlow(): Flow<List<PersonalInsight>>
    
    // Customizations
    suspend fun getCustomizations(): ProfileCustomizations
    suspend fun updateCustomizations(customizations: ProfileCustomizations)
    suspend fun resetCustomizations()
    
    // Goals Management
    suspend fun getUserGoals(): UserGoals
    suspend fun updateUserGoals(goals: UserGoals)
    suspend fun addCustomGoal(goal: CustomGoal): String
    suspend fun updateCustomGoal(goal: CustomGoal)
    suspend fun deleteCustomGoal(goalId: String): Boolean
    suspend fun completeCustomGoal(goalId: String): Boolean
    fun getGoalsFlow(): Flow<UserGoals>
    
    // Usage Analytics
    suspend fun recordAppUsage(sessionDuration: java.time.Duration)
    suspend fun recordFeatureUsage(featureName: String)
    suspend fun getUsagePatterns(): Map<String, Int>
    suspend fun getMostUsedFeatures(): List<Pair<String, Int>>
    
    // Learning and Adaptation
    suspend fun recordUserBehavior(action: String, context: Map<String, Any>)
    suspend fun getAdaptiveRecommendations(): List<String>
    suspend fun updateLearningModel()
    
    // Profile Backup and Sync
    suspend fun exportProfile(): String // JSON export
    suspend fun importProfile(profileData: String): Boolean
    suspend fun backupProfile(): Boolean
    suspend fun restoreProfile(backupData: String): Boolean
    
    // Profile Analytics
    suspend fun getProfileCompleteness(): Float // 0.0 to 1.0
    suspend fun getEngagementScore(): Float
    suspend fun getProductivityTrends(): List<Float>
    suspend fun getPersonalizationLevel(): Float
    
    // Data Management
    suspend fun cleanupOldData(retentionDays: Int)
    suspend fun anonymizeProfile(): Boolean
    suspend fun getDataUsageStats(): Map<String, Long>
    
    // Achievement Integration
    suspend fun checkProfileAchievements(): List<com.tasktracker.domain.model.Achievement>
    suspend fun unlockProfileAchievement(achievementId: String): Boolean
    
    // Smart Suggestions
    suspend fun getSmartPreferenceSuggestions(): Map<String, Any>
    suspend fun getOptimalWorkingHours(): com.tasktracker.domain.model.WorkingHours
    suspend fun suggestFocusMode(): com.tasktracker.domain.model.FocusMode
    suspend fun suggestTaskCategories(): List<String>
    
    // Profile Health
    suspend fun validateProfile(): List<String> // List of validation issues
    suspend fun repairProfile(): Boolean
    suspend fun getProfileHealth(): ProfileHealth
}

/**
 * Profile health status
 */
data class ProfileHealth(
    val isHealthy: Boolean,
    val issues: List<ProfileIssue>,
    val recommendations: List<String>,
    val lastCheckTime: java.time.Instant
)

/**
 * Profile validation issues
 */
data class ProfileIssue(
    val type: ProfileIssueType,
    val description: String,
    val severity: IssueSeverity,
    val autoFixable: Boolean
)

/**
 * Types of profile issues
 */
enum class ProfileIssueType {
    MISSING_DATA,
    INVALID_PREFERENCES,
    CORRUPTED_STATISTICS,
    OUTDATED_INSIGHTS,
    INCONSISTENT_GOALS,
    PERFORMANCE_DEGRADATION
}

/**
 * Issue severity levels
 */
enum class IssueSeverity {
    LOW,
    MEDIUM,
    HIGH,
    CRITICAL
}