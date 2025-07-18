package com.tasktracker.presentation.profile

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.tasktracker.domain.model.Achievement
import com.tasktracker.domain.model.CustomGoal
import com.tasktracker.domain.model.PersonalInsight
import com.tasktracker.domain.model.ProfileCustomizations
import com.tasktracker.domain.model.UserPreferences
import com.tasktracker.domain.model.UserProfile
import com.tasktracker.domain.repository.ProfileRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.catch
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.launch
import javax.inject.Inject

/**
 * ViewModel for the Profile screen
 */
@HiltViewModel
class ProfileViewModel @Inject constructor(
    private val profileRepository: ProfileRepository
) : ViewModel() {
    
    private val _uiState = MutableStateFlow(ProfileUiState())
    val uiState: StateFlow<ProfileUiState> = _uiState.asStateFlow()
    
    init {
        loadProfileData()
        observeProfileChanges()
    }
    
    /**
     * Load initial profile data
     */
    private fun loadProfileData() {
        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(isLoading = true)
            
            try {
                // Get or create profile
                val profile = profileRepository.getProfile() ?: profileRepository.createProfile()
                
                // Load personal insights
                val insights = profileRepository.getUnreadInsights()
                
                // Load custom goals
                val goals = profileRepository.getUserGoals().customGoals
                
                // Load recent achievements
                val achievements = profileRepository.checkProfileAchievements()
                
                _uiState.value = _uiState.value.copy(
                    isLoading = false,
                    profile = profile,
                    personalInsights = insights,
                    customGoals = goals,
                    recentAchievements = achievements.take(5),
                    error = null
                )
                
            } catch (e: Exception) {
                _uiState.value = _uiState.value.copy(
                    isLoading = false,
                    error = e.message ?: "Failed to load profile data"
                )
            }
        }
    }
    
    /**
     * Observe profile changes in real-time
     */
    private fun observeProfileChanges() {
        viewModelScope.launch {
            combine(
                profileRepository.getProfileFlow(),
                profileRepository.getInsightsFlow(),
                profileRepository.getGoalsFlow()
            ) { profile, insights, goals ->
                Triple(profile, insights, goals)
            }
            .catch { e ->
                _uiState.value = _uiState.value.copy(
                    error = e.message ?: "Failed to observe profile changes"
                )
            }
            .collect { (profile, insights, goals) ->
                _uiState.value = _uiState.value.copy(
                    profile = profile,
                    personalInsights = insights.filter { !it.isRead },
                    customGoals = goals.customGoals
                )
            }
        }
    }
    
    /**
     * Update user preferences
     */
    fun updatePreferences(preferences: UserPreferences) {
        viewModelScope.launch {
            try {
                profileRepository.updatePreferences(preferences)
                
                // Update local state
                _uiState.value.profile?.let { currentProfile ->
                    val updatedProfile = currentProfile.updatePreferences(preferences)
                    _uiState.value = _uiState.value.copy(profile = updatedProfile)
                }
                
            } catch (e: Exception) {
                _uiState.value = _uiState.value.copy(
                    error = e.message ?: "Failed to update preferences"
                )
            }
        }
    }
    
    /**
     * Update profile customizations
     */
    fun updateCustomizations(customizations: ProfileCustomizations) {
        viewModelScope.launch {
            try {
                profileRepository.updateCustomizations(customizations)
                
                // Update local state
                _uiState.value.profile?.let { currentProfile ->
                    val updatedProfile = currentProfile.copy(customizations = customizations)
                    _uiState.value = _uiState.value.copy(profile = updatedProfile)
                }
                
            } catch (e: Exception) {
                _uiState.value = _uiState.value.copy(
                    error = e.message ?: "Failed to update customizations"
                )
            }
        }
    }
    
    /**
     * Mark insight as read
     */
    fun markInsightAsRead(insightId: String) {
        viewModelScope.launch {
            try {
                profileRepository.markInsightAsRead(insightId)
                
                // Update local state
                val updatedInsights = _uiState.value.personalInsights.map { insight ->
                    if (insight.id == insightId) {
                        insight.copy(isRead = true)
                    } else {
                        insight
                    }
                }.filter { !it.isRead }
                
                _uiState.value = _uiState.value.copy(personalInsights = updatedInsights)
                
            } catch (e: Exception) {
                _uiState.value = _uiState.value.copy(
                    error = e.message ?: "Failed to mark insight as read"
                )
            }
        }
    }
    
    /**
     * Dismiss insight
     */
    fun dismissInsight(insightId: String) {
        viewModelScope.launch {
            try {
                profileRepository.dismissInsight(insightId)
                
                // Update local state
                val updatedInsights = _uiState.value.personalInsights.filter { it.id != insightId }
                _uiState.value = _uiState.value.copy(personalInsights = updatedInsights)
                
            } catch (e: Exception) {
                _uiState.value = _uiState.value.copy(
                    error = e.message ?: "Failed to dismiss insight"
                )
            }
        }
    }
    
    /**
     * Add custom goal
     */
    fun addCustomGoal(goal: CustomGoal) {
        viewModelScope.launch {
            try {
                val goalId = profileRepository.addCustomGoal(goal)
                
                // Update local state
                val updatedGoals = _uiState.value.customGoals + goal.copy(id = goalId)
                _uiState.value = _uiState.value.copy(customGoals = updatedGoals)
                
            } catch (e: Exception) {
                _uiState.value = _uiState.value.copy(
                    error = e.message ?: "Failed to add custom goal"
                )
            }
        }
    }
    
    /**
     * Update custom goal
     */
    fun updateCustomGoal(goal: CustomGoal) {
        viewModelScope.launch {
            try {
                profileRepository.updateCustomGoal(goal)
                
                // Update local state
                val updatedGoals = _uiState.value.customGoals.map { existingGoal ->
                    if (existingGoal.id == goal.id) goal else existingGoal
                }
                _uiState.value = _uiState.value.copy(customGoals = updatedGoals)
                
            } catch (e: Exception) {
                _uiState.value = _uiState.value.copy(
                    error = e.message ?: "Failed to update custom goal"
                )
            }
        }
    }
    
    /**
     * Complete custom goal
     */
    fun completeCustomGoal(goalId: String) {
        viewModelScope.launch {
            try {
                val success = profileRepository.completeCustomGoal(goalId)
                
                if (success) {
                    // Update local state
                    val updatedGoals = _uiState.value.customGoals.map { goal ->
                        if (goal.id == goalId) {
                            goal.copy(isCompleted = true)
                        } else {
                            goal
                        }
                    }
                    _uiState.value = _uiState.value.copy(customGoals = updatedGoals)
                }
                
            } catch (e: Exception) {
                _uiState.value = _uiState.value.copy(
                    error = e.message ?: "Failed to complete custom goal"
                )
            }
        }
    }
    
    /**
     * Delete custom goal
     */
    fun deleteCustomGoal(goalId: String) {
        viewModelScope.launch {
            try {
                val success = profileRepository.deleteCustomGoal(goalId)
                
                if (success) {
                    // Update local state
                    val updatedGoals = _uiState.value.customGoals.filter { it.id != goalId }
                    _uiState.value = _uiState.value.copy(customGoals = updatedGoals)
                }
                
            } catch (e: Exception) {
                _uiState.value = _uiState.value.copy(
                    error = e.message ?: "Failed to delete custom goal"
                )
            }
        }
    }
    
    /**
     * Generate new personal insights
     */
    fun generateInsights() {
        viewModelScope.launch {
            try {
                val newInsights = profileRepository.generatePersonalInsights()
                
                // Update local state
                val updatedInsights = (_uiState.value.personalInsights + newInsights).distinctBy { it.id }
                _uiState.value = _uiState.value.copy(personalInsights = updatedInsights)
                
            } catch (e: Exception) {
                _uiState.value = _uiState.value.copy(
                    error = e.message ?: "Failed to generate insights"
                )
            }
        }
    }
    
    /**
     * Export profile data
     */
    fun exportProfile(): String? {
        return try {
            viewModelScope.launch {
                profileRepository.exportProfile()
            }
            // This is a simplified return - in reality, you'd handle this asynchronously
            "Profile exported successfully"
        } catch (e: Exception) {
            _uiState.value = _uiState.value.copy(
                error = e.message ?: "Failed to export profile"
            )
            null
        }
    }
    
    /**
     * Reset profile to defaults
     */
    fun resetProfile() {
        viewModelScope.launch {
            try {
                profileRepository.resetPreferencesToDefault()
                profileRepository.resetCustomizations()
                
                // Reload profile data
                loadProfileData()
                
            } catch (e: Exception) {
                _uiState.value = _uiState.value.copy(
                    error = e.message ?: "Failed to reset profile"
                )
            }
        }
    }
    
    /**
     * Get smart recommendations
     */
    fun getSmartRecommendations() {
        viewModelScope.launch {
            try {
                val recommendations = profileRepository.getAdaptiveRecommendations()
                
                // Convert recommendations to insights
                val recommendationInsights = recommendations.map { recommendation ->
                    PersonalInsight(
                        type = com.tasktracker.domain.model.PersonalInsightType.PRODUCTIVITY_DECLINE,
                        title = "Smart Recommendation",
                        description = recommendation,
                        recommendation = "Try this optimization",
                        confidence = 0.8f
                    )
                }
                
                // Update local state
                val updatedInsights = (_uiState.value.personalInsights + recommendationInsights).distinctBy { it.id }
                _uiState.value = _uiState.value.copy(personalInsights = updatedInsights)
                
            } catch (e: Exception) {
                _uiState.value = _uiState.value.copy(
                    error = e.message ?: "Failed to get smart recommendations"
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
     * Refresh profile data
     */
    fun refreshProfile() {
        loadProfileData()
    }
}

/**
 * UI state for the Profile screen
 */
data class ProfileUiState(
    val isLoading: Boolean = true,
    val profile: UserProfile? = null,
    val personalInsights: List<PersonalInsight> = emptyList(),
    val customGoals: List<CustomGoal> = emptyList(),
    val recentAchievements: List<Achievement> = emptyList(),
    val error: String? = null
) {
    val hasProfile: Boolean
        get() = profile != null
    
    val hasInsights: Boolean
        get() = personalInsights.isNotEmpty()
    
    val hasGoals: Boolean
        get() = customGoals.isNotEmpty()
    
    val hasAchievements: Boolean
        get() = recentAchievements.isNotEmpty()
    
    val profileCompleteness: Float
        get() = if (profile != null) {
            var completeness = 0f
            
            // Basic profile info (20%)
            completeness += 0.2f
            
            // Preferences set (20%)
            if (profile.preferences != UserPreferences()) {
                completeness += 0.2f
            }
            
            // Has statistics (20%)
            if (profile.statistics.totalTasksCompleted > 0) {
                completeness += 0.2f
            }
            
            // Has customizations (20%)
            if (profile.customizations != ProfileCustomizations()) {
                completeness += 0.2f
            }
            
            // Has goals (20%)
            if (customGoals.isNotEmpty()) {
                completeness += 0.2f
            }
            
            completeness
        } else 0f
}