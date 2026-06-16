
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart';

class SpeechService {
  SpeechService._() : _speech = SpeechToText();

  static final SpeechService instance = SpeechService._();

  final SpeechToText _speech;
  bool _isConfigured = false;

  // Mutable callback references so they can be updated on each listen call.
  void Function(String message)? _currentOnError;
  void Function(String status)? _currentOnStatus;

  bool get isListening => _speech.isListening;

  Future<String?> _ensureMicrophonePermission() async {
    final status = await Permission.microphone.request();

    if (status.isGranted) {
      debugPrint('Microphone permission granted');
      return null;
    }

    if (status.isPermanentlyDenied) {
      debugPrint('Microphone permission permanently denied');
      return 'Microphone permission is permanently denied. Enable it in system settings to continue.';
    }

    debugPrint('Microphone permission denied: $status');
    return 'Microphone permission is required to capture the candidate answer.';
  }

  Future<String?> _initializeSpeechRecognition() async {
    if (_isConfigured) {
      debugPrint('Speech recognition already configured');
      return null;
    }

    final permissionError = await _ensureMicrophonePermission();
    if (permissionError != null) {
      return permissionError;
    }

    debugPrint('Initializing speech recognition...');
    final available = await _speech.initialize(
      onStatus: (status) {
        debugPrint('Speech status: $status');
        // Delegate to the mutable reference so each listen call
        // can provide its own callback without needing to re-initialize.
        _currentOnStatus?.call(status);
      },
      onError: (error) {
        debugPrint('Speech error: ${error.errorMsg} (permanent: ${error.permanent})');
        _currentOnError?.call(error.errorMsg);
      },
    );

    if (!available) {
      debugPrint('Speech recognition unavailable on this device');
      return 'Speech recognition is unavailable on this device. '
          'If you are on an emulator, make sure the virtual microphone '
          'uses host audio input (Extended Controls → Microphone).';
    }

    // Log available locales for debugging
    final locales = await _speech.locales();
    debugPrint('Available speech locales: ${locales.map((l) => l.localeId).join(', ')}');

    _isConfigured = true;
    debugPrint('Speech recognition initialized successfully');
    return null;
  }

  Future<String?> startListening({
    required void Function(String transcript) onResult,
    void Function(String message)? onError,
    void Function(String status)? onStatus,
  }) async {
    // Update the mutable callback references BEFORE initializing,
    // so even the first initialize() call delegates to the right callbacks.
    _currentOnError = onError;
    _currentOnStatus = onStatus;

    final initializationError = await _initializeSpeechRecognition();
    if (initializationError != null) {
      return initializationError;
    }

    // Stop any existing listening session before starting a new one.
    if (_speech.isListening) {
      debugPrint('Stopping previous listening session');
      await _speech.stop();
      // Small delay to let the engine settle.
      await Future<void>.delayed(const Duration(milliseconds: 200));
    }

    final locale = await _speech.systemLocale();
    debugPrint('System locale: ${locale?.localeId}');

    try {
      await _speech.listen(
        onResult: (result) {
          debugPrint(
            'Speech result: "${result.recognizedWords}" '
            '(final: ${result.finalResult}, '
            'confidence: ${result.confidence})',
          );
          onResult(result.recognizedWords);
        },
        listenOptions: SpeechListenOptions(
          localeId: locale?.localeId,
          partialResults: true,
          cancelOnError: false,
          // Use dictation mode for longer, natural speech (interview answers).
          // ListenMode.search auto-stops after short phrases and is intended
          // for keyword input, which is why voice input was cutting off early.
          listenMode: ListenMode.dictation,
          autoPunctuation: true,
          // Allow 10 seconds of silence before the engine auto-stops,
          // giving the candidate time to think between sentences.
          pauseFor: const Duration(seconds: 10),
          // Also set listenFor to 2 minutes so the engine doesn't auto-stop
          // during a long answer.
          listenFor: const Duration(minutes: 2),
        ),
      );
      debugPrint('Started listening for speech (isListening: ${_speech.isListening})');
    } catch (e) {
      debugPrint('Error starting speech listening: $e');
      return 'Failed to start speech recognition: $e';
    }

    return null;
  }

  Future<void> stopListening() async {
    if (_speech.isListening) {
      debugPrint('Stopping speech listening');
      await _speech.stop();
    }
  }

  /// Force re-initialization on next use (e.g., after an error).
  void reset() {
    _isConfigured = false;
    _currentOnError = null;
    _currentOnStatus = null;
  }
}
