/// Voice input states for the voice recognition system
sealed class VoiceState {
  const VoiceState();
}

/// Initial idle state - ready to start listening
class VoiceStateIdle extends VoiceState {
  const VoiceStateIdle();
}

/// Currently listening for voice input
class VoiceStateListening extends VoiceState {
  final String currentTranscript;
  
  const VoiceStateListening({this.currentTranscript = ''});
}

/// Processing the voice input to create a task
class VoiceStateProcessing extends VoiceState {
  final String transcript;
  
  const VoiceStateProcessing(this.transcript);
}

/// Successfully completed voice input and created task
class VoiceStateCompleted extends VoiceState {
  final String transcript;
  final String taskTitle;
  
  const VoiceStateCompleted({
    required this.transcript,
    required this.taskTitle,
  });
}

/// Error occurred during voice input
class VoiceStateError extends VoiceState {
  final String message;
  final String? transcript;
  
  const VoiceStateError({
    required this.message,
    this.transcript,
  });
}