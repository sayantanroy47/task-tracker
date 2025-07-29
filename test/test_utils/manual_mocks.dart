import 'dart:async';
import 'package:task_tracker_app/core/repositories/repositories.dart';
import 'package:task_tracker_app/core/services/services.dart';
import 'package:task_tracker_app/shared/models/models.dart';

/// Manual mock implementations for testing
/// Used instead of generated mocks for simpler setup

class MockTaskRepository implements TaskRepository {
  final List<Task> _tasks = [];
  final StreamController<List<Task>> _controller = StreamController<List<Task>>.broadcast();
  int _nextId = 1;

  @override
  Future<List<Task>> getAllTasks() async => List.from(_tasks);

  @override
  Future<List<Task>> getTasksByCategory(int categoryId) async =>
      _tasks.where((task) => task.categoryId == categoryId.toString()).toList();

  @override
  Future<List<Task>> getTasksByDate(DateTime date) async =>
      _tasks.where((task) => 
          task.dueDate != null &&
          task.dueDate!.year == date.year &&
          task.dueDate!.month == date.month &&
          task.dueDate!.day == date.day).toList();

  @override
  Future<List<Task>> getTasksByDateRange(DateTime startDate, DateTime endDate) async =>
      _tasks.where((task) => 
          task.dueDate != null &&
          !task.dueDate!.isBefore(startDate) &&
          !task.dueDate!.isAfter(endDate)).toList();

  @override
  Future<List<Task>> getCompletedTasks() async =>
      _tasks.where((task) => task.isCompleted).toList();

  @override
  Future<List<Task>> getPendingTasks() async =>
      _tasks.where((task) => !task.isCompleted).toList();

  @override
  Future<List<Task>> getOverdueTasks() async =>
      _tasks.where((task) => task.isOverdue).toList();

  @override
  Future<Task?> getTaskById(int id) async {
    try {
      return _tasks.firstWhere((task) => task.id == id.toString());
    } catch (e) {
      return null;
    }
  }

  @override
  Future<List<Task>> searchTasks(String query) async =>
      _tasks.where((task) => 
          task.title.toLowerCase().contains(query.toLowerCase()) ||
          (task.description?.toLowerCase().contains(query.toLowerCase()) ?? false)).toList();

  @override
  Future<int> createTask(Task task) async {
    final newTask = task.copyWith(id: _nextId.toString());
    _tasks.add(newTask);
    _controller.add(List.from(_tasks));
    return _nextId++;
  }

  @override
  Future<void> updateTask(Task task) async {
    final index = _tasks.indexWhere((t) => t.id == task.id);
    if (index != -1) {
      _tasks[index] = task;
      _controller.add(List.from(_tasks));
    }
  }

  @override
  Future<void> deleteTask(int id) async {
    _tasks.removeWhere((task) => task.id == id.toString());
    _controller.add(List.from(_tasks));
  }

  @override
  Future<void> toggleTaskCompletion(int id) async {
    final task = await getTaskById(id);
    if (task != null) {
      await updateTask(task.copyWith(isCompleted: !task.isCompleted));
    }
  }

  @override
  Future<void> markTaskCompleted(int id) async {
    final task = await getTaskById(id);
    if (task != null && !task.isCompleted) {
      await updateTask(task.copyWith(isCompleted: true));
    }
  }

  @override
  Future<void> bulkUpdateTasks(List<Task> tasks) async {
    for (final task in tasks) {
      await updateTask(task);
    }
  }

  @override
  Future<void> bulkDeleteTasks(List<int> taskIds) async {
    for (final id in taskIds) {
      await deleteTask(id);
    }
  }

  @override
  Future<Map<int, int>> getTaskCountByCategory() async {
    final counts = <int, int>{};
    for (final task in _tasks) {
      final categoryId = int.tryParse(task.categoryId) ?? 0;
      counts[categoryId] = (counts[categoryId] ?? 0) + 1;
    }
    return counts;
  }

  @override
  Future<Map<String, int>> getTaskStatistics() async {
    return {
      'total': _tasks.length,
      'completed': _tasks.where((t) => t.isCompleted).length,
      'pending': _tasks.where((t) => !t.isCompleted).length,
      'voice': _tasks.where((t) => t.source == TaskSource.voice).length,
      'chat': _tasks.where((t) => t.source == TaskSource.chat).length,
      'manual': _tasks.where((t) => t.source == TaskSource.manual).length,
    };
  }

  @override
  Stream<List<Task>> watchAllTasks() => _controller.stream;

  @override
  Stream<List<Task>> watchTasksByDate(DateTime date) =>
      _controller.stream.asyncMap((_) => getTasksByDate(date));

  @override
  Stream<List<Task>> watchTasksByCategory(int categoryId) =>
      _controller.stream.asyncMap((_) => getTasksByCategory(categoryId));

  @override
  Stream<List<Task>> watchPendingTasks() =>
      _controller.stream.asyncMap((_) => getPendingTasks());

  void addTask(Task task) {
    _tasks.add(task);
    _controller.add(List.from(_tasks));
  }

  void clear() {
    _tasks.clear();
    _controller.add([]);
  }

  void dispose() {
    _controller.close();
  }
}

class MockCategoryRepository implements CategoryRepository {
  final List<Category> _categories = [];
  int _nextId = 1;

  @override
  Future<List<Category>> getAllCategories() async => List.from(_categories);

  @override
  Future<List<Category>> getDefaultCategories() async =>
      _categories.where((cat) => cat.isDefault).toList();

  @override
  Future<Category?> getCategoryById(int id) async {
    try {
      return _categories.firstWhere((cat) => cat.id == id.toString());
    } catch (e) {
      return null;
    }
  }

  @override
  Future<int> createCategory(Category category) async {
    final newCategory = category.copyWith(id: _nextId.toString());
    _categories.add(newCategory);
    return _nextId++;
  }

  @override
  Future<void> updateCategory(Category category) async {
    final index = _categories.indexWhere((c) => c.id == category.id);
    if (index != -1) {
      _categories[index] = category;
    }
  }

  @override
  Future<void> deleteCategory(int id) async {
    _categories.removeWhere((cat) => cat.id == id.toString());
  }

  @override
  Future<void> createDefaultCategories() async {
    // Mock implementation - categories already added
  }

  void addCategory(Category category) {
    _categories.add(category);
  }

  void clear() {
    _categories.clear();
  }
}

class MockNotificationRepository implements NotificationRepository {
  final List<TaskNotification> _notifications = [];
  int _nextId = 1;

  @override
  Future<List<TaskNotification>> getAllNotifications() async => List.from(_notifications);

  @override
  Future<List<TaskNotification>> getNotificationsByTask(String taskId) async =>
      _notifications.where((notif) => notif.taskId == taskId).toList();

  @override
  Future<List<TaskNotification>> getPendingNotifications() async =>
      _notifications.where((notif) => !notif.sent).toList();

  @override
  Future<TaskNotification?> getNotificationById(int id) async {
    try {
      return _notifications.firstWhere((notif) => notif.id == id.toString());
    } catch (e) {
      return null;
    }
  }

  @override
  Future<int> createNotification(TaskNotification notification) async {
    final newNotification = notification.copyWith(id: _nextId.toString());
    _notifications.add(newNotification);
    return _nextId++;
  }

  @override
  Future<void> updateNotification(TaskNotification notification) async {
    final index = _notifications.indexWhere((n) => n.id == notification.id);
    if (index != -1) {
      _notifications[index] = notification;
    }
  }

  @override
  Future<void> deleteNotification(int id) async {
    _notifications.removeWhere((notif) => notif.id == id.toString());
  }

  @override
  Future<void> markNotificationSent(int id) async {
    final notification = await getNotificationById(id);
    if (notification != null) {
      await updateNotification(notification.copyWith(sent: true));
    }
  }

  void addNotification(TaskNotification notification) {
    _notifications.add(notification);
  }

  void clear() {
    _notifications.clear();
  }
}

class MockDatabaseService implements DatabaseService {
  bool _initialized = false;
  final Map<String, List<Map<String, dynamic>>> _tables = {};

  @override
  Future<void> initialize() async {
    _initialized = true;
    _tables['tasks'] = [];
    _tables['categories'] = [];
    _tables['notifications'] = [];
  }

  @override
  Future<void> close() async {
    _initialized = false;
    _tables.clear();
  }

  @override
  bool get isInitialized => _initialized;

  // Mock database methods would go here
  Future<int> insert(String table, Map<String, dynamic> values) async {
    if (!_initialized) throw Exception('Database not initialized');
    _tables[table]!.add(values);
    return _tables[table]!.length;
  }

  Future<List<Map<String, dynamic>>> query(String table) async {
    if (!_initialized) throw Exception('Database not initialized');
    return List.from(_tables[table] ?? []);
  }
}

class MockVoiceService implements VoiceService {
  bool _isListening = false;
  String? _lastRecognizedText;

  @override
  Future<bool> initialize() async => true;

  @override
  Future<bool> startListening() async {
    _isListening = true;
    return true;
  }

  @override
  Future<void> stopListening() async {
    _isListening = false;
  }

  @override
  bool get isListening => _isListening;

  @override
  String? get lastRecognizedText => _lastRecognizedText;

  @override
  Stream<String> get recognizedTextStream => Stream.value(_lastRecognizedText ?? '');

  void simulateRecognition(String text) {
    _lastRecognizedText = text;
  }
}

class MockNotificationService implements NotificationService {
  final List<String> _scheduledNotifications = [];

  @override
  Future<bool> initialize() async => true;

  @override
  Future<bool> requestPermissions() async => true;

  @override
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    _scheduledNotifications.add('$id: $title at $scheduledTime');
  }

  @override
  Future<void> cancelNotification(int id) async {
    _scheduledNotifications.removeWhere((notif) => notif.startsWith('$id:'));
  }

  @override
  Future<void> cancelAllNotifications() async {
    _scheduledNotifications.clear();
  }

  List<String> get scheduledNotifications => List.from(_scheduledNotifications);
}