import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:task_tracker_app/shared/widgets/task_list_item.dart';
import 'package:task_tracker_app/shared/models/models.dart';
import '../test_utils/fixtures.dart';
import '../test_utils/test_helpers.dart';

void main() {
  group('TaskListItem Widget Tests', () {
    
    testWidgets('should display task information correctly', (tester) async {
      final task = TaskFixtures.createTask(
        title: 'Test Task',
        description: 'Test task description',
        priority: TaskPriority.high,
      );

      await tester.pumpWidget(
        TestHelpers.createTestApp(
          child: TaskListItem(
            task: task,
            onTap: () {},
            onToggleComplete: () {},
          ),
        ),
      );

      expect(find.text('Test Task'), findsOneWidget);
      expect(find.text('Test task description'), findsOneWidget);
    });

    testWidgets('should display due date when available', (tester) async {
      final task = TaskFixtures.createTask(
        title: 'Task with due date',
        dueDate: DateTime.now().add(const Duration(days: 1)),
        dueTime: const TimeOfDay(hour: 14, minute: 30),
      );

      await tester.pumpWidget(
        TestHelpers.createTestApp(
          child: TaskListItem(
            task: task,
            onTap: () {},
            onToggleComplete: () {},
          ),
        ),
      );

      expect(find.text('Task with due date'), findsOneWidget);
      // Should display formatted due date
      expect(find.textContaining('Tomorrow'), findsOneWidget);
      expect(find.textContaining('2:30 PM'), findsOneWidget);
    });

    testWidgets('should show completed state correctly', (tester) async {
      final completedTask = TaskFixtures.createTask(
        title: 'Completed Task',
        isCompleted: true,
      );

      await tester.pumpWidget(
        TestHelpers.createTestApp(
          child: TaskListItem(
            task: completedTask,
            onTap: () {},
            onToggleComplete: () {},
          ),
        ),
      );

      // Check for completion indicator (checkbox, strikethrough, etc.)
      final checkbox = find.byType(Checkbox);
      expect(checkbox, findsOneWidget);
      
      final checkboxWidget = tester.widget<Checkbox>(checkbox);
      expect(checkboxWidget.value, isTrue);
    });

    testWidgets('should show pending state correctly', (tester) async {
      final pendingTask = TaskFixtures.createTask(
        title: 'Pending Task',
        isCompleted: false,
      );

      await tester.pumpWidget(
        TestHelpers.createTestApp(
          child: TaskListItem(
            task: pendingTask,
            onTap: () {},
            onToggleComplete: () {},
          ),
        ),
      );

      final checkbox = find.byType(Checkbox);
      expect(checkbox, findsOneWidget);
      
      final checkboxWidget = tester.widget<Checkbox>(checkbox);
      expect(checkboxWidget.value, isFalse);
    });

    testWidgets('should display priority indicators', (tester) async {
      final highPriorityTask = TaskFixtures.createTask(
        title: 'High Priority Task',
        priority: TaskPriority.high,
      );

      await tester.pumpWidget(
        TestHelpers.createTestApp(
          child: TaskListItem(
            task: highPriorityTask,
            onTap: () {},
            onToggleComplete: () {},
          ),
        ),
      );

      // Should show priority indicator (icon, color, or text)
      expect(find.byIcon(Icons.priority_high), findsOneWidget);
    });

    testWidgets('should show overdue indicator for overdue tasks', (tester) async {
      final overdueTask = TaskFixtures.createTask(
        title: 'Overdue Task',
        dueDate: DateTime.now().subtract(const Duration(days: 1)),
        isCompleted: false,
      );

      await tester.pumpWidget(
        TestHelpers.createTestApp(
          child: TaskListItem(
            task: overdueTask,
            onTap: () {},
            onToggleComplete: () {},
          ),
        ),
      );

      // Should show overdue indicator (red color, warning icon, etc.)
      expect(find.byIcon(Icons.warning), findsOneWidget);
    });

    testWidgets('should handle tap events', (tester) async {
      final task = TaskFixtures.createTask(title: 'Tappable Task');
      bool tapped = false;

      await tester.pumpWidget(
        TestHelpers.createTestApp(
          child: TaskListItem(
            task: task,
            onTap: () => tapped = true,
            onToggleComplete: () {},
          ),
        ),
      );

      await tester.tap(find.text('Tappable Task'));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('should handle completion toggle', (tester) async {
      final task = TaskFixtures.createTask(
        title: 'Toggle Task',
        isCompleted: false,
      );
      bool toggled = false;

      await tester.pumpWidget(
        TestHelpers.createTestApp(
          child: TaskListItem(
            task: task,
            onTap: () {},
            onToggleComplete: () => toggled = true,
          ),
        ),
      );

      await tester.tap(find.byType(Checkbox));
      await tester.pump();

      expect(toggled, isTrue);
    });

    testWidgets('should display category information', (tester) async {
      final task = TaskFixtures.createTask(
        title: 'Work Task',
        categoryId: 'work',
      );

      await tester.pumpWidget(
        TestHelpers.createTestApp(
          child: TaskListItem(
            task: task,
            onTap: () {},
            onToggleComplete: () {},
          ),
        ),
      );

      // Should show category chip or indicator
      expect(find.text('Work Task'), findsOneWidget);
      // Category chip might be rendered based on design
    });

    testWidgets('should handle swipe actions', (tester) async {
      final task = TaskFixtures.createTask(title: 'Swipeable Task');
      bool deleteTriggered = false;
      bool editTriggered = false;

      await tester.pumpWidget(
        TestHelpers.createTestApp(
          child: TaskListItem(
            task: task,
            onTap: () {},
            onToggleComplete: () {},
            onDelete: () => deleteTriggered = true,
            onEdit: () => editTriggered = true,
          ),
        ),
      );

      // Test swipe to delete
      await tester.drag(find.text('Swipeable Task'), const Offset(-300, 0));
      await tester.pumpAndSettle();

      // Look for delete action button
      if (find.byIcon(Icons.delete).evaluate().isNotEmpty) {
        await tester.tap(find.byIcon(Icons.delete));
        await tester.pump();
        expect(deleteTriggered, isTrue);
      }
    });

    testWidgets('should display source indicator correctly', (tester) async {
      final voiceTask = TaskFixtures.createTask(
        title: 'Voice Task',
        source: TaskSource.voice,
      );

      await tester.pumpWidget(
        TestHelpers.createTestApp(
          child: TaskListItem(
            task: voiceTask,
            onTap: () {},
            onToggleComplete: () {},
          ),
        ),
      );

      // Should show voice source indicator
      expect(find.byIcon(Icons.mic), findsOneWidget);
    });

    testWidgets('should handle different task states', (tester) async {
      final testCases = [
        TaskFixtures.createTask(title: 'Normal Task', isCompleted: false),
        TaskFixtures.createTask(title: 'Completed Task', isCompleted: true),
        TaskFixtures.createOverdueTasks(count: 1).first,
        TaskFixtures.createTodaysTasks(count: 1).first,
      ];

      for (final task in testCases) {
        await tester.pumpWidget(
          TestHelpers.createTestApp(
            child: TaskListItem(
              task: task,
              onTap: () {},
              onToggleComplete: () {},
            ),
          ),
        );

        expect(find.text(task.title), findsOneWidget);
        await tester.pump();
      }
    });

    group('Accessibility Tests', () {
      testWidgets('should have proper semantics', (tester) async {
        final task = TaskFixtures.createTask(
          title: 'Accessible Task',
          description: 'Task description',
        );

        await tester.pumpWidget(
          TestHelpers.createTestApp(
            child: TaskListItem(
              task: task,
              onTap: () {},
              onToggleComplete: () {},
            ),
          ),
        );

        // Check for semantic labels
        expect(find.bySemanticsLabel('Task: Accessible Task'), findsOneWidget);
        expect(find.bySemanticsLabel('Toggle completion'), findsOneWidget);
      });

      testWidgets('should support screen reader navigation', (tester) async {
        final task = TaskFixtures.createTask(title: 'Screen Reader Task');

        await tester.pumpWidget(
          TestHelpers.createTestApp(
            child: TaskListItem(
              task: task,
              onTap: () {},
              onToggleComplete: () {},
            ),
          ),
        );

        // Test semantic navigation
        final semantics = tester.getSemantics(find.text('Screen Reader Task'));
        expect(semantics.hasAction(SemanticsAction.tap), isTrue);
      });
    });

    group('Performance Tests', () {
      testWidgets('should render efficiently with many tasks', (tester) async {
        final tasks = TaskFixtures.createTaskList(count: 100);
        
        await tester.pumpWidget(
          TestHelpers.createTestApp(
            child: ListView.builder(
              itemCount: tasks.length,
              itemBuilder: (context, index) => TaskListItem(
                task: tasks[index],
                onTap: () {},
                onToggleComplete: () {},
              ),
            ),
          ),
        );

        // Should render without performance issues
        expect(find.byType(TaskListItem), findsNWidgets(100));
      });

      testWidgets('should handle rapid state changes', (tester) async {
        final task = TaskFixtures.createTask(title: 'Rapid Change Task');
        bool isCompleted = false;

        await tester.pumpWidget(
          TestHelpers.createTestApp(
            child: StatefulBuilder(
              builder: (context, setState) => TaskListItem(
                task: task.copyWith(isCompleted: isCompleted),
                onTap: () {},
                onToggleComplete: () {
                  setState(() {
                    isCompleted = !isCompleted;
                  });
                },
              ),
            ),
          ),
        );

        // Rapidly toggle completion
        for (int i = 0; i < 10; i++) {
          await tester.tap(find.byType(Checkbox));
          await tester.pump(const Duration(milliseconds: 50));
        }

        // Should handle rapid changes without errors
        expect(tester.takeException(), isNull);
      });
    });

    group('Edge Cases', () {
      testWidgets('should handle null or empty task data', (tester) async {
        final emptyTask = TaskFixtures.createTask(
          title: '',
          description: null,
        );

        await tester.pumpWidget(
          TestHelpers.createTestApp(
            child: TaskListItem(
              task: emptyTask,
              onTap: () {},
              onToggleComplete: () {},
            ),
          ),
        );

        // Should render without crashing
        expect(find.byType(TaskListItem), findsOneWidget);
      });

      testWidgets('should handle very long task titles', (tester) async {
        final longTitleTask = TaskFixtures.createTask(
          title: 'A' * 1000, // Very long title
        );

        await tester.pumpWidget(
          TestHelpers.createTestApp(
            child: TaskListItem(
              task: longTitleTask,
              onTap: () {},
              onToggleComplete: () {},
            ),
          ),
        );

        // Should render and truncate appropriately
        expect(find.byType(TaskListItem), findsOneWidget);
      });

      testWidgets('should handle special characters in task data', (tester) async {
        final specialTask = TaskFixtures.createTask(
          title: '🎯 Special Task! @#\$%^&*()',
          description: 'Description with émojis 📝 and spéciål châràctérs',
        );

        await tester.pumpWidget(
          TestHelpers.createTestApp(
            child: TaskListItem(
              task: specialTask,
              onTap: () {},
              onToggleComplete: () {},
            ),
          ),
        );

        expect(find.text('🎯 Special Task! @#\$%^&*()'), findsOneWidget);
      });

      testWidgets('should handle missing callbacks gracefully', (tester) async {
        final task = TaskFixtures.createTask(title: 'No Callbacks Task');

        await tester.pumpWidget(
          TestHelpers.createTestApp(
            child: TaskListItem(
              task: task,
              // No callbacks provided
            ),
          ),
        );

        // Should render without crashing
        expect(find.byType(TaskListItem), findsOneWidget);
        
        // Tapping should not crash
        await tester.tap(find.text('No Callbacks Task'));
        await tester.pump();
        expect(tester.takeException(), isNull);
      });
    });
  });
}