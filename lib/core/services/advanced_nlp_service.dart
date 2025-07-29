import 'package:jiffy/jiffy.dart';
import 'package:intl/intl.dart';
import '../../features/voice/voice_state.dart';
import '../../features/voice/natural_language_parser.dart';

/// Advanced Natural Language Processing service that combines
/// the existing parser with Jiffy for enhanced date processing
class AdvancedNlpService {
  final NaturalLanguageParser _parser = NaturalLanguageParser();
  
  /// Parse voice input with enhanced date processing using Jiffy
  Future<ParsedVoiceInput> parseVoiceInput(String text) async {
    // First try the enhanced parser
    final basicResult = await _parser.parseVoiceInput(text);
    
    // If date parsing failed or has low confidence, try Jiffy-based parsing
    if (basicResult.parsedDate == null || (basicResult.dateConfidence ?? 0) < 0.7) {
      final jiffyDate = _parseWithJiffy(text);
      if (jiffyDate != null) {
        return basicResult.copyWith(
          parsedDate: jiffyDate,
          dateConfidence: 0.8, // Jiffy parsing gets good confidence
        );
      }
    }
    
    // Try enhanced natural language patterns that Jiffy might catch
    final enhancedDate = _parseEnhancedDatePatterns(text);
    if (enhancedDate != null && basicResult.parsedDate == null) {
      return basicResult.copyWith(
        parsedDate: enhancedDate.date,
        dateConfidence: enhancedDate.confidence,
      );
    }
    
    return basicResult;
  }
  
  /// Parse dates using Jiffy's natural language capabilities
  DateTime? _parseWithJiffy(String text) {
    try {
      final normalizedText = text.toLowerCase().trim();
      
      // Extract potential date expressions
      final dateExpressions = _extractDateExpressions(normalizedText);
      
      for (final expression in dateExpressions) {
        try {
          // Try common Jiffy patterns
          if (expression.contains('next') || expression.contains('this') || 
              expression.contains('tomorrow') || expression.contains('today')) {
            
            final jiffy = Jiffy.now();
            
            if (expression.contains('tomorrow')) {
              return jiffy.add(days: 1).dateTime;
            }
            if (expression.contains('today')) {
              return jiffy.dateTime;
            }
            if (expression.contains('next week')) {
              return jiffy.add(weeks: 1).dateTime;
            }
            if (expression.contains('next month')) {
              return jiffy.add(months: 1).dateTime;
            }
            if (expression.contains('this weekend')) {
              // Find next Saturday
              final daysUntilSaturday = 6 - jiffy.dateTime.weekday;
              return jiffy.add(days: daysUntilSaturday > 0 ? daysUntilSaturday : 7).dateTime;
            }
          }
          
          // Try parsing relative expressions
          final relativeDate = _parseRelativeExpression(expression);
          if (relativeDate != null) {
            return relativeDate;
          }
          
        } catch (e) {
          continue; // Try next expression
        }
      }
    } catch (e) {
      // Jiffy parsing failed, return null
    }
    
    return null;
  }
  
  /// Extract potential date expressions from text
  List<String> _extractDateExpressions(String text) {
    final expressions = <String>[];
    
    // Common date expression patterns
    final patterns = [
      r'\b(?:next|this|last)\s+(?:week|month|year|weekend|friday|monday|tuesday|wednesday|thursday|saturday|sunday)\b',
      r'\bin\s+\d+\s+(?:days?|weeks?|months?|years?)\b',
      r'\b(?:tomorrow|today|yesterday)\b',
      r'\b(?:end|beginning)\s+of\s+(?:this|next|last)\s+(?:week|month|year)\b',
      r'\b(?:january|february|march|april|may|june|july|august|september|october|november|december)\s+\d{1,2}\b',
    ];
    
    for (final pattern in patterns) {
      final matches = RegExp(pattern, caseSensitive: false).allMatches(text);
      for (final match in matches) {
        expressions.add(match.group(0)!);
      }
    }
    
    return expressions;
  }
  
  /// Parse relative expressions that might not be caught by basic patterns
  DateTime? _parseRelativeExpression(String expression) {
    final jiffy = Jiffy.now();
    final expr = expression.toLowerCase().trim();
    
    // Handle "in X days/weeks/months" patterns
    final inPattern = RegExp(r'in\s+(\d+)\s+(days?|weeks?|months?|years?)');
    final inMatch = inPattern.firstMatch(expr);
    if (inMatch != null) {
      final amount = int.parse(inMatch.group(1)!);
      final unit = inMatch.group(2)!;
      
      switch (unit) {
        case 'day':
        case 'days':
          return jiffy.add(days: amount).dateTime;
        case 'week':
        case 'weeks':
          return jiffy.add(weeks: amount).dateTime;
        case 'month':
        case 'months':
          return jiffy.add(months: amount).dateTime;
        case 'year':
        case 'years':
          return jiffy.add(years: amount).dateTime;
      }
    }
    
    // Handle "X days/weeks from now" patterns
    final fromNowPattern = RegExp(r'(\d+)\s+(days?|weeks?|months?)\s+from\s+now');
    final fromNowMatch = fromNowPattern.firstMatch(expr);
    if (fromNowMatch != null) {
      final amount = int.parse(fromNowMatch.group(1)!);
      final unit = fromNowMatch.group(2)!;
      
      switch (unit) {
        case 'day':
        case 'days':
          return jiffy.add(days: amount).dateTime;
        case 'week':
        case 'weeks':
          return jiffy.add(weeks: amount).dateTime;
        case 'month':
        case 'months':
          return jiffy.add(months: amount).dateTime;
      }
    }
    
    // Handle "after X" patterns  
    final afterPattern = RegExp(r'after\s+(tomorrow|next\s+week|next\s+month)');
    final afterMatch = afterPattern.firstMatch(expr);
    if (afterMatch != null) {
      final after = afterMatch.group(1)!;
      if (after.contains('tomorrow')) {
        return jiffy.add(days: 2).dateTime; // Day after tomorrow
      }
      if (after.contains('next week')) {
        return jiffy.add(weeks: 1, days: 1).dateTime;
      }
      if (after.contains('next month')) {
        return jiffy.add(months: 1, days: 1).dateTime;
      }
    }
    
    return null;
  }
  
  /// Enhanced date parsing with additional patterns
  DateResult? _parseEnhancedDatePatterns(String text) {
    final jiffy = Jiffy.now();
    final normalizedText = text.toLowerCase();
    
    // Extended weekend patterns
    if (normalizedText.contains('this weekend')) {
      final saturday = jiffy.add(days: 6 - jiffy.dateTime.weekday).dateTime;
      return DateResult(saturday, 0.8);
    }
    
    if (normalizedText.contains('next weekend')) {
      final nextSaturday = jiffy.add(days: 6 - jiffy.dateTime.weekday + 7).dateTime;
      return DateResult(nextSaturday, 0.8);
    }
    
    // Holiday approximations
    if (normalizedText.contains('christmas')) {
      final christmas = DateTime(jiffy.year, 12, 25);
      if (christmas.isBefore(jiffy.dateTime)) {
        return DateResult(DateTime(jiffy.year + 1, 12, 25), 0.6);
      }
      return DateResult(christmas, 0.6);
    }
    
    if (normalizedText.contains('new year')) {
      final newYear = DateTime(jiffy.year + 1, 1, 1);
      return DateResult(newYear, 0.6);
    }
    
    // Season approximations
    if (normalizedText.contains('next spring')) {
      return DateResult(DateTime(jiffy.year + 1, 3, 20), 0.5);
    }
    if (normalizedText.contains('next summer')) {
      return DateResult(DateTime(jiffy.year + 1, 6, 21), 0.5);
    }
    
    // Fiscal/academic patterns
    if (normalizedText.contains('end of fiscal year')) {
      return DateResult(DateTime(jiffy.year, 12, 31), 0.7);
    }
    
    if (normalizedText.contains('end of school year')) {
      return DateResult(DateTime(jiffy.year, 6, 15), 0.6);
    }
    
    return null;
  }
  
  /// Get parsing statistics for debugging and optimization
  Map<String, dynamic> getParsingStats(String text) {
    return {
      'original_length': text.length,
      'word_count': text.split(' ').length,
      'has_date_keywords': _hasDateKeywords(text),
      'has_time_keywords': _hasTimeKeywords(text),
      'has_priority_keywords': _hasPriorityKeywords(text),
      'complexity_score': _calculateComplexityScore(text),
    };
  }
  
  bool _hasDateKeywords(String text) {
    final dateKeywords = [
      'tomorrow', 'today', 'yesterday', 'next', 'this', 'last',
      'week', 'month', 'year', 'weekend', 'morning', 'afternoon',
      'evening', 'night', 'monday', 'tuesday', 'wednesday', 'thursday',
      'friday', 'saturday', 'sunday'
    ];
    
    final lowercaseText = text.toLowerCase();
    return dateKeywords.any((keyword) => lowercaseText.contains(keyword));
  }
  
  bool _hasTimeKeywords(String text) {
    final timeKeywords = [
      'am', 'pm', 'oclock', 'noon', 'midnight', 'morning', 'afternoon',
      'evening', 'night', 'early', 'late', 'around', 'about'
    ];
    
    final lowercaseText = text.toLowerCase();
    return timeKeywords.any((keyword) => lowercaseText.contains(keyword));
  }
  
  bool _hasPriorityKeywords(String text) {
    final priorityKeywords = [
      'urgent', 'important', 'asap', 'critical', 'priority', 'must',
      'essential', 'vital', 'crucial', 'immediately'
    ];
    
    final lowercaseText = text.toLowerCase();
    return priorityKeywords.any((keyword) => lowercaseText.contains(keyword));
  }
  
  double _calculateComplexityScore(String text) {
    double score = 0.0;
    
    // Length factor
    score += (text.length / 100).clamp(0.0, 1.0) * 0.3;
    
    // Word count factor
    final wordCount = text.split(' ').length;
    score += (wordCount / 20).clamp(0.0, 1.0) * 0.3;
    
    // Keyword density
    final hasDate = _hasDateKeywords(text) ? 0.2 : 0.0;
    final hasTime = _hasTimeKeywords(text) ? 0.1 : 0.0;
    final hasPriority = _hasPriorityKeywords(text) ? 0.1 : 0.0;
    
    score += hasDate + hasTime + hasPriority;
    
    return score.clamp(0.0, 1.0);
  }
}