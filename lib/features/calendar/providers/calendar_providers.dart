import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../shared/models/task.dart';
import '../../../shared/providers/app_providers.dart';
import '../../tasks/providers/task_providers.dart';
import '../utils/date_time_utils.dart';

/// Calendar-related providers for state management
/// Handles date selection, task loading, and calendar display

/// Selected date provider - tracks which date is currently selected
final selectedDateProvider = StateProvider<DateTime>((ref) {
  return DateTime.now();
});

/// Focused day provider - tracks which month/year the calendar is showing
final focusedDayProvider = StateProvider<DateTime>((ref) {
  return DateTime.now();
});

/// Calendar format provider - tracks calendar display mode
final calendarFormatProvider = StateProvider<CalendarFormat>((ref) {
  return CalendarFormat.month;
});

/// Tasks for selected date provider
final tasksForSelectedDateProvider = Provider<List<Task>>((ref) {
  final selectedDate = ref.watch(selectedDateProvider);
  final allTasks = ref.watch(allTasksProvider).valueOrNull ?? [];
  
  return _getTasksForDate(allTasks, selectedDate);
});

/// Tasks for date range provider - parameterized for calendar display
final tasksForDateRangeProvider = StreamProvider.family<Map<DateTime, List<Task>>, DateTimeRange>((ref, dateRange) async {
  final repository = ref.watch(taskRepositoryProvider);
  final tasks = await repository.getTasksByDateRange(dateRange.start, dateRange.end);
  
  // Group tasks by date
  final Map<DateTime, List<Task>> tasksByDate = {};
  for (final task in tasks) {
    if (task.dueDate != null) {
      final dateKey = DateTime(task.dueDate!.year, task.dueDate!.month, task.dueDate!.day);
      tasksByDate.putIfAbsent(dateKey, () => []).add(task);
    }
  }
  
  return tasksByDate;
});

/// Calendar view mode provider
final calendarViewModeProvider = StateProvider<CalendarViewMode>((ref) {
  return CalendarViewMode.month;
});

/// Calendar state notifier for complex state management
final calendarStateProvider = StateNotifierProvider<CalendarStateNotifier, CalendarState>((ref) {
  return CalendarStateNotifier(ref);
});

/// Calendar state data class
class CalendarState {
  final DateTime selectedDate;
  final DateTime focusedDay;
  final CalendarFormat calendarFormat;
  final CalendarViewMode viewMode;
  final bool isLoading;
  final String? error;
  final Map<DateTime, List<Task>> tasksByDate;

  const CalendarState({
    required this.selectedDate,
    required this.focusedDay,
    this.calendarFormat = CalendarFormat.month,
    this.viewMode = CalendarViewMode.month,
    this.isLoading = false,
    this.error,
    this.tasksByDate = const {},
  });

  CalendarState copyWith({
    DateTime? selectedDate,
    DateTime? focusedDay,
    CalendarFormat? calendarFormat,
    CalendarViewMode? viewMode,
    bool? isLoading,
    String? error,
    Map<DateTime, List<Task>>? tasksByDate,
  }) {
    return CalendarState(
      selectedDate: selectedDate ?? this.selectedDate,
      focusedDay: focusedDay ?? this.focusedDay,
      calendarFormat: calendarFormat ?? this.calendarFormat,
      viewMode: viewMode ?? this.viewMode,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      tasksByDate: tasksByDate ?? this.tasksByDate,
    );
  }
}

/// Calendar view modes
enum CalendarViewMode {
  month,
  week,
  agenda,
}

/// Calendar state notifier for managing complex calendar operations
class CalendarStateNotifier extends StateNotifier<CalendarState> {
  final Ref _ref;

  CalendarStateNotifier(this._ref) : super(CalendarState(
    selectedDate: DateTime.now(),
    focusedDay: DateTime.now(),
  )) {
    _loadTasksForCurrentMonth();
  }

  /// Update selected date
  void selectDate(DateTime date) {
    state = state.copyWith(selectedDate: date);
  }

  /// Update focused day (month/year navigation)
  void updateFocusedDay(DateTime focusedDay) {
    state = state.copyWith(focusedDay: focusedDay);
    _loadTasksForMonth(focusedDay);
  }

  /// Update calendar format
  void updateCalendarFormat(CalendarFormat format) {
    state = state.copyWith(calendarFormat: format);
  }

  /// Update view mode
  void updateViewMode(CalendarViewMode mode) {
    state = state.copyWith(viewMode: mode);
  }

  /// Navigate to today
  void goToToday() {
    final today = DateTime.now();
    state = state.copyWith(
      selectedDate: today,
      focusedDay: today,
    );
    _loadTasksForCurrentMonth();
  }

  /// Navigate to next month
  void nextMonth() {
    final nextMonth = DateTime(state.focusedDay.year, state.focusedDay.month + 1);
    updateFocusedDay(nextMonth);
  }

  /// Navigate to previous month
  void previousMonth() {
    final previousMonth = DateTime(state.focusedDay.year, state.focusedDay.month - 1);
    updateFocusedDay(previousMonth);
  }

  /// Load tasks for current month
  void _loadTasksForCurrentMonth() {
    _loadTasksForMonth(state.focusedDay);
  }

  /// Load tasks for specific month
  void _loadTasksForMonth(DateTime month) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final repository = _ref.read(taskRepositoryProvider);
      final startOfMonth = DateTime(month.year, month.month, 1);
      final endOfMonth = DateTime(month.year, month.month + 1, 0);
      
      final tasks = await repository.getTasksByDateRange(startOfMonth, endOfMonth);
      
      // Group tasks by date
      final Map<DateTime, List<Task>> tasksByDate = {};
      for (final task in tasks) {
        if (task.dueDate != null) {
          final dateKey = DateTime(task.dueDate!.year, task.dueDate!.month, task.dueDate!.day);
          tasksByDate.putIfAbsent(dateKey, () => []).add(task);
        }
      }
      
      state = state.copyWith(
        isLoading: false,
        tasksByDate: tasksByDate,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Get tasks for a specific date
  List<Task> getTasksForDate(DateTime date) {
    final dateKey = DateTime(date.year, date.month, date.day);
    return state.tasksByDate[dateKey] ?? [];
  }

  /// Check if a date has tasks
  bool hasTasksOnDate(DateTime date) {
    final dateKey = DateTime(date.year, date.month, date.day);
    return state.tasksByDate.containsKey(dateKey) && 
           state.tasksByDate[dateKey]!.isNotEmpty;
  }

  /// Get task count for a date
  int getTaskCountForDate(DateTime date) {
    final dateKey = DateTime(date.year, date.month, date.day);
    return state.tasksByDate[dateKey]?.length ?? 0;
  }

  /// Add task to calendar (called when voice input creates a task)
  void addTaskToCalendar(Task task) {
    if (task.dueDate == null) return;
    
    final dateKey = DateTime(task.dueDate!.year, task.dueDate!.month, task.dueDate!.day);
    final updatedTasksByDate = Map<DateTime, List<Task>>.from(state.tasksByDate);
    
    updatedTasksByDate.putIfAbsent(dateKey, () => []).add(task);
    
    state = state.copyWith(tasksByDate: updatedTasksByDate);
  }

  /// Remove task from calendar
  void removeTaskFromCalendar(String taskId) {
    final updatedTasksByDate = Map<DateTime, List<Task>>.from(state.tasksByDate);
    
    for (final entry in updatedTasksByDate.entries) {
      entry.value.removeWhere((task) => task.id == taskId);
      if (entry.value.isEmpty) {
        updatedTasksByDate.remove(entry.key);
      }
    }
    
    state = state.copyWith(tasksByDate: updatedTasksByDate);
  }

  /// Update task in calendar
  void updateTaskInCalendar(Task oldTask, Task newTask) {
    // Remove from old date if it exists
    if (oldTask.dueDate != null) {
      final oldDateKey = DateTime(oldTask.dueDate!.year, oldTask.dueDate!.month, oldTask.dueDate!.day);
      final updatedTasksByDate = Map<DateTime, List<Task>>.from(state.tasksByDate);
      updatedTasksByDate[oldDateKey]?.removeWhere((task) => task.id == oldTask.id);
      
      if (updatedTasksByDate[oldDateKey]?.isEmpty ?? false) {
        updatedTasksByDate.remove(oldDateKey);
      }
      
      state = state.copyWith(tasksByDate: updatedTasksByDate);
    }
    
    // Add to new date if it exists
    if (newTask.dueDate != null) {
      addTaskToCalendar(newTask);
    }
  }
}

/// Helper function to get tasks for a specific date
List<Task> _getTasksForDate(List<Task> allTasks, DateTime date) {
  return allTasks.where((task) {
    if (task.dueDate == null) return false;
    return DateTimeUtils.isSameDay(task.dueDate!, date);
  }).toList();
}

