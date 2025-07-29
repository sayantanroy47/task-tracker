/// Voice service interface for speech recognition and natural language processing
/// Handles speech-to-text conversion and task extraction from voice input
abstract class VoiceService {
  /// Initialize the voice service with platform-specific settings
  Future<void> initialize();
  
  /// Check if speech recognition is available on the device
  Future<bool> isAvailable();
  
  /// Request microphone permissions from the user
  Future<bool> requestPermissions();
  
  /// Check if microphone permissions are granted
  Future<bool> hasPermissions();
  
  /// Start listening for voice input
  Future<void> startListening({
    Function(String)? onResult,
    Function(String)? onPartialResult,
    Function(String)? onError,
    Duration? timeout,
  });
  
  /// Stop listening for voice input
  Future<void> stopListening();
  
  /// Cancel the current listening session
  Future<void> cancel();
  
  /// Check if currently listening
  bool get isListening;
  
  /// Get supported locales for speech recognition
  Future<List<VoiceLocale>> getSupportedLocales();
  
  /// Set the locale for speech recognition
  Future<void> setLocale(String localeId);
  
  /// Process natural language text to extract task information
  Future<VoiceTaskResult> processVoiceInput(String text);
  
  /// Get confidence level of the last recognition
  double? get lastConfidence;
}

/// Represents a supported voice recognition locale
class VoiceLocale {
  final String localeId;
  final String name;
  
  const VoiceLocale({
    required this.localeId,
    required this.name,
  });
}

/// Result of voice task processing with extracted information
class VoiceTaskResult {
  final String taskTitle;
  final String? description;
  final DateTime? dueDate;
  final VoiceTimeOfDay? dueTime;
  final String? category;
  final double confidence;
  final String originalText;
  
  const VoiceTaskResult({
    required this.taskTitle,
    this.description,
    this.dueDate,
    this.dueTime,
    this.category,
    required this.confidence,
    required this.originalText,
  });
}

/// Voice-parsed time representation
class VoiceTimeOfDay {
  final int hour;
  final int minute;
  
  const VoiceTimeOfDay({
    required this.hour,
    required this.minute,
  });
}