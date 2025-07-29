import 'package:flutter/material.dart';
import '../../../shared/models/models.dart';

/// Model representing a task extracted from chat message
@immutable
class ExtractedTask {
  final String originalText;
  final String extractedTitle;
  final String? extractedDescription;
  final DateTime? extractedDate;
  final TimeOfDay? extractedTime;
  final String? suggestedCategory;
  final double confidence;
  final TaskSource source;
  final String? conversationContext;
  final String? senderInfo;
  final List<String> keywords;
  final TaskPriority inferredPriority;
  
  const ExtractedTask({
    required this.originalText,
    required this.extractedTitle,
    this.extractedDescription,
    this.extractedDate,
    this.extractedTime,
    this.suggestedCategory,
    required this.confidence,
    required this.source,
    this.conversationContext,
    this.senderInfo,
    this.keywords = const [],
    this.inferredPriority = TaskPriority.medium,
  });
  
  /// Convert to regular task for database storage
  Task toTask({required String categoryId}) {
    // Combine date and time if both are available
    DateTime? combinedDateTime;
    if (extractedDate != null && extractedTime != null) {
      combinedDateTime = DateTime(
        extractedDate!.year,
        extractedDate!.month,
        extractedDate!.day,
        extractedTime!.hour,
        extractedTime!.minute,
      );
    }
    
    return Task.create(
      title: extractedTitle,
      description: extractedDescription,
      categoryId: categoryId,
      dueDate: extractedDate,
      dueTime: combinedDateTime,
      priority: inferredPriority,
      source: source,
      hasReminder: extractedDate != null, // Auto-enable reminder if date is set
      reminderIntervals: extractedDate != null 
          ? [ReminderInterval.oneDay] // Default to 1 day reminder
          : [],
    );
  }
  
  /// Create a copy with updated fields
  ExtractedTask copyWith({
    String? originalText,
    String? extractedTitle,
    String? extractedDescription,
    DateTime? extractedDate,
    TimeOfDay? extractedTime,
    String? suggestedCategory,
    double? confidence,
    TaskSource? source,
    String? conversationContext,
    String? senderInfo,
    List<String>? keywords,
    TaskPriority? inferredPriority,
  }) {
    return ExtractedTask(
      originalText: originalText ?? this.originalText,
      extractedTitle: extractedTitle ?? this.extractedTitle,
      extractedDescription: extractedDescription ?? this.extractedDescription,
      extractedDate: extractedDate ?? this.extractedDate,
      extractedTime: extractedTime ?? this.extractedTime,
      suggestedCategory: suggestedCategory ?? this.suggestedCategory,
      confidence: confidence ?? this.confidence,
      source: source ?? this.source,
      conversationContext: conversationContext ?? this.conversationContext,
      senderInfo: senderInfo ?? this.senderInfo,
      keywords: keywords ?? this.keywords,
      inferredPriority: inferredPriority ?? this.inferredPriority,
    );
  }
  
  /// Check if this task has clear action indicators
  bool get hasActionVerb {
    final actionVerbs = ['pick up', 'buy', 'get', 'grab', 'remember', 'don\'t forget'];
    final lowerText = extractedTitle.toLowerCase();
    return actionVerbs.any((verb) => lowerText.contains(verb));
  }
  
  /// Check if this task has time references
  bool get hasTimeReference {
    return extractedDate != null || extractedTime != null;
  }
  
  /// Check if this task has request keywords
  bool get hasRequestKeywords {
    final requestKeywords = ['please', 'can you', 'could you', 'would you'];
    final lowerText = originalText.toLowerCase();
    return requestKeywords.any((keyword) => lowerText.contains(keyword));
  }
  
  /// Check if this task is ambiguous
  bool get isAmbiguous {
    // Consider task ambiguous if confidence is low or title is very short
    return confidence < 0.6 || extractedTitle.split(' ').length < 2;
  }
  
  /// Check if this task lacks context
  bool get lacksContext {
    return extractedDescription == null && keywords.isEmpty;
  }
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExtractedTask &&
          runtimeType == other.runtimeType &&
          originalText == other.originalText &&
          extractedTitle == other.extractedTitle;
          
  @override
  int get hashCode => Object.hash(originalText, extractedTitle);
  
  @override
  String toString() {
    return 'ExtractedTask{title: $extractedTitle, confidence: $confidence, date: $extractedDate}';
  }
}