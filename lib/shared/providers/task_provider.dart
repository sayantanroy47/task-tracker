import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/core.dart';
import '../models/models.dart';
import 'app_providers.dart';

/// Simple in-memory task provider for UI demonstration
/// This will be replaced with proper database integration later
class TaskNotifier extends StateNotifier<List<Task>> {
  TaskNotifier() : super([]);

  /// Add a new task
  void addTask(Task task) {
    state = [...state, task];
  }

  /// Update an existing task
  void updateTask(Task updatedTask) {
    state = [
      for (final task in state)
        if (task.id == updatedTask.id) updatedTask else task,
    ];
  }

  /// Delete a task
  void deleteTask(String taskId) {
    state = state.where((task) => task.id != taskId).toList();
  }

  /// Toggle task completion
  void toggleTaskCompletion(Task task) {
    final updatedTask = task.isCompleted ? task.uncomplete() : task.complete();
    updateTask(updatedTask);
  }

  /// Get tasks by completion status
  List<Task> getTasksByCompletion(bool isCompleted) {
    return state.where((task) => task.isCompleted == isCompleted).toList();
  }

  /// Get tasks due today
  List<Task> getTasksDueToday() {
    return state.where((task) => task.isDueToday && !task.isCompleted).toList();
  }

  /// Get overdue tasks
  List<Task> getOverdueTasks() {
    return state.where((task) => task.isOverdue && !task.isCompleted).toList();
  }

  /// Get tasks by category
  List<Task> getTasksByCategory(String categoryId) {
    return state.where((task) => task.categoryId == categoryId).toList();
  }

  /// Clear all completed tasks
  void clearCompletedTasks() {
    state = state.where((task) => !task.isCompleted).toList();
  }

  /// Load demo data for testing
  void loadDemoData() {
    final categories = Category.getDefaultCategories();
    final now = DateTime.now();
    final tomorrow = now.add(const Duration(days: 1));
    
    final demoTasks = [
      Task.create(
        title: 'Buy groceries',
        description: 'Milk, bread, eggs, and vegetables',
        categoryId: categories[1].id, // Household
        dueDate: now,
        dueTime: const TimeOfDay(hour: 15, minute: 0), // 3:00 PM
        priority: TaskPriority.medium,
        hasReminder: true,
        reminderIntervals: [ReminderInterval.oneHour],
      ),
      Task.create(
        title: 'Call mom',
        categoryId: categories[3].id, // Family
        priority: TaskPriority.high,
        hasReminder: true,
        reminderIntervals: [ReminderInterval.twelveHours],
      ),
      Task.create(
        title: 'Finish project presentation',
        description: 'Complete slides and practice presentation',
        categoryId: categories[2].id, // Work
        dueDate: tomorrow,
        dueTime: const TimeOfDay(hour: 9, minute: 0), // 9:00 AM
        priority: TaskPriority.urgent,
        hasReminder: true,
        reminderIntervals: [ReminderInterval.oneDay, ReminderInterval.oneHour],
      ),
      Task.create(
        title: 'Schedule dentist appointment',
        categoryId: categories[4].id, // Health
        priority: TaskPriority.low,
      ),
      Task.create(
        title: 'Review monthly budget',
        description: 'Check expenses and savings',
        categoryId: categories[5].id, // Finance
        priority: TaskPriority.medium,
      ),
      // Add a completed task for demonstration
      Task.create(
        title: 'Take vitamins',
        categoryId: categories[4].id, // Health
        priority: TaskPriority.low,
      ).complete(),
    ];
    
    state = demoTasks;
  }
}

/// Categories provider (static for now)
final categoriesProvider = Provider<List<Category>>((ref) {
  return Category.getDefaultCategories();
});

/// Tasks provider
final taskProvider = StateNotifierProvider<TaskNotifier, List<Task>>((ref) {
  final notifier = TaskNotifier();
  // Load demo data on initialization
  notifier.loadDemoData();
  return notifier;
});

/// Pending tasks provider (computed)
final pendingTasksProvider = Provider<List<Task>>((ref) {
  final tasks = ref.watch(taskProvider);
  return tasks.where((task) => !task.isCompleted).toList()
    ..sort((a, b) {
      // Sort by: overdue first, then due today, then by due date, then by priority
      if (a.isOverdue && !b.isOverdue) return -1;
      if (!a.isOverdue && b.isOverdue) return 1;
      
      if (a.isDueToday && !b.isDueToday) return -1;
      if (!a.isDueToday && b.isDueToday) return 1;
      
      if (a.dueDate != null && b.dueDate != null) {
        final dateComparison = a.dueDate!.compareTo(b.dueDate!);
        if (dateComparison != 0) return dateComparison;
      } else if (a.dueDate != null) {
        return -1;
      } else if (b.dueDate != null) {
        return 1;
      }
      
      return b.priority.index.compareTo(a.priority.index);
    });
});

/// Completed tasks provider (computed)
final completedTasksProvider = Provider<List<Task>>((ref) {
  final tasks = ref.watch(taskProvider);
  return tasks.where((task) => task.isCompleted).toList()
    ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt)); // Most recently completed first
});

/// Tasks due today provider (computed)
final tasksDueTodayProvider = Provider<List<Task>>((ref) {
  final tasks = ref.watch(taskProvider);
  return tasks.where((task) => task.isDueToday && !task.isCompleted).toList();
});

/// Overdue tasks provider (computed)
final overdueTasksProvider = Provider<List<Task>>((ref) {
  final tasks = ref.watch(taskProvider);
  return tasks.where((task) => task.isOverdue && !task.isCompleted).toList();
});

/// Task statistics provider
final taskStatsProvider = Provider<TaskStats>((ref) {
  final tasks = ref.watch(taskProvider);
  final total = tasks.length;
  final completed = tasks.where((task) => task.isCompleted).length;
  final pending = total - completed;
  final overdue = tasks.where((task) => task.isOverdue && !task.isCompleted).length;
  final dueToday = tasks.where((task) => task.isDueToday && !task.isCompleted).length;
  
  return TaskStats(
    total: total,
    completed: completed,
    pending: pending,
    overdue: overdue,
    dueToday: dueToday,
  );
});

/// Task statistics data class
class TaskStats {
  final int total;
  final int completed;
  final int pending;
  final int overdue;
  final int dueToday;

  const TaskStats({
    required this.total,
    required this.completed,
    required this.pending,
    required this.overdue,
    required this.dueToday,
  });

  double get completionRate => total > 0 ? completed / total : 0.0;
}