import 'package:uuid/uuid.dart';

/// Task model representing a single task item
/// Optimized for forgetful users with clear status and scheduling
class Task {
  final String id;
  final String title;
  final String? description;
  final String categoryId;
  final DateTime? dueDate;
  final DateTime? dueTime;
  final TaskPriority priority;
  final bool isCompleted;
  final DateTime createdAt;
  final DateTime updatedAt;
  final TaskSource source;
  final bool hasReminder;
  final List<ReminderInterval> reminderIntervals;

  const Task({
    required this.id,
    required this.title,
    this.description,
    required this.categoryId,
    this.dueDate,
    this.dueTime,
    this.priority = TaskPriority.medium,
    this.isCompleted = false,
    required this.createdAt,
    required this.updatedAt,
    this.source = TaskSource.manual,
    this.hasReminder = false,
    this.reminderIntervals = const [],
  });

  /// Create a new task with generated ID and timestamps
  factory Task.create({
    required String title,
    String? description,
    required String categoryId,
    DateTime? dueDate,
    DateTime? dueTime,
    TaskPriority priority = TaskPriority.medium,
    TaskSource source = TaskSource.manual,
    bool hasReminder = false,
    List<ReminderInterval> reminderIntervals = const [],
  }) {
    final now = DateTime.now();
    return Task(
      id: const Uuid().v4(),
      title: title,
      description: description,
      categoryId: categoryId,
      dueDate: dueDate,
      dueTime: dueTime,
      priority: priority,
      createdAt: now,
      updatedAt: now,
      source: source,
      hasReminder: hasReminder,
      reminderIntervals: reminderIntervals,
    );
  }

  /// Create a copy of this task with some fields updated
  Task copyWith({
    String? id,
    String? title,
    String? description,
    String? categoryId,
    DateTime? dueDate,
    DateTime? dueTime,
    TaskPriority? priority,
    bool? isCompleted,
    DateTime? createdAt,
    DateTime? updatedAt,
    TaskSource? source,
    bool? hasReminder,
    List<ReminderInterval>? reminderIntervals,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      categoryId: categoryId ?? this.categoryId,
      dueDate: dueDate ?? this.dueDate,
      dueTime: dueTime ?? this.dueTime,
      priority: priority ?? this.priority,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      source: source ?? this.source,
      hasReminder: hasReminder ?? this.hasReminder,
      reminderIntervals: reminderIntervals ?? this.reminderIntervals,
    );
  }

  /// Mark task as completed
  Task complete() {
    return copyWith(
      isCompleted: true,
      updatedAt: DateTime.now(),
    );
  }

  /// Mark task as incomplete
  Task uncomplete() {
    return copyWith(
      isCompleted: false,
      updatedAt: DateTime.now(),
    );
  }

  /// Check if task is overdue
  bool get isOverdue {
    if (isCompleted || dueDate == null) return false;
    
    final now = DateTime.now();
    final dueDateTime = dueTime != null 
        ? DateTime(dueDate!.year, dueDate!.month, dueDate!.day, 
                   dueTime!.hour, dueTime!.minute)
        : dueDate!;
    
    return now.isAfter(dueDateTime);
  }

  /// Check if task is due today
  bool get isDueToday {
    if (dueDate == null) return false;
    final now = DateTime.now();
    return dueDate!.year == now.year &&
           dueDate!.month == now.month &&
           dueDate!.day == now.day;
  }

  /// Check if task is due tomorrow
  bool get isDueTomorrow {
    if (dueDate == null) return false;
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return dueDate!.year == tomorrow.year &&
           dueDate!.month == tomorrow.month &&
           dueDate!.day == tomorrow.day;
  }

  /// Get a display string for the due date/time
  String? get dueDateTimeDisplay {
    if (dueDate == null) return null;
    
    final now = DateTime.now();
    final dateOnly = DateTime(dueDate!.year, dueDate!.month, dueDate!.day);
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    
    String dateStr;
    if (dateOnly == today) {
      dateStr = 'Today';
    } else if (dateOnly == tomorrow) {
      dateStr = 'Tomorrow';
    } else {
      dateStr = '${dueDate!.month}/${dueDate!.day}/${dueDate!.year}';
    }
    
    if (dueTime != null) {
      final hour = dueTime!.hour;
      final minute = dueTime!.minute;
      final period = hour >= 12 ? 'PM' : 'AM';
      final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
      final minuteStr = minute.toString().padLeft(2, '0');
      dateStr += ' $displayHour:$minuteStr $period';
    }
    
    return dateStr;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Task &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Task{id: $id, title: $title, isCompleted: $isCompleted, dueDate: $dueDate}';
  }

  /// Convert to Map for database storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'categoryId': categoryId,
      'dueDate': dueDate?.millisecondsSinceEpoch,
      'dueTime': dueTime?.millisecondsSinceEpoch,
      'priority': priority.index,
      'isCompleted': isCompleted ? 1 : 0,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'source': source.index,
      'hasReminder': hasReminder ? 1 : 0,
      'reminderIntervals': reminderIntervals.map((e) => e.index).join(','),
    };
  }

  /// Create from Map (database)
  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      categoryId: map['categoryId'],
      dueDate: map['dueDate'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['dueDate'])
          : null,
      dueTime: map['dueTime'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['dueTime'])
          : null,
      priority: TaskPriority.values[map['priority'] ?? 1],
      isCompleted: map['isCompleted'] == 1,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt']),
      source: TaskSource.values[map['source'] ?? 0],
      hasReminder: map['hasReminder'] == 1,
      reminderIntervals: map['reminderIntervals'] != null && map['reminderIntervals'].isNotEmpty
          ? map['reminderIntervals'].split(',').map<ReminderInterval>((e) => ReminderInterval.values[int.parse(e)]).toList()
          : [],
    );
  }
}

/// Task priority levels
enum TaskPriority {
  low,
  medium,
  high,
  urgent,
}

/// Task source indicating how the task was created
enum TaskSource {
  manual,    // Created manually by user
  voice,     // Created via voice input
  chat,      // Extracted from chat message
  calendar,  // Created from calendar integration
}

/// Reminder interval options for notifications
enum ReminderInterval {
  oneHour,     // 1 hour before due time
  sixHours,    // 6 hours before due time
  twelveHours, // 12 hours before due time
  oneDay,      // 1 day before due date
}

extension ReminderIntervalExtension on ReminderInterval {
  String get displayName {
    switch (this) {
      case ReminderInterval.oneHour:
        return '1 hour before';
      case ReminderInterval.sixHours:
        return '6 hours before';
      case ReminderInterval.twelveHours:
        return '12 hours before';
      case ReminderInterval.oneDay:
        return '1 day before';
    }
  }
  
  Duration get duration {
    switch (this) {
      case ReminderInterval.oneHour:
        return const Duration(hours: 1);
      case ReminderInterval.sixHours:
        return const Duration(hours: 6);
      case ReminderInterval.twelveHours:
        return const Duration(hours: 12);
      case ReminderInterval.oneDay:
        return const Duration(days: 1);
    }
  }
}

extension TaskPriorityExtension on TaskPriority {
  String get displayName {
    switch (this) {
      case TaskPriority.low:
        return 'Low';
      case TaskPriority.medium:
        return 'Medium';
      case TaskPriority.high:
        return 'High';
      case TaskPriority.urgent:
        return 'Urgent';
    }
  }
}