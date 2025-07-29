import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../providers/chat_integration_provider.dart';
import '../widgets/chat_task_review_screen.dart';
import '../../../core/services/intent_handler_service.dart';
import '../../../core/navigation/navigation.dart';

/// Service that coordinates chat integration functionality
class ChatIntegrationService {
  final WidgetRef _ref;
  late final StreamSubscription _sharedContentSubscription;
  
  ChatIntegrationService(this._ref) {
    _setupSharedContentListener();
  }
  
  /// Initialize the chat integration service
  Future<void> initialize() async {
    final intentHandler = IntentHandlerService.instance;
    await intentHandler.initialize();
  }
  
  /// Setup listener for shared content from external apps
  void _setupSharedContentListener() {
    final intentHandler = IntentHandlerService.instance;
    _sharedContentSubscription = intentHandler.sharedContentStream.listen(
      (sharedContent) => _handleSharedContent(sharedContent),
      onError: (error) => debugPrint('Error in shared content stream: $error'),
    );
  }
  
  /// Handle shared content by navigating to review screen
  void _handleSharedContent(SharedContent sharedContent) {
    // Reset chat integration state
    _ref.read(chatIntegrationProvider.notifier).reset();
    
    // Navigate to chat task review screen
    final router = _ref.read(routerProvider);
    
    // For now, we'll handle this with a simple navigation
    // In a real app, you might want to use a proper routing mechanism
    _navigateToReviewScreen(sharedContent);
  }
  
  /// Navigate to the chat task review screen
  void _navigateToReviewScreen(SharedContent sharedContent) {
    final context = _ref.read(navigatorKeyProvider).currentContext;
    if (context != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => ChatTaskReviewScreen(
            sharedContent: sharedContent,
          ),
        ),
      );
    }
  }
  
  /// Process shared text directly (for testing or manual invocation)
  void processSharedText(String text, {String? appName}) {
    final intentHandler = IntentHandlerService.instance;
    intentHandler.handleSharedText(text, appName: appName);
  }
  
  /// Check if chat integration is available on this platform
  Future<bool> isAvailable() async {
    final intentHandler = IntentHandlerService.instance;
    return await intentHandler.isAvailable();
  }
  
  /// Dispose resources
  void dispose() {
    _sharedContentSubscription.cancel();
    IntentHandlerService.instance.dispose();
  }
}

/// Provider for chat integration service
final chatIntegrationServiceProvider = Provider<ChatIntegrationService>((ref) {
  final service = ChatIntegrationService(ref);
  ref.onDispose(() => service.dispose());
  return service;
});

/// Provider for checking if chat integration is available
final chatIntegrationAvailableProvider = FutureProvider<bool>((ref) async {
  final service = ref.watch(chatIntegrationServiceProvider);
  return await service.isAvailable();
});