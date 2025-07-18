package com.tasktracker.domain.repository

import com.tasktracker.domain.model.FocusMode
import com.tasktracker.domain.model.FocusSession
import com.tasktracker.domain.model.FocusSettings
import com.tasktracker.domain.model.FocusStats
import kotlinx.coroutines.flow.Flow
import java.time.LocalDate

/**
 * Repository interface for focus mode operations
 */
interface FocusRepository {
    
    // Focus Session Management
    suspend fun startFocusSession(mode: FocusMode, customDuration: Long? = null): FocusSession
    suspend fun getCurrentFocusSession(): FocusSession?
    suspend fun pauseFocusSession(sessionId: String): FocusSession?
    suspend fun resumeFocusSession(sessionId: String): FocusSession?
    suspend fun completeFocusSession(sessionId: String, tasksCompleted: Int, notes: String? = null): FocusSession?
    suspend fun cancelFocusSession(sessionId: String): Boolean
    suspend fun addDistractionToSession(sessionId: String): FocusSession?
    
    // Focus Session Queries
    suspend fun getFocusSession(sessionId: String): FocusSession?
    suspend fun getFocusSessionsForDate(date: LocalDate): List<FocusSession>
    suspend fun getFocusSessionsInRange(startDate: LocalDate, endDate: LocalDate): List<FocusSession>
    suspend fun getRecentFocusSessions(limit: Int = 10): List<FocusSession>
    
    // Real-time Focus Session Flow
    fun getCurrentFocusSessionFlow(): Flow<FocusSession?>
    fun getFocusSessionsFlow(): Flow<List<FocusSession>>
    
    // Focus Settings
    suspend fun getFocusSettings(): FocusSettings
    suspend fun updateFocusSettings(settings: FocusSettings)
    fun getFocusSettingsFlow(): Flow<FocusSettings>
    
    // Focus Statistics
    suspend fun getFocusStats(): FocusStats
    suspend fun getFocusStatsForPeriod(startDate: LocalDate, endDate: LocalDate): FocusStats
    suspend fun updateFocusStats()
    fun getFocusStatsFlow(): Flow<FocusStats>
    
    // Focus Mode Analytics
    suspend fun getMostUsedFocusMode(): FocusMode?
    suspend fun getBestFocusHours(): List<Int>
    suspend fun getFocusStreakData(): Pair<Int, Int> // current streak, longest streak
    suspend fun getAverageFocusScoreByMode(): Map<FocusMode, Float>
    
    // Break Management
    suspend fun startBreak(sessionId: String): Boolean
    suspend fun endBreak(sessionId: String): Boolean
    suspend fun getBreakDuration(mode: FocusMode): Long
    
    // Distraction Tracking
    suspend fun recordDistraction(sessionId: String, type: String, timestamp: Long): Boolean
    suspend fun getDistractionStats(startDate: LocalDate, endDate: LocalDate): Map<String, Int>
    
    // Focus Session Templates
    suspend fun createFocusTemplate(name: String, mode: FocusMode, duration: Long, settings: Map<String, Any>): String
    suspend fun getFocusTemplates(): List<FocusTemplate>
    suspend fun deleteFocusTemplate(templateId: String): Boolean
    
    // Data Management
    suspend fun cleanupOldFocusSessions(retentionDays: Int)
    suspend fun exportFocusData(): String
    suspend fun importFocusData(jsonData: String): Boolean
}

/**
 * Focus session template for quick setup
 */
data class FocusTemplate(
    val id: String,
    val name: String,
    val mode: FocusMode,
    val duration: Long,
    val settings: Map<String, Any>,
    val createdAt: Long,
    val usageCount: Int = 0
)