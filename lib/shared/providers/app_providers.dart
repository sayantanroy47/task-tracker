import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/core.dart';
import '../../core/services/flutter_notification_service.dart';
import '../../core/services/task_notification_manager.dart';
import '../../core/services/voice_service_impl.dart';
import '../../core/services/intent_handler_provider.dart';
import '../../core/services/notification_preferences_service.dart';
import '../../features/chat/services/chat_integration_service.dart';

/// Core service providers that form the foundation of dependency injection
/// These providers are used throughout the app for service access

/// Database service provider - singleton instance
final databaseServiceProvider = Provider<DatabaseService>((ref) {
  return DatabaseService();
});

/// Notification preferences service provider
final notificationPreferencesServiceProvider = Provider<NotificationPreferencesService>((ref) {
  final databaseService = ref.read(databaseServiceProvider);
  return NotificationPreferencesService(databaseService);
});

/// Notification service provider - singleton instance
final notificationServiceProvider = Provider<NotificationService>((ref) {
  final service = FlutterNotificationService();
  final preferencesService = ref.read(notificationPreferencesServiceProvider);
  service.setPreferencesService(preferencesService);
  return service;
});

/// Voice service provider - singleton instance
final voiceServiceProvider = Provider<VoiceService>((ref) {
  return VoiceServiceImpl();
});

/// Task notification manager provider - depends on notification and task services
final taskNotificationManagerProvider = Provider<TaskNotificationManager>((ref) {
  final notificationService = ref.read(notificationServiceProvider);
  final taskRepository = ref.read(taskRepositoryProvider);
  final notificationRepository = ref.read(notificationRepositoryProvider);
  
  return TaskNotificationManager(
    notificationService: notificationService,
    taskRepository: taskRepository,
    notificationRepository: notificationRepository,
  );
});

/// Global navigator key provider for navigation outside of widget context
final navigatorKeyProvider = Provider<GlobalKey<NavigatorState>>((ref) {
  return GlobalKey<NavigatorState>();
});

/// Repository providers that depend on services

/// Task repository provider - depends on database service
final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  final databaseService = ref.read(databaseServiceProvider);
  return TaskRepositoryImpl(databaseService);
});

/// Category repository provider - depends on database service
final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  final databaseService = ref.read(databaseServiceProvider);
  return CategoryRepositoryImpl(databaseService);
});

/// Notification repository provider - depends on database service
final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  final databaseService = ref.read(databaseServiceProvider);
  return NotificationRepositoryImpl(databaseService);
});

/// All categories provider - provides list of all categories
final allCategoriesProvider = FutureProvider<List<Category>>((ref) async {
  final categoryRepository = ref.read(categoryRepositoryProvider);
  return await categoryRepository.getAllCategories();
});

/// All tasks provider - provides list of all tasks
final tasksProvider = FutureProvider<List<Task>>((ref) async {
  final taskRepository = ref.read(taskRepositoryProvider);
  return await taskRepository.getAllTasks();
});

/// App initialization provider that handles startup tasks
final appInitializationProvider = FutureProvider<void>((ref) async {
  // Initialize database service first
  final databaseService = ref.read(databaseServiceProvider);
  
  // Database initialization happens automatically when first accessed
  // through the singleton pattern in DatabaseService
  await databaseService.database;
  
  // Initialize notification preferences service
  final notificationPreferencesService = ref.read(notificationPreferencesServiceProvider);
  await notificationPreferencesService.initialize();
  
  // Initialize notification service
  final notificationService = ref.read(notificationServiceProvider);
  await notificationService.initialize();
  
  // Initialize voice service
  final voiceService = ref.read(voiceServiceProvider);
  await voiceService.initialize();
  
  // Initialize chat integration service
  final chatIntegrationService = ref.read(chatIntegrationServiceProvider);
  await chatIntegrationService.initialize();
  
  // Initialize notification manager and set up action handlers
  final notificationManager = ref.read(taskNotificationManagerProvider);
  notificationManager.initializeActionHandlers();
  
  // Verify default categories exist (they are inserted on first database creation)
  final categoryRepository = ref.read(categoryRepositoryProvider);
  final categories = await categoryRepository.getAllCategories();
  
  if (categories.isEmpty) {
    throw Exception('Failed to initialize default categories');
  }
});

/// App state provider for global app state management
final appStateProvider = StateNotifierProvider<AppStateNotifier, AppState>((ref) {
  return AppStateNotifier(ref);
});

/// App state notifier for managing global application state
class AppStateNotifier extends StateNotifier<AppState> {
  final Ref _ref;
  
  AppStateNotifier(this._ref) : super(const AppState.loading());
  
  /// Initialize the app and handle startup flow
  Future<void> initialize() async {
    try {
      state = const AppState.loading();
      
      // Wait for app initialization to complete
      await _ref.read(appInitializationProvider.future);
      
      // Check initial permission status
      final notificationService = _ref.read(notificationServiceProvider);
      final hasNotificationPermissions = await notificationService.hasPermissions();
      
      final voiceService = _ref.read(voiceServiceProvider);
      final hasVoicePermissions = await voiceService.hasPermissions();
      
      state = AppState.ready(
        hasNotificationPermissions: hasNotificationPermissions,
        hasVoicePermissions: hasVoicePermissions,
      );
    } catch (error) {
      state = AppState.error(error.toString());
    }
  }
  
  /// Request notification permissions
  Future<void> requestNotificationPermissions() async {
    try {
      final notificationService = _ref.read(notificationServiceProvider);
      final granted = await notificationService.requestPermissions();
      
      if (state is AppStateReady) {
        final currentState = state as AppStateReady;
        state = currentState.copyWith(hasNotificationPermissions: granted);
      }
    } catch (error) {
      // Keep current state if permission request fails
    }
  }
  
  /// Request voice permissions
  Future<void> requestVoicePermissions() async {
    try {
      final voiceService = _ref.read(voiceServiceProvider);
      final granted = await voiceService.requestPermissions();
      
      if (state is AppStateReady) {
        final currentState = state as AppStateReady;
        state = currentState.copyWith(hasVoicePermissions: granted);
      }
    } catch (error) {
      // Keep current state if permission request fails
    }
  }
}

/// App state sealed class for type-safe state management
sealed class AppState {
  const AppState();
  
  const factory AppState.loading() = AppStateLoading;
  const factory AppState.ready({
    required bool hasNotificationPermissions,
    required bool hasVoicePermissions,
  }) = AppStateReady;
  const factory AppState.error(String message) = AppStateError;
}

class AppStateLoading extends AppState {
  const AppStateLoading();
}

class AppStateReady extends AppState {
  final bool hasNotificationPermissions;
  final bool hasVoicePermissions;
  
  const AppStateReady({
    required this.hasNotificationPermissions,
    required this.hasVoicePermissions,
  });
  
  AppStateReady copyWith({
    bool? hasNotificationPermissions,
    bool? hasVoicePermissions,
  }) {
    return AppStateReady(
      hasNotificationPermissions: hasNotificationPermissions ?? this.hasNotificationPermissions,
      hasVoicePermissions: hasVoicePermissions ?? this.hasVoicePermissions,
    );
  }
}

class AppStateError extends AppState {
  final String message;
  
  const AppStateError(this.message);
}