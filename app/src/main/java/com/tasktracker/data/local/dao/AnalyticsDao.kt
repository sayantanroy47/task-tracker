package com.tasktracker.data.local.dao

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import androidx.room.Update
import com.tasktracker.data.local.entity.AchievementEntity
import com.tasktracker.data.local.entity.CategoryAnalyticsEntity
import com.tasktracker.data.local.entity.DailyAnalyticsEntity
import com.tasktracker.data.local.entity.FocusSessionEntity
import com.tasktracker.data.local.entity.MoodCorrelationEntity
import com.tasktracker.data.local.entity.ProductivityInsightEntity
import com.tasktracker.data.local.entity.ProductivityPatternEntity
import com.tasktracker.data.local.entity.StreakDataEntity
import kotlinx.coroutines.flow.Flow

/**
 * DAO for analytics-related database operations
 */
@Dao
interface AnalyticsDao {
    
    // Daily Analytics Operations
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertDailyAnalytics(analytics: DailyAnalyticsEntity)
    
    @Query("SELECT * FROM daily_analytics WHERE date = :date")
    suspend fun getDailyAnalytics(date: String): DailyAnalyticsEntity?
    
    @Query("SELECT * FROM daily_analytics WHERE date >= :startDate AND date <= :endDate ORDER BY date ASC")
    suspend fun getDailyAnalyticsRange(startDate: String, endDate: String): List<DailyAnalyticsEntity>
    
    @Query("SELECT * FROM daily_analytics ORDER BY date DESC LIMIT :limit")
    suspend fun getRecentDailyAnalytics(limit: Int): List<DailyAnalyticsEntity>
    
    @Query("SELECT * FROM daily_analytics ORDER BY date DESC")
    fun getAllDailyAnalyticsFlow(): Flow<List<DailyAnalyticsEntity>>
    
    // Productivity Insights Operations
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertProductivityInsight(insight: ProductivityInsightEntity)
    
    @Query("SELECT * FROM productivity_insights WHERE isRead = 0 ORDER BY createdAt DESC")
    suspend fun getUnreadInsights(): List<ProductivityInsightEntity>
    
    @Query("SELECT * FROM productivity_insights ORDER BY createdAt DESC LIMIT :limit")
    suspend fun getRecentInsights(limit: Int): List<ProductivityInsightEntity>
    
    @Query("UPDATE productivity_insights SET isRead = 1 WHERE id = :insightId")
    suspend fun markInsightAsRead(insightId: String)
    
    @Query("DELETE FROM productivity_insights WHERE createdAt < :cutoffTime")
    suspend fun deleteOldInsights(cutoffTime: Long)
    
    // Achievement Operations
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertAchievement(achievement: AchievementEntity)
    
    @Query("SELECT * FROM achievements ORDER BY unlockedAt DESC")
    suspend fun getAllAchievements(): List<AchievementEntity>
    
    @Query("SELECT * FROM achievements WHERE isUnlocked = 1 ORDER BY unlockedAt DESC")
    suspend fun getUnlockedAchievements(): List<AchievementEntity>
    
    @Query("SELECT * FROM achievements WHERE isUnlocked = 0 ORDER BY progress DESC")
    suspend fun getLockedAchievements(): List<AchievementEntity>
    
    @Query("UPDATE achievements SET progress = :progress, isUnlocked = :isUnlocked, unlockedAt = :unlockedAt WHERE id = :achievementId")
    suspend fun updateAchievementProgress(achievementId: String, progress: Float, isUnlocked: Boolean, unlockedAt: Long?)
    
    // Focus Session Operations
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertFocusSession(session: FocusSessionEntity)
    
    @Update
    suspend fun updateFocusSession(session: FocusSessionEntity)
    
    @Query("SELECT * FROM focus_sessions WHERE startTime >= :startTime AND startTime <= :endTime ORDER BY startTime DESC")
    suspend fun getFocusSessionsInRange(startTime: Long, endTime: Long): List<FocusSessionEntity>
    
    @Query("SELECT * FROM focus_sessions ORDER BY startTime DESC LIMIT :limit")
    suspend fun getRecentFocusSessions(limit: Int): List<FocusSessionEntity>
    
    @Query("SELECT COUNT(*) FROM focus_sessions WHERE endTime IS NOT NULL")
    suspend fun getCompletedFocusSessionCount(): Int
    
    @Query("SELECT AVG(actualDurationMinutes) FROM focus_sessions WHERE actualDurationMinutes IS NOT NULL")
    suspend fun getAverageFocusSessionDuration(): Double?
    
    // Category Analytics Operations
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertCategoryAnalytics(analytics: CategoryAnalyticsEntity)
    
    @Query("SELECT * FROM category_analytics ORDER BY taskCount DESC")
    suspend fun getAllCategoryAnalytics(): List<CategoryAnalyticsEntity>
    
    @Query("SELECT * FROM category_analytics WHERE category = :category")
    suspend fun getCategoryAnalytics(category: String): CategoryAnalyticsEntity?
    
    // Productivity Pattern Operations
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertProductivityPattern(pattern: ProductivityPatternEntity)
    
    @Query("SELECT * FROM productivity_patterns ORDER BY completionRate DESC")
    suspend fun getAllProductivityPatterns(): List<ProductivityPatternEntity>
    
    @Query("SELECT * FROM productivity_patterns WHERE hourOfDay = :hour")
    suspend fun getProductivityPatternsForHour(hour: Int): List<ProductivityPatternEntity>
    
    @Query("SELECT * FROM productivity_patterns WHERE dayOfWeek = :dayOfWeek")
    suspend fun getProductivityPatternsForDay(dayOfWeek: Int): List<ProductivityPatternEntity>
    
    // Mood Correlation Operations
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertMoodCorrelation(mood: MoodCorrelationEntity)
    
    @Query("SELECT * FROM mood_correlations WHERE date >= :startDate AND date <= :endDate ORDER BY date DESC")
    suspend fun getMoodCorrelationsInRange(startDate: String, endDate: String): List<MoodCorrelationEntity>
    
    @Query("SELECT * FROM mood_correlations ORDER BY date DESC LIMIT :limit")
    suspend fun getRecentMoodCorrelations(limit: Int): List<MoodCorrelationEntity>
    
    // Streak Operations
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertStreakData(streak: StreakDataEntity)
    
    @Query("SELECT * FROM streak_data WHERE id = 'current_streak'")
    suspend fun getCurrentStreakData(): StreakDataEntity?
    
    @Query("SELECT * FROM streak_data WHERE id = 'current_streak'")
    fun getCurrentStreakDataFlow(): Flow<StreakDataEntity?>
    
    // Aggregate Queries for Analytics
    @Query("""
        SELECT 
            COUNT(*) as totalTasks,
            SUM(CASE WHEN tasksCompleted > 0 THEN 1 ELSE 0 END) as activeDays,
            AVG(tasksCompleted) as avgTasksPerDay,
            MAX(tasksCompleted) as maxTasksInDay
        FROM daily_analytics 
        WHERE date >= :startDate
    """)
    suspend fun getAggregateStats(startDate: String): AggregateStatsResult
    
    @Query("""
        SELECT hourOfDay, AVG(completionRate) as avgCompletionRate 
        FROM productivity_patterns 
        GROUP BY hourOfDay 
        ORDER BY avgCompletionRate DESC 
        LIMIT 3
    """)
    suspend fun getPeakProductivityHours(): List<HourlyProductivityResult>
    
    // Cleanup Operations
    @Query("DELETE FROM daily_analytics WHERE date < :cutoffDate")
    suspend fun deleteOldDailyAnalytics(cutoffDate: String)
    
    @Query("DELETE FROM focus_sessions WHERE startTime < :cutoffTime")
    suspend fun deleteOldFocusSessions(cutoffTime: Long)
    
    @Query("DELETE FROM mood_correlations WHERE date < :cutoffDate")
    suspend fun deleteOldMoodCorrelations(cutoffDate: String)
}

/**
 * Result class for aggregate statistics
 */
data class AggregateStatsResult(
    val totalTasks: Int,
    val activeDays: Int,
    val avgTasksPerDay: Double,
    val maxTasksInDay: Int
)

/**
 * Result class for hourly productivity data
 */
data class HourlyProductivityResult(
    val hourOfDay: Int,
    val avgCompletionRate: Double
)