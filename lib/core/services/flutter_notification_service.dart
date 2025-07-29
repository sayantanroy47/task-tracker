import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'notification_service.dart';
import 'notification_preferences_service.dart';
import '../../shared/models/notification_preferences.dart';
import '../../shared/models/enums.dart';

/// Flutter Local Notifications implementation of NotificationService
/// Handles cross-platform local notifications for task reminders
class FlutterNotificationService implements NotificationService {
  static final FlutterNotificationService _instance = FlutterNotificationService._internal();
  factory FlutterNotificationService() => _instance;
  FlutterNotificationService._internal();

  late FlutterLocalNotificationsPlugin _notificationsPlugin;
  bool _isInitialized = false;
  NotificationPreferencesService? _preferencesService;

  // Callback functions
  Function(String? payload)? _onNotificationTapCallback;
  Function(String action, String? payload)? _onNotificationActionCallback;

  /// Set the preferences service for accessing user settings
  void setPreferencesService(NotificationPreferencesService service) {
    _preferencesService = service;
  }

  @override
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Initialize timezone data
    tz.initializeTimeZones();
    
    _notificationsPlugin = FlutterLocalNotificationsPlugin();

    // Android initialization
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS initialization with notification categories
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
      requestCriticalPermission: false,
      notificationCategories: [
        DarwinNotificationCategory(
          'task_reminder',
          actions: [
            const DarwinNotificationAction.plain(
              'complete',
              'Complete',
              options: {
                DarwinNotificationActionOption.foreground,
              },
            ),
            const DarwinNotificationAction.plain(
              'snooze',
              'Snooze',
              options: {
                DarwinNotificationActionOption.destructive,
              },
            ),
            const DarwinNotificationAction.plain(
              'reschedule',
              'Reschedule',
              options: {
                DarwinNotificationActionOption.foreground,
              },
            ),
          ],
          options: {
            DarwinNotificationCategoryOption.hiddenPreviewShowTitle,
          },
        ),
      ],
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
    );

    _isInitialized = true;
  }

  /// Handle notification response (tap or action)
  void _onNotificationResponse(NotificationResponse response) {
    final payload = response.payload;
    
    if (response.actionId != null) {
      // Handle action buttons
      _onNotificationActionCallback?.call(response.actionId!, payload);
    } else {
      // Handle tap
      _onNotificationTapCallback?.call(payload);
    }
  }

  @override
  Future<bool> requestPermissions() async {
    if (Platform.isIOS) {
      final result = await _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
      return result ?? false;
    } else if (Platform.isAndroid) {
      final androidImplementation = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      
      if (androidImplementation != null) {
        final result = await androidImplementation.requestNotificationsPermission();
        return result ?? false;
      }
    }
    return true; // Assume granted for other platforms
  }

  @override
  Future<bool> hasPermissions() async {
    if (Platform.isIOS) {
      final result = await _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.checkPermissions();
      return result?.isEnabled ?? false;
    } else if (Platform.isAndroid) {
      final androidImplementation = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      
      if (androidImplementation != null) {
        final result = await androidImplementation.areNotificationsEnabled();
        return result ?? false;
      }
    }
    return true; // Assume granted for other platforms
  }

  @override
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    // Check if notifications are allowed
    if (_preferencesService != null) {
      final isAllowed = await _preferencesService!.areNotificationsAllowed();
      if (!isAllowed) {
        return; // Skip scheduling if notifications are disabled
      }
    }

    await _notificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      await _getNotificationDetails(),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );
  }

  @override
  Future<void> schedulePeriodicNotification({
    required int id,
    required String title,
    required String body,
    required Duration period,
    String? payload,
  }) async {
    // Check if notifications are allowed
    if (_preferencesService != null) {
      final isAllowed = await _preferencesService!.areNotificationsAllowed();
      if (!isAllowed) {
        return; // Skip scheduling if notifications are disabled
      }
    }

    // Convert Duration to RepeatInterval
    RepeatInterval repeatInterval;
    if (period.inDays >= 1) {
      repeatInterval = RepeatInterval.daily;
    } else if (period.inHours >= 1) {
      repeatInterval = RepeatInterval.hourly;
    } else {
      repeatInterval = RepeatInterval.everyMinute;
    }

    await _notificationsPlugin.periodicallyShow(
      id,
      title,
      body,
      repeatInterval,
      await _getNotificationDetails(),
      payload: payload,
    );
  }

  @override
  Future<void> cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id);
  }

  @override
  Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
  }

  @override
  Future<List<PendingNotification>> getPendingNotifications() async {
    final pendingNotifications = await _notificationsPlugin.pendingNotificationRequests();
    
    return pendingNotifications.map((notification) {
      return PendingNotification(
        id: notification.id,
        title: notification.title ?? '',
        body: notification.body ?? '',
        payload: notification.payload,
      );
    }).toList();
  }

  @override
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    // Check if notifications are allowed
    if (_preferencesService != null) {
      final isAllowed = await _preferencesService!.areNotificationsAllowed();
      if (!isAllowed) {
        return; // Skip showing if notifications are disabled
      }
    }

    await _notificationsPlugin.show(
      id,
      title,
      body,
      await _getNotificationDetails(),
      payload: payload,
    );
  }

  @override
  void onNotificationTap(Function(String? payload) callback) {
    _onNotificationTapCallback = callback;
  }

  @override
  void onNotificationAction(Function(String action, String? payload) callback) {
    _onNotificationActionCallback = callback;
  }

  /// Get platform-specific notification details with action buttons
  Future<NotificationDetails> _getNotificationDetails() async {
    // Get effective settings considering preferences and quiet hours
    final effectiveSettings = _preferencesService != null 
        ? await _preferencesService!.getEffectiveSettings()
        : const EffectiveNotificationSettings(
            shouldShowNotification: true,
            shouldPlaySound: true,
            shouldVibrate: true,
            shouldShowBadge: true,
            priority: NotificationPriority.high,
            showOnLockScreen: true,
          );

    // Convert priority to platform-specific values
    final androidImportance = _getAndroidImportance(effectiveSettings.priority);
    final androidPriority = _getAndroidPriority(effectiveSettings.priority);
    final iosInterruptionLevel = _getIosInterruptionLevel(effectiveSettings.priority);

    // Android notification details with action buttons
    final androidDetails = AndroidNotificationDetails(
      'task_reminders',
      'Task Reminders',
      channelDescription: 'Notifications for task reminders and deadlines',
      importance: androidImportance,
      priority: androidPriority,
      enableVibration: effectiveSettings.shouldVibrate,
      playSound: effectiveSettings.shouldPlaySound,
      showWhen: true,
      visibility: effectiveSettings.showOnLockScreen 
          ? NotificationVisibility.public 
          : NotificationVisibility.private,
      actions: const [
        AndroidNotificationAction(
          'complete',
          'Complete',
          titleColor: Color(0xFF4CAF50),
          icon: DrawableResourceAndroidBitmap('@drawable/ic_check'),
        ),
        AndroidNotificationAction(
          'snooze',
          'Snooze',
          titleColor: Color(0xFFFF9800),
          icon: DrawableResourceAndroidBitmap('@drawable/ic_snooze'),
        ),
        AndroidNotificationAction(
          'reschedule',
          'Reschedule',
          titleColor: Color(0xFF2196F3),
        ),
      ],
    );

    // iOS notification details with action buttons
    final iosDetails = DarwinNotificationDetails(
      presentAlert: effectiveSettings.shouldShowNotification,
      presentBadge: effectiveSettings.shouldShowBadge,
      presentSound: effectiveSettings.shouldPlaySound,
      categoryIdentifier: 'task_reminder',
      interruptionLevel: iosInterruptionLevel,
    );

    return NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
  }

  /// Convert notification priority to Android importance
  Importance _getAndroidImportance(NotificationPriority priority) {
    switch (priority) {
      case NotificationPriority.low:
        return Importance.low;
      case NotificationPriority.medium:
        return Importance.defaultImportance;
      case NotificationPriority.high:
        return Importance.high;
      case NotificationPriority.urgent:
        return Importance.max;
    }
  }

  /// Convert notification priority to Android priority
  Priority _getAndroidPriority(NotificationPriority priority) {
    switch (priority) {
      case NotificationPriority.low:
        return Priority.low;
      case NotificationPriority.medium:
        return Priority.defaultPriority;
      case NotificationPriority.high:
        return Priority.high;
      case NotificationPriority.urgent:
        return Priority.max;
    }
  }

  /// Convert notification priority to iOS interruption level
  InterruptionLevel _getIosInterruptionLevel(NotificationPriority priority) {
    switch (priority) {
      case NotificationPriority.low:
        return InterruptionLevel.passive;
      case NotificationPriority.medium:
        return InterruptionLevel.active;
      case NotificationPriority.high:
        return InterruptionLevel.timeSensitive;
      case NotificationPriority.urgent:
        return InterruptionLevel.critical;
    }
  }

  /// Schedule task reminder notifications based on reminder intervals
  Future<void> scheduleTaskReminders({
    required String taskId,
    required String title,
    required DateTime dueDateTime,
    required List<Duration> reminderIntervals,
  }) async {
    // Cancel existing notifications for this task
    await cancelTaskNotifications(taskId);

    for (int i = 0; i < reminderIntervals.length; i++) {
      final reminderTime = dueDateTime.subtract(reminderIntervals[i]);
      
      // Only schedule if reminder time is in the future
      if (reminderTime.isAfter(DateTime.now())) {
        final notificationId = _generateNotificationId(taskId, i);
        
        final payload = jsonEncode({
          'taskId': taskId,
          'action': 'reminder',
          'intervalIndex': i,
        });

        final intervalText = _formatInterval(reminderIntervals[i]);
        
        await scheduleNotification(
          id: notificationId,
          title: 'Task Reminder: $title',
          body: 'Due in $intervalText',
          scheduledDate: reminderTime,
          payload: payload,
        );
      }
    }
  }

  /// Cancel all notifications for a specific task
  Future<void> cancelTaskNotifications(String taskId) async {
    final pendingNotifications = await getPendingNotifications();
    
    for (final notification in pendingNotifications) {
      if (notification.payload != null) {
        try {
          final payloadData = jsonDecode(notification.payload!);
          if (payloadData['taskId'] == taskId) {
            await cancelNotification(notification.id);
          }
        } catch (e) {
          // Ignore malformed payload
        }
      }
    }
  }

  /// Generate unique notification ID for task and interval
  int _generateNotificationId(String taskId, int intervalIndex) {
    // Use hash of taskId + intervalIndex to generate unique ID
    final combined = '$taskId-$intervalIndex';
    return combined.hashCode.abs() % 2147483647; // Keep within int32 range
  }

  /// Format duration for display
  String _formatInterval(Duration duration) {
    if (duration.inDays > 0) {
      return '${duration.inDays} day${duration.inDays > 1 ? 's' : ''}';
    } else if (duration.inHours > 0) {
      return '${duration.inHours} hour${duration.inHours > 1 ? 's' : ''}';
    } else {
      return '${duration.inMinutes} minute${duration.inMinutes > 1 ? 's' : ''}';
    }
  }
}