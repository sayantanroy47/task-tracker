package com.tasktracker.data.repository

import com.tasktracker.data.local.dao.AnalyticsDao
import com.tasktracker.data.local.dao.TaskDao
import com.tasktracker.data.local.entity.AchievementEntity
import com.tasktracker.data.local.entity.CategoryAnalyticsEntity
import com.tasktracker.data.local.entity.DailyAnalyticsEntity
import com.tasktracker.data.local.entity.FocusSessionEntity
import com.tasktracker.data.local.entity.MoodCorrelationEntity
import com.tasktracker.data.local.entity.ProductivityInsightEntity
import com.tasktracker.data.local.entity.ProductivityPatternEntity
import com.tasktracker.data.local.entity.StreakDataEntity
import com.tasktracker.domain.model.Achievement
import com.tasktracker.domain.model.AchievementCategory
import com.tasktracker.domain.model.AchievementRequirement
import com.tasktracker.domain.model.CategoryStats
import com.tasktracker.domain.model.DailyStats
import com.tasktracker.domain.model.FocusMode
import com.tasktracker.domain.model.FocusSession
import com.tasktracker.domain.model.FocusSessionStats
import com.tasktracker.domain.model.InsightType
import com.tasktracker.domain.model.MoodCorrelation
import com.tasktracker.domain.model.ProductivityInsight
import com.tasktracker.domain.model.ProductivityMetrics
import com.tasktracker.domain.model.ProductivityPattern
import com.tasktracker.domain.model.TrendDirection
import com.tasktracker.domain.model.WeeklyStats
import com.tasktracker.domain.repository.AnalyticsRepository
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.map
import java.time.Duration
import java.time.Instant
import java.time.LocalDate
import java.time.format.DateTimeFormatter
import java.time.temporal.ChronoUnit
import javax.inject.Inject
import javax.inject.Singleton
import kotlin.math.roundToInt

@Singleton
class AnalyticsRepositoryImpl @Inject constructor(
    private val analyticsDao: AnalyticsDao,
    private val taskDao: TaskDao
) : AnalyticsRepository {
    
    private val dateFormatter = DateTimeFormatter.ISO_LOCAL_DATE
    
    override suspend fun getProductivityMetrics(): ProductivityMetrics {
        val today = LocalDate.now()
        val todayStats = getDailyStats(today)
        val weeklyTrend = getDailyStatsRange(today.minusDays(6), today)
        val streakData = analyticsDao.getCurrentStreakData()
        val insights = getUnreadInsights()
        val aggregateStats = analyticsDao.getAggregateStats(today.minusDays(30).format(dateFormatter))
        val peakHours = analyticsDao.getPeakProductivityHours().map { it.hourOfDay }
        
        return ProductivityMetrics(
            tasksCompletedToday = todayStats?.tasksCompleted ?: 0,
            tasksCreatedToday = todayStats?.tasksCreated ?: 0,
            completionRate = todayStats?.completionRate ?: 0f,
            averageCompletionTime = Duration.ofMinutes(todayStats?.averageTaskDuration?.toMinutes() ?: 0),
            peakProductivityHours = peakHours,
            weeklyTrend = weeklyTrend,
            monthlyTrend = emptyList(), // TODO: Implement monthly trends
            currentStreak = streakData?.currentStreak ?: 0,
            longestStreak = streakData?.longestStreak ?: 0,
            totalTasksCompleted = aggregateStats.totalTasks,
            totalFocusTime = Duration.ofMinutes(0), // TODO: Calculate from focus sessions
            averageDailyTasks = aggregateStats.avgTasksPerDay.toFloat(),
            mostProductiveDay = null, // TODO: Calculate most productive day
            insights = insights
        )
    }
    
    override suspend fun getDailyStats(date: LocalDate): DailyStats? {
        val entity = analyticsDao.getDailyAnalytics(date.format(dateFormatter))
        return entity?.let { mapDailyStatsEntityToDomain(it) }
    }
    
    override suspend fun getWeeklyStats(weekStart: LocalDate): WeeklyStats {
        val weekEnd = weekStart.plusDays(6)
        val dailyStats = getDailyStatsRange(weekStart, weekEnd)
        
        return WeeklyStats(
            weekStart = weekStart,
            totalTasksCompleted = dailyStats.sumOf { it.tasksCompleted },
            totalTasksCreated = dailyStats.sumOf { it.tasksCreated },
            totalFocusTime = Duration.ofMinutes(dailyStats.sumOf { it.focusTimeMinutes.toLong() }),
            averageCompletionRate = dailyStats.map { it.completionRate }.average().toFloat(),
            mostProductiveDay = dailyStats.maxByOrNull { it.tasksCompleted }?.date,
            dailyStats = dailyStats
        )
    }
    
    override suspend fun getDailyStatsRange(startDate: LocalDate, endDate: LocalDate): List<DailyStats> {
        val entities = analyticsDao.getDailyAnalyticsRange(
            startDate.format(dateFormatter),
            endDate.format(dateFormatter)
        )
        return entities.map { mapDailyStatsEntityToDomain(it) }
    }
    
    override suspend fun getWeeklyStatsRange(startDate: LocalDate, endDate: LocalDate): List<WeeklyStats> {
        val weeklyStats = mutableListOf<WeeklyStats>()
        var currentWeekStart = startDate
        
        while (currentWeekStart.isBefore(endDate) || currentWeekStart.isEqual(endDate)) {
            weeklyStats.add(getWeeklyStats(currentWeekStart))
            currentWeekStart = currentWeekStart.plusWeeks(1)
        }
        
        return weeklyStats
    }
    
    override fun getProductivityMetricsFlow(): Flow<ProductivityMetrics> {
        return combine(
            analyticsDao.getAllDailyAnalyticsFlow(),
            analyticsDao.getCurrentStreakDataFlow()
        ) { dailyAnalytics, streakData ->
            // Recompute metrics when data changes
            getProductivityMetrics()
        }
    }
    
    override fun getDailyStatsFlow(): Flow<List<DailyStats>> {
        return analyticsDao.getAllDailyAnalyticsFlow().map { entities ->
            entities.map { mapDailyStatsEntityToDomain(it) }
        }
    }
    
    override suspend fun recordTaskCompletion(taskId: String, completionTime: Long, category: String?) {
        val date = LocalDate.now()
        updateDailyStats(date)
        category?.let { updateCategoryStats(it, true, completionTime) }
        
        // Update streak
        val hasCompletedTaskToday = (getDailyStats(date)?.tasksCompleted ?: 0) > 0
        updateStreak(hasCompletedTaskToday)
    }
    
    override suspend fun recordTaskCreation(taskId: String, creationTime: Long, category: String?) {
        updateDailyStats(LocalDate.now())
        category?.let { updateCategoryStats(it, false, 0) }
    }
    
    override suspend fun updateDailyStats(date: LocalDate) {
        val dateStr = date.format(dateFormatter)
        val startOfDay = date.atStartOfDay().toInstant(java.time.ZoneOffset.UTC).toEpochMilli()
        val endOfDay = date.plusDays(1).atStartOfDay().toInstant(java.time.ZoneOffset.UTC).toEpochMilli()
        
        // Get tasks for this day
        val allTasks = taskDao.getAllTasks() // This should be filtered by date in a real implementation
        val tasksCreatedToday = allTasks.count { it.createdAt >= startOfDay && it.createdAt < endOfDay }
        val tasksCompletedToday = allTasks.count { 
            it.isCompleted && it.completedAt != null && it.completedAt >= startOfDay && it.completedAt < endOfDay 
        }
        
        val completionRate = if (tasksCreatedToday > 0) {
            tasksCompletedToday.toFloat() / tasksCreatedToday.toFloat()
        } else 0f
        
        // Calculate average completion time (simplified)
        val avgCompletionTime = if (tasksCompletedToday > 0) {
            Duration.ofHours(1) // Placeholder - should calculate actual time
        } else Duration.ZERO
        
        val entity = DailyAnalyticsEntity(
            date = dateStr,
            tasksCompleted = tasksCompletedToday,
            tasksCreated = tasksCreatedToday,
            focusTimeMinutes = 0, // TODO: Get from focus sessions
            completionRate = completionRate,
            averageTaskDurationMinutes = avgCompletionTime.toMinutes(),
            peakHour = null, // TODO: Calculate peak hour
            createdAt = System.currentTimeMillis(),
            updatedAt = System.currentTimeMillis()
        )
        
        analyticsDao.insertDailyAnalytics(entity)
    }
    
    override suspend fun generateInsights(): List<ProductivityInsight> {
        val insights = mutableListOf<ProductivityInsight>()
        val recentStats = analyticsDao.getRecentDailyAnalytics(7)
        
        // Generate completion rate insight
        val avgCompletionRate = recentStats.map { it.completionRate }.average()
        if (avgCompletionRate < 0.5) {
            insights.add(
                ProductivityInsight(
                    id = "low_completion_${System.currentTimeMillis()}",
                    type = InsightType.COMPLETION_PATTERN,
                    title = "Completion Rate Could Improve",
                    description = "Your task completion rate is ${(avgCompletionRate * 100).roundToInt()}% this week.",
                    actionSuggestion = "Try breaking large tasks into smaller, manageable pieces.",
                    confidence = 0.8f,
                    createdAt = Instant.now()
                )
            )
        }
        
        // Generate streak opportunity insight
        val streakData = analyticsDao.getCurrentStreakData()
        if (streakData?.currentStreak == 0 && recentStats.any { it.tasksCompleted > 0 }) {
            insights.add(
                ProductivityInsight(
                    id = "streak_opportunity_${System.currentTimeMillis()}",
                    type = InsightType.STREAK_OPPORTUNITY,
                    title = "Start a New Streak!",
                    description = "You've been completing tasks regularly. Start a completion streak today!",
                    actionSuggestion = "Complete at least one task today to begin your streak.",
                    confidence = 0.9f,
                    createdAt = Instant.now()
                )
            )
        }
        
        return insights
    }
    
    override suspend fun getUnreadInsights(): List<ProductivityInsight> {
        return analyticsDao.getUnreadInsights().map { mapInsightEntityToDomain(it) }
    }
    
    override suspend fun markInsightAsRead(insightId: String) {
        analyticsDao.markInsightAsRead(insightId)
    }
    
    override suspend fun getProductivityPatterns(): List<ProductivityPattern> {
        return analyticsDao.getAllProductivityPatterns().map { mapPatternEntityToDomain(it) }
    }
    
    override suspend fun updateProductivityPatterns() {
        // This would analyze historical data and update patterns
        // Implementation would be more complex in a real app
    }
    
    override suspend fun getAllAchievements(): List<Achievement> {
        return analyticsDao.getAllAchievements().map { mapAchievementEntityToDomain(it) }
    }
    
    override suspend fun getUnlockedAchievements(): List<Achievement> {
        return analyticsDao.getUnlockedAchievements().map { mapAchievementEntityToDomain(it) }
    }
    
    override suspend fun checkAndUnlockAchievements(): List<Achievement> {
        val newlyUnlocked = mutableListOf<Achievement>()
        val allAchievements = getAllAchievements()
        val metrics = getProductivityMetrics()
        
        allAchievements.filter { !it.isUnlocked }.forEach { achievement ->
            val shouldUnlock = when (achievement.requirement) {
                is AchievementRequirement.TaskCount -> 
                    metrics.totalTasksCompleted >= achievement.requirement.count
                is AchievementRequirement.StreakDays -> 
                    metrics.currentStreak >= achievement.requirement.days
                is AchievementRequirement.FocusTime -> 
                    metrics.totalFocusTime.toMinutes() >= achievement.requirement.minutes
                is AchievementRequirement.CompletionRate -> 
                    metrics.completionRate >= achievement.requirement.rate
                AchievementRequirement.FirstTask -> 
                    metrics.totalTasksCompleted >= 1
                else -> false
            }
            
            if (shouldUnlock) {
                analyticsDao.updateAchievementProgress(
                    achievement.id, 
                    1.0f, 
                    true, 
                    System.currentTimeMillis()
                )
                newlyUnlocked.add(achievement.copy(isUnlocked = true, unlockedAt = Instant.now()))
            }
        }
        
        return newlyUnlocked
    }
    
    override suspend fun updateAchievementProgress(achievementId: String, progress: Float) {
        analyticsDao.updateAchievementProgress(achievementId, progress, false, null)
    }
    
    override suspend fun recordFocusSessionStart(sessionId: String, mode: String, plannedDuration: Int) {
        val entity = FocusSessionEntity(
            id = sessionId,
            startTime = System.currentTimeMillis(),
            endTime = null,
            plannedDurationMinutes = plannedDuration,
            actualDurationMinutes = null,
            focusMode = mode,
            tasksCompleted = 0,
            distractionCount = 0,
            focusScore = 0f,
            notes = null
        )
        analyticsDao.insertFocusSession(entity)
    }
    
    override suspend fun recordFocusSessionEnd(
        sessionId: String, 
        actualDuration: Int, 
        tasksCompleted: Int, 
        distractionCount: Int
    ) {
        // This would update the existing session
        // Implementation simplified for brevity
    }
    
    override suspend fun getFocusSessionStats(): FocusSessionStats {
        val sessions = analyticsDao.getRecentFocusSessions(30)
        val completedSessions = sessions.filter { it.endTime != null }
        
        return FocusSessionStats(
            totalSessions = sessions.size,
            totalFocusTime = Duration.ofMinutes(completedSessions.sumOf { it.actualDurationMinutes?.toLong() ?: 0 }),
            averageSessionLength = Duration.ofMinutes(
                if (completedSessions.isNotEmpty()) {
                    completedSessions.mapNotNull { it.actualDurationMinutes }.average().toLong()
                } else 0
            ),
            completionRate = if (sessions.isNotEmpty()) {
                completedSessions.size.toFloat() / sessions.size.toFloat()
            } else 0f,
            mostUsedMode = null, // TODO: Calculate most used mode
            peakFocusHours = emptyList(), // TODO: Calculate peak hours
            weeklyFocusTime = emptyList(), // TODO: Calculate weekly focus time
            distractionCount = completedSessions.sumOf { it.distractionCount },
            focusScore = completedSessions.map { it.focusScore }.average().toFloat()
        )
    }
    
    override suspend fun getFocusSessionsInRange(startDate: LocalDate, endDate: LocalDate): List<FocusSession> {
        val startTime = startDate.atStartOfDay().toInstant(java.time.ZoneOffset.UTC).toEpochMilli()
        val endTime = endDate.plusDays(1).atStartOfDay().toInstant(java.time.ZoneOffset.UTC).toEpochMilli()
        
        return analyticsDao.getFocusSessionsInRange(startTime, endTime).map { mapFocusSessionEntityToDomain(it) }
    }
    
    override suspend fun getCategoryStats(): List<CategoryStats> {
        return analyticsDao.getAllCategoryAnalytics().map { mapCategoryStatsEntityToDomain(it) }
    }
    
    override suspend fun updateCategoryStats(category: String, taskCompleted: Boolean, completionTime: Long) {
        val existing = analyticsDao.getCategoryAnalytics(category)
        val updated = if (existing != null) {
            existing.copy(
                taskCount = existing.taskCount + 1,
                completedCount = if (taskCompleted) existing.completedCount + 1 else existing.completedCount,
                totalCompletionTimeMinutes = existing.totalCompletionTimeMinutes + (completionTime / 60000),
                lastUpdated = System.currentTimeMillis()
            )
        } else {
            CategoryAnalyticsEntity(
                category = category,
                taskCount = 1,
                completedCount = if (taskCompleted) 1 else 0,
                totalCompletionTimeMinutes = completionTime / 60000,
                lastUpdated = System.currentTimeMillis()
            )
        }
        analyticsDao.insertCategoryAnalytics(updated)
    }
    
    override suspend fun getCurrentStreak(): Int {
        return analyticsDao.getCurrentStreakData()?.currentStreak ?: 0
    }
    
    override suspend fun getLongestStreak(): Int {
        return analyticsDao.getCurrentStreakData()?.longestStreak ?: 0
    }
    
    override suspend fun updateStreak(hasCompletedTaskToday: Boolean) {
        val today = LocalDate.now()
        val existing = analyticsDao.getCurrentStreakData()
        
        val updated = if (existing != null) {
            val lastCompletionDate = existing.lastCompletionDate?.let { LocalDate.parse(it) }
            val daysSinceLastCompletion = if (lastCompletionDate != null) {
                ChronoUnit.DAYS.between(lastCompletionDate, today)
            } else Long.MAX_VALUE
            
            when {
                hasCompletedTaskToday && daysSinceLastCompletion == 1L -> {
                    // Continue streak
                    val newStreak = existing.currentStreak + 1
                    existing.copy(
                        currentStreak = newStreak,
                        longestStreak = maxOf(existing.longestStreak, newStreak),
                        lastCompletionDate = today.format(dateFormatter),
                        updatedAt = System.currentTimeMillis()
                    )
                }
                hasCompletedTaskToday && daysSinceLastCompletion == 0L -> {
                    // Same day, no change
                    existing
                }
                hasCompletedTaskToday -> {
                    // Start new streak
                    existing.copy(
                        currentStreak = 1,
                        lastCompletionDate = today.format(dateFormatter),
                        streakStartDate = today.format(dateFormatter),
                        updatedAt = System.currentTimeMillis()
                    )
                }
                daysSinceLastCompletion > 1 -> {
                    // Break streak
                    existing.copy(
                        currentStreak = 0,
                        updatedAt = System.currentTimeMillis()
                    )
                }
                else -> existing
            }
        } else {
            StreakDataEntity(
                currentStreak = if (hasCompletedTaskToday) 1 else 0,
                longestStreak = if (hasCompletedTaskToday) 1 else 0,
                lastCompletionDate = if (hasCompletedTaskToday) today.format(dateFormatter) else null,
                streakStartDate = if (hasCompletedTaskToday) today.format(dateFormatter) else null,
                updatedAt = System.currentTimeMillis()
            )
        }
        
        analyticsDao.insertStreakData(updated)
    }
    
    override fun getStreakFlow(): Flow<Pair<Int, Int>> {
        return analyticsDao.getCurrentStreakDataFlow().map { streakData ->
            Pair(streakData?.currentStreak ?: 0, streakData?.longestStreak ?: 0)
        }
    }
    
    override suspend fun recordMoodData(date: LocalDate, energyLevel: Int, moodRating: Int, notes: String?) {
        val entity = MoodCorrelationEntity(
            date = date.format(dateFormatter),
            energyLevel = energyLevel,
            moodRating = moodRating,
            tasksCompleted = getDailyStats(date)?.tasksCompleted ?: 0,
            focusTimeMinutes = getDailyStats(date)?.focusTimeMinutes ?: 0,
            notes = notes,
            createdAt = System.currentTimeMillis()
        )
        analyticsDao.insertMoodCorrelation(entity)
    }
    
    override suspend fun getMoodCorrelations(startDate: LocalDate, endDate: LocalDate): List<MoodCorrelation> {
        return analyticsDao.getMoodCorrelationsInRange(
            startDate.format(dateFormatter),
            endDate.format(dateFormatter)
        ).map { mapMoodCorrelationEntityToDomain(it) }
    }
    
    override suspend fun analyzeMoodProductivityCorrelation(): Map<String, Float> {
        // This would perform correlation analysis
        // Simplified implementation
        return mapOf(
            "energy_productivity_correlation" to 0.7f,
            "mood_productivity_correlation" to 0.6f
        )
    }
    
    override suspend fun cleanupOldData(retentionDays: Int) {
        val cutoffDate = LocalDate.now().minusDays(retentionDays.toLong())
        val cutoffTime = cutoffDate.atStartOfDay().toInstant(java.time.ZoneOffset.UTC).toEpochMilli()
        
        analyticsDao.deleteOldDailyAnalytics(cutoffDate.format(dateFormatter))
        analyticsDao.deleteOldFocusSessions(cutoffTime)
        analyticsDao.deleteOldMoodCorrelations(cutoffDate.format(dateFormatter))
        analyticsDao.deleteOldInsights(cutoffTime)
    }
    
    override suspend fun exportAnalyticsData(): String {
        // This would export all analytics data as JSON
        return "{}" // Placeholder
    }
    
    override suspend fun importAnalyticsData(jsonData: String): Boolean {
        // This would import analytics data from JSON
        return true // Placeholder
    }
    
    override suspend fun resetAllAnalytics() {
        // This would clear all analytics data
        // Implementation would involve clearing all tables
    }
    
    override suspend fun precomputeAnalytics() {
        // This would precompute expensive analytics calculations
        updateProductivityPatterns()
        generateInsights()
    }
    
    override suspend fun refreshAnalyticsCache() {
        // This would refresh any cached analytics data
        precomputeAnalytics()
    }
    
    // Mapping functions
    private fun mapDailyStatsEntityToDomain(entity: DailyAnalyticsEntity): DailyStats {
        return DailyStats(
            date = LocalDate.parse(entity.date),
            tasksCompleted = entity.tasksCompleted,
            tasksCreated = entity.tasksCreated,
            focusTimeMinutes = entity.focusTimeMinutes,
            completionRate = entity.completionRate,
            averageTaskDuration = Duration.ofMinutes(entity.averageTaskDurationMinutes),
            peakHour = entity.peakHour
        )
    }
    
    private fun mapInsightEntityToDomain(entity: ProductivityInsightEntity): ProductivityInsight {
        return ProductivityInsight(
            id = entity.id,
            type = InsightType.valueOf(entity.type),
            title = entity.title,
            description = entity.description,
            actionSuggestion = entity.actionSuggestion,
            confidence = entity.confidence,
            createdAt = Instant.ofEpochMilli(entity.createdAt),
            isRead = entity.isRead
        )
    }
    
    private fun mapAchievementEntityToDomain(entity: AchievementEntity): Achievement {
        return Achievement(
            id = entity.id,
            title = entity.title,
            description = entity.description,
            iconName = entity.iconName,
            category = AchievementCategory.valueOf(entity.category),
            requirement = AchievementRequirement.TaskCount(1), // Simplified
            unlockedAt = entity.unlockedAt?.let { Instant.ofEpochMilli(it) },
            progress = entity.progress,
            isUnlocked = entity.isUnlocked
        )
    }
    
    private fun mapPatternEntityToDomain(entity: ProductivityPatternEntity): ProductivityPattern {
        return ProductivityPattern(
            hourOfDay = entity.hourOfDay,
            dayOfWeek = entity.dayOfWeek,
            completionRate = entity.completionRate,
            averageTasksCompleted = entity.averageTasksCompleted,
            focusQuality = entity.focusQuality
        )
    }
    
    private fun mapFocusSessionEntityToDomain(entity: FocusSessionEntity): FocusSession {
        return FocusSession(
            id = entity.id,
            startTime = Instant.ofEpochMilli(entity.startTime),
            plannedDuration = Duration.ofMinutes(entity.plannedDurationMinutes.toLong()),
            actualDuration = entity.actualDurationMinutes?.let { Duration.ofMinutes(it.toLong()) },
            mode = FocusMode.valueOf(entity.focusMode),
            tasksCompleted = entity.tasksCompleted,
            distractionCount = entity.distractionCount,
            focusScore = entity.focusScore
        )
    }
    
    private fun mapCategoryStatsEntityToDomain(entity: CategoryAnalyticsEntity): CategoryStats {
        return CategoryStats(
            category = entity.category,
            taskCount = entity.taskCount,
            completionRate = if (entity.taskCount > 0) {
                entity.completedCount.toFloat() / entity.taskCount.toFloat()
            } else 0f,
            averageCompletionTime = Duration.ofMinutes(
                if (entity.completedCount > 0) {
                    entity.totalCompletionTimeMinutes / entity.completedCount
                } else 0
            ),
            trend = TrendDirection.STABLE // Simplified
        )
    }
    
    private fun mapMoodCorrelationEntityToDomain(entity: MoodCorrelationEntity): MoodCorrelation {
        return MoodCorrelation(
            date = LocalDate.parse(entity.date),
            energyLevel = entity.energyLevel,
            moodRating = entity.moodRating,
            tasksCompleted = entity.tasksCompleted,
            focusTime = Duration.ofMinutes(entity.focusTimeMinutes.toLong()),
            notes = entity.notes
        )
    }
}