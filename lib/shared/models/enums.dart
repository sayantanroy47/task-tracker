/// Task priority levels
enum TaskPriority {
  low,
  medium,
  high,
  urgent,
}

extension TaskPriorityExtension on TaskPriority {
  String get displayName {
    switch (this) {
      case TaskPriority.low:
        return 'Low';
      case TaskPriority.medium:
        return 'Medium';
      case TaskPriority.high:
        return 'High';
      case TaskPriority.urgent:
        return 'Urgent';
    }
  }
  
  int get value {
    switch (this) {
      case TaskPriority.low:
        return 1;
      case TaskPriority.medium:
        return 2;
      case TaskPriority.high:
        return 3;
      case TaskPriority.urgent:
        return 4;
    }
  }
}

/// Task source indicating how the task was created
enum TaskSource {
  manual('manual', 'Manual'),
  voice('voice', 'Voice'),
  chat('chat', 'Chat'),
  calendar('calendar', 'Calendar');

  const TaskSource(this.value, this.label);

  final String value;
  final String label;

  static TaskSource fromValue(String value) {
    return TaskSource.values.firstWhere(
      (source) => source.value == value,
      orElse: () => TaskSource.manual,
    );
  }
}

/// Notification types for reminders
enum NotificationType {
  oneDay('1day', '1 Day Before'),
  twelveHours('12hrs', '12 Hours Before'),
  sixHours('6hrs', '6 Hours Before'),
  oneHour('1hr', '1 Hour Before');

  const NotificationType(this.value, this.label);

  final String value;
  final String label;

  static NotificationType fromValue(String value) {
    return NotificationType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => NotificationType.oneHour,
    );
  }
}

/// Reminder interval enum (used for notification preferences)
enum ReminderInterval {
  oneHour,
  sixHours,
  twelveHours,
  oneDay,
}

extension ReminderIntervalExtension on ReminderInterval {
  String get displayName {
    switch (this) {
      case ReminderInterval.oneHour:
        return '1 hour before';
      case ReminderInterval.sixHours:
        return '6 hours before';
      case ReminderInterval.twelveHours:
        return '12 hours before';
      case ReminderInterval.oneDay:
        return '1 day before';
    }
  }
  
  Duration get duration {
    switch (this) {
      case ReminderInterval.oneHour:
        return const Duration(hours: 1);
      case ReminderInterval.sixHours:
        return const Duration(hours: 6);
      case ReminderInterval.twelveHours:
        return const Duration(hours: 12);
      case ReminderInterval.oneDay:
        return const Duration(days: 1);
    }
  }
}

/// Notification priority levels
enum NotificationPriority {
  low,
  medium,
  high,
  urgent,
}

extension NotificationPriorityExtension on NotificationPriority {
  String get displayName {
    switch (this) {
      case NotificationPriority.low:
        return 'Low';
      case NotificationPriority.medium:
        return 'Medium';
      case NotificationPriority.high:
        return 'High';
      case NotificationPriority.urgent:
        return 'Urgent';
    }
  }
  
  int get value {
    switch (this) {
      case NotificationPriority.low:
        return 1;
      case NotificationPriority.medium:
        return 2;
      case NotificationPriority.high:
        return 3;
      case NotificationPriority.urgent:
        return 4;
    }
  }
  
  /// Get the Android notification importance level
  int get androidImportance {
    switch (this) {
      case NotificationPriority.low:
        return 2; // IMPORTANCE_LOW
      case NotificationPriority.medium:
        return 3; // IMPORTANCE_DEFAULT
      case NotificationPriority.high:
        return 4; // IMPORTANCE_HIGH
      case NotificationPriority.urgent:
        return 5; // IMPORTANCE_MAX
    }
  }
}