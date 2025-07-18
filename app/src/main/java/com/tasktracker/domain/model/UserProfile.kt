package com.tasktracker.domain.model

import java.time.Duration
import java.time.Instant
import java.time.LocalTime
import java.util.UUID

/**
 * User profile data model for local personalization
 */
data class UserProfile(
    val id: String = UUID.randomUUID().toString(),
    val createdAt: Instant = Instant.now(),
    val lastUpdated: Instant = Instant.now(),
    val preferences: UserPreferences = UserPreferences(),
    val statistics: UserStatistics = UserStatistics(),
    val achievements: List<Achievement> = emptyList(),
    val personalInsights: List<PersonalInsight> = emptyList(),
    val customizations: ProfileCustomizations = ProfileCustomizations()
) {
    /**
     * Update the profile with new statistics
     */
    fun updateStatistics(newStats: UserStatistics): UserProfile {
        return copy(
            statistics = newStats,
            lastUpdated = Instant.now()
        )
    }
    
    /**
     * Add a new achievement to the profile
     */
    fun addAchievement(achievement: Achievement): UserProfile {
        return copy(
            achievements = achievements + achievement,
            lastUpdated = Instant.now()
        )
    }
    
    /**
     * Update user preferences
     */
    fun updatePreferences(newPreferences: UserPreferences): UserProfile {
        return copy(
            preferences = newPreferences,
            lastUpdated = Instant.now()
        )
    }
    
    /**
     * Get the user's productivity level based on statistics
     */
    fun getProductivityLevel(): ProductivityLevel {
        val completionRate = statistics.averageCompletionRate
        val consistency = statistics.consistencyScore
        
        return when {
            completionRate >= 0.9f && consistency >= 0.8f -> ProductivityLevel.EXPERT
            completionRate >= 0.7f && consistency >= 0.6f -> ProductivityLevel.ADVANCED
            completionRate >= 0.5f && consistency >= 0.4f -> ProductivityLevel.INTERMEDIATE
            else -> ProductivityLevel.BEGINNER
        }
    }
}

/**
 * User preferences for app customization
 */
data class UserPreferences(
    val preferredFocusMode: FocusMode = FocusMode.LIGHT_FOCUS,
    val defaultReminderTime: Duration = Duration.ofHours(1),
    val themePreference: ThemePreference = ThemePreference.SYSTEM,
    val notificationSettings: NotificationSettings = NotificationSettings(),
    val glassmorphismIntensity: Float = 0.15f,
    val enableHapticFeedback: Boolean = true,
    val enableSoundEffects: Boolean = false,
    val autoStartFocus: Boolean = false,
    val preferredWorkingHours: WorkingHours = WorkingHours(),
    val taskSortPreference: TaskSortPreference = TaskSortPreference.CREATED_DATE,
    val showCompletedTasks: Boolean = true,
    val enableSmartSuggestions: Boolean = true,
    val dataRetentionDays: Int = 365
) {
    /**
     * Check if current time is within preferred working hours
     */
    fun isWithinWorkingHours(): Boolean {
        val now = LocalTime.now()
        return now.isAfter(preferredWorkingHours.startTime) && 
               now.isBefore(preferredWorkingHours.endTime)
    }
}

/**
 * User statistics for analytics and insights
 */
data class UserStatistics(
    val totalTasksCreated: Int = 0,
    val totalTasksCompleted: Int = 0,
    val totalFocusTime: Duration = Duration.ZERO,
    val averageDailyTasks: Float = 0f,
    val averageCompletionRate: Float = 0f,
    val longestStreak: Int = 0,
    val currentStreak: Int = 0,
    val mostProductiveHour: Int? = null,
    val favoriteTaskCategories: List<String> = emptyList(),
    val totalAppUsageTime: Duration = Duration.ZERO,
    val averageTaskCompletionTime: Duration = Duration.ZERO,
    val consistencyScore: Float = 0f, // 0.0 to 1.0
    val procrastinationScore: Float = 0f, // 0.0 to 1.0 (lower is better)
    val weeklyProductivityTrend: List<Float> = emptyList(), // Last 4 weeks
    val monthlyGoalAchievementRate: Float = 0f
) {
    /**
     * Calculate overall productivity score
     */
    fun getOverallProductivityScore(): Float {
        val completionWeight = 0.3f
        val consistencyWeight = 0.25f
        val streakWeight = 0.2f
        val focusWeight = 0.15f
        val procrastinationPenalty = 0.1f
        
        val completionScore = averageCompletionRate
        val streakScore = minOf(currentStreak / 30f, 1f) // Max score at 30-day streak
        val focusScore = minOf(totalFocusTime.toHours() / 100f, 1f) // Max score at 100 hours
        val procrastinationPenalty = procrastinationScore * procrastinationPenalty
        
        return (completionScore * completionWeight +
                consistencyScore * consistencyWeight +
                streakScore * streakWeight +
                focusScore * focusWeight -
                procrastinationPenalty).coerceIn(0f, 1f)
    }
    
    /**
     * Get productivity trend direction
     */
    fun getProductivityTrend(): TrendDirection {
        if (weeklyProductivityTrend.size < 2) return TrendDirection.STABLE
        
        val recent = weeklyProductivityTrend.takeLast(2)
        val change = recent[1] - recent[0]
        
        return when {
            change > 0.1f -> TrendDirection.UP
            change < -0.1f -> TrendDirection.DOWN
            else -> TrendDirection.STABLE
        }
    }
}

/**
 * Personal insights generated from user behavior
 */
data class PersonalInsight(
    val id: String = UUID.randomUUID().toString(),
    val type: PersonalInsightType,
    val title: String,
    val description: String,
    val recommendation: String,
    val confidence: Float, // 0.0 to 1.0
    val createdAt: Instant = Instant.now(),
    val isRead: Boolean = false,
    val isActionable: Boolean = true,
    val category: InsightCategory = InsightCategory.PRODUCTIVITY
)

/**
 * Types of personal insights
 */
enum class PersonalInsightType {
    PEAK_PERFORMANCE_TIME,
    TASK_COMPLETION_PATTERN,
    FOCUS_OPTIMIZATION,
    BREAK_RECOMMENDATION,
    GOAL_ADJUSTMENT,
    HABIT_FORMATION,
    PROCRASTINATION_TRIGGER,
    MOTIVATION_BOOST,
    WORKLOAD_BALANCE,
    SKILL_DEVELOPMENT
}

/**
 * Insight categories for organization
 */
enum class InsightCategory {
    PRODUCTIVITY,
    WELLNESS,
    HABITS,
    GOALS,
    PERFORMANCE,
    MOTIVATION
}

/**
 * Profile customizations for UI personalization
 */
data class ProfileCustomizations(
    val avatarEmoji: String = "😊",
    val preferredColors: List<String> = listOf("#2196F3", "#4CAF50", "#FF9800"),
    val customQuotes: List<String> = emptyList(),
    val dashboardLayout: DashboardLayout = DashboardLayout.DEFAULT,
    val enableAnimations: Boolean = true,
    val compactMode: Boolean = false,
    val showMotivationalMessages: Boolean = true,
    val customBackgroundGradient: List<String>? = null
)

/**
 * Theme preferences
 */
enum class ThemePreference {
    LIGHT,
    DARK,
    SYSTEM
}

/**
 * Notification settings
 */
data class NotificationSettings(
    val enableTaskReminders: Boolean = true,
    val enableFocusNotifications: Boolean = true,
    val enableAchievementNotifications: Boolean = true,
    val enableInsightNotifications: Boolean = true,
    val quietHoursStart: LocalTime = LocalTime.of(22, 0),
    val quietHoursEnd: LocalTime = LocalTime.of(8, 0),
    val reminderFrequency: ReminderFrequency = ReminderFrequency.SMART,
    val notificationSound: NotificationSound = NotificationSound.DEFAULT
)

/**
 * Working hours preference
 */
data class WorkingHours(
    val startTime: LocalTime = LocalTime.of(9, 0),
    val endTime: LocalTime = LocalTime.of(17, 0),
    val workDays: Set<java.time.DayOfWeek> = setOf(
        java.time.DayOfWeek.MONDAY,
        java.time.DayOfWeek.TUESDAY,
        java.time.DayOfWeek.WEDNESDAY,
        java.time.DayOfWeek.THURSDAY,
        java.time.DayOfWeek.FRIDAY
    ),
    val timeZone: String = "UTC"
)

/**
 * Task sorting preferences
 */
enum class TaskSortPreference {
    CREATED_DATE,
    DUE_DATE,
    PRIORITY,
    ALPHABETICAL,
    COMPLETION_STATUS,
    CUSTOM
}

/**
 * Reminder frequency options
 */
enum class ReminderFrequency {
    NEVER,
    ONCE,
    SMART, // AI-determined optimal frequency
    EVERY_HOUR,
    EVERY_DAY,
    CUSTOM
}

/**
 * Notification sound options
 */
enum class NotificationSound {
    DEFAULT,
    GENTLE,
    CHIME,
    NONE,
    CUSTOM
}

/**
 * Dashboard layout options
 */
enum class DashboardLayout {
    DEFAULT,
    COMPACT,
    DETAILED,
    MINIMAL,
    CUSTOM
}

/**
 * Productivity levels for gamification
 */
enum class ProductivityLevel(
    val displayName: String,
    val description: String,
    val color: String,
    val requiredScore: Float
) {
    BEGINNER(
        displayName = "Getting Started",
        description = "Building productivity habits",
        color = "#9E9E9E",
        requiredScore = 0f
    ),
    INTERMEDIATE(
        displayName = "Making Progress",
        description = "Developing consistent patterns",
        color = "#2196F3",
        requiredScore = 0.3f
    ),
    ADVANCED(
        displayName = "Highly Productive",
        description = "Excellent task management",
        color = "#4CAF50",
        requiredScore = 0.6f
    ),
    EXPERT(
        displayName = "Productivity Master",
        description = "Peak performance achieved",
        color = "#FF9800",
        requiredScore = 0.8f
    );
    
    /**
     * Get the next level
     */
    fun getNextLevel(): ProductivityLevel? {
        val values = values()
        val currentIndex = values.indexOf(this)
        return if (currentIndex < values.size - 1) {
            values[currentIndex + 1]
        } else null
    }
    
    /**
     * Calculate progress to next level
     */
    fun getProgressToNext(currentScore: Float): Float {
        val nextLevel = getNextLevel() ?: return 1f
        val currentLevelScore = requiredScore
        val nextLevelScore = nextLevel.requiredScore
        
        return ((currentScore - currentLevelScore) / (nextLevelScore - currentLevelScore))
            .coerceIn(0f, 1f)
    }
}

/**
 * User goals and targets
 */
data class UserGoals(
    val dailyTaskTarget: Int = 5,
    val weeklyFocusTimeTarget: Duration = Duration.ofHours(10),
    val monthlyCompletionRateTarget: Float = 0.8f,
    val streakTarget: Int = 30,
    val customGoals: List<CustomGoal> = emptyList()
)

/**
 * Custom user-defined goals
 */
data class CustomGoal(
    val id: String = UUID.randomUUID().toString(),
    val title: String,
    val description: String,
    val targetValue: Float,
    val currentValue: Float = 0f,
    val unit: String,
    val deadline: Instant? = null,
    val isCompleted: Boolean = false,
    val createdAt: Instant = Instant.now()
) {
    /**
     * Calculate progress percentage
     */
    fun getProgress(): Float {
        return if (targetValue > 0) {
            (currentValue / targetValue).coerceIn(0f, 1f)
        } else 0f
    }
    
    /**
     * Check if goal is overdue
     */
    fun isOverdue(): Boolean {
        return deadline?.isBefore(Instant.now()) == true && !isCompleted
    }
}