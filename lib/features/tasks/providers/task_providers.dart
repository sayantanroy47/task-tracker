import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/task.dart';
import '../../../shared/providers/app_providers.dart';
import '../../../core/repositories/task_repository.dart';

/// Task-related providers for state management
/// Handles task operations and state across the application

/// All tasks provider - watches all tasks in real-time
final allTasksProvider = StreamProvider<List<Task>>((ref) {
  final repository = ref.watch(taskRepositoryProvider);
  return repository.watchAllTasks();
});

/// Pending tasks provider - only incomplete tasks
final pendingTasksProvider = StreamProvider<List<Task>>((ref) {
  final repository = ref.watch(taskRepositoryProvider);
  return repository.watchPendingTasks();
});

/// Completed tasks provider - only completed tasks
final completedTasksProvider = FutureProvider<List<Task>>((ref) {
  final repository = ref.watch(taskRepositoryProvider);
  return repository.getCompletedTasks();
});

/// Overdue tasks provider
final overdueTasksProvider = FutureProvider<List<Task>>((ref) {
  final repository = ref.watch(taskRepositoryProvider);
  return repository.getOverdueTasks();
});

/// Tasks by category provider - parameterized
final tasksByCategoryProvider = StreamProvider.family<List<Task>, String>((ref, categoryId) {
  final repository = ref.watch(taskRepositoryProvider);
  return repository.watchTasksByCategory(categoryId);
});

/// Tasks by date provider - parameterized
final tasksByDateProvider = StreamProvider.family<List<Task>, DateTime>((ref, date) {
  final repository = ref.watch(taskRepositoryProvider);
  return repository.watchTasksByDate(date);
});

/// Task operations provider for CRUD operations
final taskOperationsProvider = Provider<TaskOperations>((ref) {
  return TaskOperations(ref);
});

/// Task operations class for handling CRUD operations
class TaskOperations {
  final Ref _ref;
  
  TaskOperations(this._ref);
  
  TaskRepository get _repository => _ref.read(taskRepositoryProvider);
  
  /// Create a new task
  Future<Task> createTask({
    required String title,
    String? description,
    required String categoryId,
    DateTime? dueDate,
    TimeOfDay? dueTime,
    TaskPriority priority = TaskPriority.medium,
    TaskSource source = TaskSource.manual,
  }) async {
    final task = Task.create(
      title: title,
      description: description,
      categoryId: categoryId,
      dueDate: dueDate,
      dueTime: dueTime,
      priority: priority,
      source: source,
    );
    
    return await _repository.createTask(task);
  }
  
  /// Update an existing task
  Future<void> updateTask(Task task) async {
    return await _repository.updateTask(task);
  }
  
  /// Delete a task
  Future<void> deleteTask(String id) async {
    return await _repository.deleteTask(id);
  }
  
  /// Toggle task completion
  Future<void> toggleTaskCompletion(String id) async {
    return await _repository.toggleTaskCompletion(id);
  }
  
  /// Mark task as completed
  Future<void> markTaskCompleted(String id) async {
    return await _repository.markTaskCompleted(id);
  }
  
  /// Search tasks
  Future<List<Task>> searchTasks(String query) async {
    return await _repository.searchTasks(query);
  }
  
  /// Get tasks by date range
  Future<List<Task>> getTasksByDateRange(DateTime startDate, DateTime endDate) async {
    return await _repository.getTasksByDateRange(startDate, endDate);
  }
}