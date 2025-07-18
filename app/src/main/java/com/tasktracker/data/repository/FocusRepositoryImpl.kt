package com.tasktracker.data.repository

import com.tasktracker.data.local.dao.AnalyticsDao
import com.tasktracker.data.local.entity.FocusSessionEntity
import com.tasktracker.domain.model.FocusMode
import com.tasktracker.domain.model.FocusSession
import com.tasktracker.domain.model.FocusSettings
import com.tasktracker.domain.model.FocusStats
import com.tasktracker.domain.repository.FocusRepository
import com.tasktracker.domain.repository.FocusTemplate
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.map
import java.time.Duration
import java.time.Instant
import java.time.LocalDate
import java.time.ZoneOffset
import java.util.UUID
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class FocusRepositoryImpl @Inject constructor(
    private val analyticsDao: AnalyticsDao
) : FocusRepository {
    
    private val _currentSession = MutableStateFlow<FocusSession?>(null)
    private val _focusSettings = MutableStateFlow(FocusSettings())
    
    override suspend fun startFocusSession(mode: FocusMode, customDuration: Long?): FocusSession {
        val duration = if (customDuration != null) {
            Duration.ofMinutes(customDuration)
        } else {
            _focusSettings.value.getEffectiveDuration(mode)
        }
        
        val session = FocusSession(
            startTime = Instant.now(),
            plannedDuration = duration,
            mode = mode
        )
        
        // Save to database
        val entity = mapFocusSessionToEntity(session)
        analyticsDao.insertFocusSession(entity)
        
        // Update current session
        _currentSession.value = session
        
        return session
    }
    
    override suspend fun getCurrentFocusSession(): FocusSession? {
        return _currentSession.value
    }
    
    override suspend fun pauseFocusSession(sessionId: String): FocusSession? {
        val currentSession = _currentSession.value
        if (currentSession?.id == sessionId) {
            val pausedSession = currentSession.pause()
            _currentSession.value = pausedSession
            
            // Update in database
            val entity = mapFocusSessionToEntity(pausedSession)
            analyticsDao.updateFocusSession(entity)
            
            return pausedSession
        }
        return null
    }
    
    override suspend fun resumeFocusSession(sessionId: String): FocusSession? {
        val currentSession = _currentSession.value
        if (currentSession?.id == sessionId) {
            val resumedSession = currentSession.resume()
            _currentSession.value = resumedSession
            
            // Update in database
            val entity = mapFocusSessionToEntity(resumedSession)
            analyticsDao.updateFocusSession(entity)
            
            return resumedSession
        }
        return null
    }
    
    override suspend fun completeFocusSession(sessionId: String, tasksCompleted: Int, notes: String?): FocusSession? {
        val currentSession = _currentSession.value
        if (currentSession?.id == sessionId) {
            val completedSession = currentSession.complete(tasksCompleted, notes)
            _currentSession.value = null // Clear current session
            
            // Update in database
            val entity = mapFocusSessionToEntity(completedSession)
            analyticsDao.updateFocusSession(entity)
            
            return completedSession
        }
        return null
    }
    
    override suspend fun cancelFocusSession(sessionId: String): Boolean {
        val currentSession = _currentSession.value
        if (currentSession?.id == sessionId) {
            _currentSession.value = null
            
            // Mark as cancelled in database (you might want to add a cancelled field)
            val entity = mapFocusSessionToEntity(currentSession.copy(isCompleted = true))
            analyticsDao.updateFocusSession(entity)
            
            return true
        }
        return false
    }
    
    override suspend fun addDistractionToSession(sessionId: String): FocusSession? {
        val currentSession = _currentSession.value
        if (currentSession?.id == sessionId) {
            val updatedSession = currentSession.addDistraction()
            _currentSession.value = updatedSession
            
            // Update in database
            val entity = mapFocusSessionToEntity(updatedSession)
            analyticsDao.updateFocusSession(entity)
            
            return updatedSession
        }
        return null
    }
    
    override suspend fun getFocusSession(sessionId: String): FocusSession? {
        // This would query the database for a specific session
        // For now, return current session if IDs match
        return if (_currentSession.value?.id == sessionId) {
            _currentSession.value
        } else null
    }
    
    override suspend fun getFocusSessionsForDate(date: LocalDate): List<FocusSession> {
        val startOfDay = date.atStartOfDay().toInstant(ZoneOffset.UTC).toEpochMilli()
        val endOfDay = date.plusDays(1).atStartOfDay().toInstant(ZoneOffset.UTC).toEpochMilli()
        
        val entities = analyticsDao.getFocusSessionsInRange(startOfDay, endOfDay)
        return entities.map { mapFocusSessionEntityToDomain(it) }
    }
    
    override suspend fun getFocusSessionsInRange(startDate: LocalDate, endDate: LocalDate): List<FocusSession> {
        val startTime = startDate.atStartOfDay().toInstant(ZoneOffset.UTC).toEpochMilli()
        val endTime = endDate.plusDays(1).atStartOfDay().toInstant(ZoneOffset.UTC).toEpochMilli()
        
        val entities = analyticsDao.getFocusSessionsInRange(startTime, endTime)
        return entities.map { mapFocusSessionEntityToDomain(it) }
    }
    
    override suspend fun getRecentFocusSessions(limit: Int): List<FocusSession> {
        val entities = analyticsDao.getRecentFocusSessions(limit)
        return entities.map { mapFocusSessionEntityToDomain(it) }
    }
    
    override fun getCurrentFocusSessionFlow(): Flow<FocusSession?> {
        return _currentSession.asStateFlow()
    }
    
    override fun getFocusSessionsFlow(): Flow<List<FocusSession>> {
        // This would observe database changes
        // For now, return empty flow
        return MutableStateFlow(emptyList<FocusSession>()).asStateFlow()
    }
    
    override suspend fun getFocusSettings(): FocusSettings {
        return _focusSettings.value
    }
    
    override suspend fun updateFocusSettings(settings: FocusSettings) {
        _focusSettings.value = settings
        // In a real implementation, you'd save to database or preferences
    }
    
    override fun getFocusSettingsFlow(): Flow<FocusSettings> {
        return _focusSettings.asStateFlow()
    }
    
    override suspend fun getFocusStats(): FocusStats {
        val recentSessions = getRecentFocusSessions(30)
        val completedSessions = recentSessions.filter { it.isCompleted }
        
        return FocusStats(
            totalSessions = recentSessions.size,
            completedSessions = completedSessions.size,
            totalFocusTime = completedSessions.fold(Duration.ZERO) { acc, session ->
                acc.plus(session.actualDuration ?: Duration.ZERO)
            },
            averageSessionLength = if (completedSessions.isNotEmpty()) {
                val totalMinutes = completedSessions.sumOf { 
                    (it.actualDuration ?: Duration.ZERO).toMinutes() 
                }
                Duration.ofMinutes(totalMinutes / completedSessions.size)
            } else Duration.ZERO,
            averageFocusScore = if (completedSessions.isNotEmpty()) {
                completedSessions.map { it.focusScore }.average().toFloat()
            } else 0f,
            totalTasksCompleted = completedSessions.sumOf { it.tasksCompleted },
            totalDistractions = completedSessions.sumOf { it.distractionCount },
            favoriteMode = getMostUsedFocusMode(),
            longestSession = completedSessions.maxOfOrNull { 
                it.actualDuration ?: Duration.ZERO 
            } ?: Duration.ZERO,
            currentStreak = calculateCurrentStreak(recentSessions)
        )
    }
    
    override suspend fun getFocusStatsForPeriod(startDate: LocalDate, endDate: LocalDate): FocusStats {
        val sessions = getFocusSessionsInRange(startDate, endDate)
        val completedSessions = sessions.filter { it.isCompleted }
        
        return FocusStats(
            totalSessions = sessions.size,
            completedSessions = completedSessions.size,
            totalFocusTime = completedSessions.fold(Duration.ZERO) { acc, session ->
                acc.plus(session.actualDuration ?: Duration.ZERO)
            },
            averageSessionLength = if (completedSessions.isNotEmpty()) {
                val totalMinutes = completedSessions.sumOf { 
                    (it.actualDuration ?: Duration.ZERO).toMinutes() 
                }
                Duration.ofMinutes(totalMinutes / completedSessions.size)
            } else Duration.ZERO,
            averageFocusScore = if (completedSessions.isNotEmpty()) {
                completedSessions.map { it.focusScore }.average().toFloat()
            } else 0f,
            totalTasksCompleted = completedSessions.sumOf { it.tasksCompleted },
            totalDistractions = completedSessions.sumOf { it.distractionCount }
        )
    }
    
    override suspend fun updateFocusStats() {
        // This would recalculate and cache focus statistics
        // Implementation depends on your caching strategy
    }
    
    override fun getFocusStatsFlow(): Flow<FocusStats> {
        // This would observe database changes and recalculate stats
        return MutableStateFlow(FocusStats()).asStateFlow()
    }
    
    override suspend fun getMostUsedFocusMode(): FocusMode? {
        val recentSessions = getRecentFocusSessions(50)
        return recentSessions
            .groupBy { it.mode }
            .maxByOrNull { it.value.size }
            ?.key
    }
    
    override suspend fun getBestFocusHours(): List<Int> {
        val recentSessions = getRecentFocusSessions(50)
        return recentSessions
            .filter { it.isCompleted && it.focusScore > 0.7f }
            .groupBy { it.startTime.atZone(ZoneOffset.UTC).hour }
            .toList()
            .sortedByDescending { it.second.size }
            .take(3)
            .map { it.first }
    }
    
    override suspend fun getFocusStreakData(): Pair<Int, Int> {
        val recentSessions = getRecentFocusSessions(30)
        val currentStreak = calculateCurrentStreak(recentSessions)
        val longestStreak = calculateLongestStreak(recentSessions)
        return Pair(currentStreak, longestStreak)
    }
    
    override suspend fun getAverageFocusScoreByMode(): Map<FocusMode, Float> {
        val recentSessions = getRecentFocusSessions(50)
        return recentSessions
            .filter { it.isCompleted }
            .groupBy { it.mode }
            .mapValues { (_, sessions) ->
                sessions.map { it.focusScore }.average().toFloat()
            }
    }
    
    override suspend fun startBreak(sessionId: String): Boolean {
        // Implementation would mark session as on break
        return true
    }
    
    override suspend fun endBreak(sessionId: String): Boolean {
        // Implementation would end break and resume session
        return true
    }
    
    override suspend fun getBreakDuration(mode: FocusMode): Long {
        return _focusSettings.value.getEffectiveBreakDuration(mode).toMinutes()
    }
    
    override suspend fun recordDistraction(sessionId: String, type: String, timestamp: Long): Boolean {
        // Implementation would record distraction details
        return addDistractionToSession(sessionId) != null
    }
    
    override suspend fun getDistractionStats(startDate: LocalDate, endDate: LocalDate): Map<String, Int> {
        // Implementation would return distraction statistics by type
        return emptyMap()
    }
    
    override suspend fun createFocusTemplate(name: String, mode: FocusMode, duration: Long, settings: Map<String, Any>): String {
        val templateId = UUID.randomUUID().toString()
        // Implementation would save template to database
        return templateId
    }
    
    override suspend fun getFocusTemplates(): List<FocusTemplate> {
        // Implementation would return saved templates
        return emptyList()
    }
    
    override suspend fun deleteFocusTemplate(templateId: String): Boolean {
        // Implementation would delete template from database
        return true
    }
    
    override suspend fun cleanupOldFocusSessions(retentionDays: Int) {
        val cutoffTime = LocalDate.now().minusDays(retentionDays.toLong())
            .atStartOfDay().toInstant(ZoneOffset.UTC).toEpochMilli()
        analyticsDao.deleteOldFocusSessions(cutoffTime)
    }
    
    override suspend fun exportFocusData(): String {
        val sessions = getRecentFocusSessions(100)
        // Implementation would serialize sessions to JSON
        return "{\"sessions\": []}"
    }
    
    override suspend fun importFocusData(jsonData: String): Boolean {
        // Implementation would parse JSON and import sessions
        return true
    }
    
    // Helper methods
    private fun mapFocusSessionToEntity(session: FocusSession): FocusSessionEntity {
        return FocusSessionEntity(
            id = session.id,
            startTime = session.startTime.toEpochMilli(),
            endTime = if (session.isCompleted) System.currentTimeMillis() else null,
            plannedDurationMinutes = session.plannedDuration.toMinutes().toInt(),
            actualDurationMinutes = session.actualDuration?.toMinutes()?.toInt(),
            focusMode = session.mode.name,
            tasksCompleted = session.tasksCompleted,
            distractionCount = session.distractionCount,
            focusScore = session.focusScore,
            notes = session.notes
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
            focusScore = entity.focusScore,
            notes = entity.notes,
            isCompleted = entity.endTime != null
        )
    }
    
    private fun calculateCurrentStreak(sessions: List<FocusSession>): Int {
        val completedSessions = sessions
            .filter { it.isCompleted }
            .sortedByDescending { it.startTime }
        
        var streak = 0
        var currentDate = LocalDate.now()
        
        for (session in completedSessions) {
            val sessionDate = session.startTime.atZone(ZoneOffset.UTC).toLocalDate()
            if (sessionDate == currentDate || sessionDate == currentDate.minusDays(1)) {
                streak++
                currentDate = sessionDate.minusDays(1)
            } else {
                break
            }
        }
        
        return streak
    }
    
    private fun calculateLongestStreak(sessions: List<FocusSession>): Int {
        val completedSessions = sessions
            .filter { it.isCompleted }
            .sortedBy { it.startTime }
        
        var longestStreak = 0
        var currentStreak = 0
        var lastDate: LocalDate? = null
        
        for (session in completedSessions) {
            val sessionDate = session.startTime.atZone(ZoneOffset.UTC).toLocalDate()
            
            if (lastDate == null || sessionDate == lastDate.plusDays(1)) {
                currentStreak++
                longestStreak = maxOf(longestStreak, currentStreak)
            } else if (sessionDate != lastDate) {
                currentStreak = 1
            }
            
            lastDate = sessionDate
        }
        
        return longestStreak
    }
}