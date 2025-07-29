import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:task_tracker_app/core/services/notification_service.dart';
import '../../test_utils/fixtures.dart';
import '../../test_utils/mocks.dart';

// Generate mocks using build_runner
@GenerateMocks([NotificationService])
void main() {
  group('NotificationService Tests', () {
    late NotificationService notificationService;
    late MockNotificationService mockNotificationService;

    setUp(() {
      mockNotificationService = MockNotificationService();
      notificationService = mockNotificationService;
    });

    group('Initialization and Permissions', () {
      test('should initialize successfully', () async {
        when(mockNotificationService.initialize()).thenAnswer((_) async {});
        
        await notificationService.initialize();
        
        verify(mockNotificationService.initialize()).called(1);
      });

      test('should request permissions successfully', () async {
        when(mockNotificationService.requestPermissions()).thenAnswer((_) async => true);
        
        final granted = await notificationService.requestPermissions();
        
        expect(granted, isTrue);
        verify(mockNotificationService.requestPermissions()).called(1);
      });

      test('should handle permission denial', () async {
        when(mockNotificationService.requestPermissions()).thenAnswer((_) async => false);
        
        final granted = await notificationService.requestPermissions();
        
        expect(granted, isFalse);
      });

      test('should check existing permissions', () async {
        when(mockNotificationService.hasPermissions()).thenAnswer((_) async => true);
        
        final hasPermissions = await notificationService.hasPermissions();
        
        expect(hasPermissions, isTrue);
        verify(mockNotificationService.hasPermissions()).called(1);
      });
    });

    group('Notification Scheduling', () {
      test('should schedule notification successfully', () async {
        final scheduledDate = DateTime.now().add(const Duration(hours: 1));
        
        when(mockNotificationService.scheduleNotification(
          id: anyNamed('id'),
          title: anyNamed('title'),
          body: anyNamed('body'),
          scheduledDate: anyNamed('scheduledDate'),
          payload: anyNamed('payload'),
        )).thenAnswer((_) async {});

        await notificationService.scheduleNotification(
          id: 1,
          title: 'Test Notification',
          body: 'This is a test notification',
          scheduledDate: scheduledDate,
          payload: 'test-payload',
        );

        verify(mockNotificationService.scheduleNotification(
          id: 1,
          title: 'Test Notification',
          body: 'This is a test notification',
          scheduledDate: scheduledDate,
          payload: 'test-payload',
        )).called(1);
      });

      test('should schedule notification without payload', () async {
        final scheduledDate = DateTime.now().add(const Duration(hours: 2));
        
        when(mockNotificationService.scheduleNotification(
          id: anyNamed('id'),
          title: anyNamed('title'),
          body: anyNamed('body'),
          scheduledDate: anyNamed('scheduledDate'),
          payload: anyNamed('payload'),
        )).thenAnswer((_) async {});

        await notificationService.scheduleNotification(
          id: 2,
          title: 'No Payload Notification',
          body: 'This notification has no payload',
          scheduledDate: scheduledDate,
        );

        verify(mockNotificationService.scheduleNotification(
          id: 2,
          title: 'No Payload Notification',
          body: 'This notification has no payload',
          scheduledDate: scheduledDate,
          payload: null,
        )).called(1);
      });

      test('should schedule periodic notifications', () async {
        when(mockNotificationService.schedulePeriodicNotification(
          id: anyNamed('id'),
          title: anyNamed('title'),
          body: anyNamed('body'),
          period: anyNamed('period'),
          payload: anyNamed('payload'),
        )).thenAnswer((_) async {});

        await notificationService.schedulePeriodicNotification(
          id: 10,
          title: 'Daily Reminder',
          body: 'Your daily task reminder',
          period: const Duration(days: 1),
          payload: 'daily-reminder',
        );

        verify(mockNotificationService.schedulePeriodicNotification(
          id: 10,
          title: 'Daily Reminder',
          body: 'Your daily task reminder',
          period: const Duration(days: 1),
          payload: 'daily-reminder',
        )).called(1);
      });

      test('should handle multiple notification scheduling', () async {
        final notifications = [
          {
            'id': 1,
            'title': 'Task 1 Reminder',
            'body': 'Don\'t forget about task 1',
            'scheduledDate': DateTime.now().add(const Duration(hours: 1)),
          },
          {
            'id': 2,
            'title': 'Task 2 Reminder',
            'body': 'Don\'t forget about task 2',
            'scheduledDate': DateTime.now().add(const Duration(hours: 2)),
          },
          {
            'id': 3,
            'title': 'Task 3 Reminder',
            'body': 'Don\'t forget about task 3',
            'scheduledDate': DateTime.now().add(const Duration(hours: 3)),
          },
        ];

        for (final notification in notifications) {
          when(mockNotificationService.scheduleNotification(
            id: notification['id'] as int,
            title: notification['title'] as String,
            body: notification['body'] as String,
            scheduledDate: notification['scheduledDate'] as DateTime,
          )).thenAnswer((_) async {});
        }

        for (final notification in notifications) {
          await notificationService.scheduleNotification(
            id: notification['id'] as int,
            title: notification['title'] as String,
            body: notification['body'] as String,
            scheduledDate: notification['scheduledDate'] as DateTime,
          );
        }

        for (final notification in notifications) {
          verify(mockNotificationService.scheduleNotification(
            id: notification['id'] as int,
            title: notification['title'] as String,
            body: notification['body'] as String,
            scheduledDate: notification['scheduledDate'] as DateTime,
          )).called(1);
        }
      });
    });

    group('Notification Management', () {
      test('should cancel specific notification', () async {
        when(mockNotificationService.cancelNotification(1)).thenAnswer((_) async {});

        await notificationService.cancelNotification(1);

        verify(mockNotificationService.cancelNotification(1)).called(1);
      });

      test('should cancel all notifications', () async {
        when(mockNotificationService.cancelAllNotifications()).thenAnswer((_) async {});

        await notificationService.cancelAllNotifications();

        verify(mockNotificationService.cancelAllNotifications()).called(1);
      });

      test('should get pending notifications', () async {
        final pendingNotifications = [
          PendingNotification(
            id: 1,
            title: 'Pending 1',
            body: 'Body 1',
            scheduledDate: DateTime.now().add(const Duration(hours: 1)),
            payload: 'payload-1',
          ),
          PendingNotification(
            id: 2,
            title: 'Pending 2',
            body: 'Body 2',
            scheduledDate: DateTime.now().add(const Duration(hours: 2)),
            payload: 'payload-2',
          ),
        ];

        when(mockNotificationService.getPendingNotifications())
            .thenAnswer((_) async => pendingNotifications);

        final result = await notificationService.getPendingNotifications();

        expect(result.length, 2);
        expect(result[0].title, 'Pending 1');
        expect(result[1].title, 'Pending 2');
        verify(mockNotificationService.getPendingNotifications()).called(1);
      });

      test('should handle empty pending notifications list', () async {
        when(mockNotificationService.getPendingNotifications())
            .thenAnswer((_) async => []);

        final result = await notificationService.getPendingNotifications();

        expect(result, isEmpty);
      });
    });

    group('Immediate Notifications', () {
      test('should show immediate notification', () async {
        when(mockNotificationService.showNotification(
          id: anyNamed('id'),
          title: anyNamed('title'),
          body: anyNamed('body'),
          payload: anyNamed('payload'),
        )).thenAnswer((_) async {});

        await notificationService.showNotification(
          id: 100,
          title: 'Immediate Notification',
          body: 'This notification shows immediately',
          payload: 'immediate-payload',
        );

        verify(mockNotificationService.showNotification(
          id: 100,
          title: 'Immediate Notification',
          body: 'This notification shows immediately',
          payload: 'immediate-payload',
        )).called(1);
      });

      test('should show notification without payload', () async {
        when(mockNotificationService.showNotification(
          id: anyNamed('id'),
          title: anyNamed('title'),
          body: anyNamed('body'),
          payload: anyNamed('payload'),
        )).thenAnswer((_) async {});

        await notificationService.showNotification(
          id: 101,
          title: 'Simple Notification',
          body: 'This is a simple notification',
        );

        verify(mockNotificationService.showNotification(
          id: 101,
          title: 'Simple Notification',
          body: 'This is a simple notification',
          payload: null,
        )).called(1);
      });
    });

    group('Notification Callbacks', () {
      test('should register notification tap callback', () {
        String? tappedPayload;
        
        when(mockNotificationService.onNotificationTap(any)).thenReturn(null);

        notificationService.onNotificationTap((payload) {
          tappedPayload = payload;
        });

        verify(mockNotificationService.onNotificationTap(any)).called(1);
      });

      test('should register notification action callback', () {
        String? actionReceived;
        String? payloadReceived;
        
        when(mockNotificationService.onNotificationAction(any)).thenReturn(null);

        notificationService.onNotificationAction((action, payload) {
          actionReceived = action;
          payloadReceived = payload;
        });

        verify(mockNotificationService.onNotificationAction(any)).called(1);
      });
    });

    group('Error Handling', () {
      test('should handle initialization errors', () async {
        when(mockNotificationService.initialize())
            .thenThrow(Exception('Failed to initialize notifications'));

        expect(
          () => notificationService.initialize(),
          throwsException,
        );
      });

      test('should handle permission request errors', () async {
        when(mockNotificationService.requestPermissions())
            .thenThrow(Exception('Permission request failed'));

        expect(
          () => notificationService.requestPermissions(),
          throwsException,
        );
      });

      test('should handle scheduling errors', () async {
        final futureDate = DateTime.now().add(const Duration(hours: 1));
        
        when(mockNotificationService.scheduleNotification(
          id: anyNamed('id'),
          title: anyNamed('title'),
          body: anyNamed('body'),
          scheduledDate: anyNamed('scheduledDate'),
        )).thenThrow(Exception('Failed to schedule notification'));

        expect(
          () => notificationService.scheduleNotification(
            id: 1,
            title: 'Test',
            body: 'Test body',
            scheduledDate: futureDate,
          ),
          throwsException,
        );
      });

      test('should handle cancellation errors', () async {
        when(mockNotificationService.cancelNotification(1))
            .thenThrow(Exception('Failed to cancel notification'));

        expect(
          () => notificationService.cancelNotification(1),
          throwsException,
        );
      });

      test('should handle invalid notification IDs', () async {
        when(mockNotificationService.cancelNotification(-1))
            .thenThrow(ArgumentError('Invalid notification ID'));

        expect(
          () => notificationService.cancelNotification(-1),
          throwsArgumentError,
        );
      });
    });

    group('Performance Tests', () {
      test('should schedule notifications efficiently', () async {
        const numberOfNotifications = 100;
        final baseTime = DateTime.now();

        // Setup mocks for bulk scheduling
        for (int i = 0; i < numberOfNotifications; i++) {
          when(mockNotificationService.scheduleNotification(
            id: i,
            title: 'Notification $i',
            body: 'Body $i',
            scheduledDate: baseTime.add(Duration(minutes: i)),
          )).thenAnswer((_) async {});
        }

        final stopwatch = Stopwatch()..start();

        // Schedule all notifications
        final futures = <Future<void>>[];
        for (int i = 0; i < numberOfNotifications; i++) {
          futures.add(notificationService.scheduleNotification(
            id: i,
            title: 'Notification $i',
            body: 'Body $i',
            scheduledDate: baseTime.add(Duration(minutes: i)),
          ));
        }
        await Future.wait(futures);

        stopwatch.stop();

        expect(stopwatch.elapsedMilliseconds, lessThan(5000)); // Should complete within 5 seconds

        // Verify all were called
        for (int i = 0; i < numberOfNotifications; i++) {
          verify(mockNotificationService.scheduleNotification(
            id: i,
            title: 'Notification $i',
            body: 'Body $i',
            scheduledDate: baseTime.add(Duration(minutes: i)),
          )).called(1);
        }
      });

      test('should handle bulk cancellation efficiently', () async {
        const numberOfNotifications = 50;

        // Setup mocks for bulk cancellation
        for (int i = 0; i < numberOfNotifications; i++) {
          when(mockNotificationService.cancelNotification(i))
              .thenAnswer((_) async {});
        }

        final stopwatch = Stopwatch()..start();

        // Cancel all notifications
        final futures = <Future<void>>[];
        for (int i = 0; i < numberOfNotifications; i++) {
          futures.add(notificationService.cancelNotification(i));
        }
        await Future.wait(futures);

        stopwatch.stop();

        expect(stopwatch.elapsedMilliseconds, lessThan(2000)); // Should complete within 2 seconds
      });
    });

    group('Edge Cases', () {
      test('should handle scheduling notification for past date', () async {
        final pastDate = DateTime.now().subtract(const Duration(hours: 1));

        when(mockNotificationService.scheduleNotification(
          id: anyNamed('id'),
          title: anyNamed('title'),
          body: anyNamed('body'),
          scheduledDate: anyNamed('scheduledDate'),
        )).thenThrow(ArgumentError('Cannot schedule notification for past date'));

        expect(
          () => notificationService.scheduleNotification(
            id: 1,
            title: 'Past Notification',
            body: 'This is in the past',
            scheduledDate: pastDate,
          ),
          throwsArgumentError,
        );
      });

      test('should handle very long notification texts', () async {
        final longTitle = 'A' * 1000;
        final longBody = 'B' * 5000;
        final futureDate = DateTime.now().add(const Duration(hours: 1));

        when(mockNotificationService.scheduleNotification(
          id: anyNamed('id'),
          title: anyNamed('title'),
          body: anyNamed('body'),
          scheduledDate: anyNamed('scheduledDate'),
        )).thenAnswer((_) async {});

        await notificationService.scheduleNotification(
          id: 1,
          title: longTitle,
          body: longBody,
          scheduledDate: futureDate,
        );

        verify(mockNotificationService.scheduleNotification(
          id: 1,
          title: longTitle,
          body: longBody,
          scheduledDate: futureDate,
        )).called(1);
      });

      test('should handle special characters in notifications', () async {
        const specialTitle = '🔔 Special Notification! @#$%^&*()';
        const specialBody = 'Body with émojis 🎯📱 and spéciål châràctérs';
        final futureDate = DateTime.now().add(const Duration(hours: 1));

        when(mockNotificationService.scheduleNotification(
          id: anyNamed('id'),
          title: anyNamed('title'),
          body: anyNamed('body'),
          scheduledDate: anyNamed('scheduledDate'),
        )).thenAnswer((_) async {});

        await notificationService.scheduleNotification(
          id: 1,
          title: specialTitle,
          body: specialBody,
          scheduledDate: futureDate,
        );

        verify(mockNotificationService.scheduleNotification(
          id: 1,
          title: specialTitle,
          body: specialBody,
          scheduledDate: futureDate,
        )).called(1);
      });
    });
  });

  group('PendingNotification Tests', () {
    test('should create PendingNotification with all fields', () {
      final scheduledDate = DateTime.now().add(const Duration(hours: 1));
      
      const notification = PendingNotification(
        id: 1,
        title: 'Test Pending',
        body: 'Test pending body',
        scheduledDate: null, // Will be set below
        payload: 'test-payload',
      );

      final notificationWithDate = PendingNotification(
        id: notification.id,
        title: notification.title,
        body: notification.body,
        scheduledDate: scheduledDate,
        payload: notification.payload,
      );

      expect(notificationWithDate.id, 1);
      expect(notificationWithDate.title, 'Test Pending');
      expect(notificationWithDate.body, 'Test pending body');
      expect(notificationWithDate.scheduledDate, scheduledDate);
      expect(notificationWithDate.payload, 'test-payload');
    });

    test('should create PendingNotification with minimal fields', () {
      const notification = PendingNotification(
        id: 2,
        title: 'Minimal Notification',
        body: 'Minimal body',
      );

      expect(notification.id, 2);
      expect(notification.title, 'Minimal Notification');
      expect(notification.body, 'Minimal body');
      expect(notification.scheduledDate, isNull);
      expect(notification.payload, isNull);
    });

    test('should handle edge case IDs', () {
      const maxIntNotification = PendingNotification(
        id: 2147483647, // Max int32 value
        title: 'Max ID',
        body: 'Maximum ID test',
      );

      const zeroNotification = PendingNotification(
        id: 0,
        title: 'Zero ID',
        body: 'Zero ID test',
      );

      expect(maxIntNotification.id, 2147483647);
      expect(zeroNotification.id, 0);
    });
  });
}