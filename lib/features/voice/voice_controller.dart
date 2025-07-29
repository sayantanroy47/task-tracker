import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/voice_service.dart';
import '../../core/services/advanced_nlp_service.dart';
import '../../shared/models/models.dart';
import 'voice_state.dart';
import 'natural_language_parser.dart';

/// Controller for managing voice input lifecycle and task creation
class VoiceInputController extends StateNotifier<VoiceInputState> {
  final VoiceService _voiceService;
  final TaskRepository _taskRepository;
  final CategoryRepository _categoryRepository;
  final AdvancedNlpService _advancedNlpService;
  final NaturalLanguageParser _parser = NaturalLanguageParser();
  
  Timer? _successTimer;
  
  VoiceInputController({
    required VoiceService voiceService,
    required TaskRepository taskRepository,
    required CategoryRepository categoryRepository,
    required AdvancedNlpService advancedNlpService,
  })  : _voiceService = voiceService,
        _taskRepository = taskRepository,
        _categoryRepository = categoryRepository,
        _advancedNlpService = advancedNlpService,
        super(const VoiceInputState.idle());
  
  @override
  void dispose() {
    _successTimer?.cancel();
    _voiceService.cancel();
    super.dispose();
  }
  
  /// Start voice input process
  Future<void> startVoiceInput() async {
    try {
      state = const VoiceInputState.initializing();
      
      // Initialize voice service if needed
      await _voiceService.initialize();
      
      // Check availability
      if (!await _voiceService.isAvailable()) {
        state = const VoiceInputState.error('Voice recognition not available on this device');
        return;
      }
      
      // Check permissions
      if (!await _voiceService.hasPermissions()) {
        final granted = await _voiceService.requestPermissions();
        if (!granted) {
          state = const VoiceInputState.error('Microphone permission is required for voice input');
          return;
        }
      }
      
      // Start listening
      state = const VoiceInputState.listening();
      
      await _voiceService.startListening(
        onResult: _handleFinalResult,
        onPartialResult: _handlePartialResult,
        onError: _handleError,
        timeout: const Duration(seconds: 30),
      );
      
    } catch (e) {
      state = VoiceInputState.error('Failed to start voice input: $e');
    }
  }
  
  /// Stop voice input
  Future<void> stopVoiceInput() async {
    try {
      await _voiceService.stopListening();
      if (state is! VoiceInputConfirmation) {
        state = const VoiceInputState.idle();
      }
    } catch (e) {
      state = VoiceInputState.error('Failed to stop voice input: $e');
    }
  }
  
  /// Cancel voice input
  Future<void> cancelVoiceInput() async {
    try {
      await _voiceService.cancel();
      state = const VoiceInputState.idle();
    } catch (e) {
      state = VoiceInputState.error('Failed to cancel voice input: $e');
    }
  }
  
  /// Confirm and create task from parsed voice input
  Future<void> confirmAndCreateTask(ParsedVoiceInput parsedInput) async {
    try {
      state = const VoiceInputState.creating();
      
      // Find category ID by name
      String categoryId = 'personal'; // Default category ID
      if (parsedInput.suggestedCategory != null) {
        try {
          final categories = await _categoryRepository.getAllCategories();
          final matchingCategory = categories.firstWhere(
            (cat) => cat.name.toLowerCase() == parsedInput.suggestedCategory!.toLowerCase(),
            orElse: () => categories.first, // Default to first category
          );
          categoryId = matchingCategory.id;
        } catch (e) {
          // Use default if category lookup fails
        }
      }
      
      // Determine priority from parsed input
      TaskPriority taskPriority = TaskPriority.medium; // Default
      if (parsedInput.suggestedPriority != null) {
        switch (parsedInput.suggestedPriority!.toLowerCase()) {
          case 'urgent':
            taskPriority = TaskPriority.urgent;
            break;
          case 'high':
            taskPriority = TaskPriority.high;
            break;
          case 'low':
            taskPriority = TaskPriority.low;
            break;
          default:
            taskPriority = TaskPriority.medium;
        }
      }

      // Create task from parsed input using the enhanced model
      final task = Task.create(
        title: parsedInput.taskTitle,
        description: parsedInput.description,
        categoryId: categoryId,
        dueDate: parsedInput.parsedDate,
        dueTime: parsedInput.parsedTime,
        priority: taskPriority,
        source: TaskSource.voice,
        hasReminder: parsedInput.parsedDate != null || parsedInput.parsedTime != null,
        reminderIntervals: parsedInput.parsedDate != null || parsedInput.parsedTime != null
            ? [ReminderInterval.oneHour]
            : [],
      );
      
      // Add task through repository
      await _taskRepository.createTask(task);
      
      // Show success state briefly
      state = const VoiceInputState.success();
      
      // Return to idle after a delay
      _successTimer = Timer(const Duration(seconds: 2), () {
        if (mounted) {
          state = const VoiceInputState.idle();
        }
      });
      
    } catch (e) {
      state = VoiceInputState.error('Failed to create task: $e');
    }
  }
  
  /// Retry voice input after error
  Future<void> retry() async {
    state = const VoiceInputState.idle();
    await startVoiceInput();
  }
  
  /// Edit parsed voice input
  void editParsedInput(ParsedVoiceInput updatedInput) {
    if (state is VoiceInputConfirmation) {
      state = VoiceInputState.confirmation(updatedInput);
    }
  }
  
  /// Reset to idle state
  void resetToIdle() {
    _successTimer?.cancel();
    state = const VoiceInputState.idle();
  }
  
  // Private helper methods
  
  void _handlePartialResult(String partialText) {
    if (partialText.trim().isNotEmpty) {
      state = VoiceInputState.processing(partialText);
    }
  }
  
  Future<void> _handleFinalResult(String finalText) async {
    if (finalText.trim().isEmpty) {
      state = const VoiceInputState.error('No speech detected. Please try again.');
      return;
    }
    
    try {
      // Parse the voice input using advanced NLP service (which falls back to basic parser)
      final parsed = await _advancedNlpService.parseVoiceInput(finalText);
      
      // Check confidence threshold
      if (parsed.confidence < 0.3) {
        state = VoiceInputState.error('Speech recognition confidence too low. Please try again.');
        return;
      }
      
      // Show confirmation state
      state = VoiceInputState.confirmation(parsed);
      
    } catch (e) {
      state = VoiceInputState.error('Failed to process voice input: $e');
    }
  }
  
  void _handleError(String error) {
    state = VoiceInputState.error(error);
  }
}