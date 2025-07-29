import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:task_tracker_app/shared/models/models.dart';
import '../../test_utils/fixtures.dart';

void main() {
  group('Task Model Tests', () {
    late Task sampleTask;
    late DateTime testDate;
    late TimeOfDay testTime;

    setUp(() {
      testDate = DateTime(2024, 3, 15, 14, 30);
      testTime = const TimeOfDay(hour: 14, minute: 30);
      sampleTask = TaskFixtures.createTask(
        id: 'test-task-1',
        title: 'Test Task',
        description: 'Test Description',
        categoryId: 'cat-1',
        dueDate: testDate,
        dueTime: testTime,
        priority: TaskPriority.high,
        isCompleted: false,
        source: TaskSource.voice,
        hasReminder: true,
        reminderIntervals: [ReminderInterval.oneHour, ReminderInterval.oneDay],
      );
    });

    group('Constructor and Factory Methods', () {
      test('should create task with required fields', () {
        final task = Task(
          id: 'test-id',
          title: 'Test Title',
          categoryId: 'cat-1',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        expect(task.id, 'test-id');
        expect(task.title, 'Test Title');
        expect(task.categoryId, 'cat-1');
        expect(task.priority, TaskPriority.medium); // default
        expect(task.isCompleted, false); // default
        expect(task.source, TaskSource.manual); // default
      });

      test('should create task using factory constructor', () {
        final task = Task.create(
          title: 'Factory Task',
          categoryId: 'cat-2',
          priority: TaskPriority.urgent,
          source: TaskSource.voice,
        );

        expect(task.title, 'Factory Task');
        expect(task.categoryId, 'cat-2');
        expect(task.priority, TaskPriority.urgent);
        expect(task.source, TaskSource.voice);
        expect(task.id.isNotEmpty, true);
        expect(task.createdAt.isBefore(DateTime.now().add(const Duration(seconds: 1))), true);
      });

      test('should generate unique IDs with factory constructor', () {
        final task1 = Task.create(title: 'Task 1', categoryId: 'cat-1');
        final task2 = Task.create(title: 'Task 2', categoryId: 'cat-1');

        expect(task1.id, isNot(equals(task2.id)));
      });
    });

    group('copyWith Method', () {
      test('should create copy with updated fields', () {
        final updatedTask = sampleTask.copyWith(
          title: 'Updated Title',
          priority: TaskPriority.low,
          isCompleted: true,
        );

        expect(updatedTask.title, 'Updated Title');
        expect(updatedTask.priority, TaskPriority.low);
        expect(updatedTask.isCompleted, true);
        expect(updatedTask.id, sampleTask.id); // unchanged
        expect(updatedTask.categoryId, sampleTask.categoryId); // unchanged
        expect(updatedTask.updatedAt.isAfter(sampleTask.updatedAt), true);
      });

      test('should preserve unchanged fields', () {
        final updatedTask = sampleTask.copyWith(title: 'New Title');

        expect(updatedTask.description, sampleTask.description);
        expect(updatedTask.dueDate, sampleTask.dueDate);
        expect(updatedTask.dueTime, sampleTask.dueTime);
        expect(updatedTask.source, sampleTask.source);
      });

      test('should allow setting fields to null', () {
        final updatedTask = sampleTask.copyWith(
          description: null,
          dueDate: null,
          dueTime: null,
        );

        expect(updatedTask.description, null);
        expect(updatedTask.dueDate, null);
        expect(updatedTask.dueTime, null);
      });
    });

    group('Task State Methods', () {
      test('complete() should mark task as completed', () {
        final incompleteTask = TaskFixtures.createTask(isCompleted: false);
        final completedTask = incompleteTask.complete();

        expect(completedTask.isCompleted, true);
        expect(completedTask.id, incompleteTask.id);
        expect(completedTask.updatedAt.isAfter(incompleteTask.updatedAt), true);
      });

      test('uncomplete() should mark task as incomplete', () {
        final completedTask = TaskFixtures.createTask(isCompleted: true);
        final incompleteTask = completedTask.uncomplete();

        expect(incompleteTask.isCompleted, false);
        expect(incompleteTask.id, completedTask.id);
        expect(incompleteTask.updatedAt.isAfter(completedTask.updatedAt), true);
      });
    });

    group('Date/Time Property Tests', () {
      test('isOverdue should return true for past due tasks', () {
        final pastDate = DateTime.now().subtract(const Duration(days: 1));
        final overdueTask = TaskFixtures.createTask(
          dueDate: pastDate,
          isCompleted: false,
        );

        expect(overdueTask.isOverdue, true);
      });

      test('isOverdue should return false for completed tasks', () {
        final pastDate = DateTime.now().subtract(const Duration(days: 1));
        final completedTask = TaskFixtures.createTask(
          dueDate: pastDate,
          isCompleted: true,
        );

        expect(completedTask.isOverdue, false);
      });

      test('isOverdue should return false for future tasks', () {
        final futureDate = DateTime.now().add(const Duration(days: 1));
        final futureTask = TaskFixtures.createTask(
          dueDate: futureDate,
          isCompleted: false,
        );

        expect(futureTask.isOverdue, false);
      });

      test('isOverdue should return false for tasks without due date', () {
        final taskWithoutDate = TaskFixtures.createTask(
          dueDate: null,
          isCompleted: false,
        );

        expect(taskWithoutDate.isOverdue, false);
      });

      test('isDueToday should return true for tasks due today', () {
        final today = DateTime.now();
        final todayTask = TaskFixtures.createTask(dueDate: today);

        expect(todayTask.isDueToday, true);
      });

      test('isDueToday should return false for tasks due other days', () {
        final tomorrow = DateTime.now().add(const Duration(days: 1));
        final tomorrowTask = TaskFixtures.createTask(dueDate: tomorrow);

        expect(tomorrowTask.isDueToday, false);
      });

      test('isDueTomorrow should return true for tasks due tomorrow', () {
        final tomorrow = DateTime.now().add(const Duration(days: 1));
        final tomorrowTask = TaskFixtures.createTask(dueDate: tomorrow);

        expect(tomorrowTask.isDueTomorrow, true);
      });

      test('isDueTomorrow should return false for tasks due today', () {
        final today = DateTime.now();
        final todayTask = TaskFixtures.createTask(dueDate: today);

        expect(todayTask.isDueTomorrow, false);
      });
    });

    group('Display Properties', () {
      test('dueDateTimeDisplay should format today correctly', () {
        final today = DateTime.now();
        final task = TaskFixtures.createTask(
          dueDate: today,
          dueTime: const TimeOfDay(hour: 14, minute: 30),
        );

        expect(task.dueDateTimeDisplay, 'Today 2:30 PM');
      });

      test('dueDateTimeDisplay should format tomorrow correctly', () {
        final tomorrow = DateTime.now().add(const Duration(days: 1));
        final task = TaskFixtures.createTask(
          dueDate: tomorrow,
          dueTime: const TimeOfDay(hour: 9, minute: 15),
        );

        expect(task.dueDateTimeDisplay, 'Tomorrow 9:15 AM');
      });

      test('dueDateTimeDisplay should format future dates correctly', () {
        final futureDate = DateTime(2024, 12, 25);
        final task = TaskFixtures.createTask(
          dueDate: futureDate,
          dueTime: const TimeOfDay(hour: 18, minute: 0),
        );

        expect(task.dueDateTimeDisplay, '12/25/2024 6:00 PM');
      });

      test('dueDateTimeDisplay should handle date without time', () {
        final today = DateTime.now();
        final task = TaskFixtures.createTask(
          dueDate: today,
          dueTime: null,
        );

        expect(task.dueDateTimeDisplay, 'Today');
      });

      test('dueDateTimeDisplay should return null for tasks without due date', () {
        final task = TaskFixtures.createTask(dueDate: null);

        expect(task.dueDateTimeDisplay, null);
      });

      test('dueDateTimeDisplay should handle midnight correctly', () {
        final today = DateTime.now();
        final task = TaskFixtures.createTask(
          dueDate: today,
          dueTime: const TimeOfDay(hour: 0, minute: 0),
        );

        expect(task.dueDateTimeDisplay, 'Today 12:00 AM');
      });

      test('dueDateTimeDisplay should handle noon correctly', () {
        final today = DateTime.now();
        final task = TaskFixtures.createTask(
          dueDate: today,
          dueTime: const TimeOfDay(hour: 12, minute: 0),
        );

        expect(task.dueDateTimeDisplay, 'Today 12:00 PM');
      });
    });

    group('Serialization Tests', () {
      test('toMap should serialize task correctly', () {
        final task = TaskFixtures.createTask(
          id: 'test-id',
          title: 'Test Task',
          description: 'Test Description',
          categoryId: 'cat-1',
          dueDate: DateTime(2024, 3, 15),
          dueTime: const TimeOfDay(hour: 14, minute: 30),
          priority: TaskPriority.high,
          isCompleted: true,
          source: TaskSource.voice,
        );

        final map = task.toMap();

        expect(map['id'], 'test-id');
        expect(map['title'], 'Test Task');
        expect(map['description'], 'Test Description');
        expect(map['category_id'], 'cat-1');
        expect(map['due_date'], '2024-03-15');
        expect(map['due_time'], '14:30');
        expect(map['priority'], 2); // TaskPriority.high.index
        expect(map['completed'], 1);
        expect(map['source'], 'voice');
      });

      test('toMap should handle null values correctly', () {
        final task = TaskFixtures.createTask(
          description: null,
          dueDate: null,
          dueTime: null,
        );

        final map = task.toMap();

        expect(map['description'], null);
        expect(map['due_date'], null);
        expect(map['due_time'], null);
      });

      test('fromMap should deserialize task correctly', () {
        final map = {
          'id': 'test-id',
          'title': 'Test Task',
          'description': 'Test Description',
          'category_id': 'cat-1',
          'due_date': '2024-03-15T00:00:00.000',
          'due_time': '14:30',
          'priority': 2,
          'completed': 1,
          'created_at': '2024-03-15T10:00:00.000',
          'updated_at': '2024-03-15T10:30:00.000',
          'source': 'voice',
        };

        final task = Task.fromMap(map);

        expect(task.id, 'test-id');
        expect(task.title, 'Test Task');
        expect(task.description, 'Test Description');
        expect(task.categoryId, 'cat-1');
        expect(task.dueDate, DateTime(2024, 3, 15));
        expect(task.dueTime, const TimeOfDay(hour: 14, minute: 30));
        expect(task.priority, TaskPriority.high);
        expect(task.isCompleted, true);
        expect(task.source, TaskSource.voice);
      });

      test('fromMap should handle null values correctly', () {
        final map = {
          'id': 'test-id',
          'title': 'Test Task',
          'category_id': 'cat-1',
          'priority': 1,
          'completed': 0,
          'created_at': '2024-03-15T10:00:00.000',
          'updated_at': '2024-03-15T10:30:00.000',
          'source': 'manual',
        };

        final task = Task.fromMap(map);

        expect(task.description, null);
        expect(task.dueDate, null);
        expect(task.dueTime, null);
        expect(task.isCompleted, false);
      });

      test('fromMap should handle legacy field names', () {
        final map = {
          'id': 'test-id',
          'title': 'Test Task',
          'categoryId': 'cat-1', // legacy field name
          'isCompleted': true, // legacy field name
          'priority': 1,
          'source': 0, // legacy integer value
        };

        final task = Task.fromMap(map);

        expect(task.categoryId, 'cat-1');
        expect(task.isCompleted, true);
        expect(task.source, TaskSource.manual);
      });

      test('fromMap should provide defaults for missing fields', () {
        final map = {
          'id': 'test-id',
          'title': 'Test Task',
        };

        final task = Task.fromMap(map);

        expect(task.categoryId, '');
        expect(task.priority, TaskPriority.medium);
        expect(task.isCompleted, false);
        expect(task.source, TaskSource.manual);
        expect(task.createdAt.isBefore(DateTime.now().add(const Duration(seconds: 1))), true);
      });
    });

    group('Equality and HashCode', () {
      test('should be equal when IDs match', () {
        final task1 = TaskFixtures.createTask(id: 'same-id', title: 'Task 1');
        final task2 = TaskFixtures.createTask(id: 'same-id', title: 'Task 2');

        expect(task1, equals(task2));
        expect(task1.hashCode, equals(task2.hashCode));
      });

      test('should not be equal when IDs differ', () {
        final task1 = TaskFixtures.createTask(id: 'id-1', title: 'Same Title');
        final task2 = TaskFixtures.createTask(id: 'id-2', title: 'Same Title');

        expect(task1, isNot(equals(task2)));
        expect(task1.hashCode, isNot(equals(task2.hashCode)));
      });
    });

    group('toString Method', () {
      test('should return readable string representation', () {
        final task = TaskFixtures.createTask(
          id: 'test-id',
          title: 'Test Task',
          isCompleted: false,
          dueDate: DateTime(2024, 3, 15),
        );

        final string = task.toString();

        expect(string, contains('test-id'));
        expect(string, contains('Test Task'));
        expect(string, contains('false'));
        expect(string, contains('2024-03-15'));
      });
    });

    group('Edge Cases', () {
      test('should handle very long titles', () {
        final longTitle = 'A' * 1000;
        final task = TaskFixtures.createTask(title: longTitle);

        expect(task.title, longTitle);
        expect(task.title.length, 1000);
      });

      test('should handle special characters in title and description', () {
        const specialTitle = '!@#\$%^&*()_+{}|:<>?[]\\;\'\",./ 🎯📝✅';
        const specialDescription = 'Task with emojis: 🎯📝✅ and symbols: !@#\$%';
        
        final task = TaskFixtures.createTask(
          title: specialTitle,
          description: specialDescription,
        );

        expect(task.title, specialTitle);
        expect(task.description, specialDescription);
      });

      test('should handle extreme dates', () {
        final veryOldDate = DateTime(1900, 1, 1);
        final veryFutureDate = DateTime(2100, 12, 31);

        final oldTask = TaskFixtures.createTask(dueDate: veryOldDate);
        final futureTask = TaskFixtures.createTask(dueDate: veryFutureDate);

        expect(oldTask.dueDate, veryOldDate);
        expect(futureTask.dueDate, veryFutureDate);
        expect(oldTask.isOverdue, true);
        expect(futureTask.isOverdue, false);
      });

      test('should handle invalid time parsing gracefully', () {
        final map = {
          'id': 'test-id',
          'title': 'Test Task',
          'category_id': 'cat-1',
          'due_time': 'invalid-time',
          'priority': 1,
          'completed': 0,
          'created_at': '2024-03-15T10:00:00.000',
          'updated_at': '2024-03-15T10:30:00.000',
          'source': 'manual',
        };

        final task = Task.fromMap(map);
        expect(task.dueTime, null);
      });
    });
  });

  group('TaskPriority Enum Tests', () {
    test('should have correct display names', () {
      expect(TaskPriority.low.displayName, 'Low');
      expect(TaskPriority.medium.displayName, 'Medium');
      expect(TaskPriority.high.displayName, 'High');
      expect(TaskPriority.urgent.displayName, 'Urgent');
    });

    test('should have correct index values', () {
      expect(TaskPriority.low.index, 0);
      expect(TaskPriority.medium.index, 1);
      expect(TaskPriority.high.index, 2);
      expect(TaskPriority.urgent.index, 3);
    });
  });

  group('TaskSource Enum Tests', () {
    test('should have correct values', () {
      expect(TaskSource.manual.name, 'manual');
      expect(TaskSource.voice.name, 'voice');
      expect(TaskSource.chat.name, 'chat');
      expect(TaskSource.calendar.name, 'calendar');
    });
  });

  group('ReminderInterval Enum Tests', () {
    test('should have correct display names', () {
      expect(ReminderInterval.oneHour.displayName, '1 hour before');
      expect(ReminderInterval.sixHours.displayName, '6 hours before');
      expect(ReminderInterval.twelveHours.displayName, '12 hours before');
      expect(ReminderInterval.oneDay.displayName, '1 day before');
    });

    test('should have correct durations', () {
      expect(ReminderInterval.oneHour.duration, const Duration(hours: 1));
      expect(ReminderInterval.sixHours.duration, const Duration(hours: 6));
      expect(ReminderInterval.twelveHours.duration, const Duration(hours: 12));
      expect(ReminderInterval.oneDay.duration, const Duration(days: 1));
    });
  });
}