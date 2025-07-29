import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import '../../features/chat/models/models.dart';

/// Service for handling shared content intents from external apps
class IntentHandlerService {
  static const MethodChannel _channel = MethodChannel('task_tracker/intent_handler');
  
  static IntentHandlerService? _instance;
  static IntentHandlerService get instance => _instance ??= IntentHandlerService._();
  
  IntentHandlerService._() {
    _setupMethodCallHandler();
  }
  
  final StreamController<SharedContent> _sharedContentController = 
      StreamController<SharedContent>.broadcast();
  
  /// Stream of shared content from external apps
  Stream<SharedContent> get sharedContentStream => _sharedContentController.stream;
  
  /// Initialize the intent handler service
  Future<void> initialize() async {
    try {
      await _channel.invokeMethod('initialize');
      
      // Check for any pending shared content on app launch
      final pendingContent = await _getPendingSharedContent();
      if (pendingContent != null) {
        _sharedContentController.add(pendingContent);
      }
    } catch (e) {
      debugPrint('Failed to initialize intent handler: $e');
    }
  }
  
  /// Setup method call handler for platform communication
  void _setupMethodCallHandler() {
    _channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'onSharedContent':
          final sharedContent = _parseSharedContent(call.arguments);
          if (sharedContent != null) {
            _sharedContentController.add(sharedContent);
          }
          break;
        default:
          debugPrint('Unknown method call: ${call.method}');
      }
    });
  }
  
  /// Get any shared content that was pending when app was launched
  Future<SharedContent?> _getPendingSharedContent() async {
    try {
      final result = await _channel.invokeMethod('getPendingSharedContent');
      return _parseSharedContent(result);
    } catch (e) {
      debugPrint('Failed to get pending shared content: $e');
      return null;
    }
  }
  
  /// Parse shared content from platform data
  SharedContent? _parseSharedContent(dynamic data) {
    if (data == null || data is! Map) return null;
    
    final map = Map<String, dynamic>.from(data);
    final text = map['text'] as String?;
    
    if (text == null || text.trim().isEmpty) return null;
    
    return SharedContent.fromIntent(
      text: text.trim(),
      appName: map['appName'] as String?,
      senderInfo: map['senderInfo'] as String?,
      conversationContext: map['conversationContext'] as String?,
    );
  }
  
  /// Handle shared text directly (for testing or manual invocation)
  void handleSharedText(String text, {String? appName}) {
    final sharedContent = SharedContent.fromIntent(
      text: text,
      appName: appName,
    );
    _sharedContentController.add(sharedContent);
  }
  
  /// Clear any pending shared content
  Future<void> clearPendingContent() async {
    try {
      await _channel.invokeMethod('clearPendingContent');
    } catch (e) {
      debugPrint('Failed to clear pending content: $e');
    }
  }
  
  /// Check if the service is available on this platform
  Future<bool> isAvailable() async {
    try {
      final result = await _channel.invokeMethod('isAvailable');
      return result == true;
    } catch (e) {
      return false;
    }
  }
  
  /// Dispose resources
  void dispose() {
    _sharedContentController.close();
  }
}

/// Provider function for dependency injection
IntentHandlerService getIntentHandlerService() => IntentHandlerService.instance;