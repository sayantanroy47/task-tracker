import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:jiffy/jiffy.dart';

/// Comprehensive date/time utilities with timezone awareness
/// Handles natural language parsing, edge cases, and timezone conversions
class DateTimeUtils {
  static final _dateFormat = DateFormat('yyyy-MM-dd');
  static final _timeFormat = DateFormat('HH:mm');
  static final _dateTimeFormat = DateFormat('yyyy-MM-dd HH:mm');
  static final _displayDateFormat = DateFormat('MMM d, yyyy');
  static final _displayTimeFormat = DateFormat('h:mm a');

  /// Parse natural language date/time input
  /// Handles inputs like "tomorrow at 3 PM", "next Monday", "in 2 hours"
  static ParsedDateTime? parseNaturalLanguage(String input) {
    if (input.trim().isEmpty) return null;

    try {
      final cleanInput = input.toLowerCase().trim();
      final now = DateTime.now();

      // Handle "today" and variations
      if (_matchesPattern(cleanInput, ['today', 'now'])) {
        return ParsedDateTime(
          date: now,
          time: _extractTime(cleanInput) ?? TimeOfDay.fromDateTime(now),
          confidence: 0.9,
          originalInput: input,
        );
      }

      // Handle "tomorrow"
      if (_matchesPattern(cleanInput, ['tomorrow', 'tmrw'])) {
        final tomorrow = now.add(const Duration(days: 1));
        return ParsedDateTime(
          date: tomorrow,
          time: _extractTime(cleanInput),
          confidence: 0.9,
          originalInput: input,
        );
      }

      // Handle "yesterday"
      if (_matchesPattern(cleanInput, ['yesterday'])) {
        final yesterday = now.subtract(const Duration(days: 1));
        return ParsedDateTime(
          date: yesterday,
          time: _extractTime(cleanInput),
          confidence: 0.9,
          originalInput: input,
        );
      }

      // Handle day names (Monday, Tuesday, etc.)
      final dayOfWeek = _parseDayOfWeek(cleanInput);
      if (dayOfWeek != null) {
        final targetDate = _getNextWeekday(now, dayOfWeek);
        return ParsedDateTime(
          date: targetDate,
          time: _extractTime(cleanInput),
          confidence: 0.85,
          originalInput: input,
        );
      }

      // Handle relative dates (in X days, after X days)
      final relativeDays = _parseRelativeDays(cleanInput);
      if (relativeDays != null) {
        final targetDate = now.add(Duration(days: relativeDays));
        return ParsedDateTime(
          date: targetDate,
          time: _extractTime(cleanInput),
          confidence: 0.8,
          originalInput: input,
        );
      }

      // Handle relative times (in X hours, after X minutes)
      final relativeTime = _parseRelativeTime(cleanInput);
      if (relativeTime != null) {
        final targetDateTime = now.add(relativeTime);
        return ParsedDateTime(
          date: targetDateTime,
          time: TimeOfDay.fromDateTime(targetDateTime),
          confidence: 0.8,
          originalInput: input,
        );
      }

      // Handle month names and dates (January 15, Jan 15, 1/15)
      final specificDate = _parseSpecificDate(cleanInput, now.year);
      if (specificDate != null) {
        return ParsedDateTime(
          date: specificDate,
          time: _extractTime(cleanInput),
          confidence: 0.75,
          originalInput: input,
        );
      }

      // Handle next/this week/month
      final relativeDate = _parseRelativeDate(cleanInput, now);
      if (relativeDate != null) {
        return ParsedDateTime(
          date: relativeDate,
          time: _extractTime(cleanInput),
          confidence: 0.7,
          originalInput: input,
        );
      }

      // Fallback: try Jiffy for more complex parsing
      return _tryJiffyParsing(input, now);

    } catch (e) {
      // If all parsing fails, return null
      return null;
    }
  }

  /// Extract time from natural language input
  static TimeOfDay? _extractTime(String input) {
    final timePatterns = [
      // 12-hour format with AM/PM
      RegExp(r'(\d{1,2})(?::(\d{2}))?\s*(am|pm)', caseSensitive: false),
      // 24-hour format
      RegExp(r'(\d{1,2}):(\d{2})'),
      // Simple hour format
      RegExp(r'at\s+(\d{1,2})', caseSensitive: false),
    ];

    for (final pattern in timePatterns) {
      final match = pattern.firstMatch(input);
      if (match != null) {
        try {
          int hour = int.parse(match.group(1)!);
          int minute = match.groupCount >= 2 && match.group(2) != null 
              ? int.parse(match.group(2)!) 
              : 0;
          
          // Handle AM/PM
          if (match.groupCount >= 3 && match.group(3) != null) {
            final period = match.group(3)!.toLowerCase();
            if (period == 'pm' && hour != 12) {
              hour += 12;
            } else if (period == 'am' && hour == 12) {
              hour = 0;
            }
          }

          if (hour >= 0 && hour <= 23 && minute >= 0 && minute <= 59) {
            return TimeOfDay(hour: hour, minute: minute);
          }
        } catch (e) {
          continue;
        }
      }
    }

    // Handle common time expressions
    final timeMap = {
      'morning': const TimeOfDay(hour: 9, minute: 0),
      'noon': const TimeOfDay(hour: 12, minute: 0),
      'afternoon': const TimeOfDay(hour: 14, minute: 0),
      'evening': const TimeOfDay(hour: 18, minute: 0),
      'night': const TimeOfDay(hour: 20, minute: 0),
      'midnight': const TimeOfDay(hour: 0, minute: 0),
    };

    for (final entry in timeMap.entries) {
      if (input.toLowerCase().contains(entry.key)) {
        return entry.value;
      }
    }

    return null;
  }

  /// Check if input matches any of the given patterns
  static bool _matchesPattern(String input, List<String> patterns) {
    return patterns.any((pattern) => input.contains(pattern));
  }

  /// Parse day of week from input
  static int? _parseDayOfWeek(String input) {
    final dayMap = {
      'monday': 1, 'mon': 1,
      'tuesday': 2, 'tue': 2, 'tues': 2,
      'wednesday': 3, 'wed': 3,
      'thursday': 4, 'thu': 4, 'thur': 4, 'thurs': 4,
      'friday': 5, 'fri': 5,
      'saturday': 6, 'sat': 6,
      'sunday': 7, 'sun': 7,
    };

    for (final entry in dayMap.entries) {
      if (input.contains(entry.key)) {
        return entry.value;
      }
    }
    return null;
  }

  /// Get next occurrence of a specific weekday
  static DateTime _getNextWeekday(DateTime from, int targetWeekday) {
    final currentWeekday = from.weekday;
    int daysUntilTarget = targetWeekday - currentWeekday;
    
    if (daysUntilTarget <= 0) {
      daysUntilTarget += 7; // Next week
    }
    
    return from.add(Duration(days: daysUntilTarget));
  }

  /// Parse relative days (in X days, after X days)
  static int? _parseRelativeDays(String input) {
    final patterns = [
      RegExp(r'in\s+(\d+)\s+days?', caseSensitive: false),
      RegExp(r'after\s+(\d+)\s+days?', caseSensitive: false),
      RegExp(r'(\d+)\s+days?\s+from\s+now', caseSensitive: false),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(input);
      if (match != null) {
        return int.tryParse(match.group(1)!);
      }
    }
    return null;
  }

  /// Parse relative time (in X hours, after X minutes)
  static Duration? _parseRelativeTime(String input) {
    final patterns = [
      RegExp(r'in\s+(\d+)\s+hours?', caseSensitive: false),
      RegExp(r'in\s+(\d+)\s+minutes?', caseSensitive: false),
      RegExp(r'in\s+(\d+)\s+mins?', caseSensitive: false),
      RegExp(r'after\s+(\d+)\s+hours?', caseSensitive: false),
      RegExp(r'after\s+(\d+)\s+minutes?', caseSensitive: false),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(input);
      if (match != null) {
        final value = int.tryParse(match.group(1)!);
        if (value != null) {
          if (pattern.pattern.contains('hour')) {
            return Duration(hours: value);
          } else if (pattern.pattern.contains('min')) {
            return Duration(minutes: value);
          }
        }
      }
    }
    return null;
  }

  /// Parse specific dates (January 15, Jan 15, 1/15, 15/1)
  static DateTime? _parseSpecificDate(String input, int defaultYear) {
    // Month names
    final monthNames = {
      'january': 1, 'jan': 1,
      'february': 2, 'feb': 2,
      'march': 3, 'mar': 3,
      'april': 4, 'apr': 4,
      'may': 5,
      'june': 6, 'jun': 6,
      'july': 7, 'jul': 7,
      'august': 8, 'aug': 8,
      'september': 9, 'sep': 9, 'sept': 9,
      'october': 10, 'oct': 10,
      'november': 11, 'nov': 11,
      'december': 12, 'dec': 12,
    };

    // Try month name + day (January 15, Jan 15)
    for (final entry in monthNames.entries) {
      final pattern = RegExp('${entry.key}\\s+(\\d{1,2})', caseSensitive: false);
      final match = pattern.firstMatch(input);
      if (match != null) {
        final day = int.tryParse(match.group(1)!);
        if (day != null && day >= 1 && day <= 31) {
          try {
            return DateTime(defaultYear, entry.value, day);
          } catch (e) {
            continue;
          }
        }
      }
    }

    // Try numeric formats (1/15, 15/1, 1-15, 15-1)
    final numericPatterns = [
      RegExp(r'(\d{1,2})[\/\-](\d{1,2})'),
      RegExp(r'(\d{1,2})\/(\d{1,2})\/(\d{2,4})'),
    ];

    for (final pattern in numericPatterns) {
      final match = pattern.firstMatch(input);
      if (match != null) {
        try {
          if (match.groupCount == 3) {
            // Format: MM/DD/YYYY or DD/MM/YYYY
            final part1 = int.parse(match.group(1)!);
            final part2 = int.parse(match.group(2)!);
            final year = int.parse(match.group(3)!);
            
            // Assume MM/DD format for US-style dates
            if (part1 <= 12) {
              return DateTime(year, part1, part2);
            } else {
              return DateTime(year, part2, part1);
            }
          } else {
            // Format: MM/DD or DD/MM
            final part1 = int.parse(match.group(1)!);
            final part2 = int.parse(match.group(2)!);
            
            // Assume MM/DD format for US-style dates
            if (part1 <= 12) {
              return DateTime(defaultYear, part1, part2);
            } else {
              return DateTime(defaultYear, part2, part1);
            }
          }
        } catch (e) {
          continue;
        }
      }
    }

    return null;
  }

  /// Parse relative dates (next week, this month, etc.)
  static DateTime? _parseRelativeDate(String input, DateTime now) {
    if (input.contains('next week')) {
      return now.add(const Duration(days: 7));
    }
    if (input.contains('this week')) {
      return now;
    }
    if (input.contains('next month')) {
      return DateTime(now.year, now.month + 1, now.day);
    }
    if (input.contains('this month')) {
      return now;
    }
    return null;
  }

  /// Try parsing with Jiffy library for complex date strings
  static ParsedDateTime? _tryJiffyParsing(String input, DateTime now) {
    try {
      // Initialize Jiffy with current time
      final jiffy = Jiffy.parseFromDateTime(now);
      
      // Try some common Jiffy patterns
      final patterns = [
        'MMMM d, yyyy',
        'MMM d, yyyy',
        'MM/dd/yyyy',
        'dd/MM/yyyy',
        'yyyy-MM-dd',
      ];

      for (final pattern in patterns) {
        try {
          final parsed = Jiffy.parse(input, pattern: pattern);
          return ParsedDateTime(
            date: parsed.dateTime,
            time: _extractTime(input),
            confidence: 0.6,
            originalInput: input,
          );
        } catch (e) {
          continue;
        }
      }
    } catch (e) {
      // Jiffy parsing failed
    }
    return null;
  }

  /// Validate and adjust date/time for edge cases
  static DateTime validateAndAdjustDateTime(DateTime dateTime) {
    final now = DateTime.now();
    
    // If the date is in the past and it's a simple date (no time specified),
    // assume next year
    if (dateTime.isBefore(now) && 
        dateTime.hour == 0 && 
        dateTime.minute == 0 && 
        dateTime.second == 0) {
      return DateTime(now.year + 1, dateTime.month, dateTime.day);
    }
    
    return dateTime;
  }

  /// Handle timezone conversion
  static DateTime convertToLocalTimeZone(DateTime utcDateTime) {
    return utcDateTime.toLocal();
  }

  /// Handle Daylight Saving Time adjustments
  static DateTime adjustForDST(DateTime dateTime) {
    // Flutter's DateTime automatically handles DST when converting to local time
    return dateTime.toLocal();
  }

  /// Format date for display
  static String formatDateForDisplay(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final yesterday = today.subtract(const Duration(days: 1));
    
    final targetDate = DateTime(date.year, date.month, date.day);
    
    if (targetDate == today) {
      return 'Today';
    } else if (targetDate == tomorrow) {
      return 'Tomorrow';
    } else if (targetDate == yesterday) {
      return 'Yesterday';
    } else if (date.year == now.year) {
      return DateFormat('MMM d').format(date);
    } else {
      return _displayDateFormat.format(date);
    }
  }

  /// Format time for display
  static String formatTimeForDisplay(TimeOfDay time) {
    final dateTime = DateTime(2023, 1, 1, time.hour, time.minute);
    return _displayTimeFormat.format(dateTime);
  }

  /// Format date and time for display
  static String formatDateTimeForDisplay(DateTime dateTime) {
    final dateStr = formatDateForDisplay(dateTime);
    final timeStr = formatTimeForDisplay(TimeOfDay.fromDateTime(dateTime));
    return '$dateStr at $timeStr';
  }

  /// Get week range for a date
  static DateTimeRange getWeekRange(DateTime date) {
    final startOfWeek = date.subtract(Duration(days: date.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    return DateTimeRange(
      start: DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day),
      end: DateTime(endOfWeek.year, endOfWeek.month, endOfWeek.day, 23, 59, 59),
    );
  }

  /// Get month range for a date
  static DateTimeRange getMonthRange(DateTime date) {
    final startOfMonth = DateTime(date.year, date.month, 1);
    final endOfMonth = DateTime(date.year, date.month + 1, 0, 23, 59, 59);
    return DateTimeRange(start: startOfMonth, end: endOfMonth);
  }

  /// Check if two dates are the same day
  static bool isSameDay(DateTime? a, DateTime? b) {
    if (a == null || b == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  /// Check if date is today
  static bool isToday(DateTime date) {
    return isSameDay(date, DateTime.now());
  }

  /// Check if date is in the past
  static bool isPastDay(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final targetDate = DateTime(date.year, date.month, date.day);
    return targetDate.isBefore(today);
  }

  /// Check if date is in the future
  static bool isFutureDay(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final targetDate = DateTime(date.year, date.month, date.day);
    return targetDate.isAfter(today);
  }

  /// Get business days between two dates
  static int getBusinessDaysBetween(DateTime start, DateTime end) {
    int count = 0;
    DateTime current = start;
    
    while (current.isBefore(end) || isSameDay(current, end)) {
      if (current.weekday <= 5) { // Monday = 1, Friday = 5
        count++;
      }
      current = current.add(const Duration(days: 1));
    }
    
    return count;
  }
}

/// Extension methods for Flutter's TimeOfDay
extension TimeOfDayExtensions on TimeOfDay {
  /// Convert TimeOfDay to DateTime using a specific date
  DateTime toDateTime(DateTime date) {
    return DateTime(date.year, date.month, date.day, hour, minute);
  }
}

/// Date time range representation
class DateTimeRange {
  final DateTime start;
  final DateTime end;

  const DateTimeRange({required this.start, required this.end});

  Duration get duration => end.difference(start);
  
  bool contains(DateTime date) {
    return date.isAfter(start) && date.isBefore(end) || 
           DateTimeUtils.isSameDay(date, start) || 
           DateTimeUtils.isSameDay(date, end);
  }
}

/// Parsed date/time result from natural language processing
class ParsedDateTime {
  final DateTime date;
  final TimeOfDay? time;
  final double confidence; // 0.0 to 1.0
  final String originalInput;

  const ParsedDateTime({
    required this.date,
    this.time,
    required this.confidence,
    required this.originalInput,
  });

  /// Get combined DateTime if time is specified
  DateTime? get dateTime {
    if (time == null) return date;
    return time!.toDateTime(date);
  }

  /// Check if this is a high-confidence parse
  bool get isHighConfidence => confidence >= 0.8;

  /// Check if this is a low-confidence parse that needs user confirmation
  bool get needsConfirmation => confidence < 0.6;

  @override
  String toString() {
    final timeStr = time != null ? ' at ${DateTimeUtils.formatTimeForDisplay(time!)}' : '';
    return '${DateTimeUtils.formatDateForDisplay(date)}$timeStr (${(confidence * 100).toInt()}% confidence)';
  }
}