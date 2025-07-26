/// Notification service interface for managing local notifications
/// Handles scheduling, displaying, and managing task reminders
abstract class NotificationService {
  /// Initialize the notification service with platform-specific settings
  Future<void> initialize();
  
  /// Request notification permissions from the user
  Future<bool> requestPermissions();
  
  /// Check if notification permissions are granted
  Future<bool> hasPermissions();
  
  /// Schedule a notification for a specific date and time
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  });
  
  /// Schedule periodic notifications (daily, hourly, etc.)
  Future<void> schedulePeriodicNotification({
    required int id,
    required String title,
    required String body,
    required Duration period,
    String? payload,
  });
  
  /// Cancel a specific notification by ID
  Future<void> cancelNotification(int id);
  
  /// Cancel all scheduled notifications
  Future<void> cancelAllNotifications();
  
  /// Get all pending notifications
  Future<List<PendingNotification>> getPendingNotifications();
  
  /// Show an immediate notification
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  });
  
  /// Handle notification tap events
  void onNotificationTap(Function(String? payload) callback);
  
  /// Handle notification actions (complete, snooze, etc.)
  void onNotificationAction(Function(String action, String? payload) callback);
}

/// Represents a pending notification
class PendingNotification {
  final int id;
  final String title;
  final String body;
  final DateTime? scheduledDate;
  final String? payload;
  
  const PendingNotification({
    required this.id,
    required this.title,
    required this.body,
    this.scheduledDate,
    this.payload,
  });
}