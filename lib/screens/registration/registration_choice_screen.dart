
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../login/dashboard_screen.dart';
import '../../login/login_screen.dart';
import '../../voice/voice_service.dart';

/// ===========================================================
/// VOICE REGISTRATION SCREEN
/// ===========================================================
///
/// Voice-first registration flow:
///
/// Splash
///   ↓
/// User says "Register"
///   ↓
/// Registration
///   ↓
/// Say email
///   ↓
/// Confirm email
///   ↓
/// Say password
///   ↓
/// Confirm password
///   ↓
/// Firebase account creation
///   ↓
/// Dashboard
///
/// IMPORTANT:
/// - No typing is required.
/// - Password is NEVER spoken back to the user.
/// - Password confirmation is performed internally.
/// - Firebase Authentication creates the account.
/// ===========================================================

class RegistrationChoiceScreen extends StatefulWidget {
  const RegistrationChoiceScreen({
    super.key,
  });

  @override
  State<RegistrationChoiceScreen> createState() =>
      _RegistrationChoiceScreenState();
}

class _RegistrationChoiceScreenState
    extends State<RegistrationChoiceScreen> {
  // ============================================================
  // VOICE SERVICE
  // ============================================================

  final VoiceService _voice = VoiceService();

  // ============================================================
  // FIREBASE
  // ============================================================

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  // ============================================================
  // REGISTRATION DATA
  // ============================================================

  String _email = '';
  String _password = '';

  // ============================================================
  // STATE
  // ============================================================

  bool _isInitializing = true;
  bool _isListening = false;
  bool _isLoading = false;
  bool _hasNavigated = false;

  bool _waitingForEmail = false;
  bool _waitingForEmailConfirmation = false;
  bool _waitingForPassword = false;
  bool _waitingForPasswordConfirmation = false;

  String _statusText =
      'Starting voice registration...';

  String _currentStep =
      'Starting...';

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _startRegistration();
  }

  // ============================================================
  // START REGISTRATION
  // ============================================================

  Future<void> _startRegistration() async {
    try {
      if (!mounted) {
        return;
      }

      setState(() {
        _isInitializing = true;
        _statusText =
            'Starting voice registration...';
        _currentStep =
            'Starting...';
      });

      final bool initialized =
          await _voice.initialize();

      if (!initialized) {
        if (!mounted) {
          return;
        }

        setState(() {
          _isInitializing = false;
          _statusText =
              'Voice system unavailable';
          _currentStep =
              'Voice unavailable';
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
        _statusText =
            'Voice registration ready';
        _currentStep =
            'Email address';
      });

      await Future.delayed(
        const Duration(milliseconds: 500),
      );

      if (!mounted) {
        return;
      }

      await _voice.speak(
        'Welcome to Vision Guide registration. '
        'This registration is voice controlled. '
        'No typing is required.',
      );

      await Future.delayed(
        const Duration(milliseconds: 500),
      );

      if (!mounted) {
        return;
      }

      await _requestEmail();
    } catch (e) {
      debugPrint(
        'REGISTRATION INITIALIZATION ERROR: $e',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _isInitializing = false;
        _statusText =
            'Voice registration error';
        _currentStep =
            'Error';
      });

      await _voice.speak(
        'There was a problem starting '
        'registration. Please try again.',
      );
    }
  }

  // ============================================================
  // REQUEST EMAIL
  // ============================================================

  Future<void> _requestEmail() async {
    if (!mounted ||
        _isLoading ||
        _hasNavigated) {
      return;
    }

    _waitingForEmail = false;

    if (mounted) {
      setState(() {
        _isListening = false;
        _statusText =
            'Please say your email address';
        _currentStep =
            'Email address';
      });
    }

    await _voice.speak(
      'Please say your email address.',
    );

    await Future.delayed(
      const Duration(milliseconds: 500),
    );

    if (!mounted) {
      return;
    }

    await _listenForEmail();
  }

  // ============================================================
  // LISTEN FOR EMAIL
  // ============================================================

  Future<void> _listenForEmail() async {
    if (!mounted ||
        _isLoading ||
        _hasNavigated ||
        _waitingForEmail) {
      return;
    }

    _waitingForEmail = true;

    setState(() {
      _isListening = true;
      _statusText =
          'Listening for your email...';
      _currentStep =
          'Email address';
    });

    final bool received =
        await _voice.listen(
      localeId: 'en_ZA',
      acceptPartialResults: false,
      onResult: (String text) async {
        if (!mounted ||
            _isLoading ||
            _hasNavigated ||
            !_waitingForEmail) {
          return;
        }

        _waitingForEmail = false;

        await _processEmail(text);
      },
    );

    if (!mounted ||
        _isLoading ||
        _hasNavigated ||
        !_waitingForEmail) {
      return;
    }

    if (!received) {
      _waitingForEmail = false;

      setState(() {
        _isListening = false;
        _statusText =
            'No email address heard';
      });

      await Future.delayed(
        const Duration(milliseconds: 400),
      );

      if (!mounted) {
        return;
      }

      await _voice.speak(
        'I did not hear your email address. '
        'Please say your email address again.',
      );

      await Future.delayed(
        const Duration(milliseconds: 500),
      );

      if (!mounted) {
        return;
      }

      await _listenForEmail();
    }
  }

  // ============================================================
  // PROCESS EMAIL
  // ============================================================

  Future<void> _processEmail(
    String text,
  ) async {
    await _voice.stopListening();

    _waitingForEmail = false;

    if (!mounted) {
      return;
    }

    setState(() {
      _isListening = false;
    });

    final String email =
        _cleanEmail(text);

    debugPrint(
      'REGISTRATION EMAIL: $email',
    );

    if (!_isValidEmail(email)) {
      setState(() {
        _statusText =
            'Email address not understood';
      });

      await _voice.speak(
        'I could not understand a valid '
        'email address. '
        'Please say your email address again.',
      );

      await Future.delayed(
        const Duration(milliseconds: 500),
      );

      if (!mounted) {
        return;
      }

      await _listenForEmail();

      return;
    }

    _email = email;

    if (!mounted) {
      return;
    }

    setState(() {
      _statusText =
          'Email received';
      _currentStep =
          'Confirm email';
    });

    await _voice.speak(
      'I heard $email. '
      'If this is correct, say Confirm. '
      'If it is incorrect, say Again.',
    );

    await Future.delayed(
      const Duration(milliseconds: 500),
    );

    if (!mounted) {
      return;
    }

    await _listenForEmailConfirmation();
  }

  // ============================================================
  // LISTEN FOR EMAIL CONFIRMATION
  // ============================================================

  Future<void> _listenForEmailConfirmation() async {
    if (!mounted ||
        _isLoading ||
        _hasNavigated ||
        _waitingForEmailConfirmation) {
      return;
    }

    _waitingForEmailConfirmation = true;

    setState(() {
      _isListening = true;
      _statusText =
          'Listening for confirmation...';
      _currentStep =
          'Confirm email';
    });

    final bool received =
        await _voice.listen(
      localeId: 'en_ZA',
      acceptPartialResults: true,
      onResult: (String text) async {
        if (!mounted ||
            _isLoading ||
            _hasNavigated ||
            !_waitingForEmailConfirmation) {
          return;
        }

        _waitingForEmailConfirmation = false;

        await _processEmailConfirmation(text);
      },
    );

    if (!mounted ||
        _isLoading ||
        _hasNavigated ||
        !_waitingForEmailConfirmation) {
      return;
    }

    if (!received) {
      _waitingForEmailConfirmation = false;

      setState(() {
        _isListening = false;
        _statusText =
            'Waiting for confirmation';
      });

      await _voice.speak(
        'Please say Confirm if the email '
        'address is correct, or Again to '
        'enter a different email address.',
      );

      await Future.delayed(
        const Duration(milliseconds: 400),
      );

      if (!mounted) {
        return;
      }

      await _listenForEmailConfirmation();
    }
  }

  // ============================================================
  // PROCESS EMAIL CONFIRMATION
  // ============================================================

  Future<void> _processEmailConfirmation(
    String text,
  ) async {
    await _voice.stopListening();

    _waitingForEmailConfirmation = false;

    if (!mounted) {
      return;
    }

    setState(() {
      _isListening = false;
    });

    final String command =
        text.toLowerCase().trim();

    debugPrint(
      'EMAIL CONFIRMATION: $command',
    );

    if (_containsAny(command, [
      'confirm',
      'confirmed',
      'yes',
      'correct',
      'that is correct',
      'continue',
    ])) {
      await _requestPassword();

      return;
    }

    if (_containsAny(command, [
      'again',
      'no',
      'incorrect',
      'wrong',
      'change',
      'different',
    ])) {
      _email = '';

      await _requestEmail();

      return;
    }

    await _voice.speak(
      'I did not understand. '
      'Please say Confirm if the email '
      'address is correct, or say Again '
      'to enter another email address.',
    );

    await Future.delayed(
      const Duration(milliseconds: 500),
    );

    if (!mounted) {
      return;
    }

    await _listenForEmailConfirmation();
  }

  // ============================================================
  // REQUEST PASSWORD
  // ============================================================

  Future<void> _requestPassword() async {
    if (!mounted ||
        _isLoading ||
        _hasNavigated) {
      return;
    }

    setState(() {
      _isListening = false;
      _statusText =
          'Please say your password';
      _currentStep =
          'Password';
    });

    await _voice.speak(
      'Now say your password clearly. '
      'For example, if your password contains '
      'numbers or special characters, say them '
      'as words. '
      'I will not repeat your password aloud.',
    );

    await Future.delayed(
      const Duration(milliseconds: 700),
    );

    if (!mounted) {
      return;
    }

    await _listenForPassword();
  }

  // ============================================================
  // LISTEN FOR PASSWORD
  // ============================================================

  Future<void> _listenForPassword() async {
    if (!mounted ||
        _isLoading ||
        _hasNavigated ||
        _waitingForPassword) {
      return;
    }

    _waitingForPassword = true;

    setState(() {
      _isListening = true;
      _statusText =
          'Listening for password...';
      _currentStep =
          'Password';
    });

    final bool received =
        await _voice.listen(
      localeId: 'en_ZA',
      acceptPartialResults: false,
      onResult: (String text) async {
        if (!mounted ||
            _isLoading ||
            _hasNavigated ||
            !_waitingForPassword) {
          return;
        }

        _waitingForPassword = false;

        await _processPassword(text);
      },
    );

    if (!mounted ||
        _isLoading ||
        _hasNavigated ||
        !_waitingForPassword) {
      return;
    }

    if (!received) {
      _waitingForPassword = false;

      setState(() {
        _isListening = false;
        _statusText =
            'No password heard';
      });

      await _voice.speak(
        'I did not hear your password. '
        'Please say your password again.',
      );

      await Future.delayed(
        const Duration(milliseconds: 500),
      );

      if (!mounted) {
        return;
      }

      await _listenForPassword();
    }
  }

  // ============================================================
  // PROCESS PASSWORD
  // ============================================================

  Future<void> _processPassword(
    String text,
  ) async {
    await _voice.stopListening();

    _waitingForPassword = false;

    if (!mounted) {
      return;
    }

    setState(() {
      _isListening = false;
    });

    final String password =
        _convertSpokenPassword(text);

    debugPrint(
      'REGISTRATION PASSWORD RECEIVED '
      '(length=${password.length})',
    );

    if (password.length < 6) {
      setState(() {
        _statusText =
            'Password is too short';
      });

      await _voice.speak(
        'Your password must contain at least '
        '6 characters. '
        'Please say your password again.',
      );

      await Future.delayed(
        const Duration(milliseconds: 500),
      );

      if (!mounted) {
        return;
      }

      await _listenForPassword();

      return;
    }

    _password = password;

    if (!mounted) {
      return;
    }

    setState(() {
      _statusText =
          'Password received';
      _currentStep =
          'Confirm password';
    });

    await _voice.speak(
      'Password received. '
      'Please say the same password again '
      'for confirmation. '
      'I will not repeat it aloud.',
    );

    await Future.delayed(
      const Duration(milliseconds: 700),
    );

    if (!mounted) {
      return;
    }

    await _listenForPasswordConfirmation();
  }

  // ============================================================
  // LISTEN FOR PASSWORD CONFIRMATION
  // ============================================================

  Future<void> _listenForPasswordConfirmation() async {
    if (!mounted ||
        _isLoading ||
        _hasNavigated ||
        _waitingForPasswordConfirmation) {
      return;
    }

    _waitingForPasswordConfirmation = true;

    setState(() {
      _isListening = true;
      _statusText =
          'Listening for password confirmation...';
      _currentStep =
          'Confirm password';
    });

    final bool received =
        await _voice.listen(
      localeId: 'en_ZA',
      acceptPartialResults: false,
      onResult: (String text) async {
        if (!mounted ||
            _isLoading ||
            _hasNavigated ||
            !_waitingForPasswordConfirmation) {
          return;
        }

        _waitingForPasswordConfirmation = false;

        await _processPasswordConfirmation(text);
      },
    );

    if (!mounted ||
        _isLoading ||
        _hasNavigated ||
        !_waitingForPasswordConfirmation) {
      return;
    }

    if (!received) {
      _waitingForPasswordConfirmation = false;

      setState(() {
        _isListening = false;
        _statusText =
            'No confirmation heard';
      });

      await _voice.speak(
        'I did not hear the password confirmation. '
        'Please say the same password again.',
      );

      await Future.delayed(
        const Duration(milliseconds: 500),
      );

      if (!mounted) {
        return;
      }

      await _listenForPasswordConfirmation();
    }
  }

  // ============================================================
  // PROCESS PASSWORD CONFIRMATION
  // ============================================================

  Future<void> _processPasswordConfirmation(
    String text,
  ) async {
    await _voice.stopListening();

    _waitingForPasswordConfirmation = false;

    if (!mounted) {
      return;
    }

    setState(() {
      _isListening = false;
    });

    final String confirmedPassword =
        _convertSpokenPassword(text);

    debugPrint(
      'PASSWORD CONFIRMATION RECEIVED '
      '(length=${confirmedPassword.length})',
    );

    if (confirmedPassword != _password) {
      if (!mounted) {
        return;
      }

      setState(() {
        _statusText =
            'Passwords do not match';
        _currentStep =
            'Password';
      });

      await _voice.speak(
        'The passwords do not match. '
        'Please say your password again.',
      );

      await Future.delayed(
        const Duration(milliseconds: 500),
      );

      if (!mounted) {
        return;
      }

      _password = '';

      await _listenForPassword();

      return;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _statusText =
          'Passwords match';
      _currentStep =
          'Creating account';
      _isLoading = true;
      _isListening = false;
    });

    await _voice.speak(
      'Your passwords match. '
      'Creating your Vision Guide account. '
      'Please wait.',
    );

    await Future.delayed(
      const Duration(milliseconds: 500),
    );

    if (!mounted) {
      return;
    }

    await _createFirebaseAccount();
  }

  // ============================================================
  // FIREBASE ACCOUNT CREATION
  // ============================================================

  Future<void> _createFirebaseAccount() async {
    if (_email.isEmpty ||
        _password.isEmpty) {
      return;
    }

    try {
      debugPrint(
        'REGISTRATION: Creating Firebase account.',
      );

      await _auth.createUserWithEmailAndPassword(
        email: _email.trim(),
        password: _password,
      );

      debugPrint(
        'REGISTRATION: Firebase account created.',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _statusText =
            'Registration successful';
        _currentStep =
            'Opening dashboard';
        _isLoading = false;
      });

      await _voice.speak(
        'Registration successful. '
        'Welcome to Vision Guide. '
        'Opening your dashboard.',
      );

      await Future.delayed(
        const Duration(milliseconds: 800),
      );

      if (!mounted) {
        return;
      }

      _hasNavigated = true;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) =>
              const DashboardScreen(),
        ),
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      debugPrint(
        'REGISTRATION FIREBASE ERROR: ${e.code}',
      );

      String message;

      switch (e.code) {
        case 'email-already-in-use':
          message =
              'An account already exists '
              'with this email address.';
          break;

        case 'invalid-email':
          message =
              'The email address is invalid.';
          break;

        case 'weak-password':
          message =
              'The password is too weak. '
              'Please choose a stronger password.';
          break;

        case 'operation-not-allowed':
          message =
              'Email and password registration '
              'is not enabled in Firebase.';
          break;

        case 'network-request-failed':
          message =
              'Please check your internet connection '
              'and try again.';
          break;

        case 'too-many-requests':
          message =
              'There have been too many attempts. '
              'Please wait and try again later.';
          break;

        default:
          message =
              e.message ??
              'Registration failed. '
                  'Please try again.';
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _isListening = false;
        _statusText =
            'Registration failed';
        _currentStep =
            'Registration error';
      });

      await _voice.speak(message);

      await Future.delayed(
        const Duration(milliseconds: 700),
      );

      if (!mounted) {
        return;
      }

      if (e.code == 'email-already-in-use') {
        await _voice.speak(
          'Please say Login if you want '
          'to sign in instead, or say '
          'Register to try another email address.',
        );

        await Future.delayed(
          const Duration(milliseconds: 500),
        );

        if (!mounted) {
          return;
        }

        await _listenAfterRegistrationError();

        return;
      }

      _password = '';

      setState(() {
        _currentStep =
            'Password';
        _statusText =
            'Please try your password again';
      });

      await _voice.speak(
        'Please try again. '
        'Say your password when you are ready.',
      );

      await Future.delayed(
        const Duration(milliseconds: 500),
      );

      if (!mounted) {
        return;
      }

      await _listenForPassword();
    } catch (e) {
      debugPrint(
        'UNEXPECTED REGISTRATION ERROR: $e',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _isListening = false;
        _statusText =
            'Registration error';
        _currentStep =
            'Error';
      });

      await _voice.speak(
        'Something went wrong while '
        'creating your account. '
        'Please try again.',
      );

      await Future.delayed(
        const Duration(milliseconds: 500),
      );

      if (!mounted) {
        return;
      }

      _password = '';

      setState(() {
        _currentStep =
            'Password';
        _statusText =
            'Please try your password again';
      });

      await _listenForPassword();
    }
  }

  // ============================================================
  // REGISTRATION ERROR COMMANDS
  // ============================================================

  Future<void> _listenAfterRegistrationError() async {
    final bool received =
        await _voice.listen(
      localeId: 'en_ZA',
      acceptPartialResults: true,
      onResult: (String text) async {
        if (!mounted ||
            _hasNavigated ||
            _isLoading) {
          return;
        }

        await _processRegistrationErrorCommand(
          text,
        );
      },
    );

    if (!mounted ||
        _hasNavigated ||
        _isLoading) {
      return;
    }

    if (!received) {
      await _voice.speak(
        'Please say Login or Register.',
      );

      await Future.delayed(
        const Duration(milliseconds: 400),
      );

      if (!mounted) {
        return;
      }

      await _listenAfterRegistrationError();
    }
  }

  // ============================================================
  // PROCESS ERROR COMMAND
  // ============================================================

  Future<void> _processRegistrationErrorCommand(
    String text,
  ) async {
    await _voice.stopListening();

    final String command =
        text.toLowerCase().trim();

    debugPrint(
      'REGISTRATION ERROR COMMAND: $command',
    );

    if (_containsAny(command, [
      'login',
      'log in',
      'sign in',
      'signin',
    ])) {
      if (!mounted) {
        return;
      }

      _hasNavigated = true;

      await _voice.speak(
        'Opening login.',
      );

      await Future.delayed(
        const Duration(milliseconds: 400),
      );

      if (!mounted) {
        return;
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) =>
              const LoginScreen(),
        ),
      );

      return;
    }

    if (_containsAny(command, [
      'register',
      'registration',
      'again',
      'try again',
      'new account',
    ])) {
      _email = '';
      _password = '';

      await _requestEmail();

      return;
    }

    await _voice.speak(
      'I did not understand. '
      'Please say Login or Register.',
    );

    await Future.delayed(
      const Duration(milliseconds: 400),
    );

    if (!mounted) {
      return;
    }

    await _listenAfterRegistrationError();
  }

  // ============================================================
  // CLEAN EMAIL
  // ============================================================

  String _cleanEmail(
    String text,
  ) {
    String email =
        text.toLowerCase().trim();

    email = email.replaceAll(
      RegExp(r'\s+at\s+'),
      '@',
    );

    email = email.replaceAll(
      RegExp(r'\s+at\s*'),
      '@',
    );

    email = email.replaceAll(
      RegExp(r'\s+dot\s+'),
      '.',
    );

    email = email.replaceAll(
      RegExp(r'\s+dot\s*'),
      '.',
    );

    email = email.replaceAll(
      RegExp(r'\s+underscore\s+'),
      '_',
    );

    email = email.replaceAll(
      RegExp(r'\s+underscore\s*'),
      '_',
    );

    email = email.replaceAll(
      RegExp(r'\s+dash\s+'),
      '-',
    );

    email = email.replaceAll(
      RegExp(r'\s+hyphen\s+'),
      '-',
    );

    email = email.replaceAll(
      RegExp(r'\s+'),
      '',
    );

    return email.trim();
  }

  // ============================================================
  // VALIDATE EMAIL
  // ============================================================

  bool _isValidEmail(
    String email,
  ) {
    if (email.isEmpty) {
      return false;
    }

    final RegExp emailRegex = RegExp(
      r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
    );

    return emailRegex.hasMatch(email);
  }

  // ============================================================
  // CONVERT SPOKEN PASSWORD
  // ============================================================

  String _convertSpokenPassword(
    String text,
  ) {
    String password =
        text.toLowerCase().trim();

    password = password.replaceAll(
      RegExp(r'\b(at|at sign)\b'),
      '@',
    );

    password = password.replaceAll(
      RegExp(r'\b(dot|period)\b'),
      '.',
    );

    password = password.replaceAll(
      RegExp(r'\b(underscore)\b'),
      '_',
    );

    password = password.replaceAll(
      RegExp(r'\b(dash|hyphen)\b'),
      '-',
    );

    password = password.replaceAll(
      RegExp(r'\b(plus|plus sign)\b'),
      '+',
    );

    password = password.replaceAll(
      RegExp(r'\b(hash|hashtag|number sign)\b'),
      '#',
    );

    password = password.replaceAll(
      RegExp(r'\b(dollar|dollar sign)\b'),
      r'$',
    );

    password = password.replaceAll(
      RegExp(r'\b(percent|percent sign)\b'),
      '%',
    );

    password = password.replaceAll(
      RegExp(r'\b(exclamation|exclamation mark)\b'),
      '!',
    );

    password = password.replaceAll(
      RegExp(r'\b(question mark)\b'),
      '?',
    );

    const Map<String, String> numbers = {
      'zero': '0',
      'one': '1',
      'two': '2',
      'three': '3',
      'four': '4',
      'five': '5',
      'six': '6',
      'seven': '7',
      'eight': '8',
      'nine': '9',
    };

    for (final MapEntry<String, String> entry
        in numbers.entries) {
      password = password.replaceAll(
        RegExp(
          '\\b${entry.key}\\b',
        ),
        entry.value,
      );
    }

    password = password.replaceAll(
      RegExp(r'\s+'),
      '',
    );

    return password;
  }

  // ============================================================
  // COMMAND HELPER
  // ============================================================

  bool _containsAny(
    String text,
    List<String> phrases,
  ) {
    for (final String phrase
        in phrases) {
      if (text.contains(phrase)) {
        return true;
      }
    }

    return false;
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _hasNavigated = true;

    _voice.stopAll();

    super.dispose();
  }

  // ============================================================
  // USER INTERFACE
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    const Color primaryBlue =
        Color(0xFF0047AB);

    const Color darkBlue =
        Color(0xFF003477);

    const Color lightBlue =
        Color(0xFF1565C0);

    const Color yellow =
        Color(0xFFFFC72C);

    return Scaffold(
      backgroundColor: primaryBlue,

      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 24,
            ),

            child: ConstrainedBox(
              constraints:
                  const BoxConstraints(
                maxWidth: 650,
              ),

              child: Column(
                children: [
                  // ==================================================
                  // BRANDING
                  // ==================================================

                  Semantics(
                    header: true,

                    label:
                        'Vision Guide voice registration',

                    child: Column(
                      children: [
                        Container(
                          width: 110,
                          height: 110,

                          decoration:
                              BoxDecoration(
                            color: Colors.white,
                            shape:
                                BoxShape.circle,

                            border: Border.all(
                              color: yellow,
                              width: 5,
                            ),

                            boxShadow: const [
                              BoxShadow(
                                color:
                                    Colors.black26,
                                blurRadius: 14,
                                offset:
                                    Offset(0, 6),
                              ),
                            ],
                          ),

                          child: const Icon(
                            Icons
                                .record_voice_over,
                            color:
                                primaryBlue,
                            size: 60,
                          ),
                        ),

                        const SizedBox(
                          height: 20,
                        ),

                        const Text(
                          'Vision Guide',

                          textAlign:
                              TextAlign.center,

                          style: TextStyle(
                            fontSize: 36,
                            fontWeight:
                                FontWeight.w800,
                            color:
                                Colors.white,
                            letterSpacing:
                                0.5,
                          ),
                        ),

                        const SizedBox(
                          height: 6,
                        ),

                        const Text(
                          'VOICE REGISTRATION',

                          textAlign:
                              TextAlign.center,

                          style: TextStyle(
                            fontSize: 19,
                            fontWeight:
                                FontWeight.bold,
                            color: yellow,
                            letterSpacing:
                                2,
                          ),
                        ),

                        const SizedBox(
                          height: 8,
                        ),

                        const Text(
                          'No typing required',

                          textAlign:
                              TextAlign.center,

                          style: TextStyle(
                            fontSize: 18,
                            fontWeight:
                                FontWeight.w600,
                            color:
                                Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(
                    height: 28,
                  ),

                  // ==================================================
                  // MAIN CARD
                  // ==================================================

                  Container(
                    width:
                        double.infinity,

                    padding:
                        const EdgeInsets.all(
                      22,
                    ),

                    decoration:
                        BoxDecoration(
                      color:
                          Colors.white,

                      borderRadius:
                          BorderRadius.circular(
                        28,
                      ),

                      boxShadow: const [
                        BoxShadow(
                          color:
                              Colors.black26,
                          blurRadius: 18,
                          offset:
                              Offset(0, 8),
                        ),
                      ],
                    ),

                    child: Column(
                      children: [
                        // ============================================
                        // VOICE STATUS
                        // ============================================

                        Semantics(
                          liveRegion: true,

                          label:
                              'Registration status: '
                              '$_statusText',

                          child:
                              AnimatedContainer(
                            duration:
                                const Duration(
                              milliseconds: 250,
                            ),

                            width:
                                double.infinity,

                            padding:
                                const EdgeInsets
                                    .symmetric(
                              horizontal: 18,
                              vertical: 20,
                            ),

                            decoration:
                                BoxDecoration(
                              color:
                                  _isListening
                                      ? yellow
                                      : const Color(
                                          0xFFEAF2FF,
                                        ),

                              borderRadius:
                                  BorderRadius
                                      .circular(
                                20,
                              ),

                              border:
                                  Border.all(
                                color:
                                    _isListening
                                        ? darkBlue
                                        : primaryBlue,
                                width: 3,
                              ),
                            ),

                            child: Column(
                              children: [
                                Container(
                                  width: 76,
                                  height: 76,

                                  decoration:
                                      BoxDecoration(
                                    color:
                                        _isListening
                                            ? primaryBlue
                                            : lightBlue,

                                    shape:
                                        BoxShape
                                            .circle,
                                  ),

                                  child: Icon(
                                    _isListening
                                        ? Icons.mic
                                        : Icons
                                            .record_voice_over,

                                    color:
                                        Colors.white,

                                    size: 42,
                                  ),
                                ),

                                const SizedBox(
                                  height: 14,
                                ),

                                Text(
                                  _statusText,

                                  textAlign:
                                      TextAlign
                                          .center,

                                  style:
                                      const TextStyle(
                                    fontSize: 22,
                                    fontWeight:
                                        FontWeight
                                            .w800,
                                    color:
                                        Colors.black,
                                  ),
                                ),

                                if (_isListening) ...[
                                  const SizedBox(
                                    height: 10,
                                  ),

                                  const Text(
                                    'Listening...',
                                    style:
                                        TextStyle(
                                      fontSize: 18,
                                      fontWeight:
                                          FontWeight
                                              .bold,
                                      color:
                                          darkBlue,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(
                          height: 22,
                        ),

                        // ============================================
                        // CURRENT STEP
                        // ============================================

                        Semantics(
                          liveRegion: true,

                          label:
                              'Current registration step: '
                              '$_currentStep',

                          child: Container(
                            width:
                                double.infinity,

                            padding:
                                const EdgeInsets
                                    .all(
                              18,
                            ),

                            decoration:
                                BoxDecoration(
                              color:
                                  const Color(
                                0xFFEAF2FF,
                              ),

                              borderRadius:
                                  BorderRadius
                                      .circular(
                                18,
                              ),

                              border:
                                  Border.all(
                                color:
                                    primaryBlue,
                                width: 2,
                              ),
                            ),

                            child: Column(
                              children: [
                                const Text(
                                  'CURRENT STEP',

                                  style:
                                      TextStyle(
                                    fontSize: 15,
                                    fontWeight:
                                        FontWeight
                                            .bold,
                                    color:
                                        darkBlue,
                                    letterSpacing:
                                        1,
                                  ),
                                ),

                                const SizedBox(
                                  height: 8,
                                ),

                                Text(
                                  _currentStep,

                                  textAlign:
                                      TextAlign
                                          .center,

                                  style:
                                      const TextStyle(
                                    fontSize: 23,
                                    fontWeight:
                                        FontWeight
                                            .w800,
                                    color:
                                        Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // ============================================
                        // EMAIL
                        // ============================================

                        if (_email.isNotEmpty) ...[
                          const SizedBox(
                            height: 20,
                          ),

                          Semantics(
                            label:
                                'Email address entered: $_email',

                            child: Container(
                              width:
                                  double.infinity,

                              padding:
                                  const EdgeInsets
                                      .all(
                                18,
                              ),

                              decoration:
                                  BoxDecoration(
                                color:
                                    const Color(
                                  0xFFEAF2FF,
                                ),

                                borderRadius:
                                    BorderRadius
                                        .circular(
                                  18,
                                ),

                                border:
                                    Border.all(
                                  color:
                                      primaryBlue,
                                  width: 2,
                                ),
                              ),

                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment
                                        .start,

                                children: [
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons
                                            .email,
                                        color:
                                            primaryBlue,
                                        size: 28,
                                      ),

                                      const SizedBox(
                                        width: 10,
                                      ),

                                      const Text(
                                        'EMAIL ADDRESS',
                                        style:
                                            TextStyle(
                                          fontSize:
                                              15,
                                          fontWeight:
                                              FontWeight
                                                  .bold,
                                          color:
                                              darkBlue,
                                          letterSpacing:
                                              0.8,
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(
                                    height: 10,
                                  ),

                                  Text(
                                    _email,

                                    style:
                                        const TextStyle(
                                      fontSize: 22,
                                      fontWeight:
                                          FontWeight
                                              .w700,
                                      color:
                                          Colors
                                              .black,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],

                        const SizedBox(
                          height: 20,
                        ),

                        // ============================================
                        // SECURITY MESSAGE
                        // ============================================

                        Semantics(
                          label:
                              'Security instruction. '
                              'Your password is never displayed '
                              'or spoken back to you.',

                          child: Container(
                            width:
                                double.infinity,

                            padding:
                                const EdgeInsets
                                    .all(
                              16,
                            ),

                            decoration:
                                BoxDecoration(
                              color:
                                  const Color(
                                0xFFFFF8DD,
                              ),

                              borderRadius:
                                  BorderRadius
                                      .circular(
                                18,
                              ),

                              border:
                                  Border.all(
                                color:
                                    yellow,
                                width: 3,
                              ),
                            ),

                            child: const Row(
                              crossAxisAlignment:
                                  CrossAxisAlignment
                                      .start,

                              children: [
                                Icon(
                                  Icons.security,
                                  size: 30,
                                  color:
                                      darkBlue,
                                ),

                                SizedBox(
                                  width: 12,
                                ),

                                Expanded(
                                  child: Text(
                                    'For your security, '
                                    'your password is never '
                                    'displayed or spoken back '
                                    'to you.',

                                    style:
                                        TextStyle(
                                      fontSize: 17,
                                      fontWeight:
                                          FontWeight
                                              .w700,
                                      color:
                                          Colors
                                              .black,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(
                          height: 24,
                        ),

                        // ============================================
                        // LOADING
                        // ============================================

                        if (_isLoading)
                          const Column(
                            children: [
                              SizedBox(
                                width: 48,
                                height: 48,

                                child:
                                    CircularProgressIndicator(
                                  strokeWidth: 5,
                                  color:
                                      primaryBlue,
                                ),
                              ),

                              SizedBox(
                                height: 14,
                              ),

                              Text(
                                'Creating account...',
                                style:
                                    TextStyle(
                                  fontSize: 20,
                                  fontWeight:
                                      FontWeight
                                          .bold,
                                  color:
                                      darkBlue,
                                ),
                              ),
                            ],
                          ),

                        // ============================================
                        // VOICE INSTRUCTION
                        // ============================================

                        if (!_isLoading)
                          Semantics(
                            liveRegion: true,

                            label:
                                'Voice instruction',

                            child: Container(
                              width:
                                  double.infinity,

                              padding:
                                  const EdgeInsets
                                      .all(
                                16,
                              ),

                              decoration:
                                  BoxDecoration(
                                color:
                                    darkBlue,

                                borderRadius:
                                    BorderRadius
                                        .circular(
                                  18,
                                ),
                              ),

                              child: Text(
                                _isInitializing
                                    ? 'Starting voice assistant...'
                                    : _isListening
                                        ? 'Listening...'
                                        : 'Please follow the spoken instructions.',

                                textAlign:
                                    TextAlign.center,

                                style:
                                    const TextStyle(
                                  fontSize: 19,
                                  fontWeight:
                                      FontWeight
                                          .w700,
                                  color:
                                      Colors.white,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(
                    height: 20,
                  ),

                  // ==================================================
                  // ACCESSIBILITY FOOTER
                  // ==================================================

                  Semantics(
                    label:
                        'Voice-first accessible registration. '
                        'Large text and high contrast interface.',

                    child: const Text(
                      'VOICE-FIRST ACCESSIBLE REGISTRATION',

                      textAlign:
                          TextAlign.center,

                      style: TextStyle(
                        fontSize: 14,
                        fontWeight:
                            FontWeight.bold,
                        color:
                            Colors.white70,
                        letterSpacing:
                            1.2,
                      ),
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

