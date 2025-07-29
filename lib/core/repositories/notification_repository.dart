import '../../shared/models/models.dart';

/// Abstract repository interface for notification operations
abstract class NotificationRepository {
  /// Get all notifications
  Future<List<TaskNotification>> getAllNotifications();

  /// Get notifications for a specific task
  Future<List<TaskNotification>> getNotificationsByTask(int taskId);

  /// Get pending notifications (not sent yet)
  Future<List<TaskNotification>> getPendingNotifications();

  /// Get notifications scheduled for a specific date/time range
  Future<List<TaskNotification>> getNotificationsByTimeRange(
    DateTime startTime,
    DateTime endTime,
  );

  /// Get overdue notifications (should have been sent but weren't)
  Future<List<TaskNotification>> getOverdueNotifications();

  /// Get notification by ID
  Future<TaskNotification?> getNotificationById(int id);

  /// Create a new notification
  Future<int> createNotification(TaskNotification notification);

  /// Insert a new notification (alias for createNotification)
  Future<int> insertNotification(TaskNotification notification);

  /// Create multiple notifications for a task
  Future<List<int>> createNotificationsForTask(
    int taskId,
    DateTime taskDueDateTime,
    List<NotificationType> types,
  );

  /// Update an existing notification
  Future<void> updateNotification(TaskNotification notification);

  /// Mark notification as sent
  Future<void> markNotificationSent(int id);

  /// Delete a notification
  Future<void> deleteNotification(int id);

  /// Delete all notifications for a task
  Future<void> deleteNotificationsByTask(int taskId);

  /// Delete all notifications for a task by task ID (alias)
  Future<void> deleteNotificationsByTaskId(int taskId);

  /// Bulk delete notifications
  Future<void> bulkDeleteNotifications(List<int> notificationIds);

  /// Clean up old sent notifications
  Future<void> cleanupOldNotifications({Duration? olderThan});

  /// Get notification statistics
  Future<Map<String, int>> getNotificationStatistics();

  /// Watch pending notifications (stream)
  Stream<List<TaskNotification>> watchPendingNotifications();

  /// Watch notifications for a specific task (stream)
  Stream<List<TaskNotification>> watchNotificationsByTask(int taskId);
}