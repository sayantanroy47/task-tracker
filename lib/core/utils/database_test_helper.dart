import '../core.dart';
import '../../shared/models/models.dart';
import 'package:flutter/material.dart';

/// Helper class for testing database functionality
class DatabaseTestHelper {
  static final DatabaseService _databaseService = DatabaseService();
  static TaskRepositoryImpl? _taskRepository;
  static CategoryRepositoryImpl? _categoryRepository;
  static NotificationRepositoryImpl? _notificationRepository;

  /// Initialize repositories for testing
  static Future<void> initialize() async {
    _taskRepository = TaskRepositoryImpl(_databaseService);
    _categoryRepository = CategoryRepositoryImpl(_databaseService);
    _notificationRepository = NotificationRepositoryImpl(_databaseService);
  }

  /// Test database initialization and default categories
  static Future<Map<String, dynamic>> testDatabaseInitialization() async {
    try {
      await initialize();

      // Test database exists
      final dbExists = await _databaseService.exists();

      // Test default categories
      final categories = await _categoryRepository!.getAllCategories();
      final systemCategories = categories.where((c) => c.isSystem).toList();

      return {
        'success': true,
        'database_exists': dbExists,
        'total_categories': categories.length,
        'system_categories': systemCategories.length,
        'category_names': systemCategories.map((c) => c.name).toList(),
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Test task CRUD operations
  static Future<Map<String, dynamic>> testTaskOperations() async {
    try {
      await initialize();

      // Get a category to use for testing
      final categories = await _categoryRepository!.getAllCategories();
      if (categories.isEmpty) {
        throw Exception('No categories available for testing');
      }

      final testCategory = categories.first;
      final now = DateTime.now();

      // Create a test task
      final testTask = Task(
        title: 'Test Task',
        description: 'This is a test task created by DatabaseTestHelper',
        categoryId: testCategory.id,
        dueDate: now.add(const Duration(days: 1)),
        dueTime: const TimeOfDay(hour: 14, minute: 30),
        priority: Priority.medium,
        source: TaskSource.manual,
        createdAt: now,
        updatedAt: now,
      );

      // Test create task
      final taskId = await _taskRepository!.createTask(testTask);

      // Test get task by ID
      final retrievedTask = await _taskRepository!.getTaskById(taskId);

      // Test update task
      final updatedTask = retrievedTask!.copyWith(
        title: 'Updated Test Task',
        completed: true,
        updatedAt: DateTime.now(),
      );
      await _taskRepository!.updateTask(updatedTask);

      // Test get all tasks
      final allTasks = await _taskRepository!.getAllTasks();

      // Test search tasks
      final searchResults = await _taskRepository!.searchTasks('Updated');

      // Test delete task
      await _taskRepository!.deleteTask(taskId);

      // Verify deletion
      final deletedTask = await _taskRepository!.getTaskById(taskId);

      return {
        'success': true,
        'task_created': taskId > 0,
        'task_retrieved': retrievedTask.title == 'Test Task',
        'task_updated': true,
        'all_tasks_count': allTasks.length,
        'search_results_count': searchResults.length,
        'task_deleted': deletedTask == null,
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Test notification operations
  static Future<Map<String, dynamic>> testNotificationOperations() async {
    try {
      await initialize();

      // Create a test task first
      final categories = await _categoryRepository!.getAllCategories();
      if (categories.isEmpty) {
        throw Exception('No categories available for testing');
      }

      final testCategory = categories.first;
      final now = DateTime.now();
      final dueDateTime = now.add(const Duration(days: 1));

      final testTask = Task(
        title: 'Test Task for Notifications',
        categoryId: testCategory.id,
        dueDate: dueDateTime,
        dueTime: const TimeOfDay(hour: 14, minute: 30),
        createdAt: now,
        updatedAt: now,
      );

      final taskId = await _taskRepository!.createTask(testTask);

      // Create notifications for the task
      final fullDueDateTime = DateTime(
        dueDateTime.year,
        dueDateTime.month,
        dueDateTime.day,
        14, // hour
        30, // minute
      );

      final notificationIds =
          await _notificationRepository!.createNotificationsForTask(
        taskId,
        fullDueDateTime,
        [NotificationType.oneDay, NotificationType.oneHour],
      );

      // Test get notifications by task
      final taskNotifications =
          await _notificationRepository!.getNotificationsByTask(taskId);

      // Test get all notifications
      final allNotifications =
          await _notificationRepository!.getAllNotifications();

      // Clean up
      await _notificationRepository!.deleteNotificationsByTask(taskId);
      await _taskRepository!.deleteTask(taskId);

      return {
        'success': true,
        'notifications_created': notificationIds.length,
        'task_notifications_count': taskNotifications.length,
        'all_notifications_count': allNotifications.length,
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Run comprehensive database tests
  static Future<Map<String, dynamic>> runAllTests() async {
    final results = <String, dynamic>{};

    // Test database initialization
    final initTest = await testDatabaseInitialization();
    results['initialization'] = initTest;

    if (initTest['success'] == true) {
      // Test task operations
      final taskTest = await testTaskOperations();
      results['task_operations'] = taskTest;

      // Test notification operations
      final notificationTest = await testNotificationOperations();
      results['notification_operations'] = notificationTest;
    }

    return results;
  }

  /// Clean up test data and reset database
  static Future<void> cleanup() async {
    await _databaseService.reset();
  }
}
