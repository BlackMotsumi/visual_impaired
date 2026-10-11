import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../../services/speech_services.dart';
//import '../../services/registration_service.dart';
import 'voice_password_screen.dart';

class VoiceRegistrationScreen extends StatefulWidget {
  const VoiceRegistrationScreen({super.key});

  @override
  State<VoiceRegistrationScreen> createState() =>
      _VoiceRegistrationScreenState();
}

class _VoiceRegistrationScreenState
    extends State<VoiceRegistrationScreen> {
  final SpeechService _speechService = SpeechService();
  final FlutterTts _tts = FlutterTts();

  String _fullName = '';
  String _studentNumber = '';
  String _email = '';

  String _spokenWords = '';
  bool _isListening = false;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _initializeSpeech();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _speak(
        "Welcome to voice registration. "
        "I will ask you for your full name, student number, and email address.",
      );
    });
  }

  Future<void> _initializeSpeech() async {
    final available = await _speechService.initialize();

    if (!available && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Speech recognition is not available on this device.',
          ),
        ),
      );
    }
  }

  Future<void> _speak(String message) async {
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.45);
    await _tts.awaitSpeakCompletion(true);
    await _tts.speak(message);
  }

  Future<String> _listenForAnswer(String prompt) async {
  await _speak(prompt);

  if (!mounted) return '';

  setState(() {
    _isListening = true;
    _spokenWords = '';
  });

  final result = await _speechService.listenForResult(
    listenFor: const Duration(seconds: 8),
    pauseFor: const Duration(seconds: 2),
  );

  if (!mounted) return '';

  setState(() {
    _isListening = false;
    _spokenWords = result;
  });

  print('FINAL ANSWER RECEIVED: "$result"');

  return result;
}

  Future<void> _startRegistration() async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      // STEP 1: Full name
      _fullName = await _listenForAnswer(
        "Please say your full name.",
      );

      if (_fullName.isEmpty) {
        await _speak(
          "I did not hear your full name. Let's try again.",
        );

        if (mounted) {
          setState(() {
            _isProcessing = false;
          });
        }

        return;
      }

      // STEP 2: Student number
      _studentNumber = await _listenForAnswer(
        "Please say your student number.",
      );

      if (_studentNumber.isEmpty) {
        await _speak(
          "I did not hear your student number. Let's try again.",
        );

        if (mounted) {
          setState(() {
            _isProcessing = false;
          });
        }

        return;
      }

      // STEP 3: Email
      _email = await _listenForAnswer(
        "Please say your email address.",
      );

      if (_email.isEmpty) {
        await _speak(
          "I did not hear your email address. Let's try again.",
        );

        if (mounted) {
          setState(() {
            _isProcessing = false;
          });
        }

        return;
      }

      // STEP 4: Confirm details
      await _confirmDetails();
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _confirmDetails() async {
    await _tts.speak(
      "I heard the following details. "
      "Full name: $_fullName. "
      "Student number: $_studentNumber. "
      "Email: $_email. "
      "Are these details correct? "
      "Please say yes or no.",
    );

    final confirmation = await _listenForAnswer(
      "Are these details correct? Please say yes or no.",
    );

    final answer = confirmation.toLowerCase();

    if (answer.contains('yes') ||
        answer.contains('correct')) {
      await _tts.speak(
        "Thank you. Your details have been confirmed.",
      );

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => VoicePasswordScreen(
            fullName: _fullName,
            studentNumber: _studentNumber,
            email: _email,
          ),
        ),
      );
    } else {
      await _tts.speak(
        "Okay. Let's start again and capture your details.",
      );

      if (!mounted) return;

      setState(() {
        _fullName = '';
        _studentNumber = '';
        _email = '';
        _spokenWords = '';
      });

      await _startRegistration();
    }
  }

  @override
  void dispose() {
    _speechService.stopListening();
    _tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Voice Registration'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(25),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.mic,
                size: 100,
                color: Color(0xFF0B6E4F),
              ),

              const SizedBox(height: 30),

              const Text(
                'Voice Registration',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 20),

              Text(
                _isListening
                    ? 'Listening...'
                    : 'Tap the button to begin',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                ),
              ),

              const SizedBox(height: 30),

              if (_spokenWords.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: const Color(0xFF0B6E4F),
                    ),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Text(
                    _spokenWords,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 20,
                    ),
                  ),
                ),

              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                height: 65,
                child: ElevatedButton.icon(
                  onPressed:
                      _isProcessing ? null : _startRegistration,
                  icon: const Icon(Icons.mic),
                  label: Text(
                    _isProcessing
                        ? 'Processing...'
                        : 'Start Voice Registration',
                    style: const TextStyle(
                      fontSize: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}