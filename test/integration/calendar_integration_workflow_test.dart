import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:task_tracker_app/main.dart' as app;
import 'package:task_tracker_app/shared/models/models.dart';
import '../test_utils/fixtures.dart';
import '../test_utils/test_helpers.dart';

/// Integration tests for calendar integration workflows
/// Tests calendar view, scheduling, and date-based task management
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Calendar Integration Workflow Tests', () {
    
    testWidgets('Navigate to calendar view and display tasks', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Navigate to calendar tab
      await tester.tap(find.byIcon(Icons.calendar_today));
      await tester.pumpAndSettle();

      // Should show calendar widget
      expect(find.byType(TableCalendar), findsOneWidget);
      
      // Should show current month
      final now = DateTime.now();
      final monthYear = DateFormat('MMMM yyyy').format(now);
      expect(find.text(monthYear), findsOneWidget);

      // Should show today highlighted
      expect(find.text(now.day.toString()), findsOneWidget);
    });

    testWidgets('Create task from calendar date selection', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Navigate to calendar
      await tester.tap(find.byIcon(Icons.calendar_today));
      await tester.pumpAndSettle();

      // Tap on a future date
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      await tester.tap(find.text(tomorrow.day.toString()).last);
      await tester.pumpAndSettle();

      // Should show "Add task for [date]" option
      expect(find.text('Add task for ${DateFormat('MMM d').format(tomorrow)}'), findsOneWidget);

      await tester.tap(find.text('Add task for ${DateFormat('MMM d').format(tomorrow)}'));
      await tester.pumpAndSettle();

      // Should open task creation with pre-filled date
      expect(find.text('New Task'), findsOneWidget);
      expect(find.text(DateFormat('MMM d, yyyy').format(tomorrow)), findsOneWidget);

      // Create the task
      await tester.enterText(find.byType(TextField).first, 'Calendar scheduled task');
      await tester.tap(find.text('Save Task'));
      await tester.pumpAndSettle();

      // Navigate back to calendar
      await tester.tap(find.byIcon(Icons.calendar_today));
      await tester.pumpAndSettle();

      // Task should appear on calendar
      await tester.tap(find.text(tomorrow.day.toString()).last);
      await tester.pumpAndSettle();

      expect(find.text('Calendar scheduled task'), findsOneWidget);
    });

    testWidgets('View task details from calendar', (tester) async {
      // Pre-create some tasks
      await TestHelpers.createTasksForDate(tester, DateTime.now(), [
        'Morning meeting',
        'Lunch with client',
        'Afternoon review'
      ]);

      app.main();
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.calendar_today));
      await tester.pumpAndSettle();

      // Today should show task indicators
      final today = DateTime.now();
      await tester.tap(find.text(today.day.toString()));
      await tester.pumpAndSettle();

      // Should show list of today's tasks
      expect(find.text('Tasks for Today'), findsOneWidget);
      expect(find.text('Morning meeting'), findsOneWidget);
      expect(find.text('Lunch with client'), findsOneWidget);
      expect(find.text('Afternoon review'), findsOneWidget);

      // Tap on a specific task
      await tester.tap(find.text('Morning meeting'));
      await tester.pumpAndSettle();

      // Should show task details
      expect(find.text('Task Details'), findsOneWidget);
      expect(find.text('Morning meeting'), findsOneWidget);
    });

    testWidgets('Navigate between calendar months', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.calendar_today));
      await tester.pumpAndSettle();

      final currentMonth = DateTime.now();
      
      // Navigate to next month
      await tester.tap(find.byIcon(Icons.chevron_right));
      await tester.pumpAndSettle();

      final nextMonth = DateTime(currentMonth.year, currentMonth.month + 1);
      final nextMonthName = DateFormat('MMMM yyyy').format(nextMonth);
      expect(find.text(nextMonthName), findsOneWidget);

      // Navigate back to current month
      await tester.tap(find.byIcon(Icons.chevron_left));
      await tester.pumpAndSettle();

      final currentMonthName = DateFormat('MMMM yyyy').format(currentMonth);
      expect(find.text(currentMonthName), findsOneWidget);

      // Navigate to previous month
      await tester.tap(find.byIcon(Icons.chevron_left));
      await tester.pumpAndSettle();

      final prevMonth = DateTime(currentMonth.year, currentMonth.month - 1);
      final prevMonthName = DateFormat('MMMM yyyy').format(prevMonth);
      expect(find.text(prevMonthName), findsOneWidget);
    });

    testWidgets('Week view integration', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.calendar_today));
      await tester.pumpAndSettle();

      // Switch to week view
      await tester.tap(find.text('Week'));
      await tester.pumpAndSettle();

      // Should show week view with days of current week
      final now = DateTime.now();
      final weekStart = now.subtract(Duration(days: now.weekday - 1));
      
      for (int i = 0; i < 7; i++) {
        final day = weekStart.add(Duration(days: i));
        expect(find.text(DateFormat('E').format(day)), findsOneWidget); // Mon, Tue, etc.
      }

      // Should show hourly slots
      expect(find.text('9 AM'), findsOneWidget);
      expect(find.text('12 PM'), findsOneWidget);
      expect(find.text('3 PM'), findsOneWidget);
    });

    testWidgets('Drag and drop task to reschedule', (tester) async {
      // Create a task for today
      await TestHelpers.createTasksForDate(tester, DateTime.now(), ['Reschedule me']);

      app.main();
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.calendar_today));
      await tester.pumpAndSettle();

      // Switch to week view for easier drag and drop
      await tester.tap(find.text('Week'));
      await tester.pumpAndSettle();

      // Find the task
      final taskFinder = find.text('Reschedule me');
      expect(taskFinder, findsOneWidget);

      // Drag task to tomorrow's slot
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      final tomorrowSlot = find.textContaining(DateFormat('E').format(tomorrow));
      
      await tester.drag(taskFinder, const Offset(200, 0));
      await tester.pumpAndSettle();

      // Should show reschedule confirmation
      expect(find.text('Reschedule task?'), findsOneWidget);
      expect(find.text('Move to ${DateFormat('MMM d').format(tomorrow)}'), findsOneWidget);

      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();

      // Task should now appear on tomorrow
      await tester.tap(find.textContaining(DateFormat('E').format(tomorrow)));
      await tester.pumpAndSettle();

      expect(find.text('Reschedule me'), findsOneWidget);
    });

    testWidgets('Calendar agenda view integration', (tester) async {
      // Create tasks for multiple days
      final today = DateTime.now();
      await TestHelpers.createTasksForDate(tester, today, ['Today task']);
      await TestHelpers.createTasksForDate(tester, today.add(const Duration(days: 1)), ['Tomorrow task']);
      await TestHelpers.createTasksForDate(tester, today.add(const Duration(days: 2)), ['Day after task']);

      app.main();
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.calendar_today));
      await tester.pumpAndSettle();

      // Switch to agenda view
      await tester.tap(find.text('Agenda'));
      await tester.pumpAndSettle();

      // Should show upcoming tasks in chronological order
      expect(find.text('Today'), findsOneWidget);
      expect(find.text('Today task'), findsOneWidget);
      
      expect(find.text('Tomorrow'), findsOneWidget);
      expect(find.text('Tomorrow task'), findsOneWidget);
      
      expect(find.text(DateFormat('EEEE').format(today.add(const Duration(days: 2)))), findsOneWidget);
      expect(find.text('Day after task'), findsOneWidget);
    });

    testWidgets('Time-based task scheduling in day view', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.calendar_today));
      await tester.pumpAndSettle();

      // Switch to day view
      await tester.tap(find.text('Day'));
      await tester.pumpAndSettle();

      // Should show hourly time slots for today
      expect(find.text('8:00 AM'), findsOneWidget);
      expect(find.text('9:00 AM'), findsOneWidget);
      expect(find.text('10:00 AM'), findsOneWidget);

      // Tap on 2:00 PM slot
      await tester.tap(find.text('2:00 PM'));
      await tester.pumpAndSettle();

      // Should open quick task creation for that time
      expect(find.text('New task at 2:00 PM'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'Afternoon meeting');
      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle();

      // Task should appear in the 2:00 PM slot
      expect(find.text('Afternoon meeting'), findsOneWidget);
    });

    testWidgets('Calendar task completion workflow', (tester) async {
      // Create tasks with different completion states
      await TestHelpers.createTasksWithStates(tester, [
        {'title': 'Completed task', 'completed': true, 'date': DateTime.now()},
        {'title': 'Pending task', 'completed': false, 'date': DateTime.now()},
        {'title': 'Overdue task', 'completed': false, 'date': DateTime.now().subtract(const Duration(days: 1))},
      ]);

      app.main();
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.calendar_today));
      await tester.pumpAndSettle();

      // Today should show completed and pending tasks differently
      final today = DateTime.now();
      await tester.tap(find.text(today.day.toString()));
      await tester.pumpAndSettle();

      // Completed task should be shown with checkmark
      expect(find.text('Completed task'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);

      // Pending task should have checkbox
      expect(find.text('Pending task'), findsOneWidget);
      
      // Complete the pending task
      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();

      // Should update to completed state
      expect(find.byIcon(Icons.check_circle), findsNWidgets(2)); // Both tasks now completed
    });

    testWidgets('Calendar filtering and search', (tester) async {
      // Create tasks in different categories
      await TestHelpers.createCategorizedTasks(tester, {
        'Work': ['Team meeting', 'Project deadline'],
        'Personal': ['Grocery shopping', 'Call mom'],
        'Health': ['Doctor appointment', 'Gym session'],
      });

      app.main();
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.calendar_today));
      await tester.pumpAndSettle();

      // Open filter menu
      await tester.tap(find.byIcon(Icons.filter_list));
      await tester.pumpAndSettle();

      // Filter by Work category
      await tester.tap(find.text('Work'));
      await tester.tap(find.text('Apply'));
      await tester.pumpAndSettle();

      // Should only show work tasks
      expect(find.text('Team meeting'), findsOneWidget);
      expect(find.text('Project deadline'), findsOneWidget);
      expect(find.text('Grocery shopping'), findsNothing);

      // Clear filter
      await tester.tap(find.byIcon(Icons.filter_list));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Clear All'));
      await tester.tap(find.text('Apply'));
      await tester.pumpAndSettle();

      // Should show all tasks again
      expect(find.text('Team meeting'), findsOneWidget);
      expect(find.text('Grocery shopping'), findsOneWidget);
    });

    testWidgets('Calendar export and sharing', (tester) async {
      // Create some tasks to export
      await TestHelpers.createTasksForDateRange(tester, 
        DateTime.now(), 
        DateTime.now().add(const Duration(days: 7)),
        ['Daily standup', 'Weekly review', 'Client presentation']
      );

      app.main();
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.calendar_today));
      await tester.pumpAndSettle();

      // Open options menu
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      // Select export option
      await tester.tap(find.text('Export Calendar'));
      await tester.pumpAndSettle();

      // Should show export options
      expect(find.text('Export Options'), findsOneWidget);
      expect(find.text('Export as ICS'), findsOneWidget);
      expect(find.text('Share Calendar Link'), findsOneWidget);
      expect(find.text('Print Calendar'), findsOneWidget);

      // Test ICS export
      await tester.tap(find.text('Export as ICS'));
      await tester.pumpAndSettle();

      // Should show export configuration
      expect(find.text('Date Range'), findsOneWidget);
      expect(find.text('Include Completed Tasks'), findsOneWidget);
      expect(find.text('Categories to Include'), findsOneWidget);

      await tester.tap(find.text('Export'));
      await tester.pumpAndSettle();

      // Should show export success
      expect(find.text('Calendar exported successfully'), findsOneWidget);
    });

    testWidgets('Calendar sync with external calendar', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.calendar_today));
      await tester.pumpAndSettle();

      // Open settings
      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();

      // Navigate to calendar sync settings
      await tester.tap(find.text('Calendar Sync'));
      await tester.pumpAndSettle();

      // Should show sync options
      expect(find.text('Google Calendar'), findsOneWidget);
      expect(find.text('Apple Calendar'), findsOneWidget);
      expect(find.text('Outlook Calendar'), findsOneWidget);

      // Enable Google Calendar sync
      await tester.tap(find.text('Google Calendar'));
      await tester.pumpAndSettle();

      // Should show authentication flow (mocked)
      expect(find.text('Connect to Google Calendar'), findsOneWidget);
      await tester.tap(find.text('Authorize'));
      await tester.pumpAndSettle();

      // Should show sync configuration
      expect(find.text('Sync Settings'), findsOneWidget);
      expect(find.text('Two-way sync'), findsOneWidget);
      expect(find.text('Sync interval: Every 15 minutes'), findsOneWidget);

      // Enable sync
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      // Should show sync status
      expect(find.text('Sync enabled'), findsOneWidget);
      expect(find.byIcon(Icons.sync), findsOneWidget);
    });

    group('Calendar Performance Tests', () {
      testWidgets('Calendar performance with many tasks', (tester) async {
        // Create many tasks across multiple months
        await TestHelpers.createManyTasksAcrossTime(tester, 
          startDate: DateTime.now().subtract(const Duration(days: 30)),
          endDate: DateTime.now().add(const Duration(days: 60)),
          taskCount: 500
        );

        app.main();
        await tester.pumpAndSettle();

        final stopwatch = Stopwatch()..start();

        // Navigate to calendar
        await tester.tap(find.byIcon(Icons.calendar_today));
        await tester.pumpAndSettle();

        stopwatch.stop();

        // Should load calendar quickly even with many tasks
        expect(stopwatch.elapsedMilliseconds, lessThan(2000));
        expect(find.byType(TableCalendar), findsOneWidget);

        // Test month navigation performance
        final navigationStopwatch = Stopwatch()..start();

        for (int i = 0; i < 5; i++) {
          await tester.tap(find.byIcon(Icons.chevron_right));
          await tester.pumpAndSettle();
        }

        navigationStopwatch.stop();
        expect(navigationStopwatch.elapsedMilliseconds, lessThan(3000));
      });

      testWidgets('Memory usage during calendar navigation', (tester) async {
        app.main();
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.calendar_today));
        await tester.pumpAndSettle();

        // Navigate through many months rapidly
        for (int i = 0; i < 20; i++) {
          await tester.tap(find.byIcon(Icons.chevron_right));
          await tester.pump(const Duration(milliseconds: 100));
        }

        // Navigate back
        for (int i = 0; i < 20; i++) {
          await tester.tap(find.byIcon(Icons.chevron_left));
          await tester.pump(const Duration(milliseconds: 100));
        }

        // Should handle navigation without memory issues
        expect(tester.takeException(), isNull);
        expect(find.byType(TableCalendar), findsOneWidget);
      });
    });

    group('Calendar Edge Cases', () {
      testWidgets('Handle timezone changes', (tester) async {
        app.main();
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.calendar_today));
        await tester.pumpAndSettle();

        // Simulate timezone change
        await TestHelpers.simulateTimezoneChange(tester, 'UTC+8');
        await tester.pumpAndSettle();

        // Calendar should update to reflect new timezone
        expect(find.byType(TableCalendar), findsOneWidget);
        
        // Tasks should show correct times in new timezone
        // This would need specific task with time to verify
      });

      testWidgets('Handle date rollover at midnight', (tester) async {
        // Simulate app running at 11:59 PM
        await TestHelpers.simulateTimeOfDay(tester, const TimeOfDay(hour: 23, minute: 59));

        app.main();
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.calendar_today));
        await tester.pumpAndSettle();

        // Wait for time to roll over to midnight
        await TestHelpers.simulateTimeOfDay(tester, const TimeOfDay(hour: 0, minute: 1));
        await tester.pump();

        // Calendar should update to show new day
        final newDay = DateTime.now().add(const Duration(days: 1));
        expect(find.text(newDay.day.toString()), findsOneWidget);
      });

      testWidgets('Handle leap year dates', (tester) async {
        // Simulate leap year (2024)
        await TestHelpers.simulateDate(tester, DateTime(2024, 2, 29));

        app.main();
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.calendar_today));
        await tester.pumpAndSettle();

        // Should correctly show February 29th
        expect(find.text('29'), findsOneWidget);
        expect(find.text('February 2024'), findsOneWidget);

        // Create task on leap day
        await tester.tap(find.text('29'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Add task for Feb 29'));
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextField).first, 'Leap day task');
        await tester.tap(find.text('Save Task'));
        await tester.pumpAndSettle();

        // Task should be created successfully
        expect(find.text('Leap day task'), findsOneWidget);
      });
    });
  });
}