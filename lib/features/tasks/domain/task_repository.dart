import '../../../shared/models/task.dart';

/// Repository interface for task data operations
/// Follows repository pattern for clean architecture separation
abstract class TaskRepository {
  /// Get all tasks, optionally filtered by completion status
  Future<List<Task>> getAllTasks({bool? isCompleted});
  
  /// Get tasks by category ID
  Future<List<Task>> getTasksByCategory(String categoryId);
  
  /// Get tasks for a specific date
  Future<List<Task>> getTasksByDate(DateTime date);
  
  /// Get tasks within a date range
  Future<List<Task>> getTasksByDateRange(DateTime startDate, DateTime endDate);
  
  /// Get a single task by ID
  Future<Task?> getTaskById(String id);
  
  /// Create a new task
  Future<Task> createTask(Task task);
  
  /// Update an existing task
  Future<Task> updateTask(Task task);
  
  /// Delete a task by ID
  Future<bool> deleteTask(String id);
  
  /// Mark a task as completed
  Future<Task> completeTask(String id);
  
  /// Mark a task as incomplete
  Future<Task> uncompleteTask(String id);
  
  /// Search tasks by title or description
  Future<List<Task>> searchTasks(String query);
  
  /// Get overdue tasks
  Future<List<Task>> getOverdueTasks();
  
  /// Get tasks due today
  Future<List<Task>> getTasksDueToday();
  
  /// Get tasks by priority
  Future<List<Task>> getTasksByPriority(TaskPriority priority);
  
  /// Get tasks by source (manual, voice, chat)
  Future<List<Task>> getTasksBySource(TaskSource source);
  
  /// Get task count statistics
  Future<TaskStats> getTaskStats();
  
  /// Bulk operations
  Future<List<Task>> createTasks(List<Task> tasks);
  Future<bool> deleteTasks(List<String> ids);
  Future<List<Task>> updateTasks(List<Task> tasks);
  
  /// Listen to task changes (for real-time updates)
  Stream<List<Task>> watchAllTasks();
  Stream<List<Task>> watchTasksByCategory(String categoryId);
  Stream<Task?> watchTask(String id);
}

/// Task statistics for analytics
class TaskStats {
  final int totalTasks;
  final int completedTasks;
  final int pendingTasks;
  final int overdueTasks;
  final int tasksDueToday;
  final Map<String, int> tasksByCategory;
  final Map<TaskPriority, int> tasksByPriority;
  final Map<TaskSource, int> tasksBySource;
  
  const TaskStats({
    required this.totalTasks,
    required this.completedTasks,
    required this.pendingTasks,
    required this.overdueTasks,
    required this.tasksDueToday,
    required this.tasksByCategory,
    required this.tasksByPriority,
    required this.tasksBySource,
  });
  
  double get completionRate => totalTasks > 0 ? completedTasks / totalTasks : 0.0;
}