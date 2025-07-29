import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'enums.dart';

/// Task model representing a single task item
/// Optimized for forgetful users with clear status and scheduling
class Task {
  final String id;
  final String title;
  final String? description;
  final String categoryId;
  final DateTime? dueDate;
  final TimeOfDay? dueTime;
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
    TimeOfDay? dueTime,
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
    TimeOfDay? dueTime,
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

  /// Convert to Map for database storage (compatible with existing schema)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category_id': categoryId,
      'due_date': dueDate?.toIso8601String().split('T')[0],
      'due_time': dueTime != null ? '${dueTime!.hour.toString().padLeft(2, '0')}:${dueTime!.minute.toString().padLeft(2, '0')}' : null,
      'priority': priority.index,
      'completed': isCompleted ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'source': source.name,
    };
  }

  /// Convert to JSON for API compatibility
  Map<String, dynamic> toJson() => toMap();

  /// Parse TimeOfDay from string format "hour:minute"
  static TimeOfDay? _parseTimeOfDay(String? timeString) {
    if (timeString == null || timeString.isEmpty) return null;
    
    try {
      final parts = timeString.split(':');
      if (parts.length == 2) {
        final hour = int.parse(parts[0]);
        final minute = int.parse(parts[1]);
        if (hour >= 0 && hour <= 23 && minute >= 0 && minute <= 59) {
          return TimeOfDay(hour: hour, minute: minute);
        }
      }
    } catch (e) {
      // Invalid format, return null
    }
    return null;
  }

  /// Create from Map (database) - compatible with existing schema
  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id']?.toString() ?? '',
      title: map['title'] ?? '',
      description: map['description'],
      categoryId: map['category_id']?.toString() ?? map['categoryId']?.toString() ?? '',
      dueDate: map['due_date'] != null 
          ? DateTime.tryParse(map['due_date'])
          : (map['dueDate'] != null 
              ? DateTime.fromMillisecondsSinceEpoch(map['dueDate'])
              : null),
      dueTime: map['due_time'] != null 
          ? _parseTimeOfDay(map['due_time'])
          : (map['dueTime'] != null 
              ? _parseTimeOfDay(map['dueTime'])
              : null),
      priority: TaskPriority.values[map['priority'] ?? 1],
      isCompleted: (map['completed'] ?? map['isCompleted']) == 1,
      createdAt: map['created_at'] != null 
          ? DateTime.tryParse(map['created_at']) ?? DateTime.now()
          : (map['createdAt'] != null 
              ? DateTime.fromMillisecondsSinceEpoch(map['createdAt'])
              : DateTime.now()),
      updatedAt: map['updated_at'] != null 
          ? DateTime.tryParse(map['updated_at']) ?? DateTime.now()
          : (map['updatedAt'] != null 
              ? DateTime.fromMillisecondsSinceEpoch(map['updatedAt'])
              : DateTime.now()),
      source: map['source'] is String 
          ? TaskSource.values.firstWhere(
              (e) => e.name == map['source'], 
              orElse: () => TaskSource.manual,
            )
          : TaskSource.values[map['source'] ?? 0],
      hasReminder: false, // Legacy field, not in current schema
      reminderIntervals: const [], // Legacy field, not in current schema
    );
  }

  /// Create from JSON (API compatibility)
  factory Task.fromJson(Map<String, dynamic> json) => Task.fromMap(json);
}

