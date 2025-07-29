import 'package:flutter/foundation.dart';
import '../../core/services/voice_service.dart';

/// Voice input states for managing the voice recognition lifecycle
@immutable
sealed class VoiceInputState {
  const VoiceInputState();
  
  const factory VoiceInputState.idle() = VoiceInputIdle;
  const factory VoiceInputState.initializing() = VoiceInputInitializing;
  const factory VoiceInputState.listening() = VoiceInputListening;
  const factory VoiceInputState.processing(String partialText) = VoiceInputProcessing;
  const factory VoiceInputState.confirmation(ParsedVoiceInput parsedInput) = VoiceInputConfirmation;
  const factory VoiceInputState.creating() = VoiceInputCreating;
  const factory VoiceInputState.success() = VoiceInputSuccess;
  const factory VoiceInputState.error(String message) = VoiceInputError;
}

/// Voice input is idle - ready to start
class VoiceInputIdle extends VoiceInputState {
  const VoiceInputIdle();
}

/// Voice service is initializing
class VoiceInputInitializing extends VoiceInputState {
  const VoiceInputInitializing();
}

/// Voice input is actively listening
class VoiceInputListening extends VoiceInputState {
  const VoiceInputListening();
}

/// Voice input is processing partial results
class VoiceInputProcessing extends VoiceInputState {
  final String partialText;
  
  const VoiceInputProcessing(this.partialText);
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VoiceInputProcessing &&
          runtimeType == other.runtimeType &&
          partialText == other.partialText;
  
  @override
  int get hashCode => partialText.hashCode;
}

/// Voice input processed, waiting for user confirmation
class VoiceInputConfirmation extends VoiceInputState {
  final ParsedVoiceInput parsedInput;
  
  const VoiceInputConfirmation(this.parsedInput);
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VoiceInputConfirmation &&
          runtimeType == other.runtimeType &&
          parsedInput == other.parsedInput;
  
  @override
  int get hashCode => parsedInput.hashCode;
}

/// Task is being created from voice input
class VoiceInputCreating extends VoiceInputState {
  const VoiceInputCreating();
}

/// Task created successfully
class VoiceInputSuccess extends VoiceInputState {
  const VoiceInputSuccess();
}

/// Voice input failed with error
class VoiceInputError extends VoiceInputState {
  final String message;
  
  const VoiceInputError(this.message);
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VoiceInputError &&
          runtimeType == other.runtimeType &&
          message == other.message;
  
  @override
  int get hashCode => message.hashCode;
}

/// Parsed voice input containing extracted task information
@immutable
class ParsedVoiceInput {
  final String originalText;
  final String taskTitle;
  final String? description;
  final DateTime? parsedDate;
  final TimeOfDay? parsedTime;
  final String? suggestedCategory;
  final String? suggestedPriority;
  final double confidence;
  final List<String> alternatives;
  final double? dateConfidence;
  final double? timeConfidence;
  final double? categoryConfidence;
  final double? priorityConfidence;
  
  const ParsedVoiceInput({
    required this.originalText,
    required this.taskTitle,
    this.description,
    this.parsedDate,
    this.parsedTime,
    this.suggestedCategory,
    this.suggestedPriority,
    required this.confidence,
    this.alternatives = const [],
    this.dateConfidence,
    this.timeConfidence,
    this.categoryConfidence,
    this.priorityConfidence,
  });
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ParsedVoiceInput &&
          runtimeType == other.runtimeType &&
          originalText == other.originalText &&
          taskTitle == other.taskTitle &&
          description == other.description &&
          parsedDate == other.parsedDate &&
          parsedTime == other.parsedTime &&
          suggestedCategory == other.suggestedCategory &&
          suggestedPriority == other.suggestedPriority &&
          confidence == other.confidence &&
          dateConfidence == other.dateConfidence &&
          timeConfidence == other.timeConfidence &&
          categoryConfidence == other.categoryConfidence &&
          priorityConfidence == other.priorityConfidence &&
          listEquals(alternatives, other.alternatives);
  
  @override
  int get hashCode => Object.hash(
        originalText,
        taskTitle,
        description,
        parsedDate,
        parsedTime,
        suggestedCategory,
        suggestedPriority,
        confidence,
        dateConfidence,
        timeConfidence,
        categoryConfidence,
        priorityConfidence,
        alternatives,
      );
  
  /// Create a copy with updated fields
  ParsedVoiceInput copyWith({
    String? originalText,
    String? taskTitle,
    String? description,
    DateTime? parsedDate,
    TimeOfDay? parsedTime,
    String? suggestedCategory,
    String? suggestedPriority,
    double? confidence,
    List<String>? alternatives,
    double? dateConfidence,
    double? timeConfidence,
    double? categoryConfidence,
    double? priorityConfidence,
  }) {
    return ParsedVoiceInput(
      originalText: originalText ?? this.originalText,
      taskTitle: taskTitle ?? this.taskTitle,
      description: description ?? this.description,
      parsedDate: parsedDate ?? this.parsedDate,
      parsedTime: parsedTime ?? this.parsedTime,
      suggestedCategory: suggestedCategory ?? this.suggestedCategory,
      suggestedPriority: suggestedPriority ?? this.suggestedPriority,
      confidence: confidence ?? this.confidence,
      alternatives: alternatives ?? this.alternatives,
      dateConfidence: dateConfidence ?? this.dateConfidence,
      timeConfidence: timeConfidence ?? this.timeConfidence,
      categoryConfidence: categoryConfidence ?? this.categoryConfidence,
      priorityConfidence: priorityConfidence ?? this.priorityConfidence,
    );
  }
  
  @override
  String toString() {
    return 'ParsedVoiceInput(taskTitle: $taskTitle, description: $description, date: $parsedDate, time: $parsedTime, category: $suggestedCategory, priority: $suggestedPriority, confidence: $confidence)';
  }
}