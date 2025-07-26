import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/task.dart';
import '../../../shared/providers/app_providers.dart';
import '../domain/task_repository.dart';

/// Task-related providers for state management
/// Handles task operations and state across the application

/// All tasks provider - watches all tasks in real-time
final allTasksProvider = StreamProvider<List<Task>>((ref) {
  final repository = ref.watch(taskRepositoryProvider);
  return repository.watchAllTasks();
});

/// Pending tasks provider - only incomplete tasks
final pendingTasksProvider = Provider<List<Task>>((ref) {
  final allTasks = ref.watch(allTasksProvider).valueOrNull ?? [];
  return allTasks.where((task) => !task.isCompleted).toList();
});

/// Completed tasks provider - only completed tasks
final completedTasksProvider = Provider<List<Task>>((ref) {
  final allTasks = ref.watch(allTasksProvider).valueOrNull ?? [];
  return allTasks.where((task) => task.isCompleted).toList();
});

/// Tasks due today provider
final tasksDueTodayProvider = FutureProvider<List<Task>>((ref) {
  final repository = ref.watch(taskRepositoryProvider);
  return repository.getTasksDueToday();
});

/// Overdue tasks provider
final overdueTasksProvider = FutureProvider<List<Task>>((ref) {
  final repository = ref.watch(taskRepositoryProvider);
  return repository.getOverdueTasks();
});

/// Task statistics provider
final taskStatsProvider = FutureProvider<TaskStats>((ref) {
  final repository = ref.watch(taskRepositoryProvider);
  return repository.getTaskStats();
});

/// Tasks by category provider - parameterized
final tasksByCategoryProvider = StreamProvider.family<List<Task>, String>((ref, categoryId) {
  final repository = ref.watch(taskRepositoryProvider);
  return repository.watchTasksByCategory(categoryId);
});

/// Single task provider - parameterized
final singleTaskProvider = StreamProvider.family<Task?, String>((ref, taskId) {
  final repository = ref.watch(taskRepositoryProvider);
  return repository.watchTask(taskId);
});

/// Task filter state provider for UI filtering
final taskFilterProvider = StateNotifierProvider<TaskFilterNotifier, TaskFilter>((ref) {
  return TaskFilterNotifier();
});

/// Filtered tasks provider based on current filter
final filteredTasksProvider = Provider<List<Task>>((ref) {
  final allTasks = ref.watch(allTasksProvider).valueOrNull ?? [];
  final filter = ref.watch(taskFilterProvider);
  
  return _applyFilter(allTasks, filter);
});

/// Task operations provider for CRUD operations
final taskOperationsProvider = Provider<TaskOperations>((ref) {
  return TaskOperations(ref);
});

/// Task filter notifier for managing filter state
class TaskFilterNotifier extends StateNotifier<TaskFilter> {
  TaskFilterNotifier() : super(const TaskFilter());
  
  void setCategory(String? categoryId) {
    state = state.copyWith(categoryId: categoryId);
  }
  
  void setPriority(TaskPriority? priority) {
    state = state.copyWith(priority: priority);
  }
  
  void setCompletionStatus(bool? isCompleted) {
    state = state.copyWith(isCompleted: isCompleted);
  }
  
  void setDateRange(DateTime? startDate, DateTime? endDate) {
    state = state.copyWith(startDate: startDate, endDate: endDate);
  }
  
  void setSearchQuery(String? query) {
    state = state.copyWith(searchQuery: query);
  }
  
  void setSource(TaskSource? source) {
    state = state.copyWith(source: source);
  }
  
  void clearFilters() {
    state = const TaskFilter();
  }
}

/// Task filter data class
class TaskFilter {
  final String? categoryId;
  final TaskPriority? priority;
  final bool? isCompleted;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? searchQuery;
  final TaskSource? source;
  
  const TaskFilter({
    this.categoryId,
    this.priority,
    this.isCompleted,
    this.startDate,
    this.endDate,
    this.searchQuery,
    this.source,
  });
  
  TaskFilter copyWith({
    String? categoryId,
    TaskPriority? priority,
    bool? isCompleted,
    DateTime? startDate,
    DateTime? endDate,
    String? searchQuery,
    TaskSource? source,
  }) {
    return TaskFilter(
      categoryId: categoryId ?? this.categoryId,
      priority: priority ?? this.priority,
      isCompleted: isCompleted ?? this.isCompleted,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      searchQuery: searchQuery ?? this.searchQuery,
      source: source ?? this.source,
    );
  }
  
  bool get hasActiveFilters {
    return categoryId != null ||
           priority != null ||
           isCompleted != null ||
           startDate != null ||
           endDate != null ||
           (searchQuery != null && searchQuery!.isNotEmpty) ||
           source != null;
  }
}

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
    Map<String, dynamic>? metadata,
  }) async {
    final task = Task.create(
      title: title,
      description: description,
      categoryId: categoryId,
      dueDate: dueDate,
      dueTime: dueTime,
      priority: priority,
      source: source,
      metadata: metadata,
    );
    
    return await _repository.createTask(task);
  }
  
  /// Update an existing task
  Future<Task> updateTask(Task task) async {
    return await _repository.updateTask(task);
  }
  
  /// Delete a task
  Future<bool> deleteTask(String id) async {
    return await _repository.deleteTask(id);
  }
  
  /// Complete a task
  Future<Task> completeTask(String id) async {
    return await _repository.completeTask(id);
  }
  
  /// Uncomplete a task
  Future<Task> uncompleteTask(String id) async {
    return await _repository.uncompleteTask(id);
  }
  
  /// Toggle task completion
  Future<Task> toggleTaskCompletion(String id) async {
    final task = await _repository.getTaskById(id);
    if (task == null) {
      throw Exception('Task not found');
    }
    
    return task.isCompleted 
        ? await uncompleteTask(id)
        : await completeTask(id);
  }
  
  /// Search tasks
  Future<List<Task>> searchTasks(String query) async {
    return await _repository.searchTasks(query);
  }
  
  /// Create multiple tasks (bulk operation)
  Future<List<Task>> createTasks(List<Task> tasks) async {
    return await _repository.createTasks(tasks);
  }
  
  /// Delete multiple tasks (bulk operation)
  Future<bool> deleteTasks(List<String> ids) async {
    return await _repository.deleteTasks(ids);
  }
}

/// Helper function to apply filters to task list
List<Task> _applyFilter(List<Task> tasks, TaskFilter filter) {
  var filteredTasks = tasks;
  
  // Filter by category
  if (filter.categoryId != null) {
    filteredTasks = filteredTasks
        .where((task) => task.categoryId == filter.categoryId)
        .toList();
  }
  
  // Filter by priority
  if (filter.priority != null) {
    filteredTasks = filteredTasks
        .where((task) => task.priority == filter.priority)
        .toList();
  }
  
  // Filter by completion status
  if (filter.isCompleted != null) {
    filteredTasks = filteredTasks
        .where((task) => task.isCompleted == filter.isCompleted)
        .toList();
  }
  
  // Filter by date range
  if (filter.startDate != null && filter.endDate != null) {
    filteredTasks = filteredTasks.where((task) {
      if (task.dueDate == null) return false;
      return task.dueDate!.isAfter(filter.startDate!) &&
             task.dueDate!.isBefore(filter.endDate!.add(const Duration(days: 1)));
    }).toList();
  }
  
  // Filter by search query
  if (filter.searchQuery != null && filter.searchQuery!.isNotEmpty) {
    final query = filter.searchQuery!.toLowerCase();
    filteredTasks = filteredTasks.where((task) {
      return task.title.toLowerCase().contains(query) ||
             (task.description?.toLowerCase().contains(query) ?? false);
    }).toList();
  }
  
  // Filter by source
  if (filter.source != null) {
    filteredTasks = filteredTasks
        .where((task) => task.source == filter.source)
        .toList();
  }
  
  return filteredTasks;
}