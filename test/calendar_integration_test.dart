import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:task_tracker_app/shared/models/task.dart';
import 'package:task_tracker_app/features/calendar/utils/date_time_utils.dart';

/// Test suite for calendar integration to verify TimeOfDay handling
/// and calendar functionality after our updates
void main() {
  group('Calendar Integration Tests', () {
    test('Task TimeOfDay serialization and deserialization', () {
      // Test creating a task with TimeOfDay
      final task = Task.create(
        title: 'Test Task',
        categoryId: 'personal',
        dueDate: DateTime(2024, 1, 15),
        dueTime: const TimeOfDay(hour: 14, minute: 30),
        source: TaskSource.calendar,
      );

      // Test serialization to Map (for database)
      final taskMap = task.toMap();
      expect(taskMap['dueTime'], equals('14:30'));

      // Test deserialization from Map
      final deserializedTask = Task.fromMap(taskMap);
      expect(deserializedTask.dueTime?.hour, equals(14));
      expect(deserializedTask.dueTime?.minute, equals(30));
      expect(deserializedTask.source, equals(TaskSource.calendar));
    });

    test('DateTimeUtils natural language parsing', () {
      // Test parsing "tomorrow at 3 PM"
      final result = DateTimeUtils.parseNaturalLanguage('tomorrow at 3 PM');
      expect(result, isNotNull);
      expect(result!.time?.hour, equals(15)); // 3 PM = 15:00
      expect(result.time?.minute, equals(0));
      expect(result.confidence, greaterThan(0.8));
    });

    test('DateTimeUtils date comparison functions', () {
      final today = DateTime.now();
      final tomorrow = today.add(const Duration(days: 1));
      final sameTimeToday = DateTime(today.year, today.month, today.day, 10, 30);

      // Test isSameDay
      expect(DateTimeUtils.isSameDay(today, sameTimeToday), isTrue);
      expect(DateTimeUtils.isSameDay(today, tomorrow), isFalse);

      // Test isToday
      expect(DateTimeUtils.isToday(today), isTrue);
      expect(DateTimeUtils.isToday(tomorrow), isFalse);

      // Test date formatting
      expect(DateTimeUtils.formatDateForDisplay(today), equals('Today'));
      expect(DateTimeUtils.formatDateForDisplay(tomorrow), equals('Tomorrow'));
    });

    test('TimeOfDay extension methods', () {
      const timeOfDay = TimeOfDay(hour: 14, minute: 30);
      final testDate = DateTime(2024, 1, 15);
      
      // Test toDateTime extension
      final combinedDateTime = timeOfDay.toDateTime(testDate);
      expect(combinedDateTime.year, equals(2024));
      expect(combinedDateTime.month, equals(1));
      expect(combinedDateTime.day, equals(15));
      expect(combinedDateTime.hour, equals(14));
      expect(combinedDateTime.minute, equals(30));
    });

    test('Task due date display formatting', () {
      final today = DateTime.now();
      final task = Task.create(
        title: 'Test Task',
        categoryId: 'personal',
        dueDate: today,
        dueTime: const TimeOfDay(hour: 14, minute: 30),
      );

      final displayString = task.dueDateTimeDisplay;
      expect(displayString, contains('Today'));
      expect(displayString, contains('2:30 PM'));
    });

    test('Task completion state tracking', () {
      final task = Task.create(
        title: 'Test Task',
        categoryId: 'personal',
        dueDate: DateTime.now().subtract(const Duration(days: 1)),
        dueTime: const TimeOfDay(hour: 14, minute: 30),
      );

      // Test overdue detection
      expect(task.isOverdue, isTrue);

      // Test completion
      final completedTask = task.complete();
      expect(completedTask.isCompleted, isTrue);
      expect(completedTask.isOverdue, isFalse); // Completed tasks are not overdue
    });
  });

  group('Calendar Performance Tests', () {
    test('Efficient task grouping by category', () {
      // Create multiple tasks with different categories
      final tasks = [
        Task.create(title: 'Work Task 1', categoryId: 'work'),
        Task.create(title: 'Work Task 2', categoryId: 'work'),
        Task.create(title: 'Personal Task', categoryId: 'personal'),
        Task.create(title: 'Health Task', categoryId: 'health'),
      ];

      // Group tasks by category efficiently
      final stopwatch = Stopwatch()..start();
      final groupedTasks = <String, List<Task>>{};
      for (final task in tasks) {
        groupedTasks.putIfAbsent(task.categoryId, () => []).add(task);
      }
      stopwatch.stop();

      // Verify grouping and performance
      expect(groupedTasks['work']?.length, equals(2));
      expect(groupedTasks['personal']?.length, equals(1));
      expect(groupedTasks['health']?.length, equals(1));
      expect(stopwatch.elapsedMicroseconds, lessThan(1000)); // Should be very fast
    });
  });
}