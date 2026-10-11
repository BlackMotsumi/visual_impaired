import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../registration/registration_choice_screen.dart';
import '../../services/speech_services.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  // --------------------------------------------------
  // SERVICES
  // --------------------------------------------------

  final FlutterTts _tts = FlutterTts();
  final SpeechService _speechService = SpeechService();

  // --------------------------------------------------
  // UI STATE
  // --------------------------------------------------

  String spokenWords = '';

  bool _speechInitialized = false;
  bool _isNavigating = false;

  // --------------------------------------------------
  // ANIMATION
  // --------------------------------------------------

  late AnimationController _controller;
  late Animation<double> _animation;

  // --------------------------------------------------
  // INITIALIZATION
  // --------------------------------------------------

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _animation = Tween<double>(
      begin: 0.9,
      end: 1.15,
    ).animate(_controller);

    _controller.repeat(reverse: true);

    _initialize();
  }

  Future<void> _initialize() async {
    await _setupTts();

    if (!mounted) return;

    await _speakWelcome();

    if (!mounted) return;

    await _initializeSpeech();
  }

  // --------------------------------------------------
  // TEXT TO SPEECH SETUP
  // --------------------------------------------------

  Future<void> _setupTts() async {
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.45);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
  }

  // --------------------------------------------------
  // WELCOME MESSAGE
  // --------------------------------------------------

  Future<void> _speakWelcome() async {
    await _tts.stop();

    await _tts.speak(
      'Welcome to Vision Guide. '
      'Tap anywhere on the screen or say Start Registration to begin.',
    );
  }

  // --------------------------------------------------
  // SPEECH INITIALIZATION
  // --------------------------------------------------

  Future<void> _initializeSpeech() async {
    try {
      final available = await _speechService.initialize();

      if (!mounted) return;

      if (available) {
        setState(() {
          _speechInitialized = true;
          spokenWords = 'Listening...';
        });

        _listen();
      } else {
        setState(() {
          spokenWords = 'Speech recognition is unavailable.';
        });
      }
    } catch (e) {
      debugPrint('WELCOME SPEECH ERROR: $e');

      if (!mounted) return;

      setState(() {
        spokenWords = 'Speech recognition is unavailable.';
      });
    }
  }

  // --------------------------------------------------
  // LISTEN FOR START REGISTRATION
  // --------------------------------------------------

  void _listen() {
  if (!_speechInitialized || _isNavigating || !mounted) {
    return;
  }

  _speechService.startListening(
    onResult: (String text) {
      if (!mounted || _isNavigating) {
        return;
      }

      final cleanedText = text.trim();

      if (cleanedText.isEmpty) {
        return;
      }

      setState(() {
        spokenWords = cleanedText;
      });

      final command = cleanedText.toLowerCase();

      debugPrint('WELCOME VOICE COMMAND: $command');

      if (command.contains('start registration')) {
        _openRegistration();
      }
    },
  );
}

  // --------------------------------------------------
  // OPEN REGISTRATION
  // --------------------------------------------------

  Future<void> _openRegistration() async {
    if (_isNavigating || !mounted) {
      return;
    }

    _isNavigating = true;

    // Stop microphone.
    await _speechService.stopListening();

    // Stop current TTS.
    await _tts.stop();

    if (!mounted) return;

    // Tell user what is happening.
    await _tts.speak('Opening registration.');

    await Future.delayed(
      const Duration(milliseconds: 800),
    );

    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const RegistrationChoiceScreen(),
      ),
    );
  }

  // --------------------------------------------------
  // TAP ANYWHERE
  // --------------------------------------------------

  Future<void> _handleTap() async {
    await _openRegistration();
  }

  // --------------------------------------------------
  // DISPOSE
  // --------------------------------------------------

  @override
  void dispose() {
    _speechService.stopListening();
    _tts.stop();
    _controller.dispose();

    super.dispose();
  }

  // --------------------------------------------------
  // UI
  // --------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _handleTap,

        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(30),

              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,

                children: [
                  // MICROPHONE
                  ScaleTransition(
                    scale: _animation,

                    child: const Icon(
                      Icons.mic,
                      size: 120,
                      color: Color(0xFF0B6E4F),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // TITLE
                  const Text(
                    'Vision Guide',
                    textAlign: TextAlign.center,

                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0B6E4F),
                    ),
                  ),

                  const SizedBox(height: 25),

                  // INSTRUCTIONS
                  const Text(
                    'Tap anywhere\n'
                    'or\n'
                    'Say\n'
                    '"Start Registration"',
                    textAlign: TextAlign.center,

                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 30),

                  // SPEECH RESULT
                  Text(
                    spokenWords.isEmpty
                        ? 'Listening...'
                        : spokenWords,

                    textAlign: TextAlign.center,

                    style: const TextStyle(
                      fontSize: 20,
                      color: Color(0xFF0B6E4F),
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 40),

                  // DESCRIPTION
                  const Text(
                    'Designed for visually impaired students at\n'
                    'Central University of Technology',

                    textAlign: TextAlign.center,

                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}