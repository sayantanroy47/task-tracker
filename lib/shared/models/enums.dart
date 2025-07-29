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