import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'intent_handler_service.dart';

/// Provider for the intent handler service instance
final intentHandlerServiceProvider = Provider<IntentHandlerService>((ref) {
  return IntentHandlerService.instance;
});

/// Provider that ensures the intent handler service is initialized
final intentHandlerInitializationProvider = FutureProvider<void>((ref) async {
  final service = ref.watch(intentHandlerServiceProvider);
  await service.initialize();
});

/// Provider that checks if intent handling is available on this platform
final intentHandlerAvailabilityProvider = FutureProvider<bool>((ref) async {
  final service = ref.watch(intentHandlerServiceProvider);
  return await service.isAvailable();
});