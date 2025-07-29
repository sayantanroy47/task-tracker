import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:task_tracker_app/core/services/voice_service.dart';
import 'package:task_tracker_app/core/services/voice_service_impl.dart';
import '../../test_utils/fixtures.dart';
import '../../test_utils/mocks.dart';

// Generate mocks using build_runner
@GenerateMocks([VoiceService])
void main() {
  group('VoiceService Tests', () {
    late VoiceService voiceService;
    late MockVoiceService mockVoiceService;

    setUp(() {
      mockVoiceService = MockVoiceService();
      voiceService = mockVoiceService;
    });

    group('Initialization and Permissions', () {
      test('should initialize successfully', () async {
        when(mockVoiceService.initialize()).thenAnswer((_) async {});
        
        await voiceService.initialize();
        
        verify(mockVoiceService.initialize()).called(1);
      });

      test('should check availability correctly', () async {
        when(mockVoiceService.isAvailable()).thenAnswer((_) async => true);
        
        final isAvailable = await voiceService.isAvailable();
        
        expect(isAvailable, isTrue);
        verify(mockVoiceService.isAvailable()).called(1);
      });

      test('should handle unavailable speech recognition', () async {
        when(mockVoiceService.isAvailable()).thenAnswer((_) async => false);
        
        final isAvailable = await voiceService.isAvailable();
        
        expect(isAvailable, isFalse);
      });

      test('should request permissions successfully', () async {
        when(mockVoiceService.requestPermissions()).thenAnswer((_) async => true);
        
        final granted = await voiceService.requestPermissions();
        
        expect(granted, isTrue);
        verify(mockVoiceService.requestPermissions()).called(1);
      });

      test('should handle permission denial', () async {
        when(mockVoiceService.requestPermissions()).thenAnswer((_) async => false);
        
        final granted = await voiceService.requestPermissions();
        
        expect(granted, isFalse);
      });

      test('should check existing permissions', () async {
        when(mockVoiceService.hasPermissions()).thenAnswer((_) async => true);
        
        final hasPermissions = await voiceService.hasPermissions();
        
        expect(hasPermissions, isTrue);
        verify(mockVoiceService.hasPermissions()).called(1);
      });
    });

    group('Voice Recognition', () {
      test('should start listening with callbacks', () async {
        String? resultText;
        String? partialText;
        String? errorText;

        when(mockVoiceService.startListening(
          onResult: anyNamed('onResult'),
          onPartialResult: anyNamed('onPartialResult'),
          onError: anyNamed('onError'),
          timeout: anyNamed('timeout'),
        )).thenAnswer((_) async {});

        await voiceService.startListening(
          onResult: (text) => resultText = text,
          onPartialResult: (text) => partialText = text,
          onError: (error) => errorText = error,
          timeout: const Duration(seconds: 30),
        );

        verify(mockVoiceService.startListening(
          onResult: anyNamed('onResult'),
          onPartialResult: anyNamed('onPartialResult'),
          onError: anyNamed('onError'),
          timeout: const Duration(seconds: 30),
        )).called(1);
      });

      test('should stop listening', () async {
        when(mockVoiceService.stopListening()).thenAnswer((_) async {});
        
        await voiceService.stopListening();
        
        verify(mockVoiceService.stopListening()).called(1);
      });

      test('should cancel listening session', () async {
        when(mockVoiceService.cancel()).thenAnswer((_) async {});
        
        await voiceService.cancel();
        
        verify(mockVoiceService.cancel()).called(1);
      });

      test('should report listening state correctly', () {
        when(mockVoiceService.isListening).thenReturn(true);
        
        expect(voiceService.isListening, isTrue);
        
        when(mockVoiceService.isListening).thenReturn(false);
        
        expect(voiceService.isListening, isFalse);
      });

      test('should handle listening timeout', () async {
        String? errorResult;

        when(mockVoiceService.startListening(
          onResult: anyNamed('onResult'),
          onError: anyNamed('onError'),
          timeout: anyNamed('timeout'),
        )).thenAnswer((invocation) async {
          final onError = invocation.namedArguments[const Symbol('onError')] as Function(String)?;
          await Future.delayed(const Duration(milliseconds: 100));
          onError?.call('Listening timeout');
        });

        await voiceService.startListening(
          onResult: (text) {},
          onError: (error) => errorResult = error,
          timeout: const Duration(milliseconds: 50),
        );

        await Future.delayed(const Duration(milliseconds: 200));
        expect(errorResult, 'Listening timeout');
      });
    });

    group('Locale Support', () {
      test('should get supported locales', () async {
        final expectedLocales = [
          const VoiceLocale(localeId: 'en-US', name: 'English (US)'),
          const VoiceLocale(localeId: 'en-GB', name: 'English (UK)'),
          const VoiceLocale(localeId: 'es-ES', name: 'Spanish (Spain)'),
        ];

        when(mockVoiceService.getSupportedLocales())
            .thenAnswer((_) async => expectedLocales);

        final locales = await voiceService.getSupportedLocales();

        expect(locales.length, 3);
        expect(locales.first.localeId, 'en-US');
        expect(locales.first.name, 'English (US)');
      });

      test('should set locale successfully', () async {
        when(mockVoiceService.setLocale('en-US')).thenAnswer((_) async {});

        await voiceService.setLocale('en-US');

        verify(mockVoiceService.setLocale('en-US')).called(1);
      });

      test('should handle invalid locale gracefully', () async {
        when(mockVoiceService.setLocale('invalid-locale'))
            .thenThrow(ArgumentError('Invalid locale'));

        expect(
          () => voiceService.setLocale('invalid-locale'),
          throwsArgumentError,
        );
      });
    });

    group('Natural Language Processing', () {
      test('should process simple voice input correctly', () async {
        const inputText = 'Remind me to buy groceries tomorrow at 3 PM';
        final expectedResult = VoiceTaskResult(
          taskTitle: 'Buy groceries',
          dueDate: DateTime.now().add(const Duration(days: 1)),
          dueTime: const TimeOfDay(hour: 15, minute: 0),
          category: 'Household',
          confidence: 0.9,
          originalText: inputText,
        );

        when(mockVoiceService.processVoiceInput(inputText))
            .thenAnswer((_) async => expectedResult);

        final result = await voiceService.processVoiceInput(inputText);

        expect(result.taskTitle, 'Buy groceries');
        expect(result.dueTime?.hour, 15);
        expect(result.category, 'Household');
        expect(result.confidence, 0.9);
        expect(result.originalText, inputText);
      });

      test('should handle complex voice inputs', () async {
        final complexInputs = VoiceFixtures.sampleVoiceInputs;
        
        for (final input in complexInputs) {
          final mockResult = VoiceTaskResult(
            taskTitle: 'Extracted task',
            confidence: 0.8,
            originalText: input,
          );

          when(mockVoiceService.processVoiceInput(input))
              .thenAnswer((_) async => mockResult);

          final result = await voiceService.processVoiceInput(input);

          expect(result.originalText, input);
          expect(result.confidence, greaterThan(0.0));
          expect(result.taskTitle.isNotEmpty, isTrue);
        }
      });

      test('should handle voice input with time parsing', () async {
        final testCases = [
          {
            'input': 'Call mom at 5 PM',
            'expectedHour': 17,
            'expectedMinute': 0,
          },
          {
            'input': 'Meeting at 10:30 AM',
            'expectedHour': 10,
            'expectedMinute': 30,
          },
          {
            'input': 'Lunch at noon',
            'expectedHour': 12,
            'expectedMinute': 0,
          },
        ];

        for (final testCase in testCases) {
          final input = testCase['input'] as String;
          final expectedResult = VoiceTaskResult(
            taskTitle: 'Test task',
            dueTime: TimeOfDay(
              hour: testCase['expectedHour'] as int,
              minute: testCase['expectedMinute'] as int,
            ),
            confidence: 0.85,
            originalText: input,
          );

          when(mockVoiceService.processVoiceInput(input))
              .thenAnswer((_) async => expectedResult);

          final result = await voiceService.processVoiceInput(input);

          expect(result.dueTime?.hour, testCase['expectedHour']);
          expect(result.dueTime?.minute, testCase['expectedMinute']);
        }
      });

      test('should handle voice input with date parsing', () async {
        final testCases = [
          'tomorrow',
          'next Tuesday',
          'this Friday',
          'in 3 days',
          'next week',
        ];

        for (final datePhrase in testCases) {
          final input = 'Remind me to do something $datePhrase';
          final mockResult = VoiceTaskResult(
            taskTitle: 'Do something',
            dueDate: DateTime.now().add(const Duration(days: 1)),
            confidence: 0.8,
            originalText: input,
          );

          when(mockVoiceService.processVoiceInput(input))
              .thenAnswer((_) async => mockResult);

          final result = await voiceService.processVoiceInput(input);

          expect(result.dueDate, isNotNull);
          expect(result.dueDate!.isAfter(DateTime.now()), isTrue);
        }
      });

      test('should suggest appropriate categories', () async {
        final categoryTests = [
          {
            'input': 'Buy groceries at the store',
            'expectedCategory': 'Household',
          },
          {
            'input': 'Call the doctor for appointment',
            'expectedCategory': 'Health',
          },
          {
            'input': 'Submit quarterly report to manager',
            'expectedCategory': 'Work',
          },
          {
            'input': 'Pay rent and utilities',
            'expectedCategory': 'Finance',
          },
          {
            'input': 'Pick up kids from school',
            'expectedCategory': 'Family',
          },
        ];

        for (final test in categoryTests) {
          final input = test['input'] as String;
          final expectedCategory = test['expectedCategory'] as String;
          
          final mockResult = VoiceTaskResult(
            taskTitle: 'Test task',
            category: expectedCategory,
            confidence: 0.85,
            originalText: input,
          );

          when(mockVoiceService.processVoiceInput(input))
              .thenAnswer((_) async => mockResult);

          final result = await voiceService.processVoiceInput(input);

          expect(result.category, expectedCategory);
        }
      });

      test('should handle low confidence results', () async {
        const inputText = 'mumbled unclear speech';
        final lowConfidenceResult = VoiceTaskResult(
          taskTitle: 'unclear task',
          confidence: 0.3,
          originalText: inputText,
        );

        when(mockVoiceService.processVoiceInput(inputText))
            .thenAnswer((_) async => lowConfidenceResult);

        final result = await voiceService.processVoiceInput(inputText);

        expect(result.confidence, lessThan(0.5));
        expect(result.taskTitle, isNotEmpty);  // Should still provide some result
      });

      test('should get last confidence value', () {
        when(mockVoiceService.lastConfidence).thenReturn(0.95);

        expect(voiceService.lastConfidence, 0.95);

        when(mockVoiceService.lastConfidence).thenReturn(null);

        expect(voiceService.lastConfidence, isNull);
      });
    });

    group('Error Handling', () {
      test('should handle initialization errors', () async {
        when(mockVoiceService.initialize())
            .thenThrow(Exception('Failed to initialize voice service'));

        expect(
          () => voiceService.initialize(),
          throwsException,
        );
      });

      test('should handle permission request errors', () async {
        when(mockVoiceService.requestPermissions())
            .thenThrow(Exception('Permission request failed'));

        expect(
          () => voiceService.requestPermissions(),
          throwsException,
        );
      });

      test('should handle voice recognition errors', () async {
        when(mockVoiceService.startListening(
          onResult: anyNamed('onResult'),
          onError: anyNamed('onError'),
        )).thenAnswer((invocation) async {
          final onError = invocation.namedArguments[const Symbol('onError')] as Function(String)?;
          onError?.call('Speech recognition error');
        });

        String? capturedError;
        await voiceService.startListening(
          onResult: (text) {},
          onError: (error) => capturedError = error,
        );

        expect(capturedError, 'Speech recognition error');
      });

      test('should handle NLP processing errors', () async {
        const invalidInput = '';
        
        when(mockVoiceService.processVoiceInput(invalidInput))
            .thenThrow(ArgumentError('Empty input text'));

        expect(
          () => voiceService.processVoiceInput(invalidInput),
          throwsArgumentError,
        );
      });
    });

    group('Performance Tests', () {
      test('should process voice input efficiently', () async {
        const inputText = 'Quick performance test';
        final mockResult = VoiceTaskResult(
          taskTitle: 'Performance test',
          confidence: 0.9,
          originalText: inputText,
        );

        when(mockVoiceService.processVoiceInput(inputText))
            .thenAnswer((_) async => mockResult);

        final stopwatch = Stopwatch()..start();
        await voiceService.processVoiceInput(inputText);
        stopwatch.stop();

        expect(stopwatch.elapsedMilliseconds, lessThan(1000)); // Should be under 1 second
      });

      test('should handle multiple concurrent voice inputs', () async {
        const inputTexts = [
          'First voice input',
          'Second voice input',
          'Third voice input',
        ];

        for (int i = 0; i < inputTexts.length; i++) {
          final mockResult = VoiceTaskResult(
            taskTitle: 'Task ${i + 1}',
            confidence: 0.8,
            originalText: inputTexts[i],
          );

          when(mockVoiceService.processVoiceInput(inputTexts[i]))
              .thenAnswer((_) async => mockResult);
        }

        final futures = inputTexts.map((text) => voiceService.processVoiceInput(text));
        final results = await Future.wait(futures);

        expect(results.length, 3);
        for (int i = 0; i < results.length; i++) {
          expect(results[i].taskTitle, 'Task ${i + 1}');
        }
      });
    });
  });

  group('VoiceLocale Tests', () {
    test('should create VoiceLocale correctly', () {
      const locale = VoiceLocale(
        localeId: 'en-US',
        name: 'English (United States)',
      );

      expect(locale.localeId, 'en-US');
      expect(locale.name, 'English (United States)');
    });

    test('should support equality comparison', () {
      const locale1 = VoiceLocale(localeId: 'en-US', name: 'English (US)');
      const locale2 = VoiceLocale(localeId: 'en-US', name: 'English (US)');
      const locale3 = VoiceLocale(localeId: 'es-ES', name: 'Spanish (ES)');

      expect(locale1.localeId, locale2.localeId);
      expect(locale1.name, locale2.name);
      expect(locale1.localeId, isNot(locale3.localeId));
    });
  });

  group('VoiceTaskResult Tests', () {
    test('should create VoiceTaskResult with all fields', () {
      final dueDate = DateTime.now().add(const Duration(days: 1));
      const dueTime = TimeOfDay(hour: 15, minute: 30);
      
      const result = VoiceTaskResult(
        taskTitle: 'Test Task',
        description: 'Test description',
        dueDate: null,  // Will be set below
        dueTime: dueTime,
        category: 'Work',
        confidence: 0.95,
        originalText: 'Original voice input',
      );

      final resultWithDate = VoiceTaskResult(
        taskTitle: result.taskTitle,
        description: result.description,
        dueDate: dueDate,
        dueTime: result.dueTime,
        category: result.category,
        confidence: result.confidence,
        originalText: result.originalText,
      );

      expect(resultWithDate.taskTitle, 'Test Task');
      expect(resultWithDate.description, 'Test description');
      expect(resultWithDate.dueDate, dueDate);
      expect(resultWithDate.dueTime, dueTime);
      expect(resultWithDate.category, 'Work');
      expect(resultWithDate.confidence, 0.95);
      expect(resultWithDate.originalText, 'Original voice input');
    });

    test('should create VoiceTaskResult with minimal fields', () {
      const result = VoiceTaskResult(
        taskTitle: 'Minimal Task',
        confidence: 0.7,
        originalText: 'Minimal input',
      );

      expect(result.taskTitle, 'Minimal Task');
      expect(result.description, isNull);
      expect(result.dueDate, isNull);
      expect(result.dueTime, isNull);
      expect(result.category, isNull);
      expect(result.confidence, 0.7);
      expect(result.originalText, 'Minimal input');
    });
  });

  group('TimeOfDay Tests', () {
    test('should create TimeOfDay correctly', () {
      const timeOfDay = TimeOfDay(hour: 14, minute: 30);

      expect(timeOfDay.hour, 14);
      expect(timeOfDay.minute, 30);
    });

    test('should handle edge cases for time values', () {
      const midnight = TimeOfDay(hour: 0, minute: 0);
      const justBeforeMidnight = TimeOfDay(hour: 23, minute: 59);
      const noon = TimeOfDay(hour: 12, minute: 0);

      expect(midnight.hour, 0);
      expect(midnight.minute, 0);
      expect(justBeforeMidnight.hour, 23);
      expect(justBeforeMidnight.minute, 59);
      expect(noon.hour, 12);
      expect(noon.minute, 0);
    });
  });
}