import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/services.dart';
import '../../core/services/advanced_nlp_service.dart';
import '../../core/repositories/repositories.dart';
import '../../shared/models/models.dart';
import '../../shared/providers/providers.dart';
import 'voice_state.dart';
import 'voice_controller.dart';

/// Provider for the voice service implementation (deprecated - use app_providers.dart)
/// This provider is kept for backward compatibility but should be removed
/// once all references are updated to use the main app provider
@Deprecated('Use voiceServiceProvider from app_providers.dart instead')
final localVoiceServiceProvider = Provider<VoiceService>((ref) {
  return VoiceServiceImpl();
});

/// Provider for the advanced NLP service
final advancedNlpServiceProvider = Provider<AdvancedNlpService>((ref) {
  return AdvancedNlpService();
});

/// Provider for voice input state management
final voiceInputProvider = StateNotifierProvider<VoiceInputController, VoiceInputState>((ref) {
  final voiceService = ref.watch(localVoiceServiceProvider);
  final taskRepository = ref.watch(taskRepositoryProvider);
  final categoryRepository = ref.watch(categoryRepositoryProvider);
  final advancedNlpService = ref.watch(advancedNlpServiceProvider);
  
  return VoiceInputController(
    voiceService: voiceService,
    taskRepository: taskRepository,
    categoryRepository: categoryRepository,
    advancedNlpService: advancedNlpService,
  );
});

/// Provider for checking if voice is available on device
final voiceAvailabilityProvider = FutureProvider<bool>((ref) async {
  final voiceService = ref.watch(localVoiceServiceProvider);
  return await voiceService.isAvailable();
});

/// Provider for checking microphone permissions
final microphonePermissionProvider = FutureProvider<bool>((ref) async {
  final voiceService = ref.watch(localVoiceServiceProvider);
  return await voiceService.hasPermissions();
});

/// Provider for supported voice locales
final voiceLocalesProvider = FutureProvider<List<VoiceLocale>>((ref) async {
  final voiceService = ref.watch(localVoiceServiceProvider);
  return await voiceService.getSupportedLocales();
});

/// Provider for current voice locale setting
final voiceLocaleProvider = StateProvider<String>((ref) => 'en_US');

/// Provider for voice input settings
final voiceSettingsProvider = StateNotifierProvider<VoiceSettingsNotifier, VoiceSettings>((ref) {
  return VoiceSettingsNotifier();
});

/// Voice input settings
class VoiceSettings {
  final bool autoStartAfterPermission;
  final Duration listenTimeout;
  final bool enablePartialResults;
  final bool enableConfirmationBeforeCreation;
  final double confidenceThreshold;
  
  const VoiceSettings({
    this.autoStartAfterPermission = true,
    this.listenTimeout = const Duration(seconds: 30),
    this.enablePartialResults = true,
    this.enableConfirmationBeforeCreation = true,
    this.confidenceThreshold = 0.7,
  });
  
  VoiceSettings copyWith({
    bool? autoStartAfterPermission,
    Duration? listenTimeout,
    bool? enablePartialResults,
    bool? enableConfirmationBeforeCreation,
    double? confidenceThreshold,
  }) {
    return VoiceSettings(
      autoStartAfterPermission: autoStartAfterPermission ?? this.autoStartAfterPermission,
      listenTimeout: listenTimeout ?? this.listenTimeout,
      enablePartialResults: enablePartialResults ?? this.enablePartialResults,
      enableConfirmationBeforeCreation: enableConfirmationBeforeCreation ?? this.enableConfirmationBeforeCreation,
      confidenceThreshold: confidenceThreshold ?? this.confidenceThreshold,
    );
  }
}

/// Notifier for voice settings
class VoiceSettingsNotifier extends StateNotifier<VoiceSettings> {
  VoiceSettingsNotifier() : super(const VoiceSettings());
  
  void updateSettings(VoiceSettings newSettings) {
    state = newSettings;
  }
  
  void setAutoStart(bool enabled) {
    state = state.copyWith(autoStartAfterPermission: enabled);
  }
  
  void setListenTimeout(Duration timeout) {
    state = state.copyWith(listenTimeout: timeout);
  }
  
  void setPartialResults(bool enabled) {
    state = state.copyWith(enablePartialResults: enabled);
  }
  
  void setConfirmationRequired(bool required) {
    state = state.copyWith(enableConfirmationBeforeCreation: required);
  }
  
  void setConfidenceThreshold(double threshold) {
    state = state.copyWith(confidenceThreshold: threshold);
  }
}