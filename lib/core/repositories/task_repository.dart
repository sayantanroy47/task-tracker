import '../../shared/models/models.dart';

/// Abstract repository interface for task operations
abstract class TaskRepository {
  /// Get all tasks
  Future<List<Task>> getAllTasks();

  /// Get tasks by category
  Future<List<Task>> getTasksByCategory(int categoryId);

  /// Get tasks by date
  Future<List<Task>> getTasksByDate(DateTime date);

  /// Get tasks by date range
  Future<List<Task>> getTasksByDateRange(DateTime startDate, DateTime endDate);

  /// Get completed tasks
  Future<List<Task>> getCompletedTasks();

  /// Get pending tasks
  Future<List<Task>> getPendingTasks();

  /// Get overdue tasks
  Future<List<Task>> getOverdueTasks();

  /// Get task by ID
  Future<Task?> getTaskById(int id);

  /// Search tasks by title or description
  Future<List<Task>> searchTasks(String query);

  /// Create a new task
  Future<int> createTask(Task task);

  /// Update an existing task
  Future<void> updateTask(Task task);

  /// Delete a task
  Future<void> deleteTask(int id);

  /// Toggle task completion status
  Future<void> toggleTaskCompletion(int id);

  /// Mark task as completed
  Future<void> markTaskCompleted(int id);

  /// Bulk update tasks
  Future<void> bulkUpdateTasks(List<Task> tasks);

  /// Bulk delete tasks
  Future<void> bulkDeleteTasks(List<int> taskIds);

  /// Get task count by category
  Future<Map<int, int>> getTaskCountByCategory();

  /// Get task completion statistics
  Future<Map<String, int>> getTaskStatistics();

  /// Watch all tasks (stream)
  Stream<List<Task>> watchAllTasks();

  /// Watch tasks by date (stream)
  Stream<List<Task>> watchTasksByDate(DateTime date);

  /// Watch tasks by category (stream)
  Stream<List<Task>> watchTasksByCategory(int categoryId);

  /// Watch pending tasks (stream)
  Stream<List<Task>> watchPendingTasks();
}