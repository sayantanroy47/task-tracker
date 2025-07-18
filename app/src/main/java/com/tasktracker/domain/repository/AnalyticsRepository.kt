package com.tasktracker.domain.repository

import com.tasktracker.domain.model.Achievement
import com.tasktracker.domain.model.CategoryStats
import com.tasktracker.domain.model.DailyStats
import com.tasktracker.domain.model.FocusSessionStats
import com.tasktracker.domain.model.MoodCorrelation
import com.tasktracker.domain.model.ProductivityInsight
import com.tasktracker.domain.model.ProductivityMetrics
import com.tasktracker.domain.model.ProductivityPattern
import com.tasktracker.domain.model.WeeklyStats
import kotlinx.coroutines.flow.Flow
import java.time.LocalDate

/**
 * Repository interface for analytics operations
 */
interface AnalyticsRepository {
    
    // Productivity Metrics
    suspend fun getProductivityMetrics(): ProductivityMetrics
    suspend fun getDailyStats(date: LocalDate): DailyStats?
    suspend fun getWeeklyStats(weekStart: LocalDate): WeeklyStats
    suspend fun getDailyStatsRange(startDate: LocalDate, endDate: LocalDate): List<DailyStats>
    suspend fun getWeeklyStatsRange(startDate: LocalDate, endDate: LocalDate): List<WeeklyStats>
    
    // Real-time Analytics Flow
    fun getProductivityMetricsFlow(): Flow<ProductivityMetrics>
    fun getDailyStatsFlow(): Flow<List<DailyStats>>
    
    // Task Completion Analytics
    suspend fun recordTaskCompletion(taskId: String, completionTime: Long, category: String?)
    suspend fun recordTaskCreation(taskId: String, creationTime: Long, category: String?)
    suspend fun updateDailyStats(date: LocalDate)
    
    // Insights and Patterns
    suspend fun generateInsights(): List<ProductivityInsight>
    suspend fun getUnreadInsights(): List<ProductivityInsight>
    suspend fun markInsightAsRead(insightId: String)
    suspend fun getProductivityPatterns(): List<ProductivityPattern>
    suspend fun updateProductivityPatterns()
    
    // Achievements
    suspend fun getAllAchievements(): List<Achievement>
    suspend fun getUnlockedAchievements(): List<Achievement>
    suspend fun checkAndUnlockAchievements(): List<Achievement>
    suspend fun updateAchievementProgress(achievementId: String, progress: Float)
    
    // Focus Session Analytics
    suspend fun recordFocusSessionStart(sessionId: String, mode: String, plannedDuration: Int)
    suspend fun recordFocusSessionEnd(sessionId: String, actualDuration: Int, tasksCompleted: Int, distractionCount: Int)
    suspend fun getFocusSessionStats(): FocusSessionStats
    suspend fun getFocusSessionsInRange(startDate: LocalDate, endDate: LocalDate): List<com.tasktracker.domain.model.FocusSession>
    
    // Category Analytics
    suspend fun getCategoryStats(): List<CategoryStats>
    suspend fun updateCategoryStats(category: String, taskCompleted: Boolean, completionTime: Long)
    
    // Streak Management
    suspend fun getCurrentStreak(): Int
    suspend fun getLongestStreak(): Int
    suspend fun updateStreak(hasCompletedTaskToday: Boolean)
    fun getStreakFlow(): Flow<Pair<Int, Int>> // Current, Longest
    
    // Mood and Energy Correlation
    suspend fun recordMoodData(date: LocalDate, energyLevel: Int, moodRating: Int, notes: String?)
    suspend fun getMoodCorrelations(startDate: LocalDate, endDate: LocalDate): List<MoodCorrelation>
    suspend fun analyzeMoodProductivityCorrelation(): Map<String, Float>
    
    // Data Management
    suspend fun cleanupOldData(retentionDays: Int)
    suspend fun exportAnalyticsData(): String // JSON export
    suspend fun importAnalyticsData(jsonData: String): Boolean
    suspend fun resetAllAnalytics()
    
    // Performance Optimization
    suspend fun precomputeAnalytics()
    suspend fun refreshAnalyticsCache()
}