package com.tasktracker.domain.model

import java.time.Duration
import java.time.Instant
import java.time.LocalDate

/**
 * Comprehensive productivity metrics for analytics
 */
data class ProductivityMetrics(
    val tasksCompletedToday: Int,
    val tasksCreatedToday: Int,
    val completionRate: Float,
    val averageCompletionTime: Duration,
    val peakProductivityHours: List<Int>,
    val weeklyTrend: List<DailyStats>,
    val monthlyTrend: List<WeeklyStats>,
    val currentStreak: Int,
    val longestStreak: Int,
    val totalTasksCompleted: Int,
    val totalFocusTime: Duration,
    val averageDailyTasks: Float,
    val mostProductiveDay: LocalDate?,
    val insights: List<ProductivityInsight>
)

/**
 * Daily statistics for trend analysis
 */
data class DailyStats(
    val date: LocalDate,
    val tasksCompleted: Int,
    val tasksCreated: Int,
    val focusTimeMinutes: Int,
    val completionRate: Float,
    val averageTaskDuration: Duration,
    val peakHour: Int?
)

/**
 * Weekly statistics for longer-term trends
 */
data class WeeklyStats(
    val weekStart: LocalDate,
    val totalTasksCompleted: Int,
    val totalTasksCreated: Int,
    val totalFocusTime: Duration,
    val averageCompletionRate: Float,
    val mostProductiveDay: LocalDate?,
    val dailyStats: List<DailyStats>
)

/**
 * AI-generated insights about productivity patterns
 */
data class ProductivityInsight(
    val id: String,
    val type: InsightType,
    val title: String,
    val description: String,
    val actionSuggestion: String?,
    val confidence: Float, // 0.0 to 1.0
    val createdAt: Instant,
    val isRead: Boolean = false
)

/**
 * Types of productivity insights
 */
enum class InsightType {
    PEAK_HOURS,
    COMPLETION_PATTERN,
    STREAK_OPPORTUNITY,
    FOCUS_IMPROVEMENT,
    TASK_BREAKDOWN,
    PRODUCTIVITY_DECLINE,
    ACHIEVEMENT_CELEBRATION,
    HABIT_FORMATION
}

/**
 * Achievement system for gamification
 */
data class Achievement(
    val id: String,
    val title: String,
    val description: String,
    val iconName: String,
    val category: AchievementCategory,
    val requirement: AchievementRequirement,
    val unlockedAt: Instant?,
    val progress: Float = 0f, // 0.0 to 1.0
    val isUnlocked: Boolean = false
)

/**
 * Categories for achievements
 */
enum class AchievementCategory {
    STREAK,
    COMPLETION,
    FOCUS,
    CONSISTENCY,
    MILESTONE,
    SPECIAL
}

/**
 * Requirements for unlocking achievements
 */
sealed class AchievementRequirement {
    data class TaskCount(val count: Int) : AchievementRequirement()
    data class StreakDays(val days: Int) : AchievementRequirement()
    data class FocusTime(val minutes: Int) : AchievementRequirement()
    data class CompletionRate(val rate: Float) : AchievementRequirement()
    data class ConsecutiveDays(val days: Int) : AchievementRequirement()
    object FirstTask : AchievementRequirement()
    object PerfectWeek : AchievementRequirement()
}

/**
 * Focus session analytics
 */
data class FocusSessionStats(
    val totalSessions: Int,
    val totalFocusTime: Duration,
    val averageSessionLength: Duration,
    val completionRate: Float,
    val mostUsedMode: FocusMode?,
    val peakFocusHours: List<Int>,
    val weeklyFocusTime: List<Duration>,
    val distractionCount: Int,
    val focusScore: Float // Overall focus quality score
)

/**
 * Task category analytics
 */
data class CategoryStats(
    val category: String,
    val taskCount: Int,
    val completionRate: Float,
    val averageCompletionTime: Duration,
    val trend: TrendDirection
)

/**
 * Trend direction for analytics
 */
enum class TrendDirection {
    UP,
    DOWN,
    STABLE
}

/**
 * Time-based productivity patterns
 */
data class ProductivityPattern(
    val hourOfDay: Int,
    val dayOfWeek: Int,
    val completionRate: Float,
    val averageTasksCompleted: Float,
    val focusQuality: Float
)

/**
 * Mood and energy correlation data
 */
data class MoodCorrelation(
    val date: LocalDate,
    val energyLevel: Int, // 1-5 scale
    val moodRating: Int, // 1-5 scale
    val tasksCompleted: Int,
    val focusTime: Duration,
    val notes: String?
)