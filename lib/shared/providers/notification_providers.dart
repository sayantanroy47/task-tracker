import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/notification_preferences_service.dart';
import '../../shared/models/notification_preferences.dart';
import 'app_providers.dart';

/// Notification preferences service provider
final notificationPreferencesServiceProvider = Provider<NotificationPreferencesService>((ref) {
  final databaseService = ref.read(databaseServiceProvider);
  return NotificationPreferencesService(databaseService);
});

/// Notification preferences provider - manages user preferences for notifications
final notificationPreferencesProvider = StateNotifierProvider<NotificationPreferencesNotifier, AsyncValue<NotificationPreferences>>((ref) {
  final service = ref.read(notificationPreferencesServiceProvider);
  return NotificationPreferencesNotifier(service);
});

/// Effective notification settings provider - returns current notification settings considering quiet hours
final effectiveNotificationSettingsProvider = FutureProvider<EffectiveNotificationSettings>((ref) async {
  final service = ref.read(notificationPreferencesServiceProvider);
  return service.getEffectiveSettings();
});

/// Notification preferences notifier for managing notification settings
class NotificationPreferencesNotifier extends StateNotifier<AsyncValue<NotificationPreferences>> {
  final NotificationPreferencesService _service;

  NotificationPreferencesNotifier(this._service) : super(const AsyncValue.loading()) {
    _loadPreferences();
  }

  /// Load preferences from storage
  Future<void> _loadPreferences() async {
    try {
      state = const AsyncValue.loading();
      final preferences = await _service.getPreferences();
      state = AsyncValue.data(preferences ?? NotificationPreferences.defaultPreferences());
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Update notification enabled status
  Future<void> setNotificationsEnabled(bool enabled) async {
    try {
      await _service.updatePreferences(notificationsEnabled: enabled);
      await _loadPreferences();
    } catch (error) {
      // Keep current state if update fails
    }
  }

  /// Update sound enabled status
  Future<void> setSoundEnabled(bool enabled) async {
    try {
      await _service.updatePreferences(soundEnabled: enabled);
      await _loadPreferences();
    } catch (error) {
      // Keep current state if update fails
    }
  }

  /// Update vibration enabled status
  Future<void> setVibrationEnabled(bool enabled) async {
    try {
      await _service.updatePreferences(vibrationEnabled: enabled);
      await _loadPreferences();
    } catch (error) {
      // Keep current state if update fails
    }
  }

  /// Update badge enabled status
  Future<void> setBadgeEnabled(bool enabled) async {
    try {
      await _service.updatePreferences(badgeEnabled: enabled);
      await _loadPreferences();
    } catch (error) {
      // Keep current state if update fails
    }
  }

  /// Update default reminder intervals
  Future<void> setDefaultReminderIntervals(List<ReminderInterval> intervals) async {
    try {
      await _service.updatePreferences(defaultReminderIntervals: intervals);
      await _loadPreferences();
    } catch (error) {
      // Keep current state if update fails
    }
  }

  /// Update quiet hours settings
  Future<void> setQuietHours({
    required bool enabled,
    TimeOfDayQuiet? startTime,
    TimeOfDayQuiet? endTime,
  }) async {
    try {
      await _service.updatePreferences(
        quietHoursEnabled: enabled,
        quietHoursStart: startTime,
        quietHoursEnd: endTime,
      );
      await _loadPreferences();
    } catch (error) {
      // Keep current state if update fails
    }
  }

  /// Update notification priority
  Future<void> setPriority(NotificationPriority priority) async {
    try {
      await _service.updatePreferences(priority: priority);
      await _loadPreferences();
    } catch (error) {
      // Keep current state if update fails
    }
  }

  /// Update show on lock screen setting
  Future<void> setShowOnLockScreen(bool enabled) async {
    try {
      await _service.updatePreferences(showOnLockScreen: enabled);
      await _loadPreferences();
    } catch (error) {
      // Keep current state if update fails
    }
  }

  /// Update allow interruptions during quiet hours
  Future<void> setAllowInterruptions(bool enabled) async {
    try {
      await _service.updatePreferences(allowInterruptions: enabled);
      await _loadPreferences();
    } catch (error) {
      // Keep current state if update fails
    }
  }

  /// Reset all preferences to defaults
  Future<void> resetToDefaults() async {
    try {
      await _service.resetToDefaults();
      await _loadPreferences();
    } catch (error) {
      // Keep current state if update fails
    }
  }

  /// Update multiple preferences at once
  Future<void> updatePreferences(NotificationPreferences preferences) async {
    try {
      await _service.savePreferences(preferences);
      await _loadPreferences();
    } catch (error) {
      // Keep current state if update fails
    }
  }
}

/// Provider for checking if notifications are currently allowed (considering quiet hours)
final notificationsAllowedProvider = FutureProvider<bool>((ref) async {
  final service = ref.read(notificationPreferencesServiceProvider);
  return service.areNotificationsAllowed();
});

/// Provider for default reminder intervals from preferences
final defaultReminderIntervalsProvider = Provider<List<ReminderInterval>>((ref) {
  final preferencesAsync = ref.watch(notificationPreferencesProvider);
  return preferencesAsync.whenOrNull(
    data: (preferences) => preferences.defaultReminderIntervals,
  ) ?? [ReminderInterval.oneHour];
});