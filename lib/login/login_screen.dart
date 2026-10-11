import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'dashboard_screen.dart';
import 'package:visual_impaired/voice/voice_service.dart';
import '../screens/splash/splash_screen.dart';

/// Voice-first Login screen.
///
/// Flow:
///
/// Splash
///   ↓
/// User says "Login"
///   ↓
/// Login screen
///   ↓
/// User speaks email
///   ↓
/// User types password
///   ↓
/// User presses Done
///   ↓
/// User says "Login"
///   ↓
/// Firebase authentication
///   ↓
/// Dashboard
///
/// IMPORTANT:
/// The password is NEVER spoken or sent to speech recognition.
class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // ============================================================
  // CONTROLLERS
  // ============================================================

  final TextEditingController _emailController =
      TextEditingController();

  final TextEditingController _passwordController =
      TextEditingController();

  final FocusNode _passwordFocusNode =
      FocusNode();

  // ============================================================
  // VOICE SERVICE
  // ============================================================

  final VoiceService _voice = VoiceService();

  // ============================================================
  // STATE
  // ============================================================

  bool _isInitializing = true;
  bool _isListening = false;
  bool _isLoading = false;
  bool _hasNavigated = false;
  bool _waitingForEmail = false;
  bool _waitingForLoginCommand = false;
  bool _passwordEntered = false;

  String _statusText =
      'Starting voice assistant...';

  // ============================================================
  // INIT STATE
  // ============================================================

  @override
  void initState() {
    super.initState();

    _startLoginScreen();
  }

  // ============================================================
  // START LOGIN SCREEN
  // ============================================================

  Future<void> _startLoginScreen() async {
    try {
      if (!mounted) {
        return;
      }

      setState(() {
        _isInitializing = true;
        _statusText =
            'Starting voice assistant...';
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
            'Listening for your email';
      });

      await Future.delayed(
        const Duration(milliseconds: 500),
      );

      if (!mounted) {
        return;
      }

      await _voice.speak(
        'Login selected. '
        'Please say your email address. '
        'If you forgot your email address, '
        'say Back to return to the main screen.',
      );

      await Future.delayed(
        const Duration(milliseconds: 500),
      );

      if (!mounted) {
        return;
      }

      await _listenForEmail();
    } catch (e) {
      debugPrint(
        'LOGIN SCREEN INITIALIZATION ERROR: $e',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _isInitializing = false;
        _statusText =
            'Voice assistant error';
      });

      await _voice.speak(
        'There was a problem starting '
        'the login system. '
        'Please try again.',
      );
    }
  }

  // ============================================================
  // LISTEN FOR EMAIL
  // ============================================================

  Future<void> _listenForEmail() async {
    if (!mounted ||
        _isLoading ||
        _hasNavigated) {
      return;
    }

    if (_waitingForEmail) {
      return;
    }

    _waitingForEmail = true;

    setState(() {
      _isListening = true;
      _statusText =
          'Listening for your email...';
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

      await Future.delayed(
        const Duration(milliseconds: 400),
      );

      if (!mounted ||
          _isLoading ||
          _hasNavigated) {
        return;
      }

      await _voice.speak(
        'I did not hear your email address. '
        'Please say your email address. '
        'If you forgot your email address, '
        'say Back to return to the main screen.',
      );

      await Future.delayed(
        const Duration(milliseconds: 400),
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

    final String command =
        text.toLowerCase().trim();

    debugPrint(
      'LOGIN EMAIL/COMMAND: $command',
    );

    if (_containsAny(command, [
      'back',
      'go back',
      'forgot email',
      'forgot my email',
      'forgotten email',
      'i forgot my email',
      'return',
      'main screen',
      'start screen',
    ])) {
      await _returnToSplash();

      return;
    }

    final String email =
        _cleanEmail(text);

    debugPrint(
      'EMAIL FROM VOICE: $email',
    );

    if (!_isValidEmail(email)) {
      await _voice.speak(
        'I could not understand a valid '
        'email address. '
        'Please say your email address again. '
        'If you forgot your email address, '
        'say Back.',
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

    _emailController.text = email;

    if (!mounted) {
      return;
    }

    setState(() {
      _statusText =
          'Email received';
    });

    await _voice.speak(
      'I heard your email address. '
      'Please type your password. '
      'For your security, do not speak '
      'your password aloud. '
      'When you have finished typing '
      'your password, press Done on the keyboard.',
    );

    await Future.delayed(
      const Duration(milliseconds: 700),
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _statusText =
          'Type your password';
    });

    await Future.delayed(
      const Duration(milliseconds: 300),
    );

    if (!mounted) {
      return;
    }

    FocusScope.of(context).requestFocus(
      _passwordFocusNode,
    );
  }

  // ============================================================
  // RETURN TO SPLASH
  // ============================================================

  Future<void> _returnToSplash() async {
    if (!mounted ||
        _hasNavigated) {
      return;
    }

    debugPrint(
      'LOGIN: Returning to SplashScreen.',
    );

    _waitingForEmail = false;
    _waitingForLoginCommand = false;

    setState(() {
      _isListening = false;
      _statusText =
          'Returning to main screen...';
    });

    await _voice.stopListening();

    if (!mounted) {
      return;
    }

    await _voice.speak(
      'Returning to the main screen.',
    );

    if (!mounted) {
      return;
    }

    await Future.delayed(
      const Duration(milliseconds: 300),
    );

    if (!mounted) {
      return;
    }

    _hasNavigated = true;

    await Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute<void>(
        builder: (_) => SplashScreen(),
      ),
      (Route<dynamic> route) => false,
    );
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
      RegExp(r'\s+dot\s+'),
      '.',
    );

    email = email.replaceAll(
      RegExp(r'\s+underscore\s+'),
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

    email = email.replaceAll(
      ' underscore ',
      '_',
    );

    email = email.replaceAll(
      ' dash ',
      '-',
    );

    email = email.replaceAll(
      ' hyphen ',
      '-',
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
  // PASSWORD FIELD FINISHED
  // ============================================================

  Future<void> _passwordFinished() async {
    if (!mounted ||
        _isLoading ||
        _hasNavigated) {
      return;
    }

    final String password =
        _passwordController.text;

    if (password.isEmpty) {
      await _voice.speak(
        'Your password is empty. '
        'Please type your password.',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _statusText =
            'Type your password';
      });

      FocusScope.of(context).requestFocus(
        _passwordFocusNode,
      );

      return;
    }

    _passwordEntered = true;

    if (!mounted) {
      return;
    }

    setState(() {
      _statusText =
          'Password received. Say Login.';
    });

    await _voice.speak(
      'Password received. '
      'Please say Login to continue.',
    );

    await Future.delayed(
      const Duration(milliseconds: 500),
    );

    if (!mounted) {
      return;
    }

    await _listenForLoginCommand();
  }

  // ============================================================
  // LISTEN FOR LOGIN COMMAND
  // ============================================================

  Future<void> _listenForLoginCommand() async {
    if (!mounted ||
        _isLoading ||
        _hasNavigated) {
      return;
    }

    if (!_passwordEntered ||
        _passwordController.text.isEmpty) {
      return;
    }

    if (_waitingForLoginCommand) {
      return;
    }

    _waitingForLoginCommand = true;

    setState(() {
      _isListening = true;
      _statusText =
          'Listening for Login...';
    });

    final bool received =
        await _voice.listen(
      localeId: 'en_ZA',
      acceptPartialResults: true,
      onResult: (String text) async {
        if (!mounted ||
            _isLoading ||
            _hasNavigated ||
            !_waitingForLoginCommand) {
          return;
        }

        _waitingForLoginCommand = false;

        await _processLoginCommand(text);
      },
    );

    if (!mounted ||
        _isLoading ||
        _hasNavigated ||
        !_waitingForLoginCommand) {
      return;
    }

    if (!received) {
      _waitingForLoginCommand = false;

      await Future.delayed(
        const Duration(milliseconds: 300),
      );

      if (!mounted ||
          _isLoading ||
          _hasNavigated) {
        return;
      }

      await _voice.speak(
        'Please say Login to continue.',
      );

      await Future.delayed(
        const Duration(milliseconds: 400),
      );

      if (!mounted) {
        return;
      }

      await _listenForLoginCommand();
    }
  }

  // ============================================================
  // PROCESS LOGIN COMMAND
  // ============================================================

  Future<void> _processLoginCommand(
    String text,
  ) async {
    await _voice.stopListening();

    _waitingForLoginCommand = false;

    if (!mounted) {
      return;
    }

    setState(() {
      _isListening = false;
    });

    final String command =
        text.toLowerCase().trim();

    debugPrint(
      'LOGIN COMMAND: $command',
    );

    if (_containsAny(command, [
      'login',
      'log in',
      'sign in',
      'signin',
      'continue',
    ])) {
      await _login();

      return;
    }

    if (_containsAny(command, [
      'repeat',
      'again',
      'say that again',
    ])) {
      await _voice.speak(
        'Please say Login to continue.',
      );

      await Future.delayed(
        const Duration(milliseconds: 400),
      );

      if (!mounted) {
        return;
      }

      await _listenForLoginCommand();

      return;
    }

    await _voice.speak(
      'I did not understand that. '
      'Please say Login to continue.',
    );

    await Future.delayed(
      const Duration(milliseconds: 400),
    );

    if (!mounted) {
      return;
    }

    await _listenForLoginCommand();
  }

  // ============================================================
  // FIREBASE LOGIN
  // ============================================================

  Future<void> _login() async {
    if (_emailController.text.trim().isEmpty) {
      await _voice.speak(
        'Your email address is missing. '
        'Please say your email address.',
      );

      _waitingForEmail = false;

      await Future.delayed(
        const Duration(milliseconds: 400),
      );

      if (!mounted) {
        return;
      }

      await _listenForEmail();

      return;
    }

    if (_passwordController.text.isEmpty) {
      await _voice.speak(
        'Your password has not been entered. '
        'Please type your password first.',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _statusText =
            'Type your password';
      });

      FocusScope.of(context).requestFocus(
        _passwordFocusNode,
      );

      return;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _isLoading = true;
      _isListening = false;
      _statusText =
          'Signing you in...';
    });

    try {
      debugPrint(
        'LOGIN: Starting Firebase authentication.',
      );

      await _voice.stopListening();

      await _voice.speak(
        'Signing you in. Please wait.',
      );

      await FirebaseAuth.instance
          .signInWithEmailAndPassword(
        email:
            _emailController.text.trim(),
        password:
            _passwordController.text,
      );

      debugPrint(
        'LOGIN: Firebase authentication successful.',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _statusText =
            'Login successful';
      });

      await _voice.speak(
        'Login successful. '
        'Welcome back to Vision Guide. '
        'Opening your dashboard.',
      );

      if (!mounted) {
        return;
      }

      await _voice.stopListening();

      if (!mounted) {
        return;
      }

      await Future.delayed(
        const Duration(milliseconds: 300),
      );

      if (!mounted) {
        return;
      }

      _hasNavigated = true;

      await Navigator.pushReplacement(
        context,
        MaterialPageRoute<void>(
          builder: (_) =>
              const DashboardScreen(),
        ),
      );
    } on FirebaseAuthException catch (e) {
      debugPrint(
        'LOGIN FIREBASE ERROR: ${e.code}',
      );

      String message;

      switch (e.code) {
        case 'user-not-found':
          message =
              'No account was found with '
              'this email address.';
          break;

        case 'wrong-password':
        case 'invalid-credential':
          message =
              'The email or password is incorrect.';
          break;

        case 'invalid-email':
          message =
              'The email address is invalid.';
          break;

        case 'user-disabled':
          message =
              'This account has been disabled.';
          break;

        case 'network-request-failed':
          message =
              'Please check your internet connection '
              'and try again.';
          break;

        case 'too-many-requests':
          message =
              'There have been too many login attempts. '
              'Please wait and try again later.';
          break;

        default:
          message =
              e.message ??
                  'Login failed. Please try again.';
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _isListening = false;
        _statusText =
            'Login failed';
      });

      await _voice.speak(message);

      await Future.delayed(
        const Duration(milliseconds: 700),
      );

      if (!mounted) {
        return;
      }

      _passwordController.clear();

      _passwordEntered = false;

      setState(() {
        _statusText =
            'Type your password';
      });

      await _voice.speak(
        'Please type your password again. '
        'When finished, press Done.',
      );

      await Future.delayed(
        const Duration(milliseconds: 500),
      );

      if (!mounted) {
        return;
      }

      FocusScope.of(context).requestFocus(
        _passwordFocusNode,
      );
    } catch (e) {
      debugPrint(
        'UNEXPECTED LOGIN ERROR: $e',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _isListening = false;
        _statusText =
            'Login error';
      });

      await _voice.speak(
        'Something went wrong while '
        'trying to log you in. '
        'Please try again.',
      );

      await Future.delayed(
        const Duration(milliseconds: 500),
      );

      if (!mounted) {
        return;
      }

      _passwordController.clear();

      _passwordEntered = false;

      setState(() {
        _statusText =
            'Type your password';
      });

      FocusScope.of(context).requestFocus(
        _passwordFocusNode,
      );
    }
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
    _voice.stopListening();

    _emailController.dispose();

    _passwordController.dispose();

    _passwordFocusNode.dispose();

    super.dispose();
  }

  // ============================================================
  // USER INTERFACE
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    final bool showPassword =
        _emailController.text.isNotEmpty;

    const Color primaryBlue =
        Color(0xFF0047AB);

    const Color darkBlue =
        Color(0xFF003477);

    const Color lightBlue =
        Color(0xFF1565C0);

    const Color yellow =
        Color(0xFFFFC72C);

    const Color red =
        Color(0xFFD71920);

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
              constraints: const BoxConstraints(
                maxWidth: 650,
              ),

              child: Column(
                children: [
                  // ==================================================
                  // TOP BRANDING
                  // ==================================================

                  Semantics(
                    label:
                        'Vision Guide login screen',
                    header: true,

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
                          'VOICE LOGIN',
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
                      ],
                    ),
                  ),

                  const SizedBox(
                    height: 28,
                  ),

                  // ==================================================
                  // MAIN ACCESSIBILITY CARD
                  // ==================================================

                  Container(
                    width: double.infinity,

                    padding:
                        const EdgeInsets.all(22),

                    decoration:
                        BoxDecoration(
                      color: Colors.white,

                      borderRadius:
                          BorderRadius.circular(
                        28,
                      ),

                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
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
                              'Voice assistant status: '
                              '$_statusText',

                          child: AnimatedContainer(
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
                        // EMAIL INFORMATION
                        // ============================================

                        if (_emailController
                            .text
                            .isNotEmpty)
                          Semantics(
                            label:
                                'Email address received: '
                                '${_emailController.text}',

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
                                              16,
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
                                    _emailController
                                        .text,

                                    style:
                                        const TextStyle(
                                      fontSize: 22,
                                      fontWeight:
                                          FontWeight
                                              .w700,
                                      color:
                                          Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                        if (_emailController
                            .text
                            .isNotEmpty)
                          const SizedBox(
                            height: 20,
                          ),

                        // ============================================
                        // PASSWORD FIELD
                        // ============================================

                        if (showPassword)
                          Semantics(
                            label:
                                'Password field. '
                                'Type your password. '
                                'Your password will not be spoken aloud.',

                            textField: true,

                            child: TextField(
                              controller:
                                  _passwordController,

                              focusNode:
                                  _passwordFocusNode,

                              obscureText:
                                  true,

                              enableSuggestions:
                                  false,

                              autocorrect:
                                  false,

                              textInputAction:
                                  TextInputAction
                                      .done,

                              keyboardType:
                                  TextInputType
                                      .visiblePassword,

                              enabled:
                                  !_isLoading,

                              style:
                                  const TextStyle(
                                fontSize: 22,
                                fontWeight:
                                    FontWeight.w600,
                                color:
                                    Colors.black,
                              ),

                              decoration:
                                  InputDecoration(
                                labelText:
                                    'PASSWORD',

                                hintText:
                                    'Type your password',

                                helperText:
                                    'Press Done when finished',

                                labelStyle:
                                    const TextStyle(
                                  fontSize: 17,
                                  fontWeight:
                                      FontWeight
                                          .bold,
                                  color:
                                      darkBlue,
                                ),

                                hintStyle:
                                    const TextStyle(
                                  fontSize: 18,
                                  color:
                                      Colors
                                          .black54,
                                ),

                                helperStyle:
                                    const TextStyle(
                                  fontSize: 16,
                                  fontWeight:
                                      FontWeight
                                          .w600,
                                ),

                                prefixIcon:
                                    const Icon(
                                  Icons.lock,
                                  size: 30,
                                  color:
                                      primaryBlue,
                                ),

                                filled: true,

                                fillColor:
                                    Colors
                                        .white,

                                contentPadding:
                                    const EdgeInsets
                                        .symmetric(
                                  horizontal: 18,
                                  vertical: 20,
                                ),

                                border:
                                    OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius
                                          .circular(
                                    18,
                                  ),

                                  borderSide:
                                      const BorderSide(
                                    color:
                                        primaryBlue,
                                    width: 2,
                                  ),
                                ),

                                enabledBorder:
                                    OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius
                                          .circular(
                                    18,
                                  ),

                                  borderSide:
                                      const BorderSide(
                                    color:
                                        primaryBlue,
                                    width: 2,
                                  ),
                                ),

                                focusedBorder:
                                    OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius
                                          .circular(
                                    18,
                                  ),

                                  borderSide:
                                      const BorderSide(
                                    color:
                                        darkBlue,
                                    width: 4,
                                  ),
                                ),
                              ),

                              onEditingComplete:
                                  _passwordFinished,

                              onSubmitted:
                                  (_) =>
                                      _passwordFinished(),
                            ),
                          ),

                        // ============================================
                        // SECURITY MESSAGE
                        // ============================================

                        if (showPassword) ...[
                          const SizedBox(
                            height: 18,
                          ),

                          Semantics(
                            label:
                                'Security instruction: '
                                'Do not speak your password aloud.',

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
                                    Icons
                                        .security,
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
                                      'type your password. '
                                      'Do not speak it aloud.',
                                      style:
                                          TextStyle(
                                        fontSize:
                                            17,
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
                        ],

                        const SizedBox(
                          height: 24,
                        ),

                        // ============================================
                        // LOADING
                        // ============================================

                        if (_isLoading)
                          Column(
                            children: [
                              const SizedBox(
                                width: 48,
                                height: 48,

                                child:
                                    CircularProgressIndicator(
                                  strokeWidth: 5,
                                  color:
                                      primaryBlue,
                                ),
                              ),

                              const SizedBox(
                                height: 14,
                              ),

                              const Text(
                                'Please wait...',
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
                                        ? showPassword
                                            ? 'Say LOGIN.'
                                            : 'Say your email address, or say BACK.'
                                        : showPassword
                                            ? 'Type your password and press DONE.'
                                            : 'Please speak your email address, or say BACK.',

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
                        'Voice-first accessible login. '
                        'Large text and high contrast interface.',

                    child: const Text(
                      'VOICE-FIRST ACCESSIBLE LOGIN',
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
