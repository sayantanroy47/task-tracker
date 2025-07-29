import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../services/message_parser_service.dart';
import '../../../shared/models/models.dart';
import '../../../core/repositories/repositories.dart';
import '../../../core/services/services.dart';
import 'chat_integration_state.dart';

/// Provider for message parser service
final messageParserServiceProvider = Provider<MessageParserService>((ref) {
  return MessageParserService();
});

/// Chat integration notifier that manages the state of chat processing
class ChatIntegrationNotifier extends StateNotifier<ChatIntegrationState> {
  ChatIntegrationNotifier({
    required this.messageParser,
    required this.taskRepository,
    required this.categoryRepository,
    required this.notificationService,
  }) : super(const ChatIntegrationIdle());

  final MessageParserService messageParser;
  final TaskRepository taskRepository;
  final CategoryRepository categoryRepository;
  final NotificationService notificationService;

  /// Process shared content from messaging apps
  Future<void> processSharedContent(SharedContent content) async {
    state = const ChatIntegrationProcessing();

    try {
      final extractedTasks = await messageParser.parseMessageContent(content);

      if (extractedTasks.isEmpty) {
        state = const ChatIntegrationNoTasksFound();
        return;
      }

      state = ChatIntegrationTasksExtracted(
        extractedTasks: extractedTasks,
        originalContent: content,
      );
    } catch (error) {
      state = ChatIntegrationError(error.toString());
    }
  }

  /// Confirm and create tasks from extracted content
  Future<void> confirmAndCreateTasks(List<ExtractedTask> tasks) async {
    state = const ChatIntegrationCreatingTasks();

    final createdTasks = <Task>[];
    final categories = await categoryRepository.getAllCategories();

    for (final extractedTask in tasks) {
      try {
        // Find appropriate category ID
        final categoryId = await _getCategoryId(extractedTask.suggestedCategory, categories);
        
        // Convert extracted task to regular task
        final task = extractedTask.toTask(categoryId: categoryId);
        
        // Create task in repository
        final taskId = await taskRepository.createTask(task);
        final createdTask = task.copyWith(id: taskId.toString());
        createdTasks.add(createdTask);

        // Schedule notifications if task has due date
        if (task.dueDate != null && task.hasReminder) {
          await notificationService.scheduleTaskReminders(createdTask);
        }
      } catch (error) {
        // Handle individual task creation errors
        // For now, continue with other tasks
        continue;
      }
    }

    if (createdTasks.isNotEmpty) {
      state = ChatIntegrationSuccess(createdTasks: createdTasks);
    } else {
      state = const ChatIntegrationError('Failed to create any tasks');
    }
  }

  /// Edit extracted task before creation
  void editExtractedTask(int index, ExtractedTask updatedTask) {
    if (state is ChatIntegrationTasksExtracted) {
      final currentState = state as ChatIntegrationTasksExtracted;
      final updatedTasks = List<ExtractedTask>.from(currentState.extractedTasks);
      updatedTasks[index] = updatedTask;

      state = currentState.copyWith(extractedTasks: updatedTasks);
    }
  }

  /// Remove extracted task from the list
  void removeExtractedTask(int index) {
    if (state is ChatIntegrationTasksExtracted) {
      final currentState = state as ChatIntegrationTasksExtracted;
      final updatedTasks = List<ExtractedTask>.from(currentState.extractedTasks);
      updatedTasks.removeAt(index);

      if (updatedTasks.isEmpty) {
        state = const ChatIntegrationNoTasksFound();
      } else {
        state = currentState.copyWith(extractedTasks: updatedTasks);
      }
    }
  }

  /// Reset to idle state
  void reset() {
    state = const ChatIntegrationIdle();
  }

  /// Get category ID, defaulting to 'personal' if not found
  Future<String> _getCategoryId(String? suggestedCategory, List<Category> categories) async {
    if (suggestedCategory != null) {
      final category = categories.firstWhere(
        (cat) => cat.id == suggestedCategory || cat.name.toLowerCase() == suggestedCategory.toLowerCase(),
        orElse: () => categories.firstWhere((cat) => cat.id == 'personal'),
      );
      return category.id;
    }
    
    // Default to personal category
    return 'personal';
  }
}

/// Provider for chat integration notifier
final chatIntegrationProvider = StateNotifierProvider<ChatIntegrationNotifier, ChatIntegrationState>((ref) {
  return ChatIntegrationNotifier(
    messageParser: ref.watch(messageParserServiceProvider),
    taskRepository: ref.watch(taskRepositoryProvider),
    categoryRepository: ref.watch(categoryRepositoryProvider),
    notificationService: ref.watch(notificationServiceProvider),
  );
});