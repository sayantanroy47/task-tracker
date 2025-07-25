/// Task priority levels
enum Priority {
  low(1, 'Low'),
  medium(2, 'Medium'),
  high(3, 'High');

  const Priority(this.value, this.label);

  final int value;
  final String label;

  static Priority fromValue(int value) {
    return Priority.values.firstWhere(
      (priority) => priority.value == value,
      orElse: () => Priority.low,
    );
  }
}

/// Task source indicating how the task was created
enum TaskSource {
  manual('manual', 'Manual'),
  voice('voice', 'Voice'),
  chat('chat', 'Chat');

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