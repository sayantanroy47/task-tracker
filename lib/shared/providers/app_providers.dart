import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/core.dart';

/// Core service providers that form the foundation of dependency injection
/// These providers are used throughout the app for service access

/// Database service provider - singleton instance
final databaseServiceProvider = Provider<DatabaseService>((ref) {
  return DatabaseService();
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

/// App initialization provider that handles startup tasks
final appInitializationProvider = FutureProvider<void>((ref) async {
  // Initialize database service first
  final databaseService = ref.read(databaseServiceProvider);
  
  // Database initialization happens automatically when first accessed
  // through the singleton pattern in DatabaseService
  await databaseService.database;
  
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
      
      // For now, set permissions to false until voice and notification services are implemented
      state = const AppState.ready(
        hasNotificationPermissions: false,
        hasVoicePermissions: false,
      );
    } catch (error) {
      state = AppState.error(error.toString());
    }
  }
  
  /// Request notification permissions (placeholder until NotificationService is implemented)
  Future<void> requestNotificationPermissions() async {
    // TODO: Implement when NotificationService is ready
    if (state is AppStateReady) {
      final currentState = state as AppStateReady;
      state = currentState.copyWith(hasNotificationPermissions: false);
    }
  }
  
  /// Request voice permissions (placeholder until VoiceService is implemented)
  Future<void> requestVoicePermissions() async {
    // TODO: Implement when VoiceService is ready
    if (state is AppStateReady) {
      final currentState = state as AppStateReady;
      state = currentState.copyWith(hasVoicePermissions: false);
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