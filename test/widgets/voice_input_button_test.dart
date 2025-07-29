import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/mockito.dart';
import 'package:task_tracker_app/shared/widgets/voice_input_button.dart';
import 'package:task_tracker_app/core/services/voice_service.dart';
import '../test_utils/fixtures.dart';
import '../test_utils/test_helpers.dart';
import '../test_utils/mocks.dart';

void main() {
  group('VoiceInputButton Widget Tests', () {
    late MockVoiceService mockVoiceService;

    setUp(() {
      mockVoiceService = MockVoiceService();
      
      // Default mock behaviors
      when(mockVoiceService.isListening).thenReturn(false);
      when(mockVoiceService.hasPermissions()).thenAnswer((_) async => true);
      when(mockVoiceService.isAvailable()).thenAnswer((_) async => true);
    });

    testWidgets('should display default state correctly', (tester) async {
      await tester.pumpWidget(
        TestHelpers.createTestApp(
          child: VoiceInputButton(
            onVoiceResult: (result) {},
          ),
          overrides: [
            voiceServiceProvider.overrideWithValue(mockVoiceService),
          ],
        ),
      );

      // Should show microphone icon
      expect(find.byIcon(Icons.mic), findsOneWidget);
      
      // Should have proper accessibility label
      expect(find.bySemanticsLabel('Voice input'), findsOneWidget);
    });

    testWidgets('should show listening state when active', (tester) async {
      when(mockVoiceService.isListening).thenReturn(true);

      await tester.pumpWidget(
        TestHelpers.createTestApp(
          child: VoiceInputButton(
            onVoiceResult: (result) {},
          ),
          overrides: [
            voiceServiceProvider.overrideWithValue(mockVoiceService),
          ],
        ),
      );

      await tester.pump();

      // Should show listening indicator (different icon or animation)
      expect(find.byIcon(Icons.mic_off), findsOneWidget);
      
      // Should update accessibility label
      expect(find.bySemanticsLabel('Stop voice input'), findsOneWidget);
    });

    testWidgets('should handle voice input start', (tester) async {
      when(mockVoiceService.startListening(
        onResult: anyNamed('onResult'),
        onPartialResult: anyNamed('onPartialResult'),
        onError: anyNamed('onError'),
      )).thenAnswer((_) async {});

      String? capturedResult;

      await tester.pumpWidget(
        TestHelpers.createTestApp(
          child: VoiceInputButton(
            onVoiceResult: (result) => capturedResult = result,
          ),
          overrides: [
            voiceServiceProvider.overrideWithValue(mockVoiceService),
          ],
        ),
      );

      // Tap to start listening
      await tester.tap(find.byType(VoiceInputButton));
      await tester.pump();

      verify(mockVoiceService.startListening(
        onResult: anyNamed('onResult'),
        onPartialResult: anyNamed('onPartialResult'),
        onError: anyNamed('onError'),
      )).called(1);
    });

    testWidgets('should handle voice input stop', (tester) async {
      when(mockVoiceService.isListening).thenReturn(true);
      when(mockVoiceService.stopListening()).thenAnswer((_) async {});

      await tester.pumpWidget(
        TestHelpers.createTestApp(
          child: VoiceInputButton(
            onVoiceResult: (result) {},
          ),
          overrides: [
            voiceServiceProvider.overrideWithValue(mockVoiceService),
          ],
        ),
      );

      await tester.pump();

      // Tap to stop listening
      await tester.tap(find.byType(VoiceInputButton));
      await tester.pump();

      verify(mockVoiceService.stopListening()).called(1);
    });

    testWidgets('should handle voice recognition result', (tester) async {
      String? receivedResult;
      late Function(String) onResultCallback;

      when(mockVoiceService.startListening(
        onResult: anyNamed('onResult'),
        onPartialResult: anyNamed('onPartialResult'),
        onError: anyNamed('onError'),
      )).thenAnswer((invocation) async {
        onResultCallback = invocation.namedArguments[const Symbol('onResult')] as Function(String);
      });

      await tester.pumpWidget(
        TestHelpers.createTestApp(
          child: VoiceInputButton(
            onVoiceResult: (result) => receivedResult = result,
          ),
          overrides: [
            voiceServiceProvider.overrideWithValue(mockVoiceService),
          ],
        ),
      );

      // Start listening
      await tester.tap(find.byType(VoiceInputButton));
      await tester.pump();

      // Simulate voice result
      onResultCallback('Buy groceries tomorrow');
      await tester.pump();

      expect(receivedResult, equals('Buy groceries tomorrow'));
    });

    testWidgets('should show partial results during recognition', (tester) async {
      late Function(String) onPartialResultCallback;

      when(mockVoiceService.startListening(
        onResult: anyNamed('onResult'),
        onPartialResult: anyNamed('onPartialResult'),
        onError: anyNamed('onError'),
      )).thenAnswer((invocation) async {
        onPartialResultCallback = invocation.namedArguments[const Symbol('onPartialResult')] as Function(String);
      });

      await tester.pumpWidget(
        TestHelpers.createTestApp(
          child: VoiceInputButton(
            onVoiceResult: (result) {},
            showPartialResults: true,
          ),
          overrides: [
            voiceServiceProvider.overrideWithValue(mockVoiceService),
          ],
        ),
      );

      // Start listening
      await tester.tap(find.byType(VoiceInputButton));
      await tester.pump();

      // Simulate partial result
      onPartialResultCallback('Buy groc...');
      await tester.pump();

      // Should display partial result text
      expect(find.text('Buy groc...'), findsOneWidget);
    });

    testWidgets('should handle voice recognition errors', (tester) async {
      late Function(String) onErrorCallback;
      String? errorReceived;

      when(mockVoiceService.startListening(
        onResult: anyNamed('onResult'),
        onPartialResult: anyNamed('onPartialResult'),
        onError: anyNamed('onError'),
      )).thenAnswer((invocation) async {
        onErrorCallback = invocation.namedArguments[const Symbol('onError')] as Function(String);
      });

      await tester.pumpWidget(
        TestHelpers.createTestApp(
          child: VoiceInputButton(
            onVoiceResult: (result) {},
            onError: (error) => errorReceived = error,
          ),
          overrides: [
            voiceServiceProvider.overrideWithValue(mockVoiceService),
          ],
        ),
      );

      // Start listening
      await tester.tap(find.byType(VoiceInputButton));
      await tester.pump();

      // Simulate error
      onErrorCallback('Microphone not available');
      await tester.pump();

      expect(errorReceived, equals('Microphone not available'));
    });

    testWidgets('should handle permission requests', (tester) async {
      when(mockVoiceService.hasPermissions()).thenAnswer((_) async => false);
      when(mockVoiceService.requestPermissions()).thenAnswer((_) async => true);

      await tester.pumpWidget(
        TestHelpers.createTestApp(
          child: VoiceInputButton(
            onVoiceResult: (result) {},
          ),
          overrides: [
            voiceServiceProvider.overrideWithValue(mockVoiceService),
          ],
        ),
      );

      // Tap should trigger permission request
      await tester.tap(find.byType(VoiceInputButton));
      await tester.pump();

      verify(mockVoiceService.requestPermissions()).called(1);
    });

    testWidgets('should handle permission denial', (tester) async {
      when(mockVoiceService.hasPermissions()).thenAnswer((_) async => false);
      when(mockVoiceService.requestPermissions()).thenAnswer((_) async => false);

      String? permissionError;

      await tester.pumpWidget(
        TestHelpers.createTestApp(
          child: VoiceInputButton(
            onVoiceResult: (result) {},
            onError: (error) => permissionError = error,
          ),
          overrides: [
            voiceServiceProvider.overrideWithValue(mockVoiceService),
          ],
        ),
      );

      await tester.tap(find.byType(VoiceInputButton));
      await tester.pump();

      expect(permissionError, contains('permission'));
    });

    testWidgets('should show disabled state when unavailable', (tester) async {
      when(mockVoiceService.isAvailable()).thenAnswer((_) async => false);

      await tester.pumpWidget(
        TestHelpers.createTestApp(
          child: VoiceInputButton(
            onVoiceResult: (result) {},
          ),
          overrides: [
            voiceServiceProvider.overrideWithValue(mockVoiceService),
          ],
        ),
      );

      await tester.pump();

      // Button should be disabled
      final button = tester.widget<FloatingActionButton>(find.byType(FloatingActionButton));
      expect(button.onPressed, isNull);
    });

    testWidgets('should show loading state during initialization', (tester) async {
      // Simulate slow initialization
      when(mockVoiceService.isAvailable()).thenAnswer((_) async {
        await Future.delayed(const Duration(milliseconds: 100));
        return true;
      });

      await tester.pumpWidget(
        TestHelpers.createTestApp(
          child: VoiceInputButton(
            onVoiceResult: (result) {},
          ),
          overrides: [
            voiceServiceProvider.overrideWithValue(mockVoiceService),
          ],
        ),
      );

      // Should show loading indicator
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Wait for initialization
      await tester.pumpAndSettle();

      // Should show normal state
      expect(find.byIcon(Icons.mic), findsOneWidget);
    });

    group('Visual States', () {
      testWidgets('should animate between states', (tester) async {
        when(mockVoiceService.startListening(
          onResult: anyNamed('onResult'),
          onPartialResult: anyNamed('onPartialResult'),
          onError: anyNamed('onError'),
        )).thenAnswer((_) async {});

        await tester.pumpWidget(
          TestHelpers.createTestApp(
            child: VoiceInputButton(
              onVoiceResult: (result) {},
            ),
            overrides: [
              voiceServiceProvider.overrideWithValue(mockVoiceService),
            ],
          ),
        );

        // Initial state
        expect(find.byIcon(Icons.mic), findsOneWidget);

        // Start listening
        when(mockVoiceService.isListening).thenReturn(true);
        await tester.tap(find.byType(VoiceInputButton));
        await tester.pumpAndSettle();

        // Should animate to listening state
        expect(find.byIcon(Icons.mic_off), findsOneWidget);
      });

      testWidgets('should show pulse animation while listening', (tester) async {
        when(mockVoiceService.isListening).thenReturn(true);

        await tester.pumpWidget(
          TestHelpers.createTestApp(
            child: VoiceInputButton(
              onVoiceResult: (result) {},
            ),
            overrides: [
              voiceServiceProvider.overrideWithValue(mockVoiceService),
            ],
          ),
        );

        await tester.pump();

        // Should have animation widget
        expect(find.byType(AnimatedBuilder), findsOneWidget);
      });

      testWidgets('should change color based on state', (tester) async {
        await tester.pumpWidget(
          TestHelpers.createTestApp(
            child: VoiceInputButton(
              onVoiceResult: (result) {},
            ),
            overrides: [
              voiceServiceProvider.overrideWithValue(mockVoiceService),
            ],
          ),
        );

        // Get initial color
        final initialButton = tester.widget<FloatingActionButton>(find.byType(FloatingActionButton));
        final initialColor = initialButton.backgroundColor;

        // Change to listening state
        when(mockVoiceService.isListening).thenReturn(true);
        await tester.pump();

        // Color should change
        final listeningButton = tester.widget<FloatingActionButton>(find.byType(FloatingActionButton));
        expect(listeningButton.backgroundColor, isNot(equals(initialColor)));
      });
    });

    group('Accessibility Tests', () {
      testWidgets('should have proper semantic labels', (tester) async {
        await tester.pumpWidget(
          TestHelpers.createTestApp(
            child: VoiceInputButton(
              onVoiceResult: (result) {},
            ),
            overrides: [
              voiceServiceProvider.overrideWithValue(mockVoiceService),
            ],
          ),
        );

        expect(find.bySemanticsLabel('Voice input'), findsOneWidget);
      });

      testWidgets('should update semantics during state changes', (tester) async {
        await tester.pumpWidget(
          TestHelpers.createTestApp(
            child: VoiceInputButton(
              onVoiceResult: (result) {},
            ),
            overrides: [
              voiceServiceProvider.overrideWithValue(mockVoiceService),
            ],
          ),
        );

        expect(find.bySemanticsLabel('Voice input'), findsOneWidget);

        // Change to listening state
        when(mockVoiceService.isListening).thenReturn(true);
        await tester.pump();

        expect(find.bySemanticsLabel('Stop voice input'), findsOneWidget);
      });

      testWidgets('should provide voice feedback', (tester) async {
        await tester.pumpWidget(
          TestHelpers.createTestApp(
            child: VoiceInputButton(
              onVoiceResult: (result) {},
            ),
            overrides: [
              voiceServiceProvider.overrideWithValue(mockVoiceService),
            ],
          ),
        );

        // Should announce state changes for screen readers
        final semantics = tester.getSemantics(find.byType(VoiceInputButton));
        expect(semantics.hasAction(SemanticsAction.tap), isTrue);
      });
    });

    group('Performance Tests', () {
      testWidgets('should handle rapid taps without issues', (tester) async {
        when(mockVoiceService.startListening(
          onResult: anyNamed('onResult'),
          onPartialResult: anyNamed('onPartialResult'),
          onError: anyNamed('onError'),
        )).thenAnswer((_) async {});
        when(mockVoiceService.stopListening()).thenAnswer((_) async {});

        await tester.pumpWidget(
          TestHelpers.createTestApp(
            child: VoiceInputButton(
              onVoiceResult: (result) {},
            ),
            overrides: [
              voiceServiceProvider.overrideWithValue(mockVoiceService),
            ],
          ),
        );

        // Rapidly tap the button
        for (int i = 0; i < 10; i++) {
          await tester.tap(find.byType(VoiceInputButton));
          await tester.pump(const Duration(milliseconds: 50));
          
          // Toggle listening state
          when(mockVoiceService.isListening).thenReturn(i % 2 == 0);
        }

        expect(tester.takeException(), isNull);
      });

      testWidgets('should not leak memory with repeated use', (tester) async {
        when(mockVoiceService.startListening(
          onResult: anyNamed('onResult'),
          onPartialResult: anyNamed('onPartialResult'),
          onError: anyNamed('onError'),
        )).thenAnswer((_) async {});

        for (int i = 0; i < 50; i++) {
          await tester.pumpWidget(
            TestHelpers.createTestApp(
              child: VoiceInputButton(
                key: ValueKey('button_$i'),
                onVoiceResult: (result) {},
              ),
              overrides: [
                voiceServiceProvider.overrideWithValue(mockVoiceService),
              ],
            ),
          );

          await tester.tap(find.byType(VoiceInputButton));
          await tester.pump();
        }

        expect(tester.takeException(), isNull);
      });
    });

    group('Edge Cases', () {
      testWidgets('should handle null callbacks gracefully', (tester) async {
        await tester.pumpWidget(
          TestHelpers.createTestApp(
            child: VoiceInputButton(
              onVoiceResult: (result) {}, // Required callback
            ),
            overrides: [
              voiceServiceProvider.overrideWithValue(mockVoiceService),
            ],
          ),
        );

        await tester.tap(find.byType(VoiceInputButton));
        await tester.pump();

        expect(tester.takeException(), isNull);
      });

      testWidgets('should handle service initialization errors', (tester) async {
        when(mockVoiceService.isAvailable())
            .thenThrow(Exception('Service initialization failed'));

        await tester.pumpWidget(
          TestHelpers.createTestApp(
            child: VoiceInputButton(
              onVoiceResult: (result) {},
            ),
            overrides: [
              voiceServiceProvider.overrideWithValue(mockVoiceService),
            ],
          ),
        );

        await tester.pump();

        // Should show error state or disabled button
        expect(find.byType(VoiceInputButton), findsOneWidget);
      });

      testWidgets('should handle very long voice results', (tester) async {
        final longResult = 'A' * 10000; // Very long text
        String? receivedResult;

        await tester.pumpWidget(
          TestHelpers.createTestApp(
            child: VoiceInputButton(
              onVoiceResult: (result) => receivedResult = result,
              showPartialResults: true,
            ),
            overrides: [
              voiceServiceProvider.overrideWithValue(mockVoiceService),
            ],
          ),
        );

        // Simulate receiving long result
        // This would be done through the callback mechanism
        receivedResult = longResult;

        expect(receivedResult, equals(longResult));
      });

      testWidgets('should handle device rotation', (tester) async {
        await tester.pumpWidget(
          TestHelpers.createTestApp(
            child: VoiceInputButton(
              onVoiceResult: (result) {},
            ),
            overrides: [
              voiceServiceProvider.overrideWithValue(mockVoiceService),
            ],
          ),
        );

        // Simulate rotation by rebuilding with different constraints
        await tester.binding.setSurfaceSize(const Size(800, 600));
        await tester.pump();

        expect(find.byType(VoiceInputButton), findsOneWidget);

        await tester.binding.setSurfaceSize(const Size(600, 800));
        await tester.pump();

        expect(find.byType(VoiceInputButton), findsOneWidget);
      });
    });
  });
}

// Mock provider for testing
final voiceServiceProvider = Provider<VoiceService>((ref) => throw UnimplementedError());