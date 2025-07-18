package com.tasktracker.data.local.entity

import androidx.room.Entity
import androidx.room.PrimaryKey
import java.time.LocalDate

/**
 * Entity for storing daily analytics data
 */
@Entity(tableName = "daily_analytics")
data class DailyAnalyticsEntity(
    @PrimaryKey
    val date: String, // LocalDate as ISO string
    val tasksCompleted: Int,
    val tasksCreated: Int,
    val focusTimeMinutes: Int,
    val completionRate: Float,
    val averageTaskDurationMinutes: Long,
    val peakHour: Int?,
    val createdAt: Long,
    val updatedAt: Long
)

/**
 * Entity for storing productivity insights
 */
@Entity(tableName = "productivity_insights")
data class ProductivityInsightEntity(
    @PrimaryKey
    val id: String,
    val type: String, // InsightType as string
    val title: String,
    val description: String,
    val actionSuggestion: String?,
    val confidence: Float,
    val createdAt: Long,
    val isRead: Boolean = false
)

/**
 * Entity for storing achievements
 */
@Entity(tableName = "achievements")
data class AchievementEntity(
    @PrimaryKey
    val id: String,
    val title: String,
    val description: String,
    val iconName: String,
    val category: String, // AchievementCategory as string
    val requirementType: String, // Type of requirement
    val requirementValue: String, // JSON serialized requirement data
    val unlockedAt: Long?,
    val progress: Float = 0f,
    val isUnlocked: Boolean = false
)

/**
 * Entity for storing focus session data
 */
@Entity(tableName = "focus_sessions")
data class FocusSessionEntity(
    @PrimaryKey
    val id: String,
    val startTime: Long,
    val endTime: Long?,
    val plannedDurationMinutes: Int,
    val actualDurationMinutes: Int?,
    val focusMode: String, // FocusMode as string
    val tasksCompleted: Int,
    val distractionCount: Int,
    val focusScore: Float,
    val notes: String?
)

/**
 * Entity for storing task category analytics
 */
@Entity(tableName = "category_analytics")
data class CategoryAnalyticsEntity(
    @PrimaryKey
    val category: String,
    val taskCount: Int,
    val completedCount: Int,
    val totalCompletionTimeMinutes: Long,
    val lastUpdated: Long
)

/**
 * Entity for storing productivity patterns
 */
@Entity(tableName = "productivity_patterns")
data class ProductivityPatternEntity(
    @PrimaryKey
    val id: String, // Composite key: "hour_day" format
    val hourOfDay: Int,
    val dayOfWeek: Int,
    val completionRate: Float,
    val averageTasksCompleted: Float,
    val focusQuality: Float,
    val sampleSize: Int, // Number of data points used
    val lastUpdated: Long
)

/**
 * Entity for storing mood correlation data
 */
@Entity(tableName = "mood_correlations")
data class MoodCorrelationEntity(
    @PrimaryKey
    val date: String, // LocalDate as ISO string
    val energyLevel: Int,
    val moodRating: Int,
    val tasksCompleted: Int,
    val focusTimeMinutes: Int,
    val notes: String?,
    val createdAt: Long
)

/**
 * Entity for storing streak data
 */
@Entity(tableName = "streak_data")
data class StreakDataEntity(
    @PrimaryKey
    val id: String = "current_streak", // Single row table
    val currentStreak: Int,
    val longestStreak: Int,
    val lastCompletionDate: String?, // LocalDate as ISO string
    val streakStartDate: String?, // LocalDate as ISO string
    val updatedAt: Long
)