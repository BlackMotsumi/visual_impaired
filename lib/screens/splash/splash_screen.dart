
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:visual_impaired/login/login_screen.dart';
import 'package:visual_impaired/login/dashboard_screen.dart';
import 'package:visual_impaired/screens/registration/registration_choice_screen.dart';
import 'package:visual_impaired/voice/voice_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final VoiceService _voice = VoiceService();

  bool _isInitializing = true;
  bool _isListening = false;
  bool _hasNavigated = false;
  bool _isProcessingCommand = false;

  String _statusText = 'Starting Vision Guide...';

  // ======================================================
  // INITIALIZATION
  // ======================================================

  @override
  void initState() {
    super.initState();
    _startSplash();
  }

  Future<void> _startSplash() async {
    try {
      if (!mounted) {
        return;
      }

      setState(() {
        _isInitializing = true;
        _statusText = 'Starting voice assistant...';
      });

      // --------------------------------------------------
      // INITIALIZE VOICE SERVICE
      // --------------------------------------------------

      final bool initialized = await _voice.initialize();

      if (!initialized) {
        if (!mounted) {
          return;
        }

        setState(() {
          _isInitializing = false;
          _statusText = 'Voice system unavailable';
        });

        await _voice.speak(
          'I cannot access the voice system. '
          'Please check your microphone permission '
          'and try again.',
        );

        return;
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _isInitializing = false;
        _statusText = 'Checking your account...';
      });

      print('SPLASH: Checking authentication...');

      // --------------------------------------------------
      // CHECK FIREBASE AUTHENTICATION
      // --------------------------------------------------

      final User? user = FirebaseAuth.instance.currentUser;

      // ==================================================
      // USER ALREADY LOGGED IN
      // ==================================================

      if (user != null) {
        print('SPLASH: User already logged in.');

        if (!mounted) {
          return;
        }

        setState(() {
          _statusText = 'Welcome back';
        });

        await _voice.speak(
          'Welcome back to Vision Guide. '
          'You are already logged in. '
          'Opening your dashboard.',
        );

        await Future.delayed(
          const Duration(milliseconds: 700),
        );

        if (!mounted) {
          return;
        }

        _hasNavigated = true;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const DashboardScreen(),
          ),
        );

        return;
      }

      // ==================================================
      // NO USER LOGGED IN
      // ==================================================

      print('SPLASH: No logged-in user.');

      if (!mounted) {
        return;
      }

      setState(() {
        _statusText = 'Say Login or Register';
      });

      // --------------------------------------------------
      // WELCOME INSTRUCTION
      // --------------------------------------------------

      await _voice.speak(
        'Welcome to Vision Guide. '
        'Please say Login to sign in, '
        'or Register to create a new account.',
      );

      await Future.delayed(
        const Duration(milliseconds: 500),
      );

      if (!mounted) {
        return;
      }

      // --------------------------------------------------
      // START LISTENING
      // --------------------------------------------------

      await _keepListening();
    } catch (e) {
      print('SPLASH INITIALIZATION ERROR: $e');

      if (!mounted) {
        return;
      }

      setState(() {
        _isInitializing = false;
        _statusText = 'Voice assistant error';
      });

      await _voice.speak(
        'There was a problem starting '
        'Vision Guide. Please try again.',
      );
    }
  }

  // ======================================================
  // CONTINUOUS LISTENING
  // ======================================================

  Future<void> _keepListening() async {
    if (!mounted ||
        _hasNavigated ||
        _isProcessingCommand) {
      return;
    }

    setState(() {
      _isListening = true;
      _statusText = 'Listening...';
    });

    print('SPLASH: Starting listening...');

    await _voice.listen(
      acceptPartialResults: true,
      onResult: (text) async {
        if (!mounted ||
            _hasNavigated ||
            _isProcessingCommand) {
          return;
        }

        _isProcessingCommand = true;

        print('SPLASH USER SAID: $text');

        await _processCommand(text);
      },
    );

    if (!mounted ||
        _hasNavigated ||
        _isProcessingCommand) {
      return;
    }

    setState(() {
      _isListening = false;
    });

    await Future.delayed(
      const Duration(milliseconds: 300),
    );

    if (!mounted ||
        _hasNavigated ||
        _isProcessingCommand) {
      return;
    }

    await _keepListening();
  }

  // ======================================================
  // PROCESS VOICE COMMAND
  // ======================================================

  Future<void> _processCommand(String text) async {
    final String command = text.toLowerCase().trim();

    print('SPLASH COMMAND: $command');

    // Stop listening while processing the command.
    await _voice.stopListening();

    if (!mounted || _hasNavigated) {
      _isProcessingCommand = false;
      return;
    }

    setState(() {
      _isListening = false;
    });

    // ====================================================
    // LOGIN
    // ====================================================

    if (_containsAny(command, [
      'login',
      'log in',
      'sign in',
      'signin',
      'i want to login',
      'i want to log in',
      'i want to sign in',
    ])) {
      await _openLogin();
      return;
    }

    // ====================================================
    // REGISTER
    // ====================================================

    if (_containsAny(command, [
      'register',
      'registration',
      'sign up',
      'signup',
      'create account',
      'new account',
      'i want to register',
    ])) {
      await _openRegistration();
      return;
    }

    // ====================================================
    // HELP
    // ====================================================

    if (_containsAny(command, [
      'help',
      'what can i say',
      'what should i say',
      'commands',
    ])) {
      await _voice.speak(
        'You can say Login if you already '
        'have an account. '
        'You can say Register if you are '
        'a new user. '
        'You can say Repeat to hear '
        'the instructions again.',
      );

      await Future.delayed(
        const Duration(milliseconds: 500),
      );

      if (!mounted || _hasNavigated) {
        _isProcessingCommand = false;
        return;
      }

      _isProcessingCommand = false;

      await _keepListening();
      return;
    }

    // ====================================================
    // REPEAT
    // ====================================================

    if (_containsAny(command, [
      'repeat',
      'say that again',
      'again',
    ])) {
      await _voice.speak(
        'Please say Login to sign in, '
        'or Register to create a new account.',
      );

      await Future.delayed(
        const Duration(milliseconds: 400),
      );

      if (!mounted || _hasNavigated) {
        _isProcessingCommand = false;
        return;
      }

      _isProcessingCommand = false;

      await _keepListening();
      return;
    }

    // ====================================================
    // UNKNOWN COMMAND
    // ====================================================

    await _voice.speak(
      'I did not understand that. '
      'Please say Login to sign in, '
      'or Register to create a new account.',
    );

    await Future.delayed(
      const Duration(milliseconds: 500),
    );

    if (!mounted || _hasNavigated) {
      _isProcessingCommand = false;
      return;
    }

    _isProcessingCommand = false;

    await _keepListening();
  }

  // ======================================================
  // OPEN LOGIN
  // ======================================================

  Future<void> _openLogin() async {
    if (!mounted || _hasNavigated) {
      _isProcessingCommand = false;
      return;
    }

    print('SPLASH: Opening LoginScreen...');

    // Stop voice recognition before navigation.
    await _voice.stopListening();

    if (!mounted) {
      _isProcessingCommand = false;
      return;
    }

    setState(() {
      _isListening = false;
      _statusText = 'Opening login...';
    });

    // Prevent additional commands.
    _hasNavigated = true;
    _isProcessingCommand = false;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const LoginScreen(),
      ),
    );
  }

  // ======================================================
  // OPEN REGISTRATION
  // ======================================================

  Future<void> _openRegistration() async {
    if (!mounted || _hasNavigated) {
      _isProcessingCommand = false;
      return;
    }

    print(
      'SPLASH: Opening RegistrationChoiceScreen...',
    );

    // Stop voice recognition before navigation.
    await _voice.stopListening();

    if (!mounted) {
      _isProcessingCommand = false;
      return;
    }

    setState(() {
      _isListening = false;
      _statusText = 'Opening registration...';
    });

    // Prevent additional commands.
    _hasNavigated = true;
    _isProcessingCommand = false;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const RegistrationChoiceScreen(),
      ),
    );
  }

  // ======================================================
  // COMMAND MATCHING
  // ======================================================

  bool _containsAny(
    String text,
    List<String> phrases,
  ) {
    for (final String phrase in phrases) {
      if (text.contains(phrase)) {
        return true;
      }
    }

    return false;
  }

  // ======================================================
  // DISPOSE
  // ======================================================

  @override
  void dispose() {
    _hasNavigated = true;

    _voice.stopAll();

    super.dispose();
  }

  // ======================================================
  // USER INTERFACE
  // ======================================================

  @override
  Widget build(BuildContext context) {
    // Use the global CUT-inspired blue from AppTheme.
    final Color primaryBlue =
        Theme.of(context).colorScheme.primary;

    // CUT-inspired yellow for listening/attention.
    const Color yellow = Color(0xFFFFC72C);

    return Scaffold(
      backgroundColor: primaryBlue,

      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 30,
              vertical: 30,
            ),

            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [

                // ==================================================
                // CUT LOGO
                // ==================================================

                Semantics(
                  label:
                      'Central University of Technology logo',

                  child: Image.asset(
                    'assets/images/cut_logo.png',
                    width: 150,
                    height: 150,
                    fit: BoxFit.contain,
                  ),
                ),

                const SizedBox(height: 25),

                // ==================================================
                // APP NAME
                // ==================================================

                const Text(
                  'Vision Guide',
                  textAlign: TextAlign.center,

                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),

                const SizedBox(height: 12),

                // ==================================================
                // APP DESCRIPTION
                // ==================================================

                const Text(
                  'Accessible Navigation',
                  textAlign: TextAlign.center,

                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 50),

                // ==================================================
                // MICROPHONE / LISTENING INDICATOR
                // ==================================================

                AnimatedContainer(
                  duration: const Duration(
                    milliseconds: 300,
                  ),

                  width: _isListening ? 120 : 100,
                  height: _isListening ? 120 : 100,

                  decoration: BoxDecoration(
                    shape: BoxShape.circle,

                    color: _isListening
                        ? yellow
                        : Colors.white.withValues(
                            alpha: 0.20,
                          ),

                    border: Border.all(
                      color: Colors.white,
                      width: 3,
                    ),

                    boxShadow: _isListening
                        ? [
                            BoxShadow(
                              color: yellow.withValues(
                                alpha: 0.45,
                              ),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ]
                        : null,
                  ),

                  child: Icon(
                    _isListening
                        ? Icons.mic
                        : Icons.mic_none,

                    size: 55,

                    color: _isListening
                        ? Colors.black
                        : Colors.white,
                  ),
                ),

                const SizedBox(height: 30),

                // ==================================================
                // STATUS
                // ==================================================

                Semantics(
                  liveRegion: true,
                  label: _statusText,

                  child: Text(
                    _statusText,
                    textAlign: TextAlign.center,

                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 21,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // ==================================================
                // LISTENING MESSAGE
                // ==================================================

                if (_isListening)
                  const Text(
                    'Listening for your instruction...',
                    textAlign: TextAlign.center,

                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),

                // ==================================================
                // INITIALIZATION INDICATOR
                // ==================================================

                if (_isInitializing) ...[
                  const SizedBox(height: 30),

                  const SizedBox(
                    width: 35,
                    height: 35,

                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      color: yellow,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

