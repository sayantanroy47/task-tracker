import 'dart:async';
import 'package:sqflite/sqflite.dart';
import '../../../shared/models/models.dart';
import '../notification_repository.dart';
import '../../services/database_service.dart';

/// Concrete implementation of NotificationRepository using SQLite
class NotificationRepositoryImpl implements NotificationRepository {
  final DatabaseService _databaseService;
  final StreamController<List<TaskNotification>> _notificationStreamController = StreamController<List<TaskNotification>>.broadcast();

  NotificationRepositoryImpl(this._databaseService);

  Future<Database> get _database => _databaseService.database;

  @override
  Future<List<TaskNotification>> getAllNotifications() async {
    final db = await _database;
    final List<Map<String, dynamic>> maps = await db.query(
      'notifications',
      orderBy: 'scheduled_time ASC',
    );
    return maps.map((map) => TaskNotification.fromJson(map)).toList();
  }

  @override
  Future<List<TaskNotification>> getNotificationsByTask(int taskId) async {
    final db = await _database;
    final List<Map<String, dynamic>> maps = await db.query(
      'notifications',
      where: 'task_id = ?',
      whereArgs: [taskId],
      orderBy: 'scheduled_time ASC',
    );
    return maps.map((map) => TaskNotification.fromJson(map)).toList();
  }

  @override
  Future<List<TaskNotification>> getPendingNotifications() async {
    final db = await _database;
    final List<Map<String, dynamic>> maps = await db.query(
      'notifications',
      where: 'sent = ?',
      whereArgs: [0],
      orderBy: 'scheduled_time ASC',
    );
    return maps.map((map) => TaskNotification.fromJson(map)).toList();
  }

  @override
  Future<List<TaskNotification>> getNotificationsByTimeRange(
    DateTime startTime,
    DateTime endTime,
  ) async {
    final db = await _database;
    final List<Map<String, dynamic>> maps = await db.query(
      'notifications',
      where: 'scheduled_time >= ? AND scheduled_time <= ?',
      whereArgs: [startTime.toIso8601String(), endTime.toIso8601String()],
      orderBy: 'scheduled_time ASC',
    );
    return maps.map((map) => TaskNotification.fromJson(map)).toList();
  }

  @override
  Future<List<TaskNotification>> getOverdueNotifications() async {
    final db = await _database;
    final fiveMinutesAgo = DateTime.now().subtract(const Duration(minutes: 5));
    final List<Map<String, dynamic>> maps = await db.query(
      'notifications',
      where: 'sent = ? AND scheduled_time < ?',
      whereArgs: [0, fiveMinutesAgo.toIso8601String()],
      orderBy: 'scheduled_time ASC',
    );
    return maps.map((map) => TaskNotification.fromJson(map)).toList();
  }

  @override
  Future<TaskNotification?> getNotificationById(int id) async {
    final db = await _database;
    final List<Map<String, dynamic>> maps = await db.query(
      'notifications',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return TaskNotification.fromJson(maps.first);
  }

  @override
  Future<int> createNotification(TaskNotification notification) async {
    final db = await _database;
    final notificationData = notification.toJson();
    notificationData.remove('id'); // Remove id for auto-increment
    
    final id = await db.insert('notifications', notificationData);
    _notifyNotificationsChanged();
    return id;
  }

  @override
  Future<int> insertNotification(TaskNotification notification) async {
    return createNotification(notification);
  }

  @override
  Future<List<int>> createNotificationsForTask(
    int taskId,
    DateTime taskDueDateTime,
    List<NotificationType> types,
  ) async {
    final notifications = <TaskNotification>[];
    final now = DateTime.now();
    
    for (final type in types) {
      final scheduledTime = TaskNotification.calculateScheduledTime(taskDueDateTime, type);
      
      // Only create notification if scheduled time is in the future
      if (scheduledTime.isAfter(now)) {
        notifications.add(TaskNotification(
          taskId: taskId,
          scheduledTime: scheduledTime,
          type: type,
          createdAt: now,
        ));
      }
    }
    
    final ids = <int>[];
    for (final notification in notifications) {
      final id = await createNotification(notification);
      ids.add(id);
    }
    
    return ids;
  }

  @override
  Future<void> updateNotification(TaskNotification notification) async {
    final db = await _database;
    final notificationData = notification.toJson();
    
    await db.update(
      'notifications',
      notificationData,
      where: 'id = ?',
      whereArgs: [notification.id],
    );
    _notifyNotificationsChanged();
  }

  @override
  Future<void> markNotificationSent(int id) async {
    final notification = await getNotificationById(id);
    if (notification != null && !notification.sent) {
      final updatedNotification = notification.copyWith(sent: true);
      await updateNotification(updatedNotification);
    }
  }

  @override
  Future<void> deleteNotification(int id) async {
    final db = await _database;
    await db.delete(
      'notifications',
      where: 'id = ?',
      whereArgs: [id],
    );
    _notifyNotificationsChanged();
  }

  @override
  Future<void> deleteNotificationsByTask(int taskId) async {
    final db = await _database;
    await db.delete(
      'notifications',
      where: 'task_id = ?',
      whereArgs: [taskId],
    );
    _notifyNotificationsChanged();
  }

  @override
  Future<void> deleteNotificationsByTaskId(int taskId) async {
    return deleteNotificationsByTask(taskId);
  }

  @override
  Future<void> bulkDeleteNotifications(List<int> notificationIds) async {
    final db = await _database;
    final batch = db.batch();
    
    for (final id in notificationIds) {
      batch.delete(
        'notifications',
        where: 'id = ?',
        whereArgs: [id],
      );
    }
    
    await batch.commit();
    _notifyNotificationsChanged();
  }

  @override
  Future<void> cleanupOldNotifications({Duration? olderThan}) async {
    final db = await _database;
    final cutoffTime = DateTime.now().subtract(olderThan ?? const Duration(days: 30));
    
    await db.delete(
      'notifications',
      where: 'sent = ? AND scheduled_time < ?',
      whereArgs: [1, cutoffTime.toIso8601String()],
    );
    _notifyNotificationsChanged();
  }

  @override
  Future<Map<String, int>> getNotificationStatistics() async {
    final db = await _database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT 
        COUNT(*) as total_notifications,
        SUM(CASE WHEN sent = 1 THEN 1 ELSE 0 END) as sent_notifications,
        SUM(CASE WHEN sent = 0 THEN 1 ELSE 0 END) as pending_notifications,
        SUM(CASE WHEN type = '1day' THEN 1 ELSE 0 END) as one_day_notifications,
        SUM(CASE WHEN type = '12hrs' THEN 1 ELSE 0 END) as twelve_hour_notifications,
        SUM(CASE WHEN type = '6hrs' THEN 1 ELSE 0 END) as six_hour_notifications,
        SUM(CASE WHEN type = '1hr' THEN 1 ELSE 0 END) as one_hour_notifications
      FROM notifications
    ''');
    
    final result = maps.first;
    return {
      'total': result['total_notifications'] as int,
      'sent': result['sent_notifications'] as int,
      'pending': result['pending_notifications'] as int,
      'one_day': result['one_day_notifications'] as int,
      'twelve_hour': result['twelve_hour_notifications'] as int,
      'six_hour': result['six_hour_notifications'] as int,
      'one_hour': result['one_hour_notifications'] as int,
    };
  }

  @override
  Stream<List<TaskNotification>> watchPendingNotifications() {
    // Initial load
    getPendingNotifications().then((notifications) => _notificationStreamController.add(notifications));
    return _notificationStreamController.stream;
  }

  @override
  Stream<List<TaskNotification>> watchNotificationsByTask(int taskId) {
    return watchPendingNotifications().asyncMap((_) => getNotificationsByTask(taskId));
  }

  void _notifyNotificationsChanged() {
    getPendingNotifications().then((notifications) => _notificationStreamController.add(notifications));
  }

  void dispose() {
    _notificationStreamController.close();
  }
}