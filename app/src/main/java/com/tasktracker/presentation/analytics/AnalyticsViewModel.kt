package com.tasktracker.presentation.analytics

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.tasktracker.domain.model.Achievement
import com.tasktracker.domain.model.DailyStats
import com.tasktracker.domain.model.ProductivityInsight
import com.tasktracker.domain.model.ProductivityMetrics
import com.tasktracker.domain.repository.AnalyticsRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.catch
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.launch
import java.time.LocalDate
import javax.inject.Inject

/**
 * ViewModel for the Analytics screen
 */
@HiltViewModel
class AnalyticsViewModel @Inject constructor(
    private val analyticsRepository: AnalyticsRepository
) : ViewModel() {
    
    private val _uiState = MutableStateFlow(AnalyticsUiState())
    val uiState: StateFlow<AnalyticsUiState> = _uiState.asStateFlow()
    
    init {
        loadAnalyticsData()
        observeAnalyticsUpdates()
    }
    
    /**
     * Load initial analytics data
     */
    private fun loadAnalyticsData() {
        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(isLoading = true)
            
            try {
                // Load productivity metrics
                val metrics = analyticsRepository.getProductivityMetrics()
                
                // Load weekly trend data
                val endDate = LocalDate.now()
                val startDate = endDate.minusDays(6)
                val weeklyTrend = analyticsRepository.getDailyStatsRange(startDate, endDate)
                
                // Load insights
                val insights = analyticsRepository.getUnreadInsights()
                
                // Load recent achievements
                val achievements = analyticsRepository.getUnlockedAchievements().take(5)
                
                // Check for new achievements
                val newAchievements = analyticsRepository.checkAndUnlockAchievements()
                
                _uiState.value = _uiState.value.copy(
                    isLoading = false,
                    productivityMetrics = metrics,
                    weeklyTrend = weeklyTrend,
                    insights = insights,
                    recentAchievements = achievements,
                    newAchievements = newAchievements,
                    error = null
                )
                
            } catch (e: Exception) {
                _uiState.value = _uiState.value.copy(
                    isLoading = false,
                    error = e.message ?: "Failed to load analytics data"
                )
            }
        }
    }
    
    /**
     * Observe real-time analytics updates
     */
    private fun observeAnalyticsUpdates() {
        viewModelScope.launch {
            combine(
                analyticsRepository.getProductivityMetricsFlow(),
                analyticsRepository.getDailyStatsFlow(),
                analyticsRepository.getStreakFlow()
            ) { metrics, dailyStats, streak ->
                Triple(metrics, dailyStats, streak)
            }
            .catch { e ->
                _uiState.value = _uiState.value.copy(
                    error = e.message ?: "Failed to observe analytics updates"
                )
            }
            .collect { (metrics, dailyStats, streak) ->
                val weeklyTrend = dailyStats.takeLast(7)
                
                _uiState.value = _uiState.value.copy(
                    productivityMetrics = metrics,
                    weeklyTrend = weeklyTrend
                )
            }
        }
    }
    
    /**
     * Mark an insight as read
     */
    fun markInsightAsRead(insightId: String) {
        viewModelScope.launch {
            try {
                analyticsRepository.markInsightAsRead(insightId)
                
                // Update UI state by removing the read insight
                val updatedInsights = _uiState.value.insights.filter { it.id != insightId }
                _uiState.value = _uiState.value.copy(insights = updatedInsights)
                
            } catch (e: Exception) {
                _uiState.value = _uiState.value.copy(
                    error = e.message ?: "Failed to mark insight as read"
                )
            }
        }
    }
    
    /**
     * Refresh analytics data
     */
    fun refreshAnalytics() {
        viewModelScope.launch {
            try {
                analyticsRepository.refreshAnalyticsCache()
                loadAnalyticsData()
            } catch (e: Exception) {
                _uiState.value = _uiState.value.copy(
                    error = e.message ?: "Failed to refresh analytics"
                )
            }
        }
    }
    
    /**
     * Generate new insights
     */
    fun generateInsights() {
        viewModelScope.launch {
            try {
                val newInsights = analyticsRepository.generateInsights()
                
                // Add new insights to existing ones
                val updatedInsights = (_uiState.value.insights + newInsights).distinctBy { it.id }
                _uiState.value = _uiState.value.copy(insights = updatedInsights)
                
            } catch (e: Exception) {
                _uiState.value = _uiState.value.copy(
                    error = e.message ?: "Failed to generate insights"
                )
            }
        }
    }
    
    /**
     * Clear error state
     */
    fun clearError() {
        _uiState.value = _uiState.value.copy(error = null)
    }
    
    /**
     * Clear new achievements (after celebration)
     */
    fun clearNewAchievements() {
        _uiState.value = _uiState.value.copy(newAchievements = emptyList())
    }
    
    /**
     * Load extended date range data
     */
    fun loadExtendedData(startDate: LocalDate, endDate: LocalDate) {
        viewModelScope.launch {
            try {
                val extendedTrend = analyticsRepository.getDailyStatsRange(startDate, endDate)
                _uiState.value = _uiState.value.copy(weeklyTrend = extendedTrend)
            } catch (e: Exception) {
                _uiState.value = _uiState.value.copy(
                    error = e.message ?: "Failed to load extended data"
                )
            }
        }
    }
    
    /**
     * Export analytics data
     */
    fun exportAnalytics(): String? {
        return try {
            // This would typically be done in a background thread
            // For now, return a simple JSON representation
            val metrics = _uiState.value.productivityMetrics
            """
            {
                "totalTasksCompleted": ${metrics?.totalTasksCompleted ?: 0},
                "currentStreak": ${metrics?.currentStreak ?: 0},
                "longestStreak": ${metrics?.longestStreak ?: 0},
                "completionRate": ${metrics?.completionRate ?: 0f},
                "averageDailyTasks": ${metrics?.averageDailyTasks ?: 0f}
            }
            """.trimIndent()
        } catch (e: Exception) {
            _uiState.value = _uiState.value.copy(
                error = e.message ?: "Failed to export analytics"
            )
            null
        }
    }
}

/**
 * UI state for the Analytics screen
 */
data class AnalyticsUiState(
    val isLoading: Boolean = false,
    val productivityMetrics: ProductivityMetrics? = null,
    val weeklyTrend: List<DailyStats> = emptyList(),
    val insights: List<ProductivityInsight> = emptyList(),
    val recentAchievements: List<Achievement> = emptyList(),
    val newAchievements: List<Achievement> = emptyList(),
    val error: String? = null
) {
    val hasData: Boolean
        get() = productivityMetrics != null
    
    val hasInsights: Boolean
        get() = insights.isNotEmpty()
    
    val hasAchievements: Boolean
        get() = recentAchievements.isNotEmpty()
    
    val hasNewAchievements: Boolean
        get() = newAchievements.isNotEmpty()
}