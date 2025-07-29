import 'dart:async';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import 'voice_service.dart';

/// Concrete implementation of VoiceService using speech_to_text package
class VoiceServiceImpl implements VoiceService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isInitialized = false;
  bool _isListening = false;
  double? _lastConfidence;
  String _currentLocale = 'en_US';

  // Callbacks for current session
  Function(String)? _onResult;
  Function(String)? _onPartialResult;
  Function(String)? _onError;

  @override
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _isInitialized = await _speech.initialize(
        onError: _handleError,
        onStatus: _handleStatus,
        debugLogging: false,
      );

      if (!_isInitialized) {
        throw Exception('Failed to initialize speech recognition');
      }
    } catch (e) {
      _isInitialized = false;
      throw Exception('Speech recognition initialization failed: $e');
    }
  }

  @override
  Future<bool> isAvailable() async {
    if (!_isInitialized) {
      await initialize();
    }
    return _isInitialized && _speech.isAvailable;
  }

  @override
  Future<bool> requestPermissions() async {
    final permission = await Permission.microphone.request();
    return permission == PermissionStatus.granted;
  }

  @override
  Future<bool> hasPermissions() async {
    final status = await Permission.microphone.status;
    return status == PermissionStatus.granted;
  }

  @override
  Future<void> startListening({
    Function(String)? onResult,
    Function(String)? onPartialResult,
    Function(String)? onError,
    Duration? timeout,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    if (!await hasPermissions()) {
      final granted = await requestPermissions();
      if (!granted) {
        onError?.call('Microphone permission denied');
        return;
      }
    }

    if (_isListening) {
      await stopListening();
    }

    // Store callbacks for this session
    _onResult = onResult;
    _onPartialResult = onPartialResult;
    _onError = onError;

    try {
      await _speech.listen(
        onResult: _handleSpeechResult,
        localeId: _currentLocale,
        onSoundLevelChange: null, // We'll implement this for waveform later
        cancelOnError: true,
        partialResults: true,
        listenMode: stt.ListenMode.confirmation,
        listenFor: timeout ?? const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
      );

      _isListening = true;
    } catch (e) {
      _onError?.call('Failed to start listening: $e');
    }
  }

  @override
  Future<void> stopListening() async {
    if (_isListening) {
      await _speech.stop();
      _isListening = false;
    }
  }

  @override
  Future<void> cancel() async {
    if (_isListening) {
      await _speech.cancel();
      _isListening = false;
    }
  }

  @override
  bool get isListening => _isListening;

  @override
  Future<List<VoiceLocale>> getSupportedLocales() async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      final locales = await _speech.locales();
      return locales
          .map((locale) => VoiceLocale(
                localeId: locale.localeId,
                name: locale.name,
              ))
          .toList();
    } catch (e) {
      // Return default locale if fetching fails
      return [const VoiceLocale(localeId: 'en_US', name: 'English (US)')];
    }
  }

  @override
  Future<void> setLocale(String localeId) async {
    _currentLocale = localeId;
  }

  @override
  Future<VoiceTaskResult> processVoiceInput(String text) async {
    // This will be implemented in the NLP parser
    // For now, return a basic result with just the title
    return VoiceTaskResult(
      taskTitle: text.trim(),
      originalText: text,
      confidence: _lastConfidence ?? 0.5,
    );
  }

  @override
  double? get lastConfidence => _lastConfidence;

  // Private helper methods

  void _handleSpeechResult(result) {
    _lastConfidence = result.confidence;

    if (result.finalResult) {
      _onResult?.call(result.recognizedWords);
    } else {
      _onPartialResult?.call(result.recognizedWords);
    }
  }

  void _handleError(error) {
    _isListening = false;
    _onError?.call('Speech recognition error: ${error.errorMsg}');
  }

  void _handleStatus(String status) {
    switch (status) {
      case 'listening':
        _isListening = true;
        break;
      case 'notListening':
      case 'done':
        _isListening = false;
        break;
    }
  }
}
