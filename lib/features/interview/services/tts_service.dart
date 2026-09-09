import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  TtsService._() : _tts = FlutterTts();

  static final TtsService instance = TtsService._();

  final FlutterTts _tts;
  bool _isConfigured = false;

  Future<void> initialize({
    VoidCallback? onStart,
    VoidCallback? onComplete,
    void Function(String message)? onError,
  }) async {
    if (!_isConfigured) {
      await _tts.awaitSpeakCompletion(true);
      await _tts.setLanguage('en-US');
      await _tts.setSpeechRate(0.5);
      await _tts.setPitch(1.0);
      await _tts.setVolume(1.0);

      // Platform-specific audio configuration to ensure speaker output
      if (Platform.isIOS) {
        // Use the shared AVAudioSession so TTS doesn't steal exclusive access
        try {
          await _tts.setSharedInstance(true);
          await _tts.setIosAudioCategory(
            IosTextToSpeechAudioCategory.playback,
            [
              IosTextToSpeechAudioCategoryOptions.defaultToSpeaker,
              IosTextToSpeechAudioCategoryOptions.duckOthers,
            ],
            IosTextToSpeechAudioMode.defaultMode,
          );
        } catch (e) {
          debugPrint('TTS iOS audio configuration warning: $e');
        }
      } else if (Platform.isAndroid) {
        // Force TTS to use the media stream (speaker) instead of the
        // communication stream (earpiece / headphone-only).
        try {
          final engines = await _tts.getEngines;
          debugPrint('Available TTS engines: $engines');
          if (engines.isNotEmpty) {
            // Prefer Google TTS engine if available, otherwise use first
            final googleEngine = engines.firstWhere(
              (e) => e.toString().contains('google'),
              orElse: () => engines.first,
            );
            await _tts.setEngine(googleEngine.toString());
            debugPrint('TTS engine set to: $googleEngine');
          }
        } catch (e) {
          debugPrint('TTS Android engine configuration warning: $e');
        }
      }

      _isConfigured = true;
    }

    _tts.setStartHandler(() {
      onStart?.call();
    });
    _tts.setCompletionHandler(() {
      onComplete?.call();
    });
    _tts.setCancelHandler(() {
      onComplete?.call();
    });
    _tts.setErrorHandler((message) {
      onError?.call(message.toString());
    });
  }

  Future<void> speak(String text) async {
    try {
      await _tts.stop();
      await _tts.speak(text);
    } catch (e) {
      debugPrint('TTS speak error: $e');
      rethrow;
    }
  }

  Future<void> stop() async {
    try {
      await _tts.stop();
    } catch (e) {
      debugPrint('TTS stop error: $e');
    }
  }
}
