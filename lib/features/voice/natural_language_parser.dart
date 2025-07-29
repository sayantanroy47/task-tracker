import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:jiffy/jiffy.dart';
import 'voice_state.dart';

/// Natural language parser for extracting task information from voice input
class NaturalLanguageParser {
  // Date patterns for natural language recognition with enhanced patterns
  static final List<DatePattern> _datePatterns = [
    // Relative dates - basic
    DatePattern(r'\btomorrow\b', _calculateTomorrow, 0.9),
    DatePattern(r'\btoday\b', _calculateToday, 0.95),
    DatePattern(r'\btonite?\b|\btonight\b', _calculateTonight, 0.85),
    DatePattern(r'\byesterday\b', _calculateYesterday, 0.9),
    
    // Enhanced relative dates
    DatePattern(r'\bthe day after tomorrow\b', _calculateDayAfterTomorrow, 0.9),
    DatePattern(r'\bin (\d+) days?\b', _calculateInDays, 0.85),
    DatePattern(r'\b(\d+) days? from now\b', _calculateInDays, 0.85),
    DatePattern(r'\ba week from (today|now)\b', _calculateInOneWeek, 0.8),
    DatePattern(r'\btwo weeks? from (today|now)\b', _calculateInTwoWeeks, 0.8),
    
    // This week days with better patterns
    DatePattern(r'\bthis\s+(monday|tuesday|wednesday|thursday|friday|saturday|sunday)\b', _calculateThisWeekday, 0.85),
    DatePattern(r'\bnext\s+(monday|tuesday|wednesday|thursday|friday|saturday|sunday)\b', _calculateNextWeekday, 0.85),
    DatePattern(r'\b(monday|tuesday|wednesday|thursday|friday|saturday|sunday)\s+this\s+week\b', _calculateThisWeekday, 0.8),
    DatePattern(r'\b(monday|tuesday|wednesday|thursday|friday|saturday|sunday)\s+next\s+week\b', _calculateNextWeekday, 0.8),
    
    // End of period patterns
    DatePattern(r'\bend of (this )?(week|month|year)\b', _calculateEndOfPeriod, 0.75),
    DatePattern(r'\bby the end of (this )?(week|month|year)\b', _calculateEndOfPeriod, 0.75),
    DatePattern(r'\bbeginning of next (week|month|year)\b', _calculateBeginningOfNext, 0.75),
    
    // Relative time periods
    DatePattern(r'\bin\s+(\d+)\s+(days?|weeks?|months?)\b', _calculateInPeriod, 0.8),
    DatePattern(r'\bnext\s+(week|month|year)\b', _calculateNextPeriod, 0.8),
    DatePattern(r'\bthis\s+(week|month|year)\b', _calculateThisPeriod, 0.8),
    
    // Specific dates with better confidence
    DatePattern(r'\b(january|february|march|april|may|june|july|august|september|october|november|december)\s+(\d{1,2})(?:st|nd|rd|th)?\b', _calculateMonthDay, 0.9),
    DatePattern(r'\b(\d{1,2})[\/\-](\d{1,2})[\/\-](\d{2,4})\b', _calculateDateSlash, 0.85),
    DatePattern(r'\b(\d{1,2})(?:st|nd|rd|th)\s+of\s+(january|february|march|april|may|june|july|august|september|october|november|december)\b', _calculateDayOfMonth, 0.9),
    
    // Season/holiday patterns (lower confidence)
    DatePattern(r'\b(next|this)\s+(spring|summer|fall|autumn|winter)\b', _calculateSeason, 0.4),
    DatePattern(r'\bbefore\s+(christmas|thanksgiving|new year)\b', _calculateBeforeHoliday, 0.5),
  ];
  
  // Time patterns for natural language recognition with enhanced patterns
  static final List<TimePattern> _timePatterns = [
    // 12-hour format with confidence scores
    TimePattern(r'\b(\d{1,2}):?(\d{2})?\s*(am|pm)\b', _calculateTwelveHour, 0.9),
    TimePattern(r'\b(\d{1,2})\s*o\'?clock\s*(am|pm)?\b', _calculateOclock, 0.85),
    
    // Half hour and quarter hour patterns
    TimePattern(r'\bhalf past\s+(\d{1,2})\s*(am|pm)?\b', _calculateHalfPast, 0.8),
    TimePattern(r'\bquarter past\s+(\d{1,2})\s*(am|pm)?\b', _calculateQuarterPast, 0.8),
    TimePattern(r'\bquarter to\s+(\d{1,2})\s*(am|pm)?\b', _calculateQuarterTo, 0.8),
    TimePattern(r'\b(\d{1,2})\s*thirty\s*(am|pm)?\b', _calculateThirty, 0.75),
    TimePattern(r'\b(\d{1,2})\s*fifteen\s*(am|pm)?\b', _calculateFifteen, 0.75),
    TimePattern(r'\b(\d{1,2})\s*forty[\s\-]?five\s*(am|pm)?\b', _calculateFortyFive, 0.75),
    
    // Enhanced common time expressions
    TimePattern(r'\bnoon\b|\bmidday\b', _calculateNoon, 0.95),
    TimePattern(r'\bmidnight\b', _calculateMidnight, 0.95),
    TimePattern(r'\bin the morning\b|\bmorning\b', _calculateMorning, 0.6),
    TimePattern(r'\bin the afternoon\b|\bafternoon\b', _calculateAfternoon, 0.6),
    TimePattern(r'\bin the evening\b|\bevening\b', _calculateEvening, 0.6),
    TimePattern(r'\bat night\b|\bnight\b', _calculateNight, 0.6),
    
    // Early/late modifiers
    TimePattern(r'\bearly morning\b', _calculateEarlyMorning, 0.7),
    TimePattern(r'\blate morning\b', _calculateLateMorning, 0.7),
    TimePattern(r'\bearly afternoon\b', _calculateEarlyAfternoon, 0.7),
    TimePattern(r'\blate afternoon\b', _calculateLateAfternoon, 0.7),
    TimePattern(r'\bearly evening\b', _calculateEarlyEvening, 0.7),
    TimePattern(r'\blate evening\b', _calculateLateEvening, 0.7),
    
    // 24-hour format
    TimePattern(r'\b(\d{1,2}):(\d{2})\b', _calculateTwentyFourHour, 0.85),
    
    // Approximate times
    TimePattern(r'\baround\s+(\d{1,2})\s*(am|pm)?\b', _calculateApproximate, 0.7),
    TimePattern(r'\babout\s+(\d{1,2})\s*(am|pm)?\b', _calculateApproximate, 0.7),
  ];
  
  // Enhanced category patterns with confidence scores
  static final Map<String, CategoryPattern> _categoryKeywords = {
    'personal': CategoryPattern([
      'personal', 'myself', 'me', 'self', 'own', 'private', 'individual',
      'read', 'book', 'hobby', 'learn', 'study', 'relax', 'rest'
    ], 1.0),
    'household': CategoryPattern([
      'household', 'home', 'house', 'clean', 'tidy', 'organize', 'cook', 
      'kitchen', 'laundry', 'dishes', 'vacuum', 'garbage', 'trash', 
      'groceries', 'shopping', 'buy', 'store', 'repair', 'fix', 'maintain',
      'wash', 'sweep', 'mop', 'dust', 'declutter', 'garden', 'yard'
    ], 0.9),
    'work': CategoryPattern([
      'work', 'office', 'job', 'meeting', 'deadline', 'project', 'email', 
      'call', 'presentation', 'report', 'task', 'business', 'colleague', 
      'boss', 'client', 'conference', 'interview', 'submit', 'complete',
      'review', 'schedule', 'plan', 'prepare', 'send', 'finish'
    ], 0.95),
    'family': CategoryPattern([
      'family', 'mom', 'dad', 'mother', 'father', 'parent', 'child', 
      'kids', 'children', 'spouse', 'wife', 'husband', 'sibling', 
      'brother', 'sister', 'grandparent', 'visit', 'birthday', 'anniversary'
    ], 0.9),
    'health': CategoryPattern([
      'health', 'doctor', 'medical', 'appointment', 'medicine', 'pill', 
      'pharmacy', 'exercise', 'gym', 'workout', 'dentist', 'hospital', 
      'checkup', 'therapy', 'physical', 'mental', 'wellness', 'diet',
      'nutrition', 'vitamins', 'prescription', 'surgery', 'specialist'
    ], 0.95),
    'finance': CategoryPattern([
      'finance', 'money', 'pay', 'bill', 'bank', 'budget', 'expense', 
      'income', 'tax', 'investment', 'loan', 'credit', 'debt', 'saving', 
      'account', 'transfer', 'deposit', 'withdraw', 'insurance', 'mortgage',
      'rent', 'utilities', 'subscription', 'purchase', 'payment'
    ], 0.95),
  };
  
  // Priority keywords with confidence scores
  static final Map<String, PriorityPattern> _priorityKeywords = {
    'urgent': PriorityPattern('urgent', ['urgent', 'asap', 'immediately', 'critical', 'emergency'], 0.9),
    'high': PriorityPattern('high', ['important', 'priority', 'crucial', 'vital', 'essential', 'must'], 0.8),
    'medium': PriorityPattern('medium', ['normal', 'regular', 'standard', 'moderate'], 0.7),
    'low': PriorityPattern('low', ['low', 'minor', 'optional', 'when possible', 'eventually'], 0.8),
  };
  
  /// Parse voice input and extract task information with enhanced processing
  Future<ParsedVoiceInput> parseVoiceInput(String text) async {
    final normalizedText = text.toLowerCase().trim();
    
    // Extract task title by removing date/time information
    final taskTitle = _extractTaskTitle(normalizedText);
    
    // Parse date from the text with confidence
    final dateResult = _parseDateWithConfidence(normalizedText);
    
    // Parse time from the text with confidence
    final timeResult = _parseTimeWithConfidence(normalizedText);
    
    // Suggest category with confidence
    final categoryResult = _suggestCategoryWithConfidence(normalizedText);
    
    // Extract priority from text
    final priorityResult = _extractPriority(normalizedText);
    
    // Extract description for longer inputs
    final description = _extractDescription(text, taskTitle);
    
    // Calculate overall confidence with enhanced scoring
    final confidence = _calculateEnhancedConfidence(
      taskTitle, 
      dateResult, 
      timeResult, 
      categoryResult,
      priorityResult,
      description,
    );
    
    return ParsedVoiceInput(
      originalText: text,
      taskTitle: taskTitle,
      description: description,
      parsedDate: dateResult?.date,
      parsedTime: timeResult?.time,
      suggestedCategory: categoryResult?.category,
      suggestedPriority: priorityResult?.priority,
      confidence: confidence,
      alternatives: _generateAlternatives(text),
      dateConfidence: dateResult?.confidence,
      timeConfidence: timeResult?.confidence,
      categoryConfidence: categoryResult?.confidence,
      priorityConfidence: priorityResult?.confidence,
    );
  }
  
  // Private helper methods
  
  String _extractTaskTitle(String text) {
    // Remove common voice command prefixes
    String cleaned = text
        .replaceFirst(RegExp(r'^(remind me to|remember to|add task to|create task to|i need to|don\'t forget to|make sure to)\s*', caseSensitive: false), '')
        .replaceFirst(RegExp(r'^(remind|remember|add|create|note|task)\s*', caseSensitive: false), '');
    
    // Remove date and time expressions
    for (final pattern in _datePatterns) {
      cleaned = cleaned.replaceAll(RegExp(pattern.pattern, caseSensitive: false), '');
    }
    
    for (final pattern in _timePatterns) {
      cleaned = cleaned.replaceAll(RegExp(pattern.pattern, caseSensitive: false), '');
    }
    
    // Remove common prepositions and connecting words
    cleaned = cleaned
        .replaceAll(RegExp(r'\s+(at|on|in|by|before|after|during|for)\s+', caseSensitive: false), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    
    // Capitalize first letter
    if (cleaned.isNotEmpty) {
      cleaned = cleaned[0].toUpperCase() + cleaned.substring(1);
    }
    
    return cleaned.isNotEmpty ? cleaned : text;
  }
  
  DateTime? _parseDate(String text) {
    for (final pattern in _datePatterns) {
      final match = RegExp(pattern.pattern, caseSensitive: false).firstMatch(text);
      if (match != null) {
        try {
          return pattern.calculator(match);
        } catch (e) {
          continue; // Try next pattern
        }
      }
    }
    return null;
  }
  
  TimeOfDay? _parseTime(String text) {
    for (final pattern in _timePatterns) {
      final match = RegExp(pattern.pattern, caseSensitive: false).firstMatch(text);
      if (match != null) {
        try {
          return pattern.calculator(match);
        } catch (e) {
          continue; // Try next pattern
        }
      }
    }
    return null;
  }
  
  // Enhanced parsing methods with confidence scores
  
  DateResult? _parseDateWithConfidence(String text) {
    for (final pattern in _datePatterns) {
      final match = RegExp(pattern.pattern, caseSensitive: false).firstMatch(text);
      if (match != null) {
        try {
          final date = pattern.calculator(match);
          return DateResult(date, pattern.confidence);
        } catch (e) {
          continue; // Try next pattern
        }
      }
    }
    return null;
  }
  
  TimeResult? _parseTimeWithConfidence(String text) {
    for (final pattern in _timePatterns) {
      final match = RegExp(pattern.pattern, caseSensitive: false).firstMatch(text);
      if (match != null) {
        try {
          final time = pattern.calculator(match);
          return TimeResult(time, pattern.confidence);
        } catch (e) {
          continue; // Try next pattern
        }
      }
    }
    return null;
  }
  
  CategoryResult? _suggestCategoryWithConfidence(String text) {
    final words = text.toLowerCase().split(RegExp(r'\s+'));
    
    double bestScore = 0.0;
    String? bestCategory;
    
    for (final entry in _categoryKeywords.entries) {
      final categoryName = entry.key;
      final pattern = entry.value;
      
      int matchCount = 0;
      for (final word in words) {
        for (final keyword in pattern.keywords) {
          if (word.contains(keyword) || keyword.contains(word)) {
            matchCount++;
            break; // Only count each word once per category
          }
        }
      }
      
      if (matchCount > 0) {
        // Calculate score based on match count and pattern confidence
        final score = (matchCount / pattern.keywords.length) * pattern.confidence;
        if (score > bestScore) {
          bestScore = score;
          bestCategory = categoryName;
        }
      }
    }
    
    return bestCategory != null 
        ? CategoryResult(bestCategory, bestScore) 
        : null;
  }
  
  PriorityResult? _extractPriority(String text) {
    final words = text.toLowerCase().split(RegExp(r'\s+'));
    final fullText = text.toLowerCase();
    
    for (final entry in _priorityKeywords.entries) {
      final priorityLevel = entry.key;
      final pattern = entry.value;
      
      for (final keyword in pattern.keywords) {
        if (fullText.contains(keyword)) {
          return PriorityResult(priorityLevel, pattern.confidence);
        }
      }
    }
    
    return null; // Default to no priority suggestion
  }
  
  String? _extractDescription(String originalText, String taskTitle) {
    // For longer inputs, try to extract additional description
    if (originalText.length < 50) return null;
    
    final normalized = originalText.toLowerCase();
    final titleLower = taskTitle.toLowerCase();
    
    // Remove command prefixes
    String cleaned = normalized
        .replaceFirst(RegExp(r'^(remind me to|remember to|add task to|create task to|i need to|don\'t forget to|make sure to)\s*', caseSensitive: false), '')
        .replaceFirst(RegExp(r'^(remind|remember|add|create|note|task)\s*', caseSensitive: false), '');
    
    // Find the task title in the cleaned text
    final titleIndex = cleaned.indexOf(titleLower);
    if (titleIndex == -1) return null;
    
    // Extract text after the title that's not date/time info
    String remaining = cleaned.substring(titleIndex + titleLower.length).trim();
    
    // Remove date and time expressions
    for (final pattern in _datePatterns) {
      remaining = remaining.replaceAll(RegExp(pattern.pattern, caseSensitive: false), '');
    }
    for (final pattern in _timePatterns) {
      remaining = remaining.replaceAll(RegExp(pattern.pattern, caseSensitive: false), '');
    }
    
    // Remove common prepositions and clean up
    remaining = remaining
        .replaceAll(RegExp(r'\s+(at|on|in|by|before|after|during|for)\s+', caseSensitive: false), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    
    // Return description if it's meaningful
    return remaining.length > 5 ? remaining : null;
  }
  
  double _calculateEnhancedConfidence(
    String taskTitle,
    DateResult? dateResult,
    TimeResult? timeResult,
    CategoryResult? categoryResult,
    PriorityResult? priorityResult,
    String? description,
  ) {
    double confidence = 0.3; // Base confidence
    
    // Task title quality (40% weight)
    if (taskTitle.length > 3 && taskTitle.split(' ').length > 1) {
      confidence += 0.25;
    }
    if (taskTitle.length > 10) {
      confidence += 0.15;
    }
    
    // Date parsing confidence (25% weight)
    if (dateResult != null) {
      confidence += 0.25 * dateResult.confidence;
    }
    
    // Time parsing confidence (15% weight)
    if (timeResult != null) {
      confidence += 0.15 * timeResult.confidence;
    }
    
    // Category detection confidence (10% weight)
    if (categoryResult != null) {
      confidence += 0.1 * categoryResult.confidence;
    }
    
    // Priority detection confidence (5% weight)
    if (priorityResult != null) {
      confidence += 0.05 * priorityResult.confidence;
    }
    
    // Description bonus (5% weight)
    if (description != null && description.length > 5) {
      confidence += 0.05;
    }
    
    return confidence.clamp(0.0, 1.0);
  }
  
  String? _suggestCategory(String text) {
    final words = text.toLowerCase().split(' ');
    
    for (final category in _categoryKeywords.keys) {
      final keywords = _categoryKeywords[category]!;
      
      for (final keyword in keywords) {
        if (words.any((word) => word.contains(keyword) || keyword.contains(word))) {
          return category;
        }
      }
    }
    
    return null; // Default to no suggestion, will use 'Personal' in controller
  }
  
  double _calculateConfidence(String taskTitle, DateTime? date, TimeOfDay? time, String? category) {
    double confidence = 0.5; // Base confidence
    
    // Higher confidence for meaningful task titles
    if (taskTitle.length > 3 && taskTitle.split(' ').length > 1) {
      confidence += 0.2;
    }
    
    // Higher confidence if date was parsed
    if (date != null) {
      confidence += 0.2;
    }
    
    // Higher confidence if time was parsed
    if (time != null) {
      confidence += 0.1;
    }
    
    // Higher confidence if category was detected
    if (category != null) {
      confidence += 0.1;
    }
    
    return confidence.clamp(0.0, 1.0);
  }
  
  List<String> _generateAlternatives(String text) {
    // For now, return empty list. Could implement alternative interpretations later
    return [];
  }
  
  // Static calculator methods for date patterns
  
  static DateTime _calculateTomorrow(RegExpMatch match) {
    return DateTime.now().add(const Duration(days: 1));
  }
  
  static DateTime _calculateDayAfterTomorrow(RegExpMatch match) {
    return DateTime.now().add(const Duration(days: 2));
  }
  
  static DateTime _calculateInDays(RegExpMatch match) {
    final days = int.parse(match.group(1)!);
    return DateTime.now().add(Duration(days: days));
  }
  
  static DateTime _calculateInOneWeek(RegExpMatch match) {
    return DateTime.now().add(const Duration(days: 7));
  }
  
  static DateTime _calculateInTwoWeeks(RegExpMatch match) {
    return DateTime.now().add(const Duration(days: 14));
  }
  
  static DateTime _calculateEndOfPeriod(RegExpMatch match) {
    final period = match.group(2)?.toLowerCase() ?? match.group(1)?.toLowerCase();
    final now = DateTime.now();
    
    switch (period) {
      case 'week':
        // End of this week (Sunday)
        final daysUntilSunday = 7 - now.weekday;
        return now.add(Duration(days: daysUntilSunday));
      case 'month':
        // Last day of this month
        return DateTime(now.year, now.month + 1, 0);
      case 'year':
        // Last day of this year
        return DateTime(now.year, 12, 31);
      default:
        return now.add(const Duration(days: 7));
    }
  }
  
  static DateTime _calculateBeginningOfNext(RegExpMatch match) {
    final period = match.group(1)!.toLowerCase();
    final now = DateTime.now();
    
    switch (period) {
      case 'week':
        // Next Monday
        final daysUntilNextMonday = 8 - now.weekday;
        return now.add(Duration(days: daysUntilNextMonday));
      case 'month':
        // First day of next month
        return DateTime(now.year, now.month + 1, 1);
      case 'year':
        // First day of next year
        return DateTime(now.year + 1, 1, 1);
      default:
        return now.add(const Duration(days: 7));
    }
  }
  
  static DateTime _calculateSeason(RegExpMatch match) {
    final when = match.group(1)!.toLowerCase(); // next or this
    final season = match.group(2)!.toLowerCase();
    final now = DateTime.now();
    int year = now.year;
    
    if (when == 'next') year++;
    
    // Approximate season start dates
    switch (season) {
      case 'spring':
        return DateTime(year, 3, 20); // March 20
      case 'summer':
        return DateTime(year, 6, 21); // June 21
      case 'fall':
      case 'autumn':
        return DateTime(year, 9, 22); // September 22
      case 'winter':
        return DateTime(year, 12, 21); // December 21
      default:
        return now.add(const Duration(days: 90));
    }
  }
  
  static DateTime _calculateBeforeHoliday(RegExpMatch match) {
    final holiday = match.group(1)!.toLowerCase();
    final now = DateTime.now();
    int year = now.year;
    
    DateTime holidayDate;
    switch (holiday) {
      case 'christmas':
        holidayDate = DateTime(year, 12, 25);
        break;
      case 'thanksgiving':
        // Fourth Thursday of November (US)
        holidayDate = DateTime(year, 11, 1);
        final firstDayOfNov = holidayDate.weekday;
        final firstThursday = 4 - firstDayOfNov + 1;
        if (firstThursday <= 0) holidayDate = holidayDate.add(Duration(days: 7 + firstThursday));
        else holidayDate = holidayDate.add(Duration(days: firstThursday - 1));
        holidayDate = holidayDate.add(const Duration(days: 21)); // Fourth Thursday
        break;
      case 'new year':
        if (now.month == 12) {
          holidayDate = DateTime(year + 1, 1, 1);
        } else {
          holidayDate = DateTime(year, 1, 1);
        }
        break;
      default:
        return now.add(const Duration(days: 30));
    }
    
    // If holiday has passed this year, use next year
    if (holidayDate.isBefore(now)) {
      year++;
      switch (holiday) {
        case 'christmas':
          holidayDate = DateTime(year, 12, 25);
          break;
        case 'new year':
          holidayDate = DateTime(year, 1, 1);
          break;
        default:
          holidayDate = DateTime(year, holidayDate.month, holidayDate.day);
      }
    }
    
    // Return a week before the holiday
    return holidayDate.subtract(const Duration(days: 7));
  }
  
  static DateTime _calculateToday(RegExpMatch match) {
    return DateTime.now();
  }
  
  static DateTime _calculateTonight(RegExpMatch match) {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, 20, 0); // 8 PM
  }
  
  static DateTime _calculateYesterday(RegExpMatch match) {
    return DateTime.now().subtract(const Duration(days: 1));
  }
  
  static DateTime _calculateThisWeekday(RegExpMatch match) {
    final dayName = match.group(1)!.toLowerCase();
    final targetDay = _getWeekdayNumber(dayName);
    final now = DateTime.now();
    final currentDay = now.weekday;
    
    int daysToAdd = targetDay - currentDay;
    if (daysToAdd <= 0) {
      daysToAdd += 7; // Next occurrence of this weekday
    }
    
    return now.add(Duration(days: daysToAdd));
  }
  
  static DateTime _calculateNextWeekday(RegExpMatch match) {
    final dayName = match.group(1)!.toLowerCase();
    final targetDay = _getWeekdayNumber(dayName);
    final now = DateTime.now();
    final currentDay = now.weekday;
    
    int daysToAdd = targetDay - currentDay + 7; // Always next week
    
    return now.add(Duration(days: daysToAdd));
  }
  
  static DateTime _calculateInPeriod(RegExpMatch match) {
    final amount = int.parse(match.group(1)!);
    final unit = match.group(2)!.toLowerCase();
    final now = DateTime.now();
    
    switch (unit) {
      case 'day':
      case 'days':
        return now.add(Duration(days: amount));
      case 'week':
      case 'weeks':
        return now.add(Duration(days: amount * 7));
      case 'month':
      case 'months':
        return DateTime(now.year, now.month + amount, now.day);
      default:
        return now.add(Duration(days: amount));
    }
  }
  
  static DateTime _calculateNextPeriod(RegExpMatch match) {
    final unit = match.group(1)!.toLowerCase();
    final now = DateTime.now();
    
    switch (unit) {
      case 'week':
        return now.add(const Duration(days: 7));
      case 'month':
        return DateTime(now.year, now.month + 1, now.day);
      case 'year':
        return DateTime(now.year + 1, now.month, now.day);
      default:
        return now.add(const Duration(days: 7));
    }
  }
  
  static DateTime _calculateThisPeriod(RegExpMatch match) {
    final unit = match.group(1)!.toLowerCase();
    final now = DateTime.now();
    
    switch (unit) {
      case 'week':
        // Start of this week (Monday)
        return now.subtract(Duration(days: now.weekday - 1));
      case 'month':
        // Start of this month
        return DateTime(now.year, now.month, 1);
      case 'year':
        // Start of this year
        return DateTime(now.year, 1, 1);
      default:
        return now;
    }
  }
  
  static DateTime _calculateMonthDay(RegExpMatch match) {
    final monthName = match.group(1)!.toLowerCase();
    final day = int.parse(match.group(2)!);
    final month = _getMonthNumber(monthName);
    final now = DateTime.now();
    
    int year = now.year;
    
    // If the date has passed this year, use next year
    final targetDate = DateTime(year, month, day);
    if (targetDate.isBefore(now)) {
      year++;
    }
    
    return DateTime(year, month, day);
  }
  
  static DateTime _calculateDateSlash(RegExpMatch match) {
    final part1 = int.parse(match.group(1)!);
    final part2 = int.parse(match.group(2)!);
    final part3 = int.parse(match.group(3)!);
    
    // Assume MM/DD/YYYY or DD/MM/YYYY format
    // For simplicity, assume MM/DD/YYYY
    final month = part1;
    final day = part2;
    int year = part3;
    
    if (year < 100) {
      year += 2000; // Convert 2-digit year
    }
    
    return DateTime(year, month, day);
  }
  
  static DateTime _calculateDayOfMonth(RegExpMatch match) {
    final day = int.parse(match.group(1)!);
    final monthName = match.group(2)!.toLowerCase();
    final month = _getMonthNumber(monthName);
    final now = DateTime.now();
    
    int year = now.year;
    
    // If the date has passed this year, use next year
    final targetDate = DateTime(year, month, day);
    if (targetDate.isBefore(now)) {
      year++;
    }
    
    return DateTime(year, month, day);
  }
  
  // Static calculator methods for time patterns
  
  static TimeOfDay _calculateTwelveHour(RegExpMatch match) {
    final hour = int.parse(match.group(1)!);
    final minute = match.group(2) != null ? int.parse(match.group(2)!) : 0;
    final ampm = match.group(3)!.toLowerCase();
    
    int finalHour = hour;
    if (ampm == 'pm' && hour != 12) {
      finalHour += 12;
    } else if (ampm == 'am' && hour == 12) {
      finalHour = 0;
    }
    
    return TimeOfDay(hour: finalHour, minute: minute);
  }
  
  static TimeOfDay _calculateHalfPast(RegExpMatch match) {
    final hour = int.parse(match.group(1)!);
    final ampm = match.group(2)?.toLowerCase();
    
    int finalHour = hour;
    if (ampm == 'pm' && hour != 12) {
      finalHour += 12;
    } else if (ampm == 'am' && hour == 12) {
      finalHour = 0;
    }
    
    return TimeOfDay(hour: finalHour, minute: 30);
  }
  
  static TimeOfDay _calculateQuarterPast(RegExpMatch match) {
    final hour = int.parse(match.group(1)!);
    final ampm = match.group(2)?.toLowerCase();
    
    int finalHour = hour;
    if (ampm == 'pm' && hour != 12) {
      finalHour += 12;
    } else if (ampm == 'am' && hour == 12) {
      finalHour = 0;
    }
    
    return TimeOfDay(hour: finalHour, minute: 15);
  }
  
  static TimeOfDay _calculateQuarterTo(RegExpMatch match) {
    final hour = int.parse(match.group(1)!);
    final ampm = match.group(2)?.toLowerCase();
    
    int finalHour = hour - 1; // Quarter to means 15 minutes before the hour
    if (finalHour < 0) finalHour = 23;
    
    if (ampm == 'pm' && hour != 12) {
      finalHour = (hour - 1) + 12;
    } else if (ampm == 'am' && hour == 12) {
      finalHour = 23; // 11:45 PM
    }
    
    return TimeOfDay(hour: finalHour, minute: 45);
  }
  
  static TimeOfDay _calculateThirty(RegExpMatch match) {
    final hour = int.parse(match.group(1)!);
    final ampm = match.group(2)?.toLowerCase();
    
    int finalHour = hour;
    if (ampm == 'pm' && hour != 12) {
      finalHour += 12;
    } else if (ampm == 'am' && hour == 12) {
      finalHour = 0;
    }
    
    return TimeOfDay(hour: finalHour, minute: 30);
  }
  
  static TimeOfDay _calculateFifteen(RegExpMatch match) {
    final hour = int.parse(match.group(1)!);
    final ampm = match.group(2)?.toLowerCase();
    
    int finalHour = hour;
    if (ampm == 'pm' && hour != 12) {
      finalHour += 12;
    } else if (ampm == 'am' && hour == 12) {
      finalHour = 0;
    }
    
    return TimeOfDay(hour: finalHour, minute: 15);
  }
  
  static TimeOfDay _calculateFortyFive(RegExpMatch match) {
    final hour = int.parse(match.group(1)!);
    final ampm = match.group(2)?.toLowerCase();
    
    int finalHour = hour;
    if (ampm == 'pm' && hour != 12) {
      finalHour += 12;
    } else if (ampm == 'am' && hour == 12) {
      finalHour = 0;
    }
    
    return TimeOfDay(hour: finalHour, minute: 45);
  }
  
  static TimeOfDay _calculateEarlyMorning(RegExpMatch match) {
    return const TimeOfDay(hour: 7, minute: 0); // 7 AM
  }
  
  static TimeOfDay _calculateLateMorning(RegExpMatch match) {
    return const TimeOfDay(hour: 11, minute: 0); // 11 AM
  }
  
  static TimeOfDay _calculateEarlyAfternoon(RegExpMatch match) {
    return const TimeOfDay(hour: 13, minute: 0); // 1 PM
  }
  
  static TimeOfDay _calculateLateAfternoon(RegExpMatch match) {
    return const TimeOfDay(hour: 16, minute: 0); // 4 PM
  }
  
  static TimeOfDay _calculateEarlyEvening(RegExpMatch match) {
    return const TimeOfDay(hour: 17, minute: 0); // 5 PM
  }
  
  static TimeOfDay _calculateLateEvening(RegExpMatch match) {
    return const TimeOfDay(hour: 21, minute: 0); // 9 PM
  }
  
  static TimeOfDay _calculateApproximate(RegExpMatch match) {
    final hour = int.parse(match.group(1)!);
    final ampm = match.group(2)?.toLowerCase();
    
    int finalHour = hour;
    if (ampm == 'pm' && hour != 12) {
      finalHour += 12;
    } else if (ampm == 'am' && hour == 12) {
      finalHour = 0;
    }
    
    return TimeOfDay(hour: finalHour, minute: 0);
  }
  
  static TimeOfDay _calculateOclock(RegExpMatch match) {
    final hour = int.parse(match.group(1)!);
    final ampm = match.group(2)?.toLowerCase();
    
    int finalHour = hour;
    if (ampm == 'pm' && hour != 12) {
      finalHour += 12;
    } else if (ampm == 'am' && hour == 12) {
      finalHour = 0;
    } else if (ampm == null && hour <= 12) {
      // Default to PM for hours 1-12 if no AM/PM specified
      if (hour >= 8 && hour <= 12) {
        // Assume morning hours
      } else {
        finalHour += 12;
      }
    }
    
    return TimeOfDay(hour: finalHour, minute: 0);
  }
  
  static TimeOfDay _calculateNoon(RegExpMatch match) {
    return const TimeOfDay(hour: 12, minute: 0);
  }
  
  static TimeOfDay _calculateMidnight(RegExpMatch match) {
    return const TimeOfDay(hour: 0, minute: 0);
  }
  
  static TimeOfDay _calculateMorning(RegExpMatch match) {
    return const TimeOfDay(hour: 9, minute: 0); // Default to 9 AM
  }
  
  static TimeOfDay _calculateAfternoon(RegExpMatch match) {
    return const TimeOfDay(hour: 14, minute: 0); // Default to 2 PM
  }
  
  static TimeOfDay _calculateEvening(RegExpMatch match) {
    return const TimeOfDay(hour: 18, minute: 0); // Default to 6 PM
  }
  
  static TimeOfDay _calculateNight(RegExpMatch match) {
    return const TimeOfDay(hour: 20, minute: 0); // Default to 8 PM
  }
  
  static TimeOfDay _calculateTwentyFourHour(RegExpMatch match) {
    final hour = int.parse(match.group(1)!);
    final minute = int.parse(match.group(2)!);
    
    return TimeOfDay(hour: hour, minute: minute);
  }
  
  // Helper methods
  
  static int _getWeekdayNumber(String dayName) {
    switch (dayName.toLowerCase()) {
      case 'monday': return 1;
      case 'tuesday': return 2;
      case 'wednesday': return 3;
      case 'thursday': return 4;
      case 'friday': return 5;
      case 'saturday': return 6;
      case 'sunday': return 7;
      default: return 1;
    }
  }
  
  static int _getMonthNumber(String monthName) {
    switch (monthName.toLowerCase()) {
      case 'january': return 1;
      case 'february': return 2;
      case 'march': return 3;
      case 'april': return 4;
      case 'may': return 5;
      case 'june': return 6;
      case 'july': return 7;
      case 'august': return 8;
      case 'september': return 9;
      case 'october': return 10;
      case 'november': return 11;
      case 'december': return 12;
      default: return 1;
    }
  }
}

/// Data class for date parsing patterns with confidence
class DatePattern {
  final String pattern;
  final DateTime Function(RegExpMatch) calculator;
  final double confidence;
  
  const DatePattern(this.pattern, this.calculator, this.confidence);
}

/// Data class for time parsing patterns with confidence
class TimePattern {
  final String pattern;
  final TimeOfDay Function(RegExpMatch) calculator;
  final double confidence;
  
  const TimePattern(this.pattern, this.calculator, this.confidence);
}

/// Category pattern with keywords and confidence
class CategoryPattern {
  final List<String> keywords;
  final double confidence;
  
  const CategoryPattern(this.keywords, this.confidence);
}

/// Priority pattern with keywords and confidence
class PriorityPattern {
  final String priority;
  final List<String> keywords;
  final double confidence;
  
  const PriorityPattern(this.priority, this.keywords, this.confidence);
}

/// Result classes for parsing with confidence
class DateResult {
  final DateTime date;
  final double confidence;
  
  const DateResult(this.date, this.confidence);
}

class TimeResult {
  final TimeOfDay time;
  final double confidence;
  
  const TimeResult(this.time, this.confidence);
}

class CategoryResult {
  final String category;
  final double confidence;
  
  const CategoryResult(this.category, this.confidence);
}

class PriorityResult {
  final String priority;
  final double confidence;
  
  const PriorityResult(this.priority, this.confidence);
}