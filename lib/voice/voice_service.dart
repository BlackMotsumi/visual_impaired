import 'dart:async';

import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

/// Central voice service for Vision Guide.
///
/// This service is shared by:
/// - Splash screen
/// - Login
/// - Registration
/// - Dashboard
/// - Study Groups
/// - Other voice-enabled screens
///
/// IMPORTANT:
/// Android speech recognition can report "done" or "notListening"
/// BEFORE it delivers the final speech result.
///
/// Therefore, this service does NOT immediately finish a session when
/// Android reports "done"/"notListening".
class VoiceService {
  // ---------------------------------------------------------------------------
  // SINGLETON
  // ---------------------------------------------------------------------------

  static final VoiceService _instance = VoiceService._internal();

  factory VoiceService() {
    return _instance;
  }

  VoiceService._internal();

  // ---------------------------------------------------------------------------
  // VOICE ENGINES
  // ---------------------------------------------------------------------------

  final FlutterTts _tts = FlutterTts();
  final stt.SpeechToText _speech = stt.SpeechToText();

  // ---------------------------------------------------------------------------
  // STATE
  // ---------------------------------------------------------------------------

  bool _initialized = false;
  bool _isListening = false;

  bool get isListening => _isListening;
  bool get isInitialized => _initialized;

  // ---------------------------------------------------------------------------
  // SESSION MANAGEMENT
  // ---------------------------------------------------------------------------

  int _sessionId = 0;

  Completer<bool>? _listenCompleter;

  Timer? _completionTimer;

  /// Android sometimes sends the final result several seconds after
  /// "notListening" / "done".
  ///
  /// We therefore wait considerably longer before declaring that
  /// no final result was received.
  static const Duration _finalResultGracePeriod =
      Duration(seconds: 5);

  /// Absolute maximum amount of time allowed for a listening session.
  static const Duration _maximumListeningTime =
      Duration(seconds: 30);

  // ---------------------------------------------------------------------------
  // INITIALIZATION
  // ---------------------------------------------------------------------------

  Future<bool> initialize() async {
    if (_initialized) {
      return true;
    }

    try {
      // ------------------------------------------------------------
      // TEXT TO SPEECH
      // ------------------------------------------------------------

      await _tts.setLanguage('en-ZA');
      await _tts.setSpeechRate(0.45);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);

      await _tts.awaitSpeakCompletion(true);

      _tts.setStartHandler(() {
        print('VOICE TTS: started');
      });

      _tts.setCompletionHandler(() {
        print('VOICE TTS: completed');
      });

      _tts.setErrorHandler((dynamic message) {
        print('VOICE TTS ERROR: $message');
      });

      // ------------------------------------------------------------
      // SPEECH RECOGNITION
      // ------------------------------------------------------------

      final bool available = await _speech.initialize(
        onStatus: (String status) {
          print('VOICE STATUS: $status');

          // ----------------------------------------------------------
          // SPEECH STARTED
          // ----------------------------------------------------------

          if (status == 'listening') {
            _cancelCompletionTimer();

            _isListening = true;

            return;
          }

          // ----------------------------------------------------------
          // ANDROID HAS STOPPED LISTENING
          // ----------------------------------------------------------
          //
          // DO NOT immediately complete the session here.
          //
          // Android may send:
          //
          // notListening
          // done
          //
          // BEFORE:
          //
          // final speech result
          //
          // So we start a grace timer instead.
          // ----------------------------------------------------------

          if (status == 'notListening' || status == 'done') {
            _isListening = false;

            _scheduleCompletion();

            return;
          }
        },
        onError: (dynamic error) {
          print('VOICE ERROR: $error');

          _isListening = false;

          // Even after an error, give the recognizer a short opportunity
          // to deliver a pending result.
          _scheduleCompletion(
            delay: const Duration(seconds: 2),
          );
        },
      );

      if (!available) {
        print('VOICE: Speech recognition is not available.');

        _initialized = false;

        return false;
      }

      _initialized = true;

      print('VOICE: Voice engine initialized.');

      return true;
    } catch (e) {
      print('VOICE INITIALIZATION ERROR: $e');

      _initialized = false;

      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // SPEAK
  // ---------------------------------------------------------------------------

  Future<void> speak(String text) async {
    if (text.trim().isEmpty) {
      return;
    }

    try {
      print('VOICE SPEAK: $text');

      // Stop any previous speech first.
      await _tts.stop();

      await _tts.speak(text);

      print('VOICE SPEAK: Finished completely.');
    } catch (e) {
      print('VOICE SPEAK ERROR: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // LISTEN
  // ---------------------------------------------------------------------------

  Future<bool> listen({
    String localeId = 'en_ZA',
    bool acceptPartialResults = false,
    required Future<void> Function(String text) onResult,
  }) async {
    if (!_initialized) {
      final bool initialized = await initialize();

      if (!initialized) {
        print('VOICE: Cannot listen because voice engine is unavailable.');

        return false;
      }
    }

    // ------------------------------------------------------------
    // STOP ANY PREVIOUS LISTENING SESSION
    // ------------------------------------------------------------

    await _stopCurrentRecognitionOnly();

    _cancelCompletionTimer();

    // ------------------------------------------------------------
    // CREATE NEW SESSION
    // ------------------------------------------------------------

    final int currentSession = ++_sessionId;

    final Completer<bool> completer = Completer<bool>();

    _listenCompleter = completer;

    bool resultDelivered = false;
    bool sessionFinished = false;

    String lastRecognizedText = '';

    print(
      'VOICE: Starting listening session=$currentSession',
    );

    // ------------------------------------------------------------
    // START LISTENING
    // ------------------------------------------------------------

    try {
      _isListening = true;

      // ----------------------------------------------------------
      // IMPORTANT
      // ----------------------------------------------------------
      //
      // Always request partial results from Android.
      //
      // We decide ourselves whether to accept them.
      //
      // This allows us to observe the progression:
      //
      // "happy"
      // "happy at"
      // "happy at gmail.com"
      // final=true
      //
      // ----------------------------------------------------------

      await _speech.listen(
        onResult: (SpeechRecognitionResult result) async {
          if (currentSession != _sessionId) {
            print(
              'VOICE: Ignoring result from old session '
              'session=$currentSession current=$_sessionId',
            );

            return;
          }

          final String text = result.recognizedWords.trim();

          print(
            'VOICE RESULT: "$text" '
            'final=${result.finalResult} '
            'session=$currentSession',
          );

          if (text.isEmpty) {
            return;
          }

          lastRecognizedText = text;

          print(
            'VOICE RESULT PROCESSING: "$text" '
            'final=${result.finalResult} '
            'session=$currentSession',
          );

          // --------------------------------------------------------
          // FINAL RESULT
          // --------------------------------------------------------

          if (result.finalResult) {
            if (resultDelivered) {
              return;
            }

            resultDelivered = true;

            _cancelCompletionTimer();

            print(
              'VOICE COMMAND ACCEPTED: "$text"',
            );

            // ------------------------------------------------------
            // IMPORTANT:
            //
            // Finish the session BEFORE calling the screen callback.
            //
            // This prevents the screen from starting another
            // listening session while the old recognizer is still
            // active.
            // ------------------------------------------------------

            await _finishListeningSession(
              currentSession,
              result: true,
            );

            if (!sessionFinished) {
              sessionFinished = true;
            }

            // ------------------------------------------------------
            // Deliver result to the screen.
            // ------------------------------------------------------

            try {
              await onResult(text);
            } catch (e) {
              print(
                'VOICE RESULT CALLBACK ERROR: $e',
              );
            }

            return;
          }

          // --------------------------------------------------------
          // PARTIAL RESULT
          // --------------------------------------------------------

          if (!acceptPartialResults) {
            print(
              'VOICE: Partial result ignored because '
              'final result is required.',
            );

            return;
          }

          // --------------------------------------------------------
          // SHORT COMMAND MODE
          // --------------------------------------------------------
          //
          // For commands such as:
          //
          // Login
          // Register
          // Back
          // Help
          // Repeat
          //
          // we can safely accept a suitable partial result.
          //
          // This preserves the fast behavior of your Splash,
          // Dashboard and navigation commands.
          // --------------------------------------------------------

          if (_looksLikeShortCommand(text)) {
            if (resultDelivered) {
              return;
            }

            resultDelivered = true;

            _cancelCompletionTimer();

            print(
              'VOICE COMMAND ACCEPTED: "$text"',
            );

            await _finishListeningSession(
              currentSession,
              result: true,
            );

            if (!sessionFinished) {
              sessionFinished = true;
            }

            try {
              await onResult(text);
            } catch (e) {
              print(
                'VOICE RESULT CALLBACK ERROR: $e',
              );
            }

            return;
          }
        },
        localeId: localeId,
        listenMode: stt.ListenMode.dictation,

        // ----------------------------------------------------------
        // IMPORTANT:
        //
        // Android is allowed to continue listening for a reasonable
        // amount of time.
        // ----------------------------------------------------------

        listenFor: _maximumListeningTime,
        pauseFor: const Duration(seconds: 5),

        // Always request partial results.
        partialResults: true,

        cancelOnError: false,

        // Keep this enabled so Android can return the final result.
        listenOptions: stt.SpeechListenOptions(
          partialResults: true,
          listenMode: stt.ListenMode.dictation,
          cancelOnError: false,
        ),
      );
    } catch (e) {
      print(
        'VOICE LISTEN ERROR session=$currentSession: $e',
      );

      _isListening = false;

      _cancelCompletionTimer();

      if (!completer.isCompleted) {
        completer.complete(false);
      }
    }

    // ------------------------------------------------------------
    // ABSOLUTE SAFETY TIMEOUT
    // ------------------------------------------------------------
    //
    // This protects the application if Android never sends another
    // status/result.
    // ------------------------------------------------------------

    Timer(
      _maximumListeningTime + const Duration(seconds: 2),
      () {
        if (currentSession != _sessionId) {
          return;
        }

        if (completer.isCompleted) {
          return;
        }

        if (resultDelivered) {
          return;
        }

        print(
          'VOICE: Maximum listening time reached '
          'session=$currentSession',
        );

        _completeListeningSession(
          currentSession,
          result: false,
        );
      },
    );

    // ------------------------------------------------------------
    // WAIT FOR RESULT
    // ------------------------------------------------------------

    final bool received = await completer.future;

    if (currentSession == _sessionId) {
      _isListening = false;
    }

    print(
      'VOICE: Listening session finished '
      'session=$currentSession '
      'received=$received '
      'last="$lastRecognizedText"',
    );

    return received;
  }

  // ---------------------------------------------------------------------------
  // SCHEDULE COMPLETION
  // ---------------------------------------------------------------------------
  //
  // This is the critical fix.
  //
  // Android can report:
  //
  // notListening
  // done
  //
  // BEFORE:
  //
  // final=true
  //
  // We therefore wait 5 seconds.
  // ---------------------------------------------------------------------------

  void _scheduleCompletion({
    Duration? delay,
  }) {
    _cancelCompletionTimer();

    final Duration actualDelay =
        delay ?? _finalResultGracePeriod;

    print(
      'VOICE: Waiting '
      '${actualDelay.inMilliseconds}ms '
      'for final speech result...',
    );

    _completionTimer = Timer(
      actualDelay,
      () {
        if (_listenCompleter == null) {
          return;
        }

        if (_listenCompleter!.isCompleted) {
          return;
        }

        print(
          'VOICE: Final-result grace period expired.',
        );

        _completeListeningSession(
          _sessionId,
          result: false,
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // CANCEL COMPLETION TIMER
  // ---------------------------------------------------------------------------

  void _cancelCompletionTimer() {
    _completionTimer?.cancel();
    _completionTimer = null;
  }

  // ---------------------------------------------------------------------------
  // FINISH LISTENING SESSION
  // ---------------------------------------------------------------------------

  Future<void> _finishListeningSession(
    int session, {
    required bool result,
  }) async {
    if (session != _sessionId) {
      return;
    }

    print(
      'VOICE: Finishing session $session',
    );

    _cancelCompletionTimer();

    _isListening = false;

    // ------------------------------------------------------------
    // Stop recognizer.
    // ------------------------------------------------------------

    try {
      if (_speech.isListening) {
        await _speech.stop();
      }
    } catch (e) {
      print(
        'VOICE: Error stopping recognizer: $e',
      );
    }

    // ------------------------------------------------------------
    // Complete the waiting Future.
    // ------------------------------------------------------------

    _completeListeningSession(
      session,
      result: result,
    );
  }

  // ---------------------------------------------------------------------------
  // COMPLETE LISTENING SESSION
  // ---------------------------------------------------------------------------

  void _completeListeningSession(
    int session, {
    required bool result,
  }) {
    if (session != _sessionId) {
      return;
    }

    final Completer<bool>? completer = _listenCompleter;

    if (completer == null) {
      return;
    }

    if (completer.isCompleted) {
      return;
    }

    _isListening = false;

    completer.complete(result);
  }

  // ---------------------------------------------------------------------------
  // STOP CURRENT RECOGNITION ONLY
  // ---------------------------------------------------------------------------

  Future<void> _stopCurrentRecognitionOnly() async {
    try {
      if (_speech.isListening) {
        print(
          'VOICE: Stopping existing recognition...',
        );

        await _speech.stop();
      }
    } catch (e) {
      print(
        'VOICE: Error stopping existing recognition: $e',
      );
    }

    _isListening = false;
  }

  // ---------------------------------------------------------------------------
  // STOP LISTENING
  // ---------------------------------------------------------------------------

  Future<void> stopListening() async {
    print(
      'VOICE: Stopping listening...',
    );

    // Invalidate current session.
    _sessionId++;

    _cancelCompletionTimer();

    _isListening = false;

    try {
      if (_speech.isListening) {
        await _speech.stop();
      }
    } catch (e) {
      print(
        'VOICE STOP ERROR: $e',
      );
    }

    final Completer<bool>? completer = _listenCompleter;

    if (completer != null && !completer.isCompleted) {
      completer.complete(false);
    }

    _listenCompleter = null;
  }

  // ---------------------------------------------------------------------------
  // CANCEL LISTENING
  // ---------------------------------------------------------------------------

  Future<void> cancelListening() async {
    print(
      'VOICE: Cancelling listening...',
    );

    // Invalidate current session.
    _sessionId++;

    _cancelCompletionTimer();

    _isListening = false;

    try {
      if (_speech.isListening) {
        await _speech.cancel();
      }
    } catch (e) {
      print(
        'VOICE CANCEL ERROR: $e',
      );
    }

    final Completer<bool>? completer = _listenCompleter;

    if (completer != null && !completer.isCompleted) {
      completer.complete(false);
    }

    _listenCompleter = null;
  }

  // ---------------------------------------------------------------------------
  // STOP ALL VOICE ACTIVITY
  // ---------------------------------------------------------------------------

  Future<void> stopAll() async {
    print(
      'VOICE: Stopping all voice activity...',
    );

    await cancelListening();

    await stopSpeaking();
  }

  // ---------------------------------------------------------------------------
  // STOP SPEAKING
  // ---------------------------------------------------------------------------

  Future<void> stopSpeaking() async {
    try {
      await _tts.stop();
    } catch (e) {
      print(
        'VOICE TTS STOP ERROR: $e',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // SHORT COMMAND DETECTION
  // ---------------------------------------------------------------------------

  bool _looksLikeShortCommand(String text) {
    final String normalized = text
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .replaceAll(RegExp(r'\s+'), ' ');

    // ------------------------------------------------------------
    // Exact commands
    // ------------------------------------------------------------

    const Set<String> exactCommands = {
      'login',
      'log in',
      'sign in',
      'signin',

      'register',
      'sign up',
      'signup',

      'back',
      'go back',

      'help',
      'repeat',

      'continue',
      'next',

      'yes',
      'no',

      'home',
      'dashboard',

      'cancel',

      'stop',

      'logout',
      'log out',
      'sign out',
      'signout',
    };

    if (exactCommands.contains(normalized)) {
      return true;
    }

    // ------------------------------------------------------------
    // Common short command phrases
    // ------------------------------------------------------------

    const List<String> commandPhrases = [
      'please login',
      'please log in',
      'please register',
      'please sign in',
      'please sign up',

      'go back',
      'take me back',

      'go home',
      'take me home',

      'open dashboard',
      'go to dashboard',

      'repeat that',
      'say that again',

      'continue please',
      'next please',

      'yes please',
      'no please',

      'cancel that',

      'stop listening',
    ];

    for (final String phrase in commandPhrases) {
      if (normalized == phrase) {
        return true;
      }
    }

    return false;
  }

  // ---------------------------------------------------------------------------
  // DISPOSE
  // ---------------------------------------------------------------------------

  Future<void> dispose() async {
    print(
      'VOICE: Disposing voice service...',
    );

    _sessionId++;

    _cancelCompletionTimer();

    _isListening = false;

    try {
      await _speech.cancel();
    } catch (_) {}

    try {
      await _tts.stop();
    } catch (_) {}

    final Completer<bool>? completer = _listenCompleter;

    if (completer != null && !completer.isCompleted) {
      completer.complete(false);
    }

    _listenCompleter = null;

    _initialized = false;
  }
}