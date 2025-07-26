import 'package:flutter/material.dart';
import 'enums.dart';

/// Notification model for managing task reminders
@immutable
class TaskNotification {
  final int? id;
  final int taskId;
  final DateTime scheduledTime;
  final NotificationType type;
  final bool sent;
  final DateTime createdAt;

  const TaskNotification({
    this.id,
    required this.taskId,
    required this.scheduledTime,
    required this.type,
    this.sent = false,
    required this.createdAt,
  });

  /// Create a copy of this notification with optional field updates
  TaskNotification copyWith({
    int? id,
    int? taskId,
    DateTime? scheduledTime,
    NotificationType? type,
    bool? sent,
    DateTime? createdAt,
  }) {
    return TaskNotification(
      id: id ?? this.id,
      taskId: taskId ?? this.taskId,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      type: type ?? this.type,
      sent: sent ?? this.sent,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Convert notification to JSON map for database storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'task_id': taskId,
      'scheduled_time': scheduledTime.toIso8601String(),
      'type': type.value,
      'sent': sent ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Create notification from JSON map from database
  factory TaskNotification.fromJson(Map<String, dynamic> json) {
    return TaskNotification(
      id: json['id'] as int?,
      taskId: json['task_id'] as int,
      scheduledTime: DateTime.parse(json['scheduled_time'] as String),
      type: NotificationType.fromValue(json['type'] as String),
      sent: (json['sent'] as int) == 1,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  /// Calculate scheduled time based on task due date and notification type
  static DateTime calculateScheduledTime(DateTime taskDueDateTime, NotificationType type) {
    switch (type) {
      case NotificationType.oneDay:
        return taskDueDateTime.subtract(const Duration(days: 1));
      case NotificationType.twelveHours:
        return taskDueDateTime.subtract(const Duration(hours: 12));
      case NotificationType.sixHours:
        return taskDueDateTime.subtract(const Duration(hours: 6));
      case NotificationType.oneHour:
        return taskDueDateTime.subtract(const Duration(hours: 1));
    }
  }

  /// Check if notification should be sent now
  bool get shouldSend {
    if (sent) return false;
    final now = DateTime.now();
    return scheduledTime.isBefore(now) || scheduledTime.isAtSameMomentAs(now);
  }

  /// Check if notification is overdue (should have been sent but wasn't)
  bool get isOverdue {
    if (sent) return false;
    final now = DateTime.now();
    return scheduledTime.isBefore(now.subtract(const Duration(minutes: 5)));
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TaskNotification &&
        other.id == id &&
        other.taskId == taskId &&
        other.scheduledTime == scheduledTime &&
        other.type == type &&
        other.sent == sent &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      taskId,
      scheduledTime,
      type,
      sent,
      createdAt,
    );
  }

  @override
  String toString() {
    return 'TaskNotification{id: $id, taskId: $taskId, scheduledTime: $scheduledTime, type: $type, sent: $sent, createdAt: $createdAt}';
  }
}