import 'package:freezed_annotation/freezed_annotation.dart';
import '../models/models.dart';
import '../../../shared/models/models.dart';

/// State for chat integration feature
abstract class ChatIntegrationState {
  const ChatIntegrationState();
}

/// Idle state - no processing happening
class ChatIntegrationIdle extends ChatIntegrationState {
  const ChatIntegrationIdle();
}

/// Processing shared content
class ChatIntegrationProcessing extends ChatIntegrationState {
  const ChatIntegrationProcessing();
}

/// Tasks extracted successfully
class ChatIntegrationTasksExtracted extends ChatIntegrationState {
  final List<ExtractedTask> extractedTasks;
  final SharedContent originalContent;
  
  const ChatIntegrationTasksExtracted({
    required this.extractedTasks,
    required this.originalContent,
  });
  
  ChatIntegrationTasksExtracted copyWith({
    List<ExtractedTask>? extractedTasks,
    SharedContent? originalContent,
  }) {
    return ChatIntegrationTasksExtracted(
      extractedTasks: extractedTasks ?? this.extractedTasks,
      originalContent: originalContent ?? this.originalContent,
    );
  }
}

/// No tasks found in the content
class ChatIntegrationNoTasksFound extends ChatIntegrationState {
  const ChatIntegrationNoTasksFound();
}

/// Creating tasks from extracted content
class ChatIntegrationCreatingTasks extends ChatIntegrationState {
  const ChatIntegrationCreatingTasks();
}

/// Tasks created successfully
class ChatIntegrationSuccess extends ChatIntegrationState {
  final List<Task> createdTasks;
  
  const ChatIntegrationSuccess({
    required this.createdTasks,
  });
}

/// Error occurred during processing
class ChatIntegrationError extends ChatIntegrationState {
  final String message;
  
  const ChatIntegrationError(this.message);
}