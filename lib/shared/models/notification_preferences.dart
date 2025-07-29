import 'enums.dart';

/// Notification preferences model for user settings
class NotificationPreferences {
  final bool notificationsEnabled;
  final bool soundEnabled;
  final bool vibrationEnabled;
  final bool badgeEnabled;
  final List<ReminderInterval> defaultReminderIntervals;
  final TimeOfDayQuiet? quietHoursStart;
  final TimeOfDayQuiet? quietHoursEnd;
  final bool quietHoursEnabled;
  final NotificationPriority priority;
  final bool showOnLockScreen;
  final bool allowInterruptions;

  const NotificationPreferences({
    this.notificationsEnabled = true,
    this.soundEnabled = true,
    this.vibrationEnabled = true,
    this.badgeEnabled = true,
    this.defaultReminderIntervals = const [ReminderInterval.oneHour],
    this.quietHoursStart,
    this.quietHoursEnd,
    this.quietHoursEnabled = false,
    this.priority = NotificationPriority.high,
    this.showOnLockScreen = true,
    this.allowInterruptions = true,
  });

  /// Default notification preferences
  factory NotificationPreferences.defaultPreferences() {
    return const NotificationPreferences(
      notificationsEnabled: true,
      soundEnabled: true,
      vibrationEnabled: true,
      badgeEnabled: true,
      defaultReminderIntervals: [ReminderInterval.oneHour],
      quietHoursEnabled: false,
      priority: NotificationPriority.high,
      showOnLockScreen: true,
      allowInterruptions: true,
    );
  }

  /// Create copy with updated fields
  NotificationPreferences copyWith({
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
  }) {
    return NotificationPreferences(
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      badgeEnabled: badgeEnabled ?? this.badgeEnabled,
      defaultReminderIntervals: defaultReminderIntervals ?? this.defaultReminderIntervals,
      quietHoursStart: quietHoursStart ?? this.quietHoursStart,
      quietHoursEnd: quietHoursEnd ?? this.quietHoursEnd,
      quietHoursEnabled: quietHoursEnabled ?? this.quietHoursEnabled,
      priority: priority ?? this.priority,
      showOnLockScreen: showOnLockScreen ?? this.showOnLockScreen,
      allowInterruptions: allowInterruptions ?? this.allowInterruptions,
    );
  }

  /// Check if notifications should be quiet at current time
  bool get isQuietTime {
    if (!quietHoursEnabled || quietHoursStart == null || quietHoursEnd == null) {
      return false;
    }

    final now = DateTime.now();
    final currentTime = TimeOfDayQuiet(hour: now.hour, minute: now.minute);
    
    // Handle same day quiet hours (e.g., 22:00 - 06:00)
    if (quietHoursStart!.isBefore(quietHoursEnd!)) {
      return currentTime.isAfter(quietHoursStart!) && currentTime.isBefore(quietHoursEnd!);
    } else {
      // Handle overnight quiet hours (e.g., 22:00 - 06:00)
      return currentTime.isAfter(quietHoursStart!) || currentTime.isBefore(quietHoursEnd!);
    }
  }

  /// Convert to Map for storage
  Map<String, dynamic> toMap() {
    return {
      'notificationsEnabled': notificationsEnabled,
      'soundEnabled': soundEnabled,
      'vibrationEnabled': vibrationEnabled,
      'badgeEnabled': badgeEnabled,
      'defaultReminderIntervals': defaultReminderIntervals.map((e) => e.name).toList(),
      'quietHoursStart': quietHoursStart?.toMap(),
      'quietHoursEnd': quietHoursEnd?.toMap(),
      'quietHoursEnabled': quietHoursEnabled,
      'priority': priority.name,
      'showOnLockScreen': showOnLockScreen,
      'allowInterruptions': allowInterruptions,
    };
  }

  /// Create from Map
  factory NotificationPreferences.fromMap(Map<String, dynamic> map) {
    return NotificationPreferences(
      notificationsEnabled: map['notificationsEnabled'] ?? true,
      soundEnabled: map['soundEnabled'] ?? true,
      vibrationEnabled: map['vibrationEnabled'] ?? true,
      badgeEnabled: map['badgeEnabled'] ?? true,
      defaultReminderIntervals: (map['defaultReminderIntervals'] as List<dynamic>?)
          ?.map((e) => ReminderInterval.values.firstWhere(
                (interval) => interval.name == e,
                orElse: () => ReminderInterval.oneHour,
              ))
          .toList() ?? [ReminderInterval.oneHour],
      quietHoursStart: map['quietHoursStart'] != null 
          ? TimeOfDayQuiet.fromMap(map['quietHoursStart'])
          : null,
      quietHoursEnd: map['quietHoursEnd'] != null 
          ? TimeOfDayQuiet.fromMap(map['quietHoursEnd'])
          : null,
      quietHoursEnabled: map['quietHoursEnabled'] ?? false,
      priority: NotificationPriority.values.firstWhere(
        (p) => p.name == map['priority'],
        orElse: () => NotificationPriority.high,
      ),
      showOnLockScreen: map['showOnLockScreen'] ?? true,
      allowInterruptions: map['allowInterruptions'] ?? true,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NotificationPreferences &&
          runtimeType == other.runtimeType &&
          notificationsEnabled == other.notificationsEnabled &&
          soundEnabled == other.soundEnabled &&
          vibrationEnabled == other.vibrationEnabled &&
          badgeEnabled == other.badgeEnabled &&
          quietHoursEnabled == other.quietHoursEnabled &&
          priority == other.priority;

  @override
  int get hashCode => Object.hash(
        notificationsEnabled,
        soundEnabled,
        vibrationEnabled,
        badgeEnabled,
        quietHoursEnabled,
        priority,
      );
}

/// Time of day representation for quiet hours
class TimeOfDayQuiet {
  final int hour;
  final int minute;

  const TimeOfDayQuiet({
    required this.hour,
    required this.minute,
  });

  /// Check if this time is after another time
  bool isAfter(TimeOfDayQuiet other) {
    if (hour > other.hour) return true;
    if (hour == other.hour && minute > other.minute) return true;
    return false;
  }

  /// Check if this time is before another time
  bool isBefore(TimeOfDayQuiet other) {
    if (hour < other.hour) return true;
    if (hour == other.hour && minute < other.minute) return true;
    return false;
  }

  /// Convert to display string
  String toDisplayString() {
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    final minuteStr = minute.toString().padLeft(2, '0');
    return '$displayHour:$minuteStr $period';
  }

  /// Convert to Map for storage
  Map<String, dynamic> toMap() {
    return {
      'hour': hour,
      'minute': minute,
    };
  }

  /// Create from Map
  factory TimeOfDayQuiet.fromMap(Map<String, dynamic> map) {
    return TimeOfDayQuiet(
      hour: map['hour'] ?? 0,
      minute: map['minute'] ?? 0,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TimeOfDayQuiet &&
          runtimeType == other.runtimeType &&
          hour == other.hour &&
          minute == other.minute;

  @override
  int get hashCode => Object.hash(hour, minute);
}