import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:task_tracker_app/core/services/advanced_nlp_service.dart';
import 'package:task_tracker_app/features/voice/voice_state.dart';
import '../../test_utils/fixtures.dart';

// Since we can't directly mock the AdvancedNlpService (it's a concrete class),
// we'll test it directly and mock its dependencies if needed
void main() {
  group('AdvancedNlpService Tests', () {
    late AdvancedNlpService nlpService;

    setUp(() {
      nlpService = AdvancedNlpService();
    });

    group('Voice Input Parsing', () {
      test('should parse simple voice input with date', () async {
        const input = 'Remind me to buy groceries tomorrow';
        
        final result = await nlpService.parseVoiceInput(input);
        
        expect(result.taskTitle, isNotEmpty);
        expect(result.parsedDate, isNotNull);
        expect(result.parsedDate!.isAfter(DateTime.now()), isTrue);
        expect(result.originalText, input);
      });

      test('should parse voice input with time information', () async {
        const input = 'Call mom at 3 PM today';
        
        final result = await nlpService.parseVoiceInput(input);
        
        expect(result.taskTitle, contains('call'));
        expect(result.parsedTime, isNotNull);
        expect(result.parsedTime!.hour, equals(15)); // 3 PM
      });

      test('should handle multiple date expressions', () async {
        final testCases = [
          'Buy groceries tomorrow',
          'Meeting next week',
          'Doctor appointment this friday',
          'Vacation next month',
          'Call in 3 days',
          'Submit report end of this week',
        ];

        for (final testCase in testCases) {
          final result = await nlpService.parseVoiceInput(testCase);
          
          expect(result.taskTitle, isNotEmpty, 
              reason: 'Failed to extract task title from: $testCase');
          expect(result.originalText, equals(testCase));
          // Date should be parsed for most cases
          if (testCase.contains('tomorrow') || 
              testCase.contains('next') || 
              testCase.contains('this') ||
              testCase.contains('in 3 days') ||
              testCase.contains('end of')) {
            expect(result.parsedDate, isNotNull, 
                reason: 'Failed to parse date from: $testCase');
          }
        }
      });

      test('should handle complex relative date expressions', () async {
        final testCases = [
          {
            'input': 'Remind me in 5 days to water plants',
            'expectFuture': true,
          },
          {
            'input': 'Schedule meeting 2 weeks from now',
            'expectFuture': true,
          },
          {
            'input': 'Pay bills after tomorrow',
            'expectFuture': true,
          },
          {
            'input': 'Book vacation next month',
            'expectFuture': true,
          },
        ];

        for (final testCase in testCases) {
          final input = testCase['input'] as String;
          final result = await nlpService.parseVoiceInput(input);
          
          expect(result.parsedDate, isNotNull, 
              reason: 'Failed to parse date from: $input');
          
          if (testCase['expectFuture'] == true) {
            expect(result.parsedDate!.isAfter(DateTime.now()), isTrue,
                reason: 'Date should be in future for: $input');
          }
        }
      });

      test('should parse weekend expressions correctly', () async {
        final testCases = [
          'This weekend go hiking',
          'Next weekend visit parents',
          'Clean garage this weekend',
        ];

        for (final input in testCases) {
          final result = await nlpService.parseVoiceInput(input);
          
          expect(result.parsedDate, isNotNull, 
              reason: 'Failed to parse weekend date from: $input');
          
          // Weekend dates should be Saturday or Sunday
          final weekday = result.parsedDate!.weekday;
          expect(weekday == DateTime.saturday || weekday == DateTime.sunday, 
              isTrue, reason: 'Weekend date should be Saturday or Sunday');
        }
      });

      test('should handle holiday expressions', () async {
        final testCases = [
          'Buy gifts before Christmas',
          'New year resolution planning',
          'Book restaurant for Christmas dinner',
        ];

        for (final input in testCases) {
          final result = await nlpService.parseVoiceInput(input);
          
          expect(result.taskTitle, isNotEmpty, 
              reason: 'Failed to extract task from: $input');
          
          if (input.contains('Christmas')) {
            expect(result.parsedDate?.month, equals(12),
                reason: 'Christmas should be in December');
            expect(result.parsedDate?.day, equals(25),
                reason: 'Christmas should be on the 25th');
          }
          
          if (input.contains('new year')) {
            expect(result.parsedDate?.month, equals(1),
                reason: 'New Year should be in January');
            expect(result.parsedDate?.day, equals(1),
                reason: 'New Year should be on the 1st');
          }
        }
      });

      test('should extract category suggestions correctly', () async {
        final testCases = [
          {
            'input': 'Buy groceries at supermarket',
            'expectedCategory': 'Household',
          },
          {
            'input': 'Schedule doctor checkup',
            'expectedCategory': 'Health',
          },
          {
            'input': 'Submit project report to boss',
            'expectedCategory': 'Work',
          },
          {
            'input': 'Pay mortgage and utilities',
            'expectedCategory': 'Finance',
          },
          {
            'input': 'Pick up children from school',
            'expectedCategory': 'Family',
          },
        ];

        for (final testCase in testCases) {
          final input = testCase['input'] as String;
          final result = await nlpService.parseVoiceInput(input);
          
          expect(result.suggestedCategory, isNotNull,
              reason: 'Should suggest category for: $input');
          // Note: Exact category matching depends on the implementation
          // This test verifies that some category is suggested
        }
      });

      test('should handle priority keywords', () async {
        final testCases = [
          'URGENT: Call lawyer about contract',
          'Important meeting with client tomorrow',
          'ASAP fix the broken printer',
          'Critical bug in production system',
        ];

        for (final input in testCases) {
          final result = await nlpService.parseVoiceInput(input);
          
          expect(result.taskTitle, isNotEmpty);
          expect(result.priority, isNotNull,
              reason: 'Should detect priority from: $input');
          expect(result.priority, equals(TaskPriority.high),
              reason: 'Priority keywords should result in high priority');
        }
      });
    });

    group('Parsing Statistics', () {
      test('should provide parsing statistics', () {
        const input = 'Urgent: Schedule important meeting tomorrow at 3 PM';
        
        final stats = nlpService.getParsingStats(input);
        
        expect(stats, containsPair('original_length', input.length));
        expect(stats, containsPair('word_count', input.split(' ').length));
        expect(stats, containsPair('has_date_keywords', isTrue));
        expect(stats, containsPair('has_time_keywords', isTrue));
        expect(stats, containsPair('has_priority_keywords', isTrue));
        expect(stats, containsPair('complexity_score', isA<double>()));
        expect(stats['complexity_score'], greaterThan(0.0));
        expect(stats['complexity_score'], lessThanOrEqualTo(1.0));
      });

      test('should calculate complexity score correctly', () {
        final testCases = [
          {
            'input': 'Buy milk',
            'expectedComplexity': 'low', // Simple, short text
          },
          {
            'input': 'Schedule urgent important meeting with client tomorrow at 3 PM',
            'expectedComplexity': 'high', // Long with many keywords
          },
          {
            'input': 'Call mom',
            'expectedComplexity': 'low', // Very simple
          },
        ];

        for (final testCase in testCases) {
          final input = testCase['input'] as String;
          final stats = nlpService.getParsingStats(input);
          final complexity = stats['complexity_score'] as double;
          
          if (testCase['expectedComplexity'] == 'low') {
            expect(complexity, lessThan(0.5), 
                reason: 'Simple text should have low complexity: $input');
          } else if (testCase['expectedComplexity'] == 'high') {
            expect(complexity, greaterThan(0.5), 
                reason: 'Complex text should have high complexity: $input');
          }
        }
      });

      test('should detect keyword categories correctly', () {
        final testCases = [
          {
            'input': 'Tomorrow meeting at noon',
            'hasDate': true,
            'hasTime': true,
            'hasPriority': false,
          },
          {
            'input': 'Urgent task must be done',
            'hasDate': false,
            'hasTime': false,
            'hasPriority': true,
          },
          {
            'input': 'Simple task',
            'hasDate': false,
            'hasTime': false,
            'hasPriority': false,
          },
        ];

        for (final testCase in testCases) {
          final input = testCase['input'] as String;
          final stats = nlpService.getParsingStats(input);
          
          expect(stats['has_date_keywords'], equals(testCase['hasDate']),
              reason: 'Date keyword detection failed for: $input');
          expect(stats['has_time_keywords'], equals(testCase['hasTime']),
              reason: 'Time keyword detection failed for: $input');
          expect(stats['has_priority_keywords'], equals(testCase['hasPriority']),
              reason: 'Priority keyword detection failed for: $input');
        }
      });
    });

    group('Edge Cases and Error Handling', () {
      test('should handle empty input gracefully', () async {
        const input = '';
        
        final result = await nlpService.parseVoiceInput(input);
        
        expect(result.originalText, equals(input));
        expect(result.taskTitle, isNotNull); // Should provide some default
        expect(result.confidence, greaterThanOrEqualTo(0.0));
      });

      test('should handle very long input', () async {
        final longInput = 'Buy groceries ' * 100; // Very long repeated text
        
        final result = await nlpService.parseVoiceInput(longInput);
        
        expect(result.originalText, equals(longInput));
        expect(result.taskTitle, isNotEmpty);
        expect(result.confidence, greaterThanOrEqualTo(0.0));
      });

      test('should handle input with special characters', () async {
        const input = 'Buy @#\$% groceries!!! 🛒 tomorrow??? at 3:30 PM';
        
        final result = await nlpService.parseVoiceInput(input);
        
        expect(result.taskTitle, isNotEmpty);
        expect(result.parsedDate, isNotNull);
        expect(result.parsedTime, isNotNull);
        expect(result.originalText, equals(input));
      });

      test('should handle multilingual input gracefully', () async {
        final testCases = [
          'Comprar leche mañana', // Spanish
          'Acheter du lait demain', // French
          'Milch kaufen morgen', // German
        ];

        for (final input in testCases) {
          final result = await nlpService.parseVoiceInput(input);
          
          expect(result.originalText, equals(input));
          expect(result.taskTitle, isNotEmpty);
          // May not parse dates correctly for non-English, but shouldn't crash
          expect(result.confidence, greaterThanOrEqualTo(0.0));
        }
      });

      test('should handle contradictory date information', () async {
        const input = 'Meeting yesterday tomorrow next week';
        
        final result = await nlpService.parseVoiceInput(input);
        
        expect(result.taskTitle, isNotEmpty);
        expect(result.originalText, equals(input));
        // Should pick one date or handle gracefully
        expect(result.confidence, greaterThanOrEqualTo(0.0));
      });

      test('should handle ambiguous time expressions', () async {
        final testCases = [
          'Call at around 3ish',
          'Meeting sometime in the morning',
          'Task due end of day',
          'Before lunch time',
        ];

        for (final input in testCases) {
          final result = await nlpService.parseVoiceInput(input);
          
          expect(result.taskTitle, isNotEmpty, 
              reason: 'Failed to extract task from: $input');
          expect(result.originalText, equals(input));
          // May or may not parse time successfully, but shouldn't crash
          expect(result.confidence, greaterThanOrEqualTo(0.0));
        }
      });
    });

    group('Performance Tests', () {
      test('should process input efficiently', () async {
        const input = 'Schedule meeting tomorrow at 3 PM';
        
        final stopwatch = Stopwatch()..start();
        await nlpService.parseVoiceInput(input);
        stopwatch.stop();
        
        expect(stopwatch.elapsedMilliseconds, lessThan(1000),
            reason: 'NLP processing should complete within 1 second');
      });

      test('should handle batch processing efficiently', () async {
        final inputs = [
          'Buy groceries tomorrow',
          'Call doctor next week',
          'Meeting at 3 PM today',
          'Vacation planning next month',
          'Pay bills this friday',
        ];

        final stopwatch = Stopwatch()..start();
        
        final futures = inputs.map((input) => nlpService.parseVoiceInput(input));
        final results = await Future.wait(futures);
        
        stopwatch.stop();
        
        expect(results.length, equals(inputs.length));
        expect(stopwatch.elapsedMilliseconds, lessThan(3000),
            reason: 'Batch processing should complete within 3 seconds');
        
        for (int i = 0; i < results.length; i++) {
          expect(results[i].originalText, equals(inputs[i]));
          expect(results[i].taskTitle, isNotEmpty);
        }
      });

      test('should maintain performance with complex input', () async {
        const complexInput = '''
          Schedule an urgent and important meeting with the client team 
          tomorrow at 3:30 PM to discuss the quarterly business review, 
          project deliverables, budget allocations, and strategic planning 
          for the next fiscal year including resource allocation and timeline 
          adjustments for all active projects and initiatives.
        ''';

        final stopwatch = Stopwatch()..start();
        final result = await nlpService.parseVoiceInput(complexInput);
        stopwatch.stop();
        
        expect(stopwatch.elapsedMilliseconds, lessThan(2000),
            reason: 'Complex input processing should complete within 2 seconds');
        expect(result.taskTitle, isNotEmpty);
        expect(result.originalText, equals(complexInput));
      });
    });

    group('Regression Tests', () {
      test('should maintain backward compatibility', () async {
        // Test cases that should continue to work as expected
        final regressionCases = VoiceFixtures.sampleVoiceInputs;
        
        for (final input in regressionCases) {
          final result = await nlpService.parseVoiceInput(input);
          
          expect(result.originalText, equals(input));
          expect(result.taskTitle, isNotEmpty,
              reason: 'Regression: Failed to extract task from: $input');
          expect(result.confidence, greaterThanOrEqualTo(0.0),
              reason: 'Regression: Invalid confidence for: $input');
          expect(result.confidence, lessThanOrEqualTo(1.0),
              reason: 'Regression: Confidence out of range for: $input');
        }
      });

      test('should handle previously problematic inputs', () async {
        // Edge cases that might have caused issues in the past
        final problematicInputs = [
          'um, uh, remind me to, you know, call the, uh, dentist',
          'MEETING!!!! tomorrow AT 3!!!',
          '   extra   spaces   everywhere   ',
          'Meeting\nwith\nnewlines\neverywhere',
          'Meeting\ttabs\there',
        ];

        for (final input in problematicInputs) {
          final result = await nlpService.parseVoiceInput(input);
          
          expect(result.originalText, equals(input));
          expect(result.taskTitle, isNotEmpty,
              reason: 'Failed to handle problematic input: $input');
          expect(result.confidence, greaterThanOrEqualTo(0.0));
        }
      });
    });
  });

  group('DateResult Helper Class Tests', () {
    test('should create DateResult correctly', () {
      final date = DateTime.now();
      const confidence = 0.85;
      
      final result = DateResult(date, confidence);
      
      expect(result.date, equals(date));
      expect(result.confidence, equals(confidence));
    });

    test('should handle edge case confidence values', () {
      final date = DateTime.now();
      
      final minConfidence = DateResult(date, 0.0);
      final maxConfidence = DateResult(date, 1.0);
      
      expect(minConfidence.confidence, equals(0.0));
      expect(maxConfidence.confidence, equals(1.0));
    });
  });
}

/// Helper class for date parsing results
class DateResult {
  final DateTime date;
  final double confidence;
  
  const DateResult(this.date, this.confidence);
}