import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:task_tracker_app/main.dart' as app;
import 'package:task_tracker_app/shared/models/models.dart';
import '../test_utils/fixtures.dart';
import '../test_utils/test_helpers.dart';

/// Integration tests for complete task creation workflows
/// Tests the entire user journey from task creation to completion
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Task Creation Workflow Integration Tests', () {
    
    testWidgets('Complete manual task creation workflow', (tester) async {
      // Start the app
      app.main();
      await tester.pumpAndSettle();

      // Navigate to task creation screen
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      // Fill in task details
      await tester.enterText(find.byType(TextField).first, 'Buy groceries');
      await tester.enterText(find.byType(TextField).at(1), 'Get milk, bread, and eggs');

      // Select category
      await tester.tap(find.text('Household'));
      await tester.pumpAndSettle();

      // Set due date (tomorrow)
      await tester.tap(find.byIcon(Icons.calendar_today));
      await tester.pumpAndSettle();
      
      // Find tomorrow's date and tap it
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      await tester.tap(find.text(tomorrow.day.toString()));
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      // Set due time
      await tester.tap(find.byIcon(Icons.access_time));
      await tester.pumpAndSettle();
      
      // Set time to 3:00 PM
      await tester.tap(find.text('3'));
      await tester.tap(find.text('00'));
      await tester.tap(find.text('PM'));
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      // Set priority to high
      await tester.tap(find.text('High'));
      await tester.pumpAndSettle();

      // Enable reminder
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      // Save the task
      await tester.tap(find.text('Save Task'));
      await tester.pumpAndSettle();

      // Verify task appears in the list
      expect(find.text('Buy groceries'), findsOneWidget);
      expect(find.text('Tomorrow 3:00 PM'), findsOneWidget);
      expect(find.byIcon(Icons.priority_high), findsOneWidget);
    });

    testWidgets('Voice-based task creation workflow', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Tap voice input button
      await tester.tap(find.byIcon(Icons.mic));
      await tester.pumpAndSettle();

      // Wait for voice input overlay to appear
      expect(find.text('Listening...'), findsOneWidget);

      // Simulate voice input processing
      // In real integration test, this would involve actual voice recognition
      // For now, we'll simulate the result being processed
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Simulate voice result: "Call doctor tomorrow at 2 PM"
      // This would be processed by the voice service and NLP
      await TestHelpers.simulateVoiceInput(tester, 'Call doctor tomorrow at 2 PM');

      // Wait for processing
      await tester.pumpAndSettle();

      // Verify task preview appears
      expect(find.text('Call doctor'), findsOneWidget);
      expect(find.text('Tomorrow 2:00 PM'), findsOneWidget);
      expect(find.text('Health'), findsOneWidget); // Auto-categorized

      // Confirm the task
      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();

      // Verify task is added to the list
      expect(find.text('Call doctor'), findsOneWidget);
      expect(find.byIcon(Icons.mic), findsOneWidget); // Voice source indicator
    });

    testWidgets('Chat integration task creation workflow', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Simulate sharing text from external app (WhatsApp/Messages)
      const sharedText = 'Hey, can you pick up the kids from school at 3:15 PM today?';
      
      // This would normally come through intent handling
      await TestHelpers.simulateSharedText(tester, sharedText);
      await tester.pumpAndSettle();

      // Verify chat integration dialog appears
      expect(find.text('Create Task from Message'), findsOneWidget);
      expect(find.text(sharedText), findsOneWidget);

      // Verify extracted task information
      expect(find.text('Pick up kids from school'), findsOneWidget);
      expect(find.text('Today 3:15 PM'), findsOneWidget);
      expect(find.text('Family'), findsOneWidget);

      // Adjust extracted information if needed
      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, 'Pick up children from school');
      
      // Confirm and save
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Verify task is created
      expect(find.text('Pick up children from school'), findsOneWidget);
      expect(find.byIcon(Icons.chat), findsOneWidget); // Chat source indicator
    });

    testWidgets('Quick task creation workflow', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Use quick add feature (long press on FAB or swipe gesture)
      await tester.longPress(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      // Quick add dialog should appear
      expect(find.text('Quick Add Task'), findsOneWidget);

      // Enter task title only
      await tester.enterText(find.byType(TextField), 'Buy coffee');
      
      // Press enter or tap add
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      // Task should be created with defaults
      expect(find.text('Buy coffee'), findsOneWidget);
      expect(find.text('Personal'), findsOneWidget); // Default category
    });

    testWidgets('Duplicate task creation handling', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Create first task
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, 'Call dentist');
      await tester.tap(find.text('Save Task'));
      await tester.pumpAndSettle();

      // Try to create similar task
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, 'Call dentist');
      await tester.tap(find.text('Save Task'));
      await tester.pumpAndSettle();

      // Should show duplicate warning
      expect(find.text('Similar task exists'), findsOneWidget);
      expect(find.text('Create anyway'), findsOneWidget);
      expect(find.text('Edit existing'), findsOneWidget);

      // Choose to edit existing
      await tester.tap(find.text('Edit existing'));
      await tester.pumpAndSettle();

      // Should navigate to existing task edit screen
      expect(find.text('Edit Task'), findsOneWidget);
      expect(find.text('Call dentist'), findsOneWidget);
    });

    testWidgets('Task creation with validation errors', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      // Try to save without title
      await tester.tap(find.text('Save Task'));
      await tester.pumpAndSettle();

      // Should show validation error
      expect(find.text('Task title is required'), findsOneWidget);

      // Enter title but select past due date
      await tester.enterText(find.byType(TextField).first, 'Past task');
      
      await tester.tap(find.byIcon(Icons.calendar_today));
      await tester.pumpAndSettle();
      
      // Select yesterday
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      await tester.tap(find.text(yesterday.day.toString()));
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save Task'));
      await tester.pumpAndSettle();

      // Should show warning about past due date
      expect(find.text('Due date is in the past'), findsOneWidget);
      expect(find.text('Save anyway'), findsOneWidget);
      expect(find.text('Change date'), findsOneWidget);
    });

    testWidgets('Task creation with reminders workflow', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      // Fill in basic task info
      await tester.enterText(find.byType(TextField).first, 'Important meeting');
      
      // Set due date to tomorrow
      await tester.tap(find.byIcon(Icons.calendar_today));
      await tester.pumpAndSettle();
      
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      await tester.tap(find.text(tomorrow.day.toString()));
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      // Enable reminders
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      // Select reminder intervals
      await tester.tap(find.text('1 day before'));
      await tester.tap(find.text('1 hour before'));
      await tester.pumpAndSettle();

      // Save task
      await tester.tap(find.text('Save Task'));
      await tester.pumpAndSettle();

      // Verify task is created with reminder indicators
      expect(find.text('Important meeting'), findsOneWidget);
      expect(find.byIcon(Icons.notifications_active), findsOneWidget);
    });

    testWidgets('Bulk task creation workflow', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Access bulk creation feature
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Bulk Add Tasks'));
      await tester.pumpAndSettle();

      // Enter multiple tasks (one per line)
      const bulkTasks = '''
      Buy groceries
      Call mom
      Pay electricity bill
      Schedule dentist appointment
      ''';

      await tester.enterText(find.byType(TextField), bulkTasks);

      // Select default category for all
      await tester.tap(find.text('Personal'));
      await tester.pumpAndSettle();

      // Set default due date
      await tester.tap(find.text('Set due date for all'));
      await tester.pumpAndSettle();

      final nextWeek = DateTime.now().add(const Duration(days: 7));
      await tester.tap(find.text(nextWeek.day.toString()));
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      // Create all tasks
      await tester.tap(find.text('Create 4 Tasks'));
      await tester.pumpAndSettle();

      // Verify all tasks are created
      expect(find.text('Buy groceries'), findsOneWidget);
      expect(find.text('Call mom'), findsOneWidget);
      expect(find.text('Pay electricity bill'), findsOneWidget);
      expect(find.text('Schedule dentist appointment'), findsOneWidget);
    });

    testWidgets('Task creation from template workflow', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Access templates
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Templates'));
      await tester.pumpAndSettle();

      // Select a template (e.g., "Weekly Review")
      await tester.tap(find.text('Weekly Review'));
      await tester.pumpAndSettle();

      // Template details should populate
      expect(find.text('Review weekly goals and progress'), findsOneWidget);
      expect(find.text('Work'), findsOneWidget);
      expect(find.text('High'), findsOneWidget);

      // Customize if needed
      await tester.enterText(find.byType(TextField).first, 'Q1 Weekly Review');

      // Set specific date
      await tester.tap(find.byIcon(Icons.calendar_today));
      await tester.pumpAndSettle();

      // Select next Friday
      final nextFriday = DateTime.now().add(Duration(days: 5 - DateTime.now().weekday));
      await tester.tap(find.text(nextFriday.day.toString()));
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      // Create from template
      await tester.tap(find.text('Create Task'));
      await tester.pumpAndSettle();

      // Verify task is created with template values
      expect(find.text('Q1 Weekly Review'), findsOneWidget);
      expect(find.text('Work'), findsOneWidget);
      expect(find.byIcon(Icons.priority_high), findsOneWidget);
    });

    testWidgets('Task creation cancellation workflow', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      // Fill in some data
      await tester.enterText(find.byType(TextField).first, 'Incomplete task');
      await tester.enterText(find.byType(TextField).at(1), 'This task will be cancelled');

      // Cancel without saving
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      // Should show unsaved changes warning
      expect(find.text('Discard changes?'), findsOneWidget);
      expect(find.text('You have unsaved changes.'), findsOneWidget);
      expect(find.text('Discard'), findsOneWidget);
      expect(find.text('Keep editing'), findsOneWidget);

      // Choose to discard
      await tester.tap(find.text('Discard'));
      await tester.pumpAndSettle();

      // Should return to main screen without creating task
      expect(find.text('Incomplete task'), findsNothing);
      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    group('Error Handling in Task Creation', () {
      testWidgets('Handle network errors during task sync', (tester) async {
        app.main();
        await tester.pumpAndSettle();

        // Simulate network disconnection
        await TestHelpers.simulateNetworkDisconnection(tester);

        await tester.tap(find.byIcon(Icons.add));
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextField).first, 'Offline task');
        await tester.tap(find.text('Save Task'));
        await tester.pumpAndSettle();

        // Should show offline indicator
        expect(find.text('Saved locally (will sync when online)'), findsOneWidget);
        expect(find.byIcon(Icons.cloud_off), findsOneWidget);

        // Task should still be created locally
        expect(find.text('Offline task'), findsOneWidget);
      });

      testWidgets('Handle voice service errors', (tester) async {
        app.main();
        await tester.pumpAndSettle();

        // Simulate voice service unavailable
        await TestHelpers.simulateVoiceServiceError(tester);

        await tester.tap(find.byIcon(Icons.mic));
        await tester.pumpAndSettle();

        // Should show error message
        expect(find.text('Voice input not available'), findsOneWidget);
        expect(find.text('Try manual input instead'), findsOneWidget);

        // Should offer fallback to manual input
        await tester.tap(find.text('Manual Input'));
        await tester.pumpAndSettle();

        // Should navigate to manual task creation
        expect(find.text('New Task'), findsOneWidget);
      });

      testWidgets('Handle storage errors', (tester) async {
        app.main();
        await tester.pumpAndSettle();

        // Simulate storage full or permission error
        await TestHelpers.simulateStorageError(tester);

        await tester.tap(find.byIcon(Icons.add));
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextField).first, 'Storage error task');
        await tester.tap(find.text('Save Task'));
        await tester.pumpAndSettle();

        // Should show storage error
        expect(find.text('Unable to save task'), findsOneWidget);
        expect(find.text('Storage may be full or unavailable'), findsOneWidget);
        expect(find.text('Retry'), findsOneWidget);
        expect(find.text('Save to cloud'), findsOneWidget);
      });
    });

    group('Performance Tests', () {
      testWidgets('Task creation performance with large task list', (tester) async {
        // Pre-populate with many tasks
        await TestHelpers.createManyTasks(tester, count: 1000);

        app.main();
        await tester.pumpAndSettle();

        final stopwatch = Stopwatch()..start();

        // Create new task
        await tester.tap(find.byIcon(Icons.add));
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextField).first, 'Performance test task');
        await tester.tap(find.text('Save Task'));
        await tester.pumpAndSettle();

        stopwatch.stop();

        // Should complete within reasonable time even with many existing tasks
        expect(stopwatch.elapsedMilliseconds, lessThan(3000));
        expect(find.text('Performance test task'), findsOneWidget);
      });

      testWidgets('Memory usage during rapid task creation', (tester) async {
        app.main();
        await tester.pumpAndSettle();

        // Create many tasks rapidly
        for (int i = 0; i < 50; i++) {
          await tester.tap(find.byIcon(Icons.add));
          await tester.pumpAndSettle();

          await tester.enterText(find.byType(TextField).first, 'Rapid task $i');
          await tester.tap(find.text('Save Task'));
          await tester.pumpAndSettle();

          // Brief pause to allow garbage collection
          if (i % 10 == 0) {
            await tester.pump(const Duration(milliseconds: 100));
          }
        }

        // All tasks should be created without memory issues
        expect(find.text('Rapid task 49'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    });
  });
}