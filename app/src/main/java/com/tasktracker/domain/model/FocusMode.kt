package com.tasktracker.domain.model

import java.time.Duration
import java.time.Instant
import java.util.UUID

/**
 * Enum representing different focus modes
 */
enum class FocusMode(
    val displayName: String,
    val description: String,
    val defaultDuration: Duration,
    val color: String
) {
    DEEP_WORK(
        displayName = "Deep Work",
        description = "Hide all non-essential tasks and notifications",
        defaultDuration = Duration.ofMinutes(90),
        color = "#2196F3"
    ),
    LIGHT_FOCUS(
        displayName = "Light Focus",
        description = "Dim non-priority tasks while keeping them visible",
        defaultDuration = Duration.ofMinutes(45),
        color = "#4CAF50"
    ),
    POMODORO(
        displayName = "Pomodoro",
        description = "25-minute focused work sessions with breaks",
        defaultDuration = Duration.ofMinutes(25),
        color = "#FF9800"
    ),
    CUSTOM(
        displayName = "Custom",
        description = "User-defined focus parameters",
        defaultDuration = Duration.ofMinutes(60),
        color = "#9C27B0"
    );
    
    /**
     * Get the break duration for this focus mode
     */
    fun getBreakDuration(): Duration {
        return when (this) {
            POMODORO -> Duration.ofMinutes(5)
            DEEP_WORK -> Duration.ofMinutes(15)
            LIGHT_FOCUS -> Duration.ofMinutes(10)
            CUSTOM -> Duration.ofMinutes(10)
        }
    }
    
    /**
     * Check if this mode supports automatic breaks
     */
    fun supportsBreaks(): Boolean {
        return this == POMODORO || this == DEEP_WORK
    }
}

/**
 * Data class representing a focus session
 */
data class FocusSession(
    val id: String = UUID.randomUUID().toString(),
    val startTime: Instant,
    val plannedDuration: Duration,
    val actualDuration: Duration? = null,
    val mode: FocusMode,
    val tasksCompleted: Int = 0,
    val distractionCount: Int = 0,
    val focusScore: Float = 0f,
    val notes: String? = null,
    val isCompleted: Boolean = false,
    val isPaused: Boolean = false,
    val pausedAt: Instant? = null,
    val totalPausedTime: Duration = Duration.ZERO
) {
    /**
     * Calculate the current elapsed time
     */
    fun getElapsedTime(): Duration {
        val now = Instant.now()
        val baseElapsed = Duration.between(startTime, now)
        return baseElapsed.minus(totalPausedTime)
    }
    
    /**
     * Calculate remaining time in the session
     */
    fun getRemainingTime(): Duration {
        val elapsed = getElapsedTime()
        return plannedDuration.minus(elapsed).let { remaining ->
            if (remaining.isNegative) Duration.ZERO else remaining
        }
    }
    
    /**
     * Check if the session is overtime
     */
    fun isOvertime(): Boolean {
        return getElapsedTime() > plannedDuration
    }
    
    /**
     * Calculate focus efficiency (0.0 to 1.0)
     */
    fun getFocusEfficiency(): Float {
        if (actualDuration == null) return 0f
        
        val plannedMinutes = plannedDuration.toMinutes().toFloat()
        val actualMinutes = actualDuration.toMinutes().toFloat()
        val pausedMinutes = totalPausedTime.toMinutes().toFloat()
        
        // Efficiency based on time spent focused vs planned time
        val timeEfficiency = (actualMinutes - pausedMinutes) / plannedMinutes
        
        // Reduce efficiency based on distractions
        val distractionPenalty = distractionCount * 0.1f
        
        return (timeEfficiency - distractionPenalty).coerceIn(0f, 1f)
    }
    
    /**
     * Mark session as completed
     */
    fun complete(tasksCompleted: Int, notes: String? = null): FocusSession {
        return copy(
            isCompleted = true,
            actualDuration = getElapsedTime(),
            tasksCompleted = tasksCompleted,
            notes = notes,
            focusScore = getFocusEfficiency()
        )
    }
    
    /**
     * Pause the session
     */
    fun pause(): FocusSession {
        return if (!isPaused) {
            copy(isPaused = true, pausedAt = Instant.now())
        } else this
    }
    
    /**
     * Resume the session
     */
    fun resume(): FocusSession {
        return if (isPaused && pausedAt != null) {
            val pauseDuration = Duration.between(pausedAt, Instant.now())
            copy(
                isPaused = false,
                pausedAt = null,
                totalPausedTime = totalPausedTime.plus(pauseDuration)
            )
        } else this
    }
    
    /**
     * Add a distraction to the session
     */
    fun addDistraction(): FocusSession {
        return copy(distractionCount = distractionCount + 1)
    }
}

/**
 * Focus session state for UI
 */
enum class FocusSessionState {
    INACTIVE,
    PREPARING,
    ACTIVE,
    PAUSED,
    BREAK,
    COMPLETED,
    CANCELLED
}

/**
 * Focus settings for customization
 */
data class FocusSettings(
    val defaultMode: FocusMode = FocusMode.LIGHT_FOCUS,
    val enableBreaks: Boolean = true,
    val enableNotifications: Boolean = true,
    val enableHapticFeedback: Boolean = true,
    val enableSoundEffects: Boolean = false,
    val autoStartBreaks: Boolean = true,
    val hideCompletedTasks: Boolean = true,
    val dimNonPriorityTasks: Boolean = true,
    val blockDistractions: Boolean = false,
    val customDuration: Duration = Duration.ofMinutes(60),
    val customBreakDuration: Duration = Duration.ofMinutes(10)
) {
    /**
     * Get effective duration for a focus mode
     */
    fun getEffectiveDuration(mode: FocusMode): Duration {
        return if (mode == FocusMode.CUSTOM) customDuration else mode.defaultDuration
    }
    
    /**
     * Get effective break duration for a focus mode
     */
    fun getEffectiveBreakDuration(mode: FocusMode): Duration {
        return if (mode == FocusMode.CUSTOM) customBreakDuration else mode.getBreakDuration()
    }
}

/**
 * Focus statistics for analytics
 */
data class FocusStats(
    val totalSessions: Int = 0,
    val completedSessions: Int = 0,
    val totalFocusTime: Duration = Duration.ZERO,
    val averageSessionLength: Duration = Duration.ZERO,
    val averageFocusScore: Float = 0f,
    val totalTasksCompleted: Int = 0,
    val totalDistractions: Int = 0,
    val favoriteMode: FocusMode? = null,
    val bestFocusHour: Int? = null,
    val longestSession: Duration = Duration.ZERO,
    val currentStreak: Int = 0
) {
    /**
     * Calculate completion rate
     */
    fun getCompletionRate(): Float {
        return if (totalSessions > 0) {
            completedSessions.toFloat() / totalSessions.toFloat()
        } else 0f
    }
    
    /**
     * Calculate average tasks per session
     */
    fun getAverageTasksPerSession(): Float {
        return if (completedSessions > 0) {
            totalTasksCompleted.toFloat() / completedSessions.toFloat()
        } else 0f
    }
    
    /**
     * Calculate distraction rate
     */
    fun getDistractionRate(): Float {
        return if (completedSessions > 0) {
            totalDistractions.toFloat() / completedSessions.toFloat()
        } else 0f
    }
}

/**
 * Task priority for focus mode filtering
 */
enum class TaskPriority(val level: Int, val displayName: String) {
    LOW(1, "Low"),
    MEDIUM(2, "Medium"),
    HIGH(3, "High"),
    URGENT(4, "Urgent");
    
    companion object {
        fun fromLevel(level: Int): TaskPriority {
            return values().find { it.level == level } ?: MEDIUM
        }
    }
}

/**
 * Focus mode filter criteria
 */
data class FocusFilter(
    val mode: FocusMode,
    val hideCompletedTasks: Boolean = true,
    val minimumPriority: TaskPriority = TaskPriority.MEDIUM,
    val showOnlyDueTasks: Boolean = false,
    val hideRecurringTasks: Boolean = false,
    val maxTasksToShow: Int? = null
) {
    /**
     * Check if a task should be visible in this focus mode
     */
    fun shouldShowTask(
        task: Task,
        taskPriority: TaskPriority = TaskPriority.MEDIUM,
        isDueToday: Boolean = false
    ): Boolean {
        // Always hide completed tasks if setting is enabled
        if (hideCompletedTasks && task.isCompleted) return false
        
        // Check priority filter
        if (taskPriority.level < minimumPriority.level) {
            // In deep work mode, be more strict about priority
            if (mode == FocusMode.DEEP_WORK) return false
            // In other modes, just dim the task (handled by UI)
        }
        
        // Show only due tasks filter
        if (showOnlyDueTasks && !isDueToday) return false
        
        // Hide recurring tasks filter
        if (hideRecurringTasks && task.isRecurring()) return false
        
        return true
    }
    
    /**
     * Check if a task should be dimmed (visible but de-emphasized)
     */
    fun shouldDimTask(
        task: Task,
        taskPriority: TaskPriority = TaskPriority.MEDIUM
    ): Boolean {
        return when (mode) {
            FocusMode.LIGHT_FOCUS -> taskPriority.level < minimumPriority.level
            FocusMode.DEEP_WORK -> false // Tasks are either shown or hidden
            FocusMode.POMODORO -> taskPriority == TaskPriority.LOW
            FocusMode.CUSTOM -> taskPriority.level < minimumPriority.level
        }
    }
}