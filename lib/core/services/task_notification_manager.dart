import 'dart:convert';
import '../repositories/repositories.dart';
import '../../shared/models/models.dart';
import 'notification_service.dart';

/// Task notification manager that handles scheduling and managing task reminders
/// Integrates with NotificationService and TaskRepository for complete reminder management
class TaskNotificationManager {
  final NotificationService _notificationService;
  final TaskRepository _taskRepository;
  final NotificationRepository _notificationRepository;

  TaskNotificationManager({
    required NotificationService notificationService,
    required TaskRepository taskRepository,
    required NotificationRepository notificationRepository,
  })  : _notificationService = notificationService,
        _taskRepository = taskRepository,
        _notificationRepository = notificationRepository;

  /// Schedule all reminders for a task based on its reminder intervals
  Future<void> scheduleTaskReminders(Task task) async {
    if (!task.hasReminder || task.reminderIntervals.isEmpty || task.dueDate == null) {
      return;
    }

    // Cancel existing notifications for this task
    await cancelTaskReminders(task.id);

    // Calculate due date time
    final dueDateTime = task.dueTime != null
        ? DateTime(
            task.dueDate!.year,
            task.dueDate!.month,
            task.dueDate!.day,
            task.dueTime!.hour,
            task.dueTime!.minute,
          )
        : DateTime(
            task.dueDate!.year,
            task.dueDate!.month,
            task.dueDate!.day,
            9, // Default to 9 AM if no time specified
            0,
          );

    // Schedule notifications for each reminder interval
    for (int i = 0; i < task.reminderIntervals.length; i++) {
      final interval = task.reminderIntervals[i];
      final reminderTime = dueDateTime.subtract(interval.duration);

      // Only schedule if reminder time is in the future
      if (reminderTime.isAfter(DateTime.now())) {
        await _scheduleTaskReminder(
          task: task,
          reminderTime: reminderTime,
          interval: interval,
          intervalIndex: i,
        );
      }
    }
  }

  /// Schedule a single reminder for a task
  Future<void> _scheduleTaskReminder({
    required Task task,
    required DateTime reminderTime,
    required ReminderInterval interval,
    required int intervalIndex,
  }) async {
    final notificationId = _generateNotificationId(task.id, intervalIndex);

    // Create notification payload
    final payload = jsonEncode({
      'taskId': task.id,
      'action': 'reminder',
      'intervalIndex': intervalIndex,
      'dueDate': task.dueDate?.toIso8601String(),
      'dueTime': task.dueTime?.toIso8601String(),
    });

    // Create notification title and body
    final title = 'Task Reminder: ${task.title}';
    final body = _createReminderBody(task, interval);

    // Schedule the notification
    await _notificationService.scheduleNotification(
      id: notificationId,
      title: title,
      body: body,
      scheduledDate: reminderTime,
      payload: payload,
    );

    // Store notification in database
    final notification = TaskNotification(
      taskId: int.parse(task.id.hashCode.toString().substring(0, 8)),
      scheduledTime: reminderTime,
      type: _intervalToNotificationType(interval),
      createdAt: DateTime.now(),
    );

    await _notificationRepository.insertNotification(notification);
  }

  /// Create reminder notification body text
  String _createReminderBody(Task task, ReminderInterval interval) {
    final timeText = interval.displayName;
    
    if (task.dueTime != null) {
      final dueText = task.dueDateTimeDisplay;
      return 'Due $dueText ($timeText)';
    } else {
      final dueText = task.isDueToday 
          ? 'today' 
          : task.isDueTomorrow 
              ? 'tomorrow' 
              : task.dueDateTimeDisplay;
      return 'Due $dueText ($timeText)';
    }
  }

  /// Cancel all reminders for a specific task
  Future<void> cancelTaskReminders(String taskId) async {
    // Get all pending notifications
    final pendingNotifications = await _notificationService.getPendingNotifications();

    // Cancel notifications that belong to this task
    for (final notification in pendingNotifications) {
      if (notification.payload != null) {
        try {
          final payloadData = jsonDecode(notification.payload!);
          if (payloadData['taskId'] == taskId) {
            await _notificationService.cancelNotification(notification.id);
          }
        } catch (e) {
          // Ignore malformed payload
        }
      }
    }

    // Remove from database
    await _notificationRepository.deleteNotificationsByTaskId(
      int.parse(taskId.hashCode.toString().substring(0, 8))
    );
  }

  /// Reschedule all reminders when task is updated
  Future<void> rescheduleTaskReminders(Task task) async {
    await scheduleTaskReminders(task);
  }

  /// Handle notification actions (Complete, Snooze, Reschedule)
  Future<void> handleNotificationAction(String action, String? payload) async {
    if (payload == null) return;

    try {
      final payloadData = jsonDecode(payload);
      final taskId = payloadData['taskId'] as String?;
      
      if (taskId == null) return;

      switch (action) {
        case 'complete':
          await _completeTaskFromNotification(taskId);
          break;
        case 'snooze':
          await _snoozeTaskReminder(taskId, payloadData);
          break;
        case 'reschedule':
          await _rescheduleTaskFromNotification(taskId);
          break;
      }
    } catch (e) {
      // Handle error silently - notification action failed
    }
  }

  /// Complete task from notification action
  Future<void> _completeTaskFromNotification(String taskId) async {
    final task = await _taskRepository.getTaskById(taskId);
    if (task != null) {
      final completedTask = task.complete();
      await _taskRepository.updateTask(completedTask);
      await cancelTaskReminders(taskId);
    }
  }

  /// Snooze task reminder (reschedule for 10 minutes later)
  Future<void> _snoozeTaskReminder(String taskId, Map<String, dynamic> payloadData) async {
    final snoozeTime = DateTime.now().add(const Duration(minutes: 10));
    final intervalIndex = payloadData['intervalIndex'] as int? ?? 0;
    
    final task = await _taskRepository.getTaskById(taskId);
    if (task != null) {
      final notificationId = _generateNotificationId(taskId, intervalIndex);
      
      // Cancel current notification
      await _notificationService.cancelNotification(notificationId);
      
      // Schedule snoozed notification
      final payload = jsonEncode({
        'taskId': taskId,
        'action': 'reminder',
        'intervalIndex': intervalIndex,
        'snoozed': true,
      });

      await _notificationService.scheduleNotification(
        id: notificationId,
        title: 'Snoozed Reminder: ${task.title}',
        body: 'Task reminder snoozed for 10 minutes',
        scheduledDate: snoozeTime,
        payload: payload,
      );
    }
  }

  /// Open app to reschedule task from notification action
  Future<void> _rescheduleTaskFromNotification(String taskId) async {
    // This would typically open the app and navigate to task edit screen
    // For now, we'll just cancel the notification and let the app handle it
    await cancelTaskReminders(taskId);
  }

  /// Generate unique notification ID for task and interval
  int _generateNotificationId(String taskId, int intervalIndex) {
    final combined = '$taskId-$intervalIndex';
    return combined.hashCode.abs() % 2147483647; // Keep within int32 range
  }

  /// Convert ReminderInterval to NotificationType
  NotificationType _intervalToNotificationType(ReminderInterval interval) {
    switch (interval) {
      case ReminderInterval.oneHour:
        return NotificationType.oneHour;
      case ReminderInterval.sixHours:
        return NotificationType.sixHours;
      case ReminderInterval.twelveHours:
        return NotificationType.twelveHours;
      case ReminderInterval.oneDay:
        return NotificationType.oneDay;
    }
  }

  /// Update reminder preferences for a task
  Future<void> updateTaskReminderPreferences({
    required String taskId,
    required bool hasReminder,
    required List<ReminderInterval> reminderIntervals,
  }) async {
    final task = await _taskRepository.getTaskById(taskId);
    if (task != null) {
      final updatedTask = task.copyWith(
        hasReminder: hasReminder,
        reminderIntervals: reminderIntervals,
      );
      
      await _taskRepository.updateTask(updatedTask);
      
      if (hasReminder) {
        await scheduleTaskReminders(updatedTask);
      } else {
        await cancelTaskReminders(taskId);
      }
    }
  }

  /// Check and send any overdue notifications
  Future<void> checkOverdueNotifications() async {
    final allNotifications = await _notificationRepository.getAllNotifications();
    
    for (final notification in allNotifications) {
      if (notification.shouldSend && !notification.sent) {
        // Try to get the task
        final task = await _taskRepository.getTaskById(notification.taskId.toString());
        
        if (task != null && !task.isCompleted) {
          // Send immediate notification for overdue reminder
          await _notificationService.showNotification(
            id: notification.id ?? DateTime.now().millisecondsSinceEpoch,
            title: 'Overdue Task: ${task.title}',
            body: 'This task was due and needs your attention',
            payload: jsonEncode({
              'taskId': task.id,
              'action': 'overdue',
            }),
          );
          
          // Mark as sent
          final sentNotification = notification.copyWith(sent: true);
          await _notificationRepository.updateNotification(sentNotification);
        }
      }
    }
  }

  /// Initialize notification action handlers
  void initializeActionHandlers() {
    _notificationService.onNotificationAction(handleNotificationAction);
  }
}