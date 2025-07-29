import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import '../../shared/models/notification_preferences.dart';
import 'database_service.dart';

/// Service for managing notification preferences storage and retrieval
class NotificationPreferencesService {
  static const String _tableName = 'notification_preferences';
  static const String _keyId = 'user_preferences';
  
  final DatabaseService _databaseService;

  NotificationPreferencesService(this._databaseService);

  /// Initialize the preferences table
  Future<void> initialize() async {
    final db = await _databaseService.database;
    
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_tableName (
        id TEXT PRIMARY KEY,
        preferences_json TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
    
    // Insert default preferences if they don't exist
    final existing = await getPreferences();
    if (existing == null) {
      await savePreferences(NotificationPreferences.defaultPreferences());
    }
  }

  /// Get current notification preferences
  Future<NotificationPreferences?> getPreferences() async {
    try {
      final db = await _databaseService.database;
      
      final result = await db.query(
        _tableName,
        where: 'id = ?',
        whereArgs: [_keyId],
        limit: 1,
      );

      if (result.isEmpty) {
        return null;
      }

      final preferencesJson = result.first['preferences_json'] as String;
      final preferencesMap = jsonDecode(preferencesJson) as Map<String, dynamic>;
      
      return NotificationPreferences.fromMap(preferencesMap);
    } catch (e) {
      debugPrint('Error getting notification preferences: $e');
      return null;
    }
  }

  /// Save notification preferences
  Future<void> savePreferences(NotificationPreferences preferences) async {
    try {
      final db = await _databaseService.database;
      final now = DateTime.now().toIso8601String();
      
      await db.insert(
        _tableName,
        {
          'id': _keyId,
          'preferences_json': jsonEncode(preferences.toMap()),
          'created_at': now,
          'updated_at': now,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      debugPrint('Error saving notification preferences: $e');
      rethrow;
    }
  }

  /// Update specific preference fields
  Future<void> updatePreferences({
    bool? notificationsEnabled,
    bool? soundEnabled,
    bool? vibrationEnabled,
    bool? badgeEnabled,
    List<ReminderInterval>? defaultReminderIntervals,
    TimeOfDayQuiet? quietHoursStart,
    TimeOfDayQuiet? quietHoursEnd,
    bool? quietHoursEnabled,
    NotificationPriority? priority,
    bool? showOnLockScreen,
    bool? allowInterruptions,
  }) async {
    final currentPreferences = await getPreferences() ?? NotificationPreferences.defaultPreferences();
    
    final updatedPreferences = currentPreferences.copyWith(
      notificationsEnabled: notificationsEnabled,
      soundEnabled: soundEnabled,
      vibrationEnabled: vibrationEnabled,
      badgeEnabled: badgeEnabled,
      defaultReminderIntervals: defaultReminderIntervals,
      quietHoursStart: quietHoursStart,
      quietHoursEnd: quietHoursEnd,
      quietHoursEnabled: quietHoursEnabled,
      priority: priority,
      showOnLockScreen: showOnLockScreen,
      allowInterruptions: allowInterruptions,
    );
    
    await savePreferences(updatedPreferences);
  }

  /// Reset preferences to defaults
  Future<void> resetToDefaults() async {
    await savePreferences(NotificationPreferences.defaultPreferences());
  }

  /// Check if notifications are currently allowed (considering quiet hours)
  Future<bool> areNotificationsAllowed() async {
    final preferences = await getPreferences();
    if (preferences == null || !preferences.notificationsEnabled) {
      return false;
    }
    
    // Check quiet hours
    if (preferences.quietHoursEnabled && preferences.isQuietTime) {
      return false;
    }
    
    return true;
  }

  /// Get effective notification settings for current time
  Future<EffectiveNotificationSettings> getEffectiveSettings() async {
    final preferences = await getPreferences() ?? NotificationPreferences.defaultPreferences();
    final isQuietTime = preferences.quietHoursEnabled && preferences.isQuietTime;
    
    return EffectiveNotificationSettings(
      shouldShowNotification: preferences.notificationsEnabled && !isQuietTime,
      shouldPlaySound: preferences.soundEnabled && !isQuietTime,
      shouldVibrate: preferences.vibrationEnabled && (!isQuietTime || preferences.allowInterruptions),
      shouldShowBadge: preferences.badgeEnabled,
      priority: isQuietTime ? NotificationPriority.low : preferences.priority,
      showOnLockScreen: preferences.showOnLockScreen,
    );
  }
}

/// Effective notification settings considering current time and quiet hours
class EffectiveNotificationSettings {
  final bool shouldShowNotification;
  final bool shouldPlaySound;
  final bool shouldVibrate;
  final bool shouldShowBadge;
  final NotificationPriority priority;
  final bool showOnLockScreen;

  const EffectiveNotificationSettings({
    required this.shouldShowNotification,
    required this.shouldPlaySound,
    required this.shouldVibrate,
    required this.shouldShowBadge,
    required this.priority,
    required this.showOnLockScreen,
  });
}