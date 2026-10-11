import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

/// ============================================================
/// SPEECH SERVICE
/// ============================================================
///
/// Low-level Speech-to-Text service.
///
/// VoiceAssistantService uses this class to:
/// - initialize speech recognition
/// - listen for speech
/// - return recognized text
/// - stop listening
///
/// ============================================================

class SpeechService {
  final stt.SpeechToText _speech = stt.SpeechToText();

  bool _initialized = false;
  bool _available = false;

  bool get isInitialized => _initialized;
  bool get isAvailable => _available;
  bool get isListening => _speech.isListening;

  // ----------------------------------------------------------
  // INITIALIZE
  // ----------------------------------------------------------

  Future<bool> initialize() async {
    if (_initialized) {
      return _available;
    }

    try {
      _available = await _speech.initialize(
        onStatus: (String status) {
          print('SPEECH STATUS: $status');
        },
        onError: (dynamic error) {
          print('SPEECH ERROR: $error');
        },
      );

      _initialized = true;

      print(
        'SPEECH SERVICE INITIALIZED: '
        'available=$_available',
      );

      return _available;
    } catch (e) {
      print(
        'SPEECH INITIALIZATION ERROR: $e',
      );

      _initialized = true;
      _available = false;

      return false;
    }
  }

  // ----------------------------------------------------------
  // LISTEN FOR RESULT
  // ----------------------------------------------------------

  Future<String> listenForResult({
    Duration listenFor = const Duration(seconds: 10),
    Duration pauseFor = const Duration(seconds: 3),
  }) async {
    if (!_initialized) {
      final bool initialized = await initialize();

      if (!initialized) {
        return '';
      }
    }

    if (!_available) {
      print(
        'SPEECH SERVICE: Speech recognition unavailable.',
      );

      return '';
    }

    if (_speech.isListening) {
      try {
        await _speech.stop();
      } catch (e) {
        print(
          'SPEECH SERVICE: Error stopping old session: $e',
        );
      }
    }

    String recognizedText = '';

    try {
      print(
        'SPEECH SERVICE: Starting recognition...',
      );

      await _speech.listen(
        onResult: (SpeechRecognitionResult result) {
          final String text =
              result.recognizedWords.trim();

          if (text.isNotEmpty) {
            recognizedText = text;

            print(
              'SPEECH RESULT: "$text" '
              'final=${result.finalResult}',
            );
          }
        },
        localeId: 'en_ZA',
        listenMode: stt.ListenMode.dictation,
        listenFor: listenFor,
        pauseFor: pauseFor,
        partialResults: true,
        cancelOnError: false,
        listenOptions: stt.SpeechListenOptions(
          partialResults: true,
          listenMode: stt.ListenMode.dictation,
          cancelOnError: false,
        ),
      );

      // Wait until recognition stops.
      final DateTime timeout =
          DateTime.now().add(listenFor);

      while (_speech.isListening) {
        if (DateTime.now().isAfter(timeout)) {
          break;
        }

        await Future.delayed(
          const Duration(milliseconds: 100),
        );
      }

      // Give Android a small amount of time to deliver
      // the final result.
      await Future.delayed(
        const Duration(milliseconds: 500),
      );

      if (_speech.isListening) {
        await _speech.stop();
      }

      print(
        'SPEECH SERVICE FINAL RESULT: '
        '"$recognizedText"',
      );

      return recognizedText.trim();
    } catch (e) {
      print(
        'SPEECH LISTEN ERROR: $e',
      );

      try {
        if (_speech.isListening) {
          await _speech.stop();
        }
      } catch (_) {}

      return recognizedText.trim();
    }
  }

  // ----------------------------------------------------------
  // STOP LISTENING
  // ----------------------------------------------------------

  Future<void> stopListening() async {
    try {
      if (_speech.isListening) {
        await _speech.stop();
      }
    } catch (e) {
      print(
        'SPEECH STOP ERROR: $e',
      );
    }
  }

  // ----------------------------------------------------------
  // CANCEL LISTENING
  // ----------------------------------------------------------

  Future<void> cancelListening() async {
    try {
      if (_speech.isListening) {
        await _speech.cancel();
      }
    } catch (e) {
      print(
        'SPEECH CANCEL ERROR: $e',
      );
    }
  }

  // ----------------------------------------------------------
  // DISPOSE
  // ----------------------------------------------------------

  Future<void> dispose() async {
    try {
      await _speech.cancel();
    } catch (_) {}

    _initialized = false;
    _available = false;
  }
}