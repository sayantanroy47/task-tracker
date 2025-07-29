import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/voice_service.dart';
import '../../../shared/models/task.dart';
import '../../../shared/models/category.dart';
import '../../../shared/providers/app_providers.dart';
import '../../tasks/providers/task_providers.dart';
import '../providers/calendar_providers.dart';
import '../utils/date_time_utils.dart';

/// Voice-Calendar Integration Service
/// Handles the seamless integration between voice input and calendar display
/// When someone says "tomorrow at 3 PM", it should appear on calendar immediately
class VoiceCalendarIntegration {
  final Ref _ref;

  VoiceCalendarIntegration(this._ref);

  /// Process voice input and create task with calendar integration
  /// This is the main method called when voice input is processed
  Future<VoiceTaskCreationResult> processVoiceInputForCalendar({
    required String voiceText,
    String? suggestedCategoryId,
    double confidenceThreshold = 0.6,
  }) async {
    try {
      // Parse natural language for date/time information
      final parsedDateTime = DateTimeUtils.parseNaturalLanguage(voiceText);
      
      if (parsedDateTime == null) {
        return VoiceTaskCreationResult.failed(
          'Could not understand the date/time from: "$voiceText"',
          originalText: voiceText,
        );
      }

      // Check confidence level
      if (parsedDateTime.confidence < confidenceThreshold) {
        return VoiceTaskCreationResult.needsConfirmation(
          parsedDateTime: parsedDateTime,
          suggestedTask: _createTaskFromParsedData(voiceText, parsedDateTime, suggestedCategoryId),
          originalText: voiceText,
        );
      }

      // Create task with high confidence
      final task = await _createAndSaveTask(voiceText, parsedDateTime, suggestedCategoryId);
      
      // Update calendar to show the new task immediately
      await _updateCalendarWithNewTask(task);
      
      return VoiceTaskCreationResult.success(
        task: task,
        parsedDateTime: parsedDateTime,
        originalText: voiceText,
      );

    } catch (e) {
      return VoiceTaskCreationResult.failed(
        'Error processing voice input: $e',
        originalText: voiceText,
      );
    }
  }

  /// Create task from parsed voice data
  Task _createTaskFromParsedData(
    String voiceText,
    ParsedDateTime parsedDateTime,
    String? suggestedCategoryId,
  ) {
    // Extract task title from voice text (remove date/time parts)
    final taskTitle = _extractTaskTitle(voiceText);
    
    // Use suggested category or default to 'personal'
    final categoryId = suggestedCategoryId ?? 'personal';
    
    return Task.create(
      title: taskTitle,
      categoryId: categoryId,
      dueDate: parsedDateTime.date,
      dueTime: parsedDateTime.time,
      source: TaskSource.voice,
      hasReminder: true, // Default to having reminders for voice tasks
      reminderIntervals: [ReminderInterval.oneHour], // Default reminder
    );
  }

  /// Create and save task to database
  Future<Task> _createAndSaveTask(
    String voiceText,
    ParsedDateTime parsedDateTime,
    String? suggestedCategoryId,
  ) async {
    final task = _createTaskFromParsedData(voiceText, parsedDateTime, suggestedCategoryId);
    
    final taskOps = _ref.read(taskOperationsProvider);
    return await taskOps.createTask(
      title: task.title,
      description: task.description,
      categoryId: task.categoryId,
      dueDate: task.dueDate,
      dueTime: task.dueTime,
      priority: task.priority,
      source: TaskSource.voice,
    );
  }

  /// Update calendar to immediately show the new task
  Future<void> _updateCalendarWithNewTask(Task task) async {
    // Update calendar state to include the new task
    final calendarNotifier = _ref.read(calendarStateProvider.notifier);
    calendarNotifier.addTaskToCalendar(task);
    
    // If the task is for today or selected date, ensure it's visible
    if (task.dueDate != null) {
      final selectedDate = _ref.read(calendarStateProvider).selectedDate;
      if (DateTimeUtils.isSameDay(task.dueDate!, selectedDate)) {
        // Task is for currently selected date - it will be automatically visible
      } else {
        // Optionally navigate to the task's date
        calendarNotifier.selectDate(task.dueDate!);
        calendarNotifier.updateFocusedDay(task.dueDate!);
      }
    }
  }

  /// Extract task title from voice text by removing date/time expressions
  String _extractTaskTitle(String voiceText) {
    String title = voiceText;
    
    // Remove common date/time expressions
    final dateTimePatterns = [
      // Time patterns
      RegExp(r'\s+(at\s+)?\d{1,2}(:\d{2})?\s*(am|pm)', caseSensitive: false),
      RegExp(r'\s+at\s+\d{1,2}', caseSensitive: false),
      
      // Date patterns
      RegExp(r'\s+(today|tomorrow|yesterday)', caseSensitive: false),
      RegExp(r'\s+(monday|tuesday|wednesday|thursday|friday|saturday|sunday)', caseSensitive: false),
      RegExp(r'\s+(next|this)\s+(week|month)', caseSensitive: false),
      RegExp(r'\s+in\s+\d+\s+(days?|hours?|minutes?)', caseSensitive: false),
      RegExp(r'\s+(january|february|march|april|may|june|july|august|september|october|november|december)\s+\d{1,2}', caseSensitive: false),
      RegExp(r'\s+\d{1,2}[\/\-]\d{1,2}([\/\-]\d{2,4})?', caseSensitive: false),
      
      // Time indicators
      RegExp(r'\s+(morning|afternoon|evening|night|noon|midnight)', caseSensitive: false),
    ];
    
    for (final pattern in dateTimePatterns) {
      title = title.replaceAll(pattern, ' ');
    }
    
    // Clean up multiple spaces and trim
    title = title.replaceAll(RegExp(r'\s+'), ' ').trim();
    
    // If title is empty or too short, use original
    if (title.isEmpty || title.length < 3) {
      title = voiceText.trim();
    }
    
    // Capitalize first letter
    if (title.isNotEmpty) {
      title = title[0].toUpperCase() + title.substring(1);
    }
    
    return title;
  }

  /// Suggest category based on task content
  Future<String?> suggestCategoryForTask(String taskText) async {
    // Simple keyword-based category suggestion
    final lowerText = taskText.toLowerCase();
    
    // Work-related keywords
    if (_containsAny(lowerText, ['meeting', 'call', 'project', 'deadline', 'presentation', 'email', 'report'])) {
      return 'work';
    }
    
    // Health-related keywords
    if (_containsAny(lowerText, ['doctor', 'appointment', 'medicine', 'exercise', 'gym', 'health', 'dentist'])) {
      return 'health';
    }
    
    // Household keywords
    if (_containsAny(lowerText, ['clean', 'laundry', 'dishes', 'vacuum', 'repair', 'fix', 'maintenance'])) {
      return 'household';
    }
    
    // Family keywords
    if (_containsAny(lowerText, ['kids', 'children', 'school', 'pickup', 'family', 'birthday', 'anniversary'])) {
      return 'family';
    }
    
    // Finance keywords
    if (_containsAny(lowerText, ['pay', 'bill', 'bank', 'money', 'budget', 'tax', 'insurance'])) {
      return 'finance';
    }
    
    // Default to personal
    return 'personal';
  }

  /// Helper method to check if text contains any of the keywords
  bool _containsAny(String text, List<String> keywords) {
    return keywords.any((keyword) => text.contains(keyword));
  }

  /// Confirm and create task from voice input with user verification
  Future<Task> confirmAndCreateTask({
    required ParsedDateTime parsedDateTime,
    required Task suggestedTask,
    String? userModifiedTitle,
    String? userSelectedCategoryId,
    DateTime? userModifiedDate,
    TimeOfDay? userModifiedTime,
  }) async {
    // Use user modifications or fall back to suggested values
    final finalTitle = userModifiedTitle ?? suggestedTask.title;
    final finalCategoryId = userSelectedCategoryId ?? suggestedTask.categoryId;
    final finalDate = userModifiedDate ?? parsedDateTime.date;
    final finalTime = userModifiedTime ?? parsedDateTime.time;
    
    // Create the final task
    final taskOps = _ref.read(taskOperationsProvider);
    final task = await taskOps.createTask(
      title: finalTitle,
      description: suggestedTask.description,
      categoryId: finalCategoryId,
      dueDate: finalDate,
      dueTime: finalTime,
      priority: suggestedTask.priority,
      source: TaskSource.voice,
    );
    
    // Update calendar
    await _updateCalendarWithNewTask(task);
    
    return task;
  }

  /// Cancel voice task creation
  void cancelVoiceTaskCreation() {
    // No action needed - just dismiss any UI
  }
}

/// Result of voice task creation process
sealed class VoiceTaskCreationResult {
  const VoiceTaskCreationResult();

  factory VoiceTaskCreationResult.success({
    required Task task,
    required ParsedDateTime parsedDateTime,
    required String originalText,
  }) = VoiceTaskCreationSuccess;

  factory VoiceTaskCreationResult.needsConfirmation({
    required ParsedDateTime parsedDateTime,
    required Task suggestedTask,
    required String originalText,
  }) = VoiceTaskCreationNeedsConfirmation;

  factory VoiceTaskCreationResult.failed(
    String error, {
    required String originalText,
  }) = VoiceTaskCreationFailed;
}

class VoiceTaskCreationSuccess extends VoiceTaskCreationResult {
  final Task task;
  final ParsedDateTime parsedDateTime;
  final String originalText;

  const VoiceTaskCreationSuccess({
    required this.task,
    required this.parsedDateTime,
    required this.originalText,
  });
}

class VoiceTaskCreationNeedsConfirmation extends VoiceTaskCreationResult {
  final ParsedDateTime parsedDateTime;
  final Task suggestedTask;
  final String originalText;

  const VoiceTaskCreationNeedsConfirmation({
    required this.parsedDateTime,
    required this.suggestedTask,
    required this.originalText,
  });
}

class VoiceTaskCreationFailed extends VoiceTaskCreationResult {
  final String error;
  final String originalText;

  const VoiceTaskCreationFailed(this.error, {required this.originalText});
}

/// Provider for voice-calendar integration service
final voiceCalendarIntegrationProvider = Provider<VoiceCalendarIntegration>((ref) {
  return VoiceCalendarIntegration(ref);
});

/// Provider for voice task creation state management
final voiceTaskCreationStateProvider = StateNotifierProvider<VoiceTaskCreationNotifier, VoiceTaskCreationState>((ref) {
  return VoiceTaskCreationNotifier(ref);
});

/// State for voice task creation process
class VoiceTaskCreationState {
  final bool isProcessing;
  final VoiceTaskCreationResult? result;
  final String? currentVoiceText;

  const VoiceTaskCreationState({
    this.isProcessing = false,
    this.result,
    this.currentVoiceText,
  });

  VoiceTaskCreationState copyWith({
    bool? isProcessing,
    VoiceTaskCreationResult? result,
    String? currentVoiceText,
  }) {
    return VoiceTaskCreationState(
      isProcessing: isProcessing ?? this.isProcessing,
      result: result ?? this.result,
      currentVoiceText: currentVoiceText ?? this.currentVoiceText,
    );
  }
}

/// Notifier for managing voice task creation state
class VoiceTaskCreationNotifier extends StateNotifier<VoiceTaskCreationState> {
  final Ref _ref;

  VoiceTaskCreationNotifier(this._ref) : super(const VoiceTaskCreationState());

  /// Process voice input for task creation
  Future<void> processVoiceInput(String voiceText) async {
    state = state.copyWith(
      isProcessing: true,
      currentVoiceText: voiceText,
      result: null,
    );

    try {
      final integration = _ref.read(voiceCalendarIntegrationProvider);
      
      // Suggest category based on content
      final suggestedCategory = await integration.suggestCategoryForTask(voiceText);
      
      // Process the voice input
      final result = await integration.processVoiceInputForCalendar(
        voiceText: voiceText,
        suggestedCategoryId: suggestedCategory,
      );

      state = state.copyWith(
        isProcessing: false,
        result: result,
      );
    } catch (e) {
      state = state.copyWith(
        isProcessing: false,
        result: VoiceTaskCreationResult.failed(
          'Error processing voice input: $e',
          originalText: voiceText,
        ),
      );
    }
  }

  /// Confirm task creation with user modifications
  Future<void> confirmTaskCreation({
    required ParsedDateTime parsedDateTime,
    required Task suggestedTask,
    String? userModifiedTitle,
    String? userSelectedCategoryId,
    DateTime? userModifiedDate,
    TimeOfDay? userModifiedTime,
  }) async {
    state = state.copyWith(isProcessing: true);

    try {
      final integration = _ref.read(voiceCalendarIntegrationProvider);
      
      final task = await integration.confirmAndCreateTask(
        parsedDateTime: parsedDateTime,
        suggestedTask: suggestedTask,
        userModifiedTitle: userModifiedTitle,
        userSelectedCategoryId: userSelectedCategoryId,
        userModifiedDate: userModifiedDate,
        userModifiedTime: userModifiedTime,
      );

      state = state.copyWith(
        isProcessing: false,
        result: VoiceTaskCreationResult.success(
          task: task,
          parsedDateTime: parsedDateTime,
          originalText: state.currentVoiceText ?? '',
        ),
      );
    } catch (e) {
      state = state.copyWith(
        isProcessing: false,
        result: VoiceTaskCreationResult.failed(
          'Error confirming task: $e',
          originalText: state.currentVoiceText ?? '',
        ),
      );
    }
  }

  /// Cancel task creation
  void cancelTaskCreation() {
    final integration = _ref.read(voiceCalendarIntegrationProvider);
    integration.cancelVoiceTaskCreation();
    
    state = const VoiceTaskCreationState();
  }

  /// Clear current state
  void clearState() {
    state = const VoiceTaskCreationState();
  }
}