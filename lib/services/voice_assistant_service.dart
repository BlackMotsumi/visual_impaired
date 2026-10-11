import 'package:flutter_tts/flutter_tts.dart';

import 'speech_services.dart';
import 'command_processor.dart';

/// ===============================================================
/// VOICE ASSISTANT SERVICE
/// ===============================================================
/// Handles:
/// - Text-to-Speech (TTS)
/// - Speech-to-Text (STT)
/// - Voice command processing
/// - Starting/stopping listening
/// - Starting/stopping speech
///
/// Used by Dashboard, Accessibility and other voice-controlled
/// screens.
///
/// NOTE:
/// Splash/Login should continue using:
///     lib/voice/voice_service.dart
///
/// This class is for the higher-level assistant functionality.
/// ===============================================================

class VoiceAssistantService {
  // ---------------------------------------------------------------
  // SERVICES
  // ---------------------------------------------------------------

  final FlutterTts _tts = FlutterTts();

  final SpeechService _speechService = SpeechService();

  // ---------------------------------------------------------------
  // STATE
  // ---------------------------------------------------------------

  bool _initialized = false;

  bool _speechAvailable = false;

  bool _isSpeaking = false;

  // ---------------------------------------------------------------
  // SETTINGS
  // ---------------------------------------------------------------

  double _speechRate = 0.45;

  double _volume = 1.0;

  double _pitch = 1.0;

  String _language = 'en-ZA';

  // ---------------------------------------------------------------
  // GETTERS
  // ---------------------------------------------------------------

  bool get isInitialized => _initialized;

  bool get isSpeechAvailable => _speechAvailable;

  bool get isSpeaking => _isSpeaking;

  bool get isListening => _speechService.isListening;

  double get speechRate => _speechRate;

  double get volume => _volume;

  double get pitch => _pitch;

  String get language => _language;

  // ===============================================================
  // INITIALIZE
  // ===============================================================

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    try {
      // -----------------------------------------------------------
      // TTS SETTINGS
      // -----------------------------------------------------------

      await _tts.setLanguage(_language);

      await _tts.setSpeechRate(_speechRate);

      await _tts.setVolume(_volume);

      await _tts.setPitch(_pitch);

      // Wait for speech to finish before continuing.
      await _tts.awaitSpeakCompletion(true);

      // -----------------------------------------------------------
      // TTS CALLBACKS
      // -----------------------------------------------------------

      _tts.setStartHandler(() {
        _isSpeaking = true;

        print('VOICE ASSISTANT: TTS started');
      });

      _tts.setCompletionHandler(() {
        _isSpeaking = false;

        print('VOICE ASSISTANT: TTS completed');
      });

      _tts.setCancelHandler(() {
        _isSpeaking = false;

        print('VOICE ASSISTANT: TTS cancelled');
      });

      _tts.setErrorHandler((message) {
        _isSpeaking = false;

        print('VOICE ASSISTANT: TTS error: $message');
      });

      // -----------------------------------------------------------
      // SPEECH-TO-TEXT
      // -----------------------------------------------------------

      _speechAvailable = await _speechService.initialize();

      _initialized = true;

      print(
        'VOICE ASSISTANT: Initialized '
        'speechAvailable=$_speechAvailable',
      );
    } catch (e) {
      _initialized = true;

      _speechAvailable = false;

      print(
        'VOICE ASSISTANT: Initialization error: $e',
      );
    }
  }

  // ===============================================================
  // SPEAK
  // ===============================================================

  Future<void> speak(
    String text, {
    bool stopListeningFirst = true,
  }) async {
    if (text.trim().isEmpty) {
      return;
    }

    if (!_initialized) {
      await initialize();
    }

    try {
      // -----------------------------------------------------------
      // Stop microphone before speaking.
      //
      // This is important because the microphone can otherwise
      // hear the phone's own TTS voice.
      // -----------------------------------------------------------

      if (stopListeningFirst) {
        await stopListening();
      }

      // Stop anything currently being spoken.
      await _tts.stop();

      _isSpeaking = true;

      print('VOICE ASSISTANT: Speaking: $text');

      await _tts.speak(text);

      _isSpeaking = false;
    } catch (e) {
      _isSpeaking = false;

      print(
        'VOICE ASSISTANT: Speak error: $e',
      );
    }
  }

  // ===============================================================
  // STOP SPEAKING
  // ===============================================================

  Future<void> stopSpeaking() async {
    try {
      await _tts.stop();

      _isSpeaking = false;

      print('VOICE ASSISTANT: Speech stopped');
    } catch (e) {
      print(
        'VOICE ASSISTANT: Stop speech error: $e',
      );
    }
  }

  // ===============================================================
  // LISTEN FOR RAW SPEECH
  // ===============================================================
  ///
  /// Returns whatever the user said.
  ///
  /// Example:
  ///
  /// User says:
  ///     "Go back to dashboard"
  ///
  /// Returns:
  ///     "go back to dashboard"
  ///
  /// ===============================================================

  Future<String?> listenForSpeech({
    Duration listenFor = const Duration(seconds: 10),
    Duration pauseFor = const Duration(seconds: 3),
  }) async {
    if (!_initialized) {
      await initialize();
    }

    if (!_speechAvailable) {
      print(
        'VOICE ASSISTANT: Speech recognition unavailable',
      );

      return null;
    }

    try {
      // -----------------------------------------------------------
      // Make sure TTS isn't speaking.
      // -----------------------------------------------------------

      await stopSpeaking();

      // -----------------------------------------------------------
      // Stop an existing listening session.
      // -----------------------------------------------------------

      await stopListening();

      print(
        'VOICE ASSISTANT: Listening '
        'for ${listenFor.inSeconds} seconds',
      );

      final String result =
          await _speechService.listenForResult(
        listenFor: listenFor,
        pauseFor: pauseFor,
      );

      final String cleanedResult = result.trim();

      if (cleanedResult.isEmpty) {
        print(
          'VOICE ASSISTANT: No speech recognized',
        );

        return null;
      }

      print(
        'VOICE ASSISTANT: Recognized: $cleanedResult',
      );

      return cleanedResult;
    } catch (e) {
      print(
        'VOICE ASSISTANT: Listen error: $e',
      );

      return null;
    }
  }

  // ===============================================================
  // LISTEN FOR COMMAND
  // ===============================================================
  ///
  /// Listens to the user and converts the spoken sentence into
  /// a VoiceCommand using CommandProcessor.
  ///
  /// ===============================================================

  Future<VoiceCommand?> listenForCommand({
    Duration listenFor = const Duration(seconds: 10),
    Duration pauseFor = const Duration(seconds: 3),
  }) async {
    final String? speech = await listenForSpeech(
      listenFor: listenFor,
      pauseFor: pauseFor,
    );

    if (speech == null || speech.trim().isEmpty) {
      return VoiceCommand.noInput;
    }

    try {
      final VoiceCommand command =
          CommandProcessor.process(speech);

      print(
        'VOICE ASSISTANT: '
        'Speech="$speech" '
        'Command=$command',
      );

      return command;
    } catch (e) {
      print(
        'VOICE ASSISTANT: Command processing error: $e',
      );

      return VoiceCommand.unknown;
    }
  }

  // ===============================================================
  // STOP LISTENING
  // ===============================================================
  ///
  /// IMPORTANT:
  /// This method is required by AccessibilityScreen and Dashboard.
  ///
  /// ===============================================================

  Future<void> stopListening() async {
    try {
      await _speechService.stopListening();

      print(
        'VOICE ASSISTANT: Listening stopped',
      );
    } catch (e) {
      print(
        'VOICE ASSISTANT: Stop listening error: $e',
      );
    }
  }

  // ===============================================================
  // CANCEL LISTENING
  // ===============================================================

  Future<void> cancelListening() async {
    try {
      await _speechService.cancelListening();

      print(
        'VOICE ASSISTANT: Listening cancelled',
      );
    } catch (e) {
      print(
        'VOICE ASSISTANT: Cancel listening error: $e',
      );
    }
  }

  // ===============================================================
  // STOP EVERYTHING
  // ===============================================================

  Future<void> stop() async {
    try {
      await stopListening();

      await stopSpeaking();

      print(
        'VOICE ASSISTANT: All voice operations stopped',
      );
    } catch (e) {
      print(
        'VOICE ASSISTANT: Stop error: $e',
      );
    }
  }

  // ===============================================================
  // CHANGE SPEECH RATE
  // ===============================================================

  Future<void> setSpeechRate(double rate) async {
    // Keep rate in a safe range.
    _speechRate = rate.clamp(0.1, 1.0);

    try {
      await _tts.setSpeechRate(_speechRate);

      print(
        'VOICE ASSISTANT: Speech rate=$_speechRate',
      );
    } catch (e) {
      print(
        'VOICE ASSISTANT: Speech rate error: $e',
      );
    }
  }

  // ===============================================================
  // CHANGE VOLUME
  // ===============================================================

  Future<void> setVolume(double volume) async {
    _volume = volume.clamp(0.0, 1.0);

    try {
      await _tts.setVolume(_volume);

      print(
        'VOICE ASSISTANT: Volume=$_volume',
      );
    } catch (e) {
      print(
        'VOICE ASSISTANT: Volume error: $e',
      );
    }
  }

  // ===============================================================
  // CHANGE PITCH
  // ===============================================================

  Future<void> setPitch(double pitch) async {
    _pitch = pitch.clamp(0.5, 2.0);

    try {
      await _tts.setPitch(_pitch);

      print(
        'VOICE ASSISTANT: Pitch=$_pitch',
      );
    } catch (e) {
      print(
        'VOICE ASSISTANT: Pitch error: $e',
      );
    }
  }

  // ===============================================================
  // CHANGE LANGUAGE
  // ===============================================================

  Future<void> setLanguage(String language) async {
    _language = language;

    try {
      await _tts.setLanguage(_language);

      print(
        'VOICE ASSISTANT: Language=$_language',
      );
    } catch (e) {
      print(
        'VOICE ASSISTANT: Language error: $e',
      );
    }
  }

  // ===============================================================
  // REPEAT
  // ===============================================================

  Future<void> repeat(String message) async {
    await speak(message);
  }

  // ===============================================================
  // DISPOSE
  // ===============================================================

  Future<void> dispose() async {
    try {
      await stop();

      await _tts.stop();

      _initialized = false;

      _speechAvailable = false;

      print(
        'VOICE ASSISTANT: Disposed',
      );
    } catch (e) {
      print(
        'VOICE ASSISTANT: Dispose error: $e',
      );
    }
  }
}