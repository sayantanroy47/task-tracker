package com.tasktracker.data.local.entity

import androidx.room.Entity
import androidx.room.PrimaryKey

/**
 * Entity for storing user profile data
 */
@Entity(tableName = "user_profile")
data class UserProfileEntity(
    @PrimaryKey
    val id: String,
    val createdAt: Long,
    val lastUpdated: Long,
    val preferencesJson: String, // JSON serialized UserPreferences
    val statisticsJson: String,  // JSON serialized UserStatistics
    val customizationsJson: String, // JSON serialized ProfileCustomizations
    val goalsJson: String? = null // JSON serialized UserGoals
)

/**
 * Entity for storing personal insights
 */
@Entity(tableName = "personal_insights")
data class PersonalInsightEntity(
    @PrimaryKey
    val id: String,
    val type: String, // PersonalInsightType as string
    val title: String,
    val description: String,
    val recommendation: String,
    val confidence: Float,
    val createdAt: Long,
    val isRead: Boolean = false,
    val isActionable: Boolean = true,
    val category: String // InsightCategory as string
)

/**
 * Entity for storing custom goals
 */
@Entity(tableName = "custom_goals")
data class CustomGoalEntity(
    @PrimaryKey
    val id: String,
    val title: String,
    val description: String,
    val targetValue: Float,
    val currentValue: Float,
    val unit: String,
    val deadline: Long?, // Nullable timestamp
    val isCompleted: Boolean = false,
    val createdAt: Long
)

/**
 * Entity for storing user behavior patterns
 */
@Entity(tableName = "user_behavior")
data class UserBehaviorEntity(
    @PrimaryKey(autoGenerate = true)
    val id: Long = 0,
    val action: String,
    val contextJson: String, // JSON serialized context map
    val timestamp: Long,
    val sessionId: String? = null
)

/**
 * Entity for storing feature usage statistics
 */
@Entity(tableName = "feature_usage")
data class FeatureUsageEntity(
    @PrimaryKey
    val featureName: String,
    val usageCount: Int,
    val totalTimeSpent: Long, // in milliseconds
    val lastUsed: Long,
    val averageSessionDuration: Long
)

/**
 * Entity for storing app usage sessions
 */
@Entity(tableName = "app_usage_sessions")
data class AppUsageSessionEntity(
    @PrimaryKey
    val sessionId: String,
    val startTime: Long,
    val endTime: Long?,
    val duration: Long, // in milliseconds
    val featuresUsed: String, // JSON array of feature names
    val tasksCreated: Int = 0,
    val tasksCompleted: Int = 0,
    val focusSessionsStarted: Int = 0
)

/**
 * Entity for storing learning model data
 */
@Entity(tableName = "learning_model")
data class LearningModelEntity(
    @PrimaryKey
    val modelType: String, // e.g., "task_completion_predictor", "optimal_focus_time"
    val modelData: String, // JSON serialized model parameters
    val accuracy: Float,
    val lastTrained: Long,
    val trainingDataSize: Int,
    val version: Int = 1
)

/**
 * Entity for storing adaptive recommendations
 */
@Entity(tableName = "adaptive_recommendations")
data class AdaptiveRecommendationEntity(
    @PrimaryKey
    val id: String,
    val type: String, // Type of recommendation
    val title: String,
    val description: String,
    val actionData: String, // JSON serialized action parameters
    val confidence: Float,
    val createdAt: Long,
    val expiresAt: Long?,
    val isApplied: Boolean = false,
    val userFeedback: String? = null // "accepted", "rejected", "ignored"
)

/**
 * Entity for storing profile backup metadata
 */
@Entity(tableName = "profile_backups")
data class ProfileBackupEntity(
    @PrimaryKey
    val backupId: String,
    val backupType: String, // "manual", "automatic", "export"
    val createdAt: Long,
    val dataSize: Long, // Size in bytes
    val checksum: String, // For integrity verification
    val metadata: String, // JSON with backup details
    val isEncrypted: Boolean = false
)

/**
 * Entity for storing profile health checks
 */
@Entity(tableName = "profile_health_checks")
data class ProfileHealthCheckEntity(
    @PrimaryKey
    val checkId: String,
    val checkTime: Long,
    val isHealthy: Boolean,
    val issuesJson: String, // JSON serialized list of issues
    val recommendationsJson: String, // JSON serialized recommendations
    val autoFixesApplied: Int = 0
)

/**
 * Entity for storing user preferences history
 */
@Entity(tableName = "preferences_history")
data class PreferencesHistoryEntity(
    @PrimaryKey(autoGenerate = true)
    val id: Long = 0,
    val preferencesJson: String,
    val changedFields: String, // JSON array of changed field names
    val changeReason: String, // "user_action", "auto_optimization", "reset"
    val timestamp: Long
)

/**
 * Entity for storing profile productivity patterns
 */
@Entity(tableName = "profile_productivity_patterns")
data class ProfileProductivityPatternEntity(
    @PrimaryKey
    val patternId: String,
    val patternType: String, // "daily", "weekly", "monthly", "seasonal"
    val patternData: String, // JSON serialized pattern data
    val confidence: Float,
    val detectedAt: Long,
    val lastValidated: Long,
    val isActive: Boolean = true
)