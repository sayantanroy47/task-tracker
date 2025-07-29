import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:jiffy/jiffy.dart';
import '../models/models.dart';
import '../../../shared/models/models.dart';

/// Service for parsing chat messages and extracting tasks
class MessageParserService {
  
  /// Extract tasks from shared message content
  Future<List<ExtractedTask>> parseMessageContent(SharedContent content) async {
    final tasks = <ExtractedTask>[];
    
    // Clean and preprocess message text
    final cleanText = _preprocessMessage(content.text);
    
    // Apply multiple parsing strategies with enhanced patterns
    tasks.addAll(await _parseDirectRequests(cleanText, content));
    tasks.addAll(await _parseScheduledItems(cleanText, content));
    tasks.addAll(await _parseShoppingLists(cleanText, content));
    tasks.addAll(await _parseAppointments(cleanText, content));
    tasks.addAll(await _parseReminders(cleanText, content));
    tasks.addAll(await _parseDeadlines(cleanText, content));
    tasks.addAll(await _parseActionItems(cleanText, content));
    tasks.addAll(await _parseHouseholdTasks(cleanText, content));
    
    // Score and rank extracted tasks with enhanced scoring
    return _scoreAndRankTasks(tasks, content);
  }
  
  /// Clean and preprocess message text
  String _preprocessMessage(String text) {
    // Remove extra whitespace and normalize
    text = text.trim().replaceAll(RegExp(r'\s+'), ' ');
    
    // Remove common chat artifacts
    text = text.replaceAll(RegExp(r'^\w+:\s*'), ''); // Remove "Name: " prefix
    text = text.replaceAll(RegExp(r'\[.*?\]'), ''); // Remove [timestamp] or [attachments]
    
    return text;
  }
  
  /// Parse direct requests and commands
  Future<List<ExtractedTask>> _parseDirectRequests(String text, SharedContent content) async {
    final tasks = <ExtractedTask>[];
    final requestPatterns = [
      r"(can you|could you|please|would you mind)\s+(.+?)(?:[.!?]|$)",
      r"(remember to|make sure to|you need to|don't forget to)\s+(.+?)(?:[.!?]|$)",
      r"(pick up|buy|get|grab|stop by)\s+(.+?)(?:[.!?]|$)",
    ];
    
    for (final pattern in requestPatterns) {
      final regex = RegExp(pattern, caseSensitive: false);
      final matches = regex.allMatches(text);
      
      for (final match in matches) {
        final fullMatch = match.group(0)!;
        final actionPart = match.group(2)!.trim();
        
        // Parse potential date/time from the action part
        final dateTime = await _extractDateTime(actionPart);
        
        final task = ExtractedTask(
          originalText: fullMatch,
          extractedTitle: _cleanTaskTitle(actionPart),
          extractedDate: dateTime['date'],
          extractedTime: dateTime['time'],
          suggestedCategory: _suggestCategory(actionPart),
          confidence: _calculateConfidence(fullMatch, actionPart),
          source: TaskSource.chat,
          conversationContext: content.conversationContext,
          senderInfo: content.senderInfo,
          keywords: _extractKeywords(actionPart),
          inferredPriority: _inferPriority(fullMatch),
        );
        
        tasks.add(task);
      }
    }
    
    return tasks;
  }
  
  /// Parse scheduled items with dates and times
  Future<List<ExtractedTask>> _parseScheduledItems(String text, SharedContent content) async {
    final tasks = <ExtractedTask>[];
    final scheduledPatterns = [
      r"(we have|there's|appointment|meeting|dinner|lunch)\s+(.+?)\s+(tomorrow|today|next week|this \w+|on \w+|at \d+)(.+?)(?:[.!?]|$)",
      r"(.+?)\s+(tomorrow|today|next week|this \w+|on \w+)\s+(at \d+:\d+)(.+?)(?:[.!?]|$)",
    ];
    
    for (final pattern in scheduledPatterns) {
      final regex = RegExp(pattern, caseSensitive: false);
      final matches = regex.allMatches(text);
      
      for (final match in matches) {
        final fullMatch = match.group(0)!;
        final eventPart = match.group(2)?.trim();
        
        if (eventPart != null && eventPart.isNotEmpty) {
          final dateTime = await _extractDateTime(fullMatch);
          
          final task = ExtractedTask(
            originalText: fullMatch,
            extractedTitle: _cleanTaskTitle(eventPart),
            extractedDate: dateTime['date'],
            extractedTime: dateTime['time'],
            suggestedCategory: _suggestCategory(eventPart),
            confidence: _calculateConfidence(fullMatch, eventPart),
            source: TaskSource.chat,
            conversationContext: content.conversationContext,
            senderInfo: content.senderInfo,
            keywords: _extractKeywords(eventPart),
            inferredPriority: _inferPriority(fullMatch),
          );
          
          tasks.add(task);
        }
      }
    }
    
    return tasks;
  }
  
  /// Parse shopping lists and errands
  Future<List<ExtractedTask>> _parseShoppingLists(String text, SharedContent content) async {
    final tasks = <ExtractedTask>[];
    final shoppingPatterns = [
      r"(we need|buy|get|pick up)\s+(.+?)(?:[.!?]|$)",
      r"(grocery|groceries|shopping)\s+(.+?)(?:[.!?]|$)",
    ];
    
    for (final pattern in shoppingPatterns) {
      final regex = RegExp(pattern, caseSensitive: false);
      final matches = regex.allMatches(text);
      
      for (final match in matches) {
        final fullMatch = match.group(0)!;
        final itemsPart = match.group(2)!.trim();
        
        // Split items by commas or "and"
        final items = itemsPart.split(RegExp(r',|\band\b')).map((e) => e.trim()).where((e) => e.isNotEmpty);
        
        for (final item in items) {
          final dateTime = await _extractDateTime(fullMatch);
          
          final task = ExtractedTask(
            originalText: fullMatch,
            extractedTitle: 'Buy $item',
            extractedDate: dateTime['date'],
            extractedTime: dateTime['time'],
            suggestedCategory: 'household', // Shopping items default to household
            confidence: _calculateConfidence(fullMatch, item),
            source: TaskSource.chat,
            conversationContext: content.conversationContext,
            senderInfo: content.senderInfo,
            keywords: _extractKeywords(item),
            inferredPriority: _inferPriority(fullMatch),
          );
          
          tasks.add(task);
        }
      }
    }
    
    return tasks;
  }
  
  /// Parse appointments and scheduled events
  Future<List<ExtractedTask>> _parseAppointments(String text, SharedContent content) async {
    final tasks = <ExtractedTask>[];
    final appointmentPatterns = [
      r"(doctor|dentist|appointment|meeting)\s+(.+?)(?:[.!?]|$)",
      r"(.+?)\s+(appointment|meeting)\s+(.+?)(?:[.!?]|$)",
    ];
    
    for (final pattern in appointmentPatterns) {
      final regex = RegExp(pattern, caseSensitive: false);
      final matches = regex.allMatches(text);
      
      for (final match in matches) {
        final fullMatch = match.group(0)!;
        final appointmentInfo = match.group(2)?.trim() ?? match.group(1)?.trim() ?? '';
        
        if (appointmentInfo.isNotEmpty) {
          final dateTime = await _extractDateTime(fullMatch);
          
          final task = ExtractedTask(
            originalText: fullMatch,
            extractedTitle: _cleanTaskTitle(appointmentInfo),
            extractedDate: dateTime['date'],
            extractedTime: dateTime['time'],
            suggestedCategory: _suggestCategory(appointmentInfo),
            confidence: _calculateConfidence(fullMatch, appointmentInfo),
            source: TaskSource.chat,
            conversationContext: content.conversationContext,
            senderInfo: content.senderInfo,
            keywords: _extractKeywords(appointmentInfo),
            inferredPriority: _inferPriority(fullMatch),
          );
          
          tasks.add(task);
        }
      }
    }
    
    return tasks;
  }
  
  /// Extract date and time from text
  Future<Map<String, dynamic>> _extractDateTime(String text) async {
    DateTime? date;
    TimeOfDay? time;
    
    final now = DateTime.now();
    final lowerText = text.toLowerCase();
    
    // Parse relative dates
    if (lowerText.contains('today')) {
      date = now;
    } else if (lowerText.contains('tomorrow')) {
      date = now.add(const Duration(days: 1));
    } else if (lowerText.contains('next week')) {
      date = now.add(const Duration(days: 7));
    }
    
    // Parse day names (this friday, next monday, etc.)
    final dayPattern = RegExp(r'(this|next)?\s*(monday|tuesday|wednesday|thursday|friday|saturday|sunday)', caseSensitive: false);
    final dayMatch = dayPattern.firstMatch(lowerText);
    if (dayMatch != null) {
      final dayName = dayMatch.group(2)!.toLowerCase();
      final isNext = dayMatch.group(1)?.toLowerCase() == 'next';
      date = _getNextWeekday(now, dayName, isNext);
    }
    
    // Parse specific dates (12/25, Dec 25, etc.)
    final datePatterns = [
      RegExp(r'(\d{1,2})/(\d{1,2})'), // MM/DD format
      RegExp(r'(\d{1,2})/(\d{1,2})/(\d{2,4})'), // MM/DD/YY or MM/DD/YYYY format
    ];
    
    for (final pattern in datePatterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        try {
          int month = int.parse(match.group(1)!);
          int day = int.parse(match.group(2)!);
          int year = match.group(3) != null ? int.parse(match.group(3)!) : now.year;
          
          if (year < 100) year += 2000; // Handle 2-digit years
          
          date = DateTime(year, month, day);
        } catch (e) {
          // Invalid date format, continue
        }
      }
    }
    
    // Parse time
    final timePattern = RegExp(r'(\d{1,2}):?(\d{2})?\s*(am|pm)?', caseSensitive: false);
    final timeMatch = timePattern.firstMatch(lowerText);
    if (timeMatch != null) {
      try {
        int hour = int.parse(timeMatch.group(1)!);
        int minute = timeMatch.group(2) != null ? int.parse(timeMatch.group(2)!) : 0;
        final period = timeMatch.group(3)?.toLowerCase();
        
        if (period == 'pm' && hour != 12) hour += 12;
        if (period == 'am' && hour == 12) hour = 0;
        
        time = TimeOfDay(hour: hour, minute: minute);
      } catch (e) {
        // Invalid time format, continue
      }
    }
    
    // Parse common time expressions
    if (lowerText.contains('noon')) {
      time = const TimeOfDay(hour: 12, minute: 0);
    } else if (lowerText.contains('morning')) {
      time = const TimeOfDay(hour: 9, minute: 0);
    } else if (lowerText.contains('evening')) {
      time = const TimeOfDay(hour: 18, minute: 0);
    } else if (lowerText.contains('night')) {
      time = const TimeOfDay(hour: 20, minute: 0);
    }
    
    return {'date': date, 'time': time};
  }
  
  /// Get next occurrence of a weekday
  DateTime _getNextWeekday(DateTime from, String dayName, bool isNext) {
    final weekdays = {
      'monday': 1,
      'tuesday': 2,
      'wednesday': 3,
      'thursday': 4,
      'friday': 5,
      'saturday': 6,
      'sunday': 7,
    };
    
    final targetDay = weekdays[dayName]!;
    final currentDay = from.weekday;
    
    int daysToAdd;
    if (isNext) {
      daysToAdd = 7 + (targetDay - currentDay);
    } else {
      daysToAdd = targetDay - currentDay;
      if (daysToAdd <= 0) daysToAdd += 7;
    }
    
    return from.add(Duration(days: daysToAdd));
  }
  
  /// Clean and format task title
  String _cleanTaskTitle(String title) {
    // Remove common prefixes and clean up
    title = title.replaceAll(RegExp(r'^(to\s+)', caseSensitive: false), '');
    title = title.replaceAll(RegExp(r'\s+(today|tomorrow|next week|this \w+).*$', caseSensitive: false), '');
    title = title.trim();
    
    // Capitalize first letter
    if (title.isNotEmpty) {
      title = title[0].toUpperCase() + title.substring(1);
    }
    
    return title;
  }
  
  /// Suggest category based on content
  String? _suggestCategory(String content) {
    final categoryKeywords = {
      'household': ['grocery', 'groceries', 'cleaning', 'dishes', 'laundry', 'home', 'buy', 'shop'],
      'health': ['doctor', 'dentist', 'pharmacy', 'medication', 'exercise', 'gym', 'appointment'],
      'work': ['meeting', 'presentation', 'deadline', 'project', 'client', 'office', 'work'],
      'family': ['kids', 'school', 'parent', 'family', 'birthday', 'anniversary', 'dinner'],
      'finance': ['bill', 'payment', 'bank', 'insurance', 'tax', 'money', 'pay'],
      'personal': ['haircut', 'friend', 'hobby', 'lunch', 'coffee'],
    };
    
    final lowerContent = content.toLowerCase();
    
    for (final entry in categoryKeywords.entries) {
      for (final keyword in entry.value) {
        if (lowerContent.contains(keyword)) {
          return entry.key;
        }
      }
    }
    
    return null; // Default category will be assigned later
  }
  
  /// Extract relevant keywords from text
  List<String> _extractKeywords(String text) {
    final keywords = <String>[];
    final words = text.toLowerCase().split(' ');
    
    final importantWords = [
      'urgent', 'important', 'asap', 'today', 'tomorrow', 'deadline',
      'remember', 'don\'t forget', 'make sure', 'grocery', 'meeting',
      'appointment', 'doctor', 'dentist', 'work', 'family',
    ];
    
    for (final word in words) {
      if (importantWords.contains(word) && !keywords.contains(word)) {
        keywords.add(word);
      }
    }
    
    return keywords;
  }
  
  /// Infer priority from text
  TaskPriority _inferPriority(String text) {
    final urgentKeywords = ['urgent', 'asap', 'immediately', 'now', 'critical'];
    final highKeywords = ['important', 'soon', 'today', 'deadline'];
    final lowerText = text.toLowerCase();
    
    if (urgentKeywords.any((keyword) => lowerText.contains(keyword))) {
      return TaskPriority.urgent;
    } else if (highKeywords.any((keyword) => lowerText.contains(keyword))) {
      return TaskPriority.high;
    }
    
    return TaskPriority.medium;
  }
  
  /// Calculate confidence score for extracted task
  double _calculateConfidence(String originalText, String extractedPart) {
    double confidence = 0.5; // Base confidence
    
    final lowerOriginal = originalText.toLowerCase();
    final lowerExtracted = extractedPart.toLowerCase();
    
    // Boost confidence for clear task indicators
    if (_hasActionVerb(lowerOriginal)) confidence += 0.2;
    if (_hasTimeReference(lowerOriginal)) confidence += 0.2;
    if (_hasRequestKeywords(lowerOriginal)) confidence += 0.3;
    
    // Reduce confidence for uncertain patterns
    if (extractedPart.split(' ').length < 2) confidence -= 0.3;
    if (extractedPart.length < 5) confidence -= 0.2;
    
    return confidence.clamp(0.0, 1.0);
  }
  
  bool _hasActionVerb(String text) {
    final actionVerbs = ['pick up', 'buy', 'get', 'grab', 'remember', 'don\'t forget', 'make sure'];
    return actionVerbs.any((verb) => text.contains(verb));
  }
  
  bool _hasTimeReference(String text) {
    final timeWords = ['today', 'tomorrow', 'next', 'this', 'at', 'by', 'before'];
    return timeWords.any((word) => text.contains(word));
  }
  
  bool _hasRequestKeywords(String text) {
    final requestKeywords = ['please', 'can you', 'could you', 'would you'];
    return requestKeywords.any((keyword) => text.contains(keyword));
  }
  
  /// Score and rank extracted tasks
  List<ExtractedTask> _scoreAndRankTasks(List<ExtractedTask> tasks, SharedContent content) {
    // Remove duplicates based on similar titles
    final uniqueTasks = <ExtractedTask>[];
    
    for (final task in tasks) {
      final isDuplicate = uniqueTasks.any((existing) => 
        _areSimilar(existing.extractedTitle, task.extractedTitle));
      
      if (!isDuplicate) {
        uniqueTasks.add(task);
      }
    }
    
    // Sort by confidence score (highest first)
    uniqueTasks.sort((a, b) => b.confidence.compareTo(a.confidence));
    
    return uniqueTasks;
  }
  
  /// Parse reminder-specific patterns
  Future<List<ExtractedTask>> _parseReminders(String text, SharedContent content) async {
    final tasks = <ExtractedTask>[];
    final reminderPatterns = [
      r"(remind me|reminder)\s+(to\s+)?(.+?)(?:[.!?]|$)",
      r"(don't let me forget|make sure I)\s+(.+?)(?:[.!?]|$)", 
      r"(I need to remember|remember that I need)\s+(to\s+)?(.+?)(?:[.!?]|$)",
      r"(note to self|mental note)\s*:?\s*(.+?)(?:[.!?]|$)",
    ];
    
    for (final pattern in reminderPatterns) {
      final regex = RegExp(pattern, caseSensitive: false);
      final matches = regex.allMatches(text);
      
      for (final match in matches) {
        final fullMatch = match.group(0)!;
        String actionPart;
        
        // Extract the action part depending on the pattern
        if (match.groupCount >= 3 && match.group(3) != null) {
          actionPart = match.group(3)!.trim();
        } else if (match.groupCount >= 2 && match.group(2) != null) {
          actionPart = match.group(2)!.trim();
        } else {
          continue;
        }
        
        final dateTime = await _extractDateTime(actionPart);
        
        final task = ExtractedTask(
          originalText: fullMatch,
          extractedTitle: _cleanTaskTitle(actionPart),
          extractedDate: dateTime['date'],
          extractedTime: dateTime['time'],
          suggestedCategory: _suggestCategory(actionPart),
          confidence: _calculateConfidence(fullMatch, actionPart) + 0.1, // Boost for explicit reminders
          source: TaskSource.chat,
          conversationContext: content.conversationContext,
          senderInfo: content.senderInfo,
          keywords: _extractKeywords(actionPart),
          inferredPriority: _inferPriority(fullMatch),
        );
        
        tasks.add(task);
      }
    }
    
    return tasks;
  }
  
  /// Parse deadline-specific patterns
  Future<List<ExtractedTask>> _parseDeadlines(String text, SharedContent content) async {
    final tasks = <ExtractedTask>[];
    final deadlinePatterns = [
      r"(.+?)\s+(is due|due by|deadline is|must be done by)\s+(.+?)(?:[.!?]|$)",
      r"(deadline for|due date for)\s+(.+?)\s+(is|:)\s*(.+?)(?:[.!?]|$)",
      r"(.+?)\s+needs to be (done|completed|finished)\s+(by|before)\s+(.+?)(?:[.!?]|$)",
    ];
    
    for (final pattern in deadlinePatterns) {
      final regex = RegExp(pattern, caseSensitive: false);
      final matches = regex.allMatches(text);
      
      for (final match in matches) {
        final fullMatch = match.group(0)!;
        String taskPart;
        String datePart;
        
        // Extract task and date parts based on pattern structure
        if (pattern.contains('deadline for')) {
          taskPart = match.group(2)!.trim();
          datePart = match.group(4)!.trim();
        } else if (pattern.contains('needs to be')) {
          taskPart = match.group(1)!.trim();
          datePart = match.group(4)!.trim();
        } else {
          taskPart = match.group(1)!.trim();
          datePart = match.group(3)!.trim();
        }
        
        final dateTime = await _extractDateTime(datePart);
        
        final task = ExtractedTask(
          originalText: fullMatch,
          extractedTitle: _cleanTaskTitle(taskPart),
          extractedDate: dateTime['date'],
          extractedTime: dateTime['time'],
          suggestedCategory: _suggestCategory(taskPart),
          confidence: _calculateConfidence(fullMatch, taskPart) + 0.15, // Higher boost for deadlines
          source: TaskSource.chat,
          conversationContext: content.conversationContext,
          senderInfo: content.senderInfo,
          keywords: _extractKeywords(taskPart),
          inferredPriority: TaskPriority.high, // Deadlines are typically high priority
        );
        
        tasks.add(task);
      }
    }
    
    return tasks;
  }
  
  /// Parse general action items
  Future<List<ExtractedTask>> _parseActionItems(String text, SharedContent content) async {
    final tasks = <ExtractedTask>[];
    final actionPatterns = [
      r"(action item|to do|todo)\s*:?\s*(.+?)(?:[.!?]|$)",
      r"(we should|let's|let us)\s+(.+?)(?:[.!?]|$)",
      r"(it would be good to|we ought to)\s+(.+?)(?:[.!?]|$)",
      r"(\d+\.|[-•*])\s*(.+?)(?:\n|$)", // Numbered or bulleted lists
    ];
    
    for (final pattern in actionPatterns) {
      final regex = RegExp(pattern, caseSensitive: false);
      final matches = regex.allMatches(text);
      
      for (final match in matches) {
        final fullMatch = match.group(0)!;
        final actionPart = match.group(2)!.trim();
        
        // Skip very short or generic items
        if (actionPart.length < 3 || _isGenericText(actionPart)) continue;
        
        final dateTime = await _extractDateTime(actionPart);
        
        final task = ExtractedTask(
          originalText: fullMatch,
          extractedTitle: _cleanTaskTitle(actionPart),
          extractedDate: dateTime['date'],
          extractedTime: dateTime['time'],
          suggestedCategory: _suggestCategory(actionPart),
          confidence: _calculateConfidence(fullMatch, actionPart),
          source: TaskSource.chat,
          conversationContext: content.conversationContext,
          senderInfo: content.senderInfo,
          keywords: _extractKeywords(actionPart),
          inferredPriority: _inferPriority(fullMatch),
        );
        
        tasks.add(task);
      }
    }
    
    return tasks;
  }
  
  /// Parse household-specific tasks
  Future<List<ExtractedTask>> _parseHouseholdTasks(String text, SharedContent content) async {
    final tasks = <ExtractedTask>[];
    final householdPatterns = [
      r"(need to clean|cleaning|tidy up|organize)\s+(.+?)(?:[.!?]|$)",
      r"(the\s+)?(kitchen|bathroom|bedroom|living room|garage)\s+(needs|requires)\s+(.+?)(?:[.!?]|$)",
      r"(fix|repair|maintain)\s+(the\s+)?(.+?)(?:[.!?]|$)",
      r"(change|replace)\s+(the\s+)?(.+?)\s+(filter|bulb|battery)(?:[.!?]|$)",
      r"(water|feed|walk)\s+(the\s+)?(.+?)(?:[.!?]|$)",
    ];
    
    for (final pattern in householdPatterns) {
      final regex = RegExp(pattern, caseSensitive: false);
      final matches = regex.allMatches(text);
      
      for (final match in matches) {
        final fullMatch = match.group(0)!;
        String taskPart;
        
        // Extract the relevant task part based on pattern
        if (pattern.contains('needs|requires')) {
          final room = match.group(2) ?? '';
          final action = match.group(4) ?? '';
          taskPart = '$action $room'.trim();
        } else if (pattern.contains('change|replace')) {
          final item = match.group(3) ?? '';
          final type = match.group(4) ?? '';
          taskPart = 'Change $item $type'.trim();
        } else {
          taskPart = match.group(match.groupCount)!.trim();
        }
        
        if (taskPart.isEmpty) continue;
        
        final dateTime = await _extractDateTime(fullMatch);
        
        final task = ExtractedTask(
          originalText: fullMatch,
          extractedTitle: _cleanTaskTitle(taskPart),
          extractedDate: dateTime['date'],
          extractedTime: dateTime['time'],
          suggestedCategory: 'household', // All household tasks get this category
          confidence: _calculateConfidence(fullMatch, taskPart) + 0.05, // Small boost for household context
          source: TaskSource.chat,
          conversationContext: content.conversationContext,
          senderInfo: content.senderInfo,
          keywords: _extractKeywords(taskPart),
          inferredPriority: _inferPriority(fullMatch),
        );
        
        tasks.add(task);
      }
    }
    
    return tasks;
  }
  
  /// Check if text is too generic to be a useful task
  bool _isGenericText(String text) {
    final genericPhrases = [
      'ok', 'okay', 'yes', 'no', 'sure', 'thanks', 'thank you',
      'hello', 'hi', 'bye', 'goodbye', 'see you', 'talk later',
      'good', 'great', 'awesome', 'nice', 'cool', 'sounds good',
    ];
    
    final lowerText = text.toLowerCase().trim();
    return genericPhrases.contains(lowerText) || lowerText.length < 3;
  }
  
  /// Enhanced confidence calculation with multiple factors
  double _calculateConfidence(String originalText, String extractedPart) {
    double confidence = 0.3; // Lower base confidence
    
    final lowerOriginal = originalText.toLowerCase();
    final lowerExtracted = extractedPart.toLowerCase();
    
    // Task quality factors
    final wordCount = extractedPart.split(' ').length;
    if (wordCount >= 2 && wordCount <= 8) confidence += 0.2; // Good length
    if (wordCount > 8) confidence -= 0.1; // Too long might be noise
    
    // Action verb presence (strong indicator)
    if (_hasActionVerb(lowerOriginal)) confidence += 0.3;
    
    // Time reference (good indicator)
    if (_hasTimeReference(lowerOriginal)) confidence += 0.2;
    
    // Request keywords (moderate indicator) 
    if (_hasRequestKeywords(lowerOriginal)) confidence += 0.25;
    
    // Specific task indicators
    if (_hasSpecificTaskKeywords(lowerExtracted)) confidence += 0.15;
    
    // Negatives that reduce confidence
    if (_isGenericText(extractedPart)) confidence -= 0.4;
    if (extractedPart.length < 3) confidence -= 0.3;
    if (_hasQuestionIndicators(lowerOriginal)) confidence -= 0.2; // Questions less likely to be tasks
    
    // Context bonuses
    if (_hasUrgencyIndicators(lowerOriginal)) confidence += 0.1;
    if (_hasPersonalPronouns(lowerOriginal)) confidence += 0.05; // "I need to", "you should"
    
    return confidence.clamp(0.0, 1.0);
  }
  
  /// Check for specific task-related keywords
  bool _hasSpecificTaskKeywords(String text) {
    final taskKeywords = [
      'buy', 'get', 'pick up', 'purchase', 'order', 'call', 'email', 'send',
      'schedule', 'book', 'reserve', 'cancel', 'confirm', 'pay', 'deposit',
      'clean', 'wash', 'organize', 'pack', 'prepare', 'finish', 'complete',
      'submit', 'deliver', 'return', 'exchange', 'repair', 'fix'
    ];
    return taskKeywords.any((keyword) => text.contains(keyword));
  }
  
  /// Check for question indicators that reduce task likelihood
  bool _hasQuestionIndicators(String text) {
    return text.contains('?') || 
           text.startsWith('what') || 
           text.startsWith('where') ||
           text.startsWith('when') ||
           text.startsWith('why') ||
           text.startsWith('how') ||
           text.contains('do you') ||
           text.contains('can you') ||
           text.contains('will you');
  }
  
  /// Check for urgency indicators
  bool _hasUrgencyIndicators(String text) {
    final urgencyWords = ['urgent', 'asap', 'immediately', 'now', 'today', 'soon', 'quickly'];
    return urgencyWords.any((word) => text.contains(word));
  }
  
  /// Check for personal pronouns that indicate task assignment
  bool _hasPersonalPronouns(String text) {
    final pronouns = ['i need', 'i have to', 'i must', 'you need', 'you should', 'we need', 'we should'];
    return pronouns.any((pronoun) => text.contains(pronoun));
  }

  /// Check if two task titles are similar
  bool _areSimilar(String title1, String title2) {
    final words1 = title1.toLowerCase().split(' ');
    final words2 = title2.toLowerCase().split(' ');
    
    // Calculate simple word overlap
    final commonWords = words1.where((word) => words2.contains(word)).length;
    final totalWords = (words1.length + words2.length) / 2;
    
    return commonWords / totalWords > 0.7; // 70% similarity threshold
  }
}