import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/command_processor.dart';
import '../services/voice_assistant_service.dart';
import '../screens/activities/accessibility/accessibility.dart';
import '../screens/activities/campus_info/campus_info_screen.dart';
import '../screens/activities/emergency/emergency_screen.dart';
import '../screens/activities/feedback/feedback_screen.dart';
import '../screens/activities/offline_maps/offline_maps_screen.dart';
import '../screens/activities/study_group/study_group_screen.dart';
import '../screens/activities/navigation/navigation_screen.dart';
import 'login_screen.dart';

/// ============================================================
/// DASHBOARD SCREEN
/// ============================================================
///
/// Voice-first Vision Guide Dashboard.
///
/// Available voice commands:
///
/// - Navigate buildings
/// - Study groups
/// - Campus information
/// - Offline maps
/// - Accessibility
/// - Emergency help
/// - Feedback
/// - Repeat
/// - Go back
/// - Go back to dashboard
/// - Logout
///
/// Profile, Settings and Help have intentionally been removed
/// to keep the dashboard simple and reduce the voice-command scope.
/// ============================================================

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({
    super.key,
  });

  @override
  State<DashboardScreen> createState() =>
      _DashboardScreenState();
}

class _DashboardScreenState
    extends State<DashboardScreen> {
  // ==========================================================
  // VOICE ASSISTANT
  // ==========================================================

  final VoiceAssistantService _assistant =
      VoiceAssistantService();

  // ==========================================================
  // TIMER
  // ==========================================================

  Timer? _clockTimer;

  // ==========================================================
  // DASHBOARD DATA
  // ==========================================================

  String _currentDate = '';
  String _currentTime = '';

  String _studentName = 'Student';

  // ==========================================================
  // STATE
  // ==========================================================

  bool _assistantReady = false;
  bool _isListening = false;
  bool _isNavigating = false;
  bool _isDisposed = false;
  bool _startingAssistant = false;

  // ==========================================================
  // APP COLORS
  // ==========================================================

  static const Color primaryBlue =
      Color(0xFF0047AB);

  static const Color darkBlue =
      Color(0xFF003477);

  static const Color lightBlue =
      Color(0xFF1565C0);

  static const Color yellow =
      Color(0xFFFFC72C);

  static const Color lightYellow =
      Color(0xFFFFF8DD);

  static const Color softBlue =
      Color(0xFFEAF2FF);

  static const Color white =
      Colors.white;

  static const Color black =
      Color(0xFF111111);

  // ==========================================================
  // INIT STATE
  // ==========================================================

  @override
  void initState() {
    super.initState();

    _updateDateTime();

    _clockTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) {
        if (!_isDisposed) {
          _updateDateTime();
        }
      },
    );

    _loadStudentName();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isDisposed && mounted) {
        unawaited(_startAssistant());
      }
    });
  }

  // ==========================================================
  // LOAD STUDENT NAME
  // ==========================================================

  void _loadStudentName() {
    final User? user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      return;
    }

    String name = 'Student';

    if (user.displayName != null &&
        user.displayName!.trim().isNotEmpty) {
      name = user.displayName!.trim();
    } else if (user.email != null &&
        user.email!.trim().isNotEmpty) {
      final String email =
          user.email!.trim();

      final String prefix =
          email.split('@').first;

      if (prefix.isNotEmpty) {
        name = prefix;
      }
    }

    if (!_isDisposed && mounted) {
      setState(() {
        _studentName = name;
      });
    }
  }

  // ==========================================================
  // UPDATE DATE AND TIME
  // ==========================================================

  void _updateDateTime() {
    final DateTime now = DateTime.now();

    final List<String> months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    final String month =
        months[now.month - 1];

    final String day =
        now.day.toString().padLeft(2, '0');

    final String year =
        now.year.toString();

    final String hour =
        (now.hour % 12 == 0
                ? 12
                : now.hour % 12)
            .toString()
            .padLeft(2, '0');

    final String minute =
        now.minute.toString().padLeft(2, '0');

    final String second =
        now.second.toString().padLeft(2, '0');

    final String period =
        now.hour >= 12 ? 'PM' : 'AM';

    if (!_isDisposed && mounted) {
      setState(() {
        _currentDate =
            '$day $month $year';

        _currentTime =
            '$hour:$minute:$second $period';
      });
    }
  }

  // ==========================================================
  // START ASSISTANT
  // ==========================================================

  Future<void> _startAssistant() async {
    if (_isDisposed ||
        _startingAssistant) {
      return;
    }

    _startingAssistant = true;

    try {
      print(
        'DASHBOARD: Starting voice assistant.',
      );

      await _assistant.initialize();

      if (_isDisposed) {
        return;
      }

      if (mounted) {
        setState(() {
          _assistantReady = true;
        });
      }

      // --------------------------------------------------------
      // SIMPLIFIED DASHBOARD WELCOME
      // --------------------------------------------------------

      await _assistant.speak(
        'Welcome $_studentName. '
        'You are now on the Vision Guide dashboard. '
        'I am ready to help you. '
        'You can say navigate buildings, '
        'study groups, campus information, '
        'offline maps, accessibility, '
        'emergency help, feedback, '
        'repeat, go back, go to dashboard, '
        'or logout.',
      );

      if (_isDisposed) {
        return;
      }

      await Future.delayed(
        const Duration(milliseconds: 1000),
      );

      if (_isDisposed) {
        return;
      }

      await _listenForCommands();
    } catch (e) {
      print(
        'DASHBOARD: Assistant start error: $e',
      );

      if (!_isDisposed && mounted) {
        setState(() {
          _assistantReady = false;
        });
      }
    } finally {
      _startingAssistant = false;
    }
  }

  // ==========================================================
  // LISTEN FOR COMMANDS
  // ==========================================================

  Future<void> _listenForCommands() async {
    if (_isDisposed ||
        _isNavigating ||
        !_assistantReady ||
        _isListening) {
      return;
    }

    try {
      if (mounted) {
        setState(() {
          _isListening = true;
        });
      }

      print(
        'DASHBOARD: Listening for voice command.',
      );

      final VoiceCommand? command =
          await _assistant.listenForCommand(
        listenFor:
            const Duration(seconds: 10),
        pauseFor:
            const Duration(seconds: 3),
      );

      if (command == null) {
        print(
          'DASHBOARD: No command returned.',
        );

        await _resumeListening();

        return;
      }

      if (_isDisposed) {
        return;
      }

      print(
        'DASHBOARD: Voice command received: $command',
      );

      if (mounted) {
        setState(() {
          _isListening = false;
        });
      }

      await _handleVoiceCommand(command);
    } catch (e) {
      print(
        'DASHBOARD: Listening error: $e',
      );

      if (!_isDisposed && mounted) {
        setState(() {
          _isListening = false;
        });
      }

      if (!_isDisposed &&
          !_isNavigating) {
        await Future.delayed(
          const Duration(milliseconds: 700),
        );

        await _listenForCommands();
      }
    }
  }

  // ==========================================================
  // HANDLE VOICE COMMAND
  // ==========================================================

  Future<void> _handleVoiceCommand(
    VoiceCommand command,
  ) async {
    if (_isDisposed) {
      return;
    }

    print(
      'DASHBOARD: Handling command: $command',
    );

    switch (command) {
      // --------------------------------------------------------
      // BUILDING NAVIGATION
      // --------------------------------------------------------

      case VoiceCommand.navigateBuildings:
      case VoiceCommand.navigation:
        await _openActivity(
          const NavigationScreen(),
          'Opening campus navigation.',
        );
        break;

      // --------------------------------------------------------
      // STUDY GROUPS
      // --------------------------------------------------------

      case VoiceCommand.studyGroups:
        await _openActivity(
          StudyGroupsScreen(),
          'Opening study groups.',
        );
        break;

      // --------------------------------------------------------
      // CAMPUS INFORMATION
      // --------------------------------------------------------

      case VoiceCommand.campusInfo:
        await _openActivity(
          const CampusInfoScreen(),
          'Opening campus information.',
        );
        break;

      // --------------------------------------------------------
      // OFFLINE MAPS
      // --------------------------------------------------------

      case VoiceCommand.offlineMaps:
        await _openActivity(
          const OfflineMapsScreen(),
          'Opening offline maps.',
        );
        break;

      // --------------------------------------------------------
      // ACCESSIBILITY
      // --------------------------------------------------------

      case VoiceCommand.accessibility:
        await _openActivity(
          const AccessibilityScreen(),
          'Opening accessibility settings.',
        );
        break;

      // --------------------------------------------------------
      // EMERGENCY
      // --------------------------------------------------------

      case VoiceCommand.emergency:
        await _openActivity(
          const EmergencyScreen(),
          'Opening emergency assistance.',
        );
        break;

      // --------------------------------------------------------
      // FEEDBACK
      // --------------------------------------------------------

      case VoiceCommand.feedback:
        await _openActivity(
          const FeedbackScreen(),
          'Opening feedback.',
        );
        break;

      // --------------------------------------------------------
      // HELP
      // --------------------------------------------------------
      //
      // Help has been intentionally removed from the dashboard.
      // If the command processor still returns VoiceCommand.help,
      // we simply explain the available commands briefly.
      //
      // --------------------------------------------------------

      case VoiceCommand.help:
        await _assistant.speak(
          'Available commands are navigate buildings, '
          'study groups, campus information, '
          'offline maps, accessibility, '
          'emergency help, feedback, '
          'repeat, go back, go to dashboard, '
          'or logout.',
        );

        await _resumeListening();

        break;

      // --------------------------------------------------------
      // REPEAT
      // --------------------------------------------------------

      case VoiceCommand.repeat:
        await _assistant.speak(
          'Welcome $_studentName. '
          'You are on the Vision Guide dashboard. '
          'You can say navigate buildings, '
          'study groups, campus information, '
          'offline maps, accessibility, '
          'emergency help, feedback, '
          'repeat, go back, go to dashboard, '
          'or logout.',
        );

        await _resumeListening();

        break;

      // --------------------------------------------------------
      // HOME
      // --------------------------------------------------------

      case VoiceCommand.home:
        await _assistant.speak(
          'You are already on the Vision Guide dashboard.',
        );

        await _resumeListening();

        break;

      // --------------------------------------------------------
      // BACK
      // --------------------------------------------------------

      case VoiceCommand.back:
        await _assistant.speak(
          'You are currently on the dashboard. '
          'There is no previous screen.',
        );

        await _resumeListening();

        break;

      // --------------------------------------------------------
      // CANCEL
      // --------------------------------------------------------

      case VoiceCommand.cancel:
        await _assistant.speak(
          'Command cancelled. '
          'I am ready for your next command.',
        );

        await _resumeListening();

        break;

      // --------------------------------------------------------
      // LOGIN
      // --------------------------------------------------------

      case VoiceCommand.login:
        await _assistant.speak(
          'You are already logged in.',
        );

        await _resumeListening();

        break;

      // --------------------------------------------------------
      // REGISTER
      // --------------------------------------------------------

      case VoiceCommand.register:
        await _assistant.speak(
          'You are already logged in. '
          'Please log out first if you want to use another account.',
        );

        await _resumeListening();

        break;

      // --------------------------------------------------------
      // PROFILE
      // --------------------------------------------------------
      //
      // Profile is no longer offered by the dashboard.
      //
      // --------------------------------------------------------

      case VoiceCommand.profile:
        await _assistant.speak(
          'Profile is not available on the dashboard. '
          'Please choose another command.',
        );

        await _resumeListening();

        break;

      // --------------------------------------------------------
      // SETTINGS
      // --------------------------------------------------------
      //
      // Settings is no longer offered as a separate dashboard
      // command. Accessibility is the supported option.
      //
      // --------------------------------------------------------

      case VoiceCommand.settings:
        await _assistant.speak(
          'Settings is not available as a dashboard command. '
          'You can say accessibility instead.',
        );

        await _resumeListening();

        break;

      // --------------------------------------------------------
      // LOGOUT
      // --------------------------------------------------------

      case VoiceCommand.logout:
        await _logout();

        break;

      // --------------------------------------------------------
      // NO INPUT
      // --------------------------------------------------------

      case VoiceCommand.noInput:
        print(
          'DASHBOARD: No voice input received.',
        );

        await _resumeListening();

        break;

      // --------------------------------------------------------
      // UNKNOWN
      // --------------------------------------------------------

      case VoiceCommand.unknown:
        await _assistant.speak(
          'I did not understand that command. '
          'Please choose one of the available dashboard commands.',
        );

        await _resumeListening();

        break;
    }
  }

  // ==========================================================
  // RESUME LISTENING
  // ==========================================================

  Future<void> _resumeListening() async {
    if (_isDisposed ||
        _isNavigating) {
      return;
    }

    await Future.delayed(
      const Duration(milliseconds: 600),
    );

    if (_isDisposed ||
        _isNavigating) {
      return;
    }

    await _listenForCommands();
  }

  // ==========================================================
  // OPEN ACTIVITY
  // ==========================================================

  Future<void> _openActivity(
    Widget screen,
    String message,
  ) async {
    if (_isDisposed ||
        _isNavigating) {
      return;
    }

    try {
      print(
        'DASHBOARD: Opening activity.',
      );

      if (mounted) {
        setState(() {
          _isNavigating = true;
          _isListening = false;
        });
      }

      await _assistant.stop();

      await Future.delayed(
        const Duration(milliseconds: 400),
      );

      if (_isDisposed) {
        return;
      }

      await _assistant.speak(
        message,
      );

      await Future.delayed(
        const Duration(milliseconds: 700),
      );

      if (_isDisposed) {
        return;
      }

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => screen,
        ),
      );

      if (_isDisposed) {
        return;
      }

      print(
        'DASHBOARD: Activity returned.',
      );

      await _assistant.stop();

      await Future.delayed(
        const Duration(milliseconds: 1000),
      );

      if (_isDisposed) {
        return;
      }

      await _assistant.initialize();

      if (_isDisposed) {
        return;
      }

      if (mounted) {
        setState(() {
          _assistantReady = true;
          _isNavigating = false;
          _isListening = false;
        });
      }

      // --------------------------------------------------------
      // SIMPLIFIED RETURN MESSAGE
      // --------------------------------------------------------

      await _assistant.speak(
        'Welcome back $_studentName. '
        'You are now on the Vision Guide dashboard. '
        'I am ready to help you. '
        'You can say navigate buildings, '
        'study groups, campus information, '
        'offline maps, accessibility, '
        'emergency help, feedback, '
        'repeat, go back, go to dashboard, '
        'or logout.',
      );

      if (_isDisposed) {
        return;
      }

      await Future.delayed(
        const Duration(milliseconds: 1200),
      );

      if (_isDisposed) {
        return;
      }

      await _listenForCommands();
    } catch (e) {
      print(
        'DASHBOARD: Activity navigation error: $e',
      );

      if (!_isDisposed && mounted) {
        setState(() {
          _isNavigating = false;
          _isListening = false;
        });
      }

      if (!_isDisposed) {
        await Future.delayed(
          const Duration(milliseconds: 1000),
        );

        await _startAssistant();
      }
    }
  }

  // ==========================================================
  // LOGOUT
  // ==========================================================

  Future<void> _logout() async {
    if (_isDisposed) {
      return;
    }

    try {
      print(
        'DASHBOARD: Logging out.',
      );

      if (mounted) {
        setState(() {
          _isNavigating = true;
          _isListening = false;
        });
      }

      await _assistant.stop();

      await Future.delayed(
        const Duration(milliseconds: 300),
      );

      await _assistant.speak(
        'Logging out. Goodbye.',
      );

      await Future.delayed(
        const Duration(milliseconds: 700),
      );

      await FirebaseAuth.instance.signOut();

      if (_isDisposed ||
          !mounted) {
        return;
      }

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) =>
              const LoginScreen(),
        ),
        (route) => false,
      );
    } catch (e) {
      print(
        'DASHBOARD: Logout error: $e',
      );

      if (!_isDisposed && mounted) {
        setState(() {
          _isNavigating = false;
        });
      }
    }
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor: primaryBlue,

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 20,
          ),

          child: Center(
            child: ConstrainedBox(
              constraints:
                  const BoxConstraints(
                maxWidth: 700,
              ),

              child: Column(
                children: [
                  // ==================================================
                  // HEADER
                  // ==================================================

                  Semantics(
                    header: true,

                    label:
                        'Vision Guide dashboard',

                    child: Column(
                      children: [
                        // --------------------------------------------
                        // ACCESSIBILITY ICON
                        // --------------------------------------------

                        Container(
                          width: 112,
                          height: 112,

                          decoration:
                              BoxDecoration(
                            color: white,
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
                                blurRadius: 16,
                                offset:
                                    Offset(0, 7),
                              ),
                            ],
                          ),

                          child: const Icon(
                            Icons
                                .accessibility_new,
                            size: 68,
                            color:
                                primaryBlue,
                          ),
                        ),

                        const SizedBox(
                          height: 18,
                        ),

                        const Text(
                          'VISION GUIDE',

                          textAlign:
                              TextAlign.center,

                          style: TextStyle(
                            fontSize: 34,
                            fontWeight:
                                FontWeight.w900,
                            color: white,
                            letterSpacing: 2,
                          ),
                        ),

                        const SizedBox(
                          height: 6,
                        ),

                        const Text(
                          'ACCESSIBLE CAMPUS ASSISTANT',

                          textAlign:
                              TextAlign.center,

                          style: TextStyle(
                            fontSize: 16,
                            fontWeight:
                                FontWeight.bold,
                            color: yellow,
                            letterSpacing:
                                1.4,
                          ),
                        ),

                        const SizedBox(
                          height: 5,
                        ),

                        const Text(
                          'CUT BLOEMFONTEIN CAMPUS',

                          textAlign:
                              TextAlign.center,

                          style: TextStyle(
                            fontSize: 15,
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
                    height: 24,
                  ),

                  // ==================================================
                  // WELCOME CARD
                  // ==================================================

                  Container(
                    width:
                        double.infinity,

                    padding:
                        const EdgeInsets
                            .symmetric(
                      horizontal: 20,
                      vertical: 18,
                    ),

                    decoration:
                        BoxDecoration(
                      color: white,

                      borderRadius:
                          BorderRadius.circular(
                        22,
                      ),

                      boxShadow: const [
                        BoxShadow(
                          color:
                              Colors.black26,
                          blurRadius: 16,
                          offset:
                              Offset(0, 6),
                        ),
                      ],
                    ),

                    child: Column(
                      children: [
                        Text(
                          'Welcome, $_studentName',

                          textAlign:
                              TextAlign.center,

                          style:
                              const TextStyle(
                            fontSize: 26,
                            fontWeight:
                                FontWeight.w800,
                            color: black,
                          ),
                        ),

                        const SizedBox(
                          height: 8,
                        ),

                        Text(
                          _currentDate,

                          textAlign:
                              TextAlign.center,

                          style:
                              const TextStyle(
                            fontSize: 17,
                            fontWeight:
                                FontWeight.w600,
                            color:
                                Colors.black87,
                          ),
                        ),

                        const SizedBox(
                          height: 4,
                        ),

                        Text(
                          _currentTime,

                          textAlign:
                              TextAlign.center,

                          style:
                              const TextStyle(
                            fontSize: 27,
                            fontWeight:
                                FontWeight.w900,
                            color:
                                primaryBlue,
                            letterSpacing:
                                1,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(
                    height: 22,
                  ),

                  // ==================================================
                  // MAIN VOICE ASSISTANT
                  // ==================================================

                  Semantics(
                    liveRegion: true,

                    label: _isListening
                        ? 'Voice assistant is listening'
                        : _isNavigating
                            ? 'Opening activity'
                            : _assistantReady
                                ? 'Voice assistant is ready'
                                : 'Voice assistant is starting',

                    child: AnimatedContainer(
                      duration:
                          const Duration(
                        milliseconds: 300,
                      ),

                      width:
                          double.infinity,

                      padding:
                          const EdgeInsets
                              .all(
                        24,
                      ),

                      decoration:
                          BoxDecoration(
                        color: _isListening
                            ? yellow
                            : white,

                        borderRadius:
                            BorderRadius.circular(
                          28,
                        ),

                        border: Border.all(
                          color: _isListening
                              ? darkBlue
                              : yellow,
                          width: 5,
                        ),

                        boxShadow: const [
                          BoxShadow(
                            color:
                                Colors.black38,
                            blurRadius: 20,
                            offset:
                                Offset(0, 8),
                          ),
                        ],
                      ),

                      child: Column(
                        children: [
                          // ------------------------------------------
                          // VOICE ICON
                          // ------------------------------------------

                          Container(
                            width: 105,
                            height: 105,

                            decoration:
                                BoxDecoration(
                              color: _isListening
                                  ? darkBlue
                                  : primaryBlue,

                              shape:
                                  BoxShape.circle,

                              boxShadow:
                                  const [
                                BoxShadow(
                                  color:
                                      Colors.black26,
                                  blurRadius: 10,
                                  offset:
                                      Offset(
                                    0,
                                    4,
                                  ),
                                ),
                              ],
                            ),

                            child: Icon(
                              _isListening
                                  ? Icons.mic
                                  : _isNavigating
                                      ? Icons
                                          .hourglass_top
                                      : Icons
                                          .record_voice_over,

                              size: 58,

                              color:
                                  Colors.white,
                            ),
                          ),

                          const SizedBox(
                            height: 18,
                          ),

                          // ------------------------------------------
                          // STATUS
                          // ------------------------------------------

                          Text(
                            _isListening
                                ? 'LISTENING'
                                : _isNavigating
                                    ? 'OPENING'
                                    : _assistantReady
                                        ? 'VOICE ASSISTANT READY'
                                        : 'STARTING VOICE ASSISTANT',

                            textAlign:
                                TextAlign.center,

                            style:
                                TextStyle(
                              fontSize: 23,
                              fontWeight:
                                  FontWeight.w900,
                              color:
                                  _isListening
                                      ? darkBlue
                                      : primaryBlue,
                              letterSpacing:
                                  0.8,
                            ),
                          ),

                          const SizedBox(
                            height: 10,
                          ),

                          Text(
                            _isListening
                                ? 'Please speak your command.'
                                : _isNavigating
                                    ? 'Please wait while Vision Guide opens the activity.'
                                    : _assistantReady
                                        ? 'Vision Guide is ready. Speak naturally.'
                                        : 'Starting your voice assistant...',

                            textAlign:
                                TextAlign.center,

                            style:
                                const TextStyle(
                              fontSize: 18,
                              fontWeight:
                                  FontWeight.w600,
                              color: black,
                            ),
                          ),

                          const SizedBox(
                            height: 18,
                          ),

                          // ------------------------------------------
                          // LISTENING INDICATOR
                          // ------------------------------------------

                          if (_isListening)
                            Container(
                              width:
                                  double.infinity,

                              padding:
                                  const EdgeInsets
                                      .symmetric(
                                vertical: 12,
                              ),

                              decoration:
                                  BoxDecoration(
                                color:
                                    Colors.white,
                                borderRadius:
                                    BorderRadius
                                        .circular(
                                  14,
                                ),
                              ),

                              child:
                                  const Row(
                                mainAxisAlignment:
                                    MainAxisAlignment
                                        .center,

                                children: [
                                  Icon(
                                    Icons.mic,
                                    color:
                                        primaryBlue,
                                    size: 28,
                                  ),

                                  SizedBox(
                                    width: 10,
                                  ),

                                  Text(
                                    'Speak now',
                                    style:
                                        TextStyle(
                                      fontSize:
                                          20,
                                      fontWeight:
                                          FontWeight
                                              .w800,
                                      color:
                                          darkBlue,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(
                    height: 24,
                  ),

                  // ==================================================
                  // QUICK COMMANDS HEADER
                  // ==================================================

                  Semantics(
                    header: true,

                    child: Container(
                      width:
                          double.infinity,

                      padding:
                          const EdgeInsets
                              .symmetric(
                        vertical: 16,
                        horizontal: 18,
                      ),

                      decoration:
                          BoxDecoration(
                        color: darkBlue,

                        borderRadius:
                            BorderRadius.circular(
                          18,
                        ),
                      ),

                      child: const Column(
                        children: [
                          Icon(
                            Icons
                                .record_voice_over,
                            color: yellow,
                            size: 34,
                          ),

                          SizedBox(
                            height: 8,
                          ),

                          Text(
                            'WHAT CAN I SAY?',

                            textAlign:
                                TextAlign.center,

                            style: TextStyle(
                              fontSize: 22,
                              fontWeight:
                                  FontWeight.w900,
                              color: white,
                              letterSpacing:
                                  1,
                            ),
                          ),

                          SizedBox(
                            height: 4,
                          ),

                          Text(
                            'Speak any command below',

                            textAlign:
                                TextAlign.center,

                            style: TextStyle(
                              fontSize: 16,
                              color:
                                  Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(
                    height: 14,
                  ),

                  // ==================================================
                  // COMMAND GRID
                  //
                  // PROFILE, SETTINGS AND HELP REMOVED
                  // ==================================================

                  _buildCommandCard(
                    Icons.navigation,
                    'Navigate buildings',
                  ),

                  _buildCommandCard(
                    Icons.groups,
                    'Study groups',
                  ),

                  _buildCommandCard(
                    Icons.school,
                    'Campus information',
                  ),

                  _buildCommandCard(
                    Icons.map,
                    'Offline maps',
                  ),

                  _buildCommandCard(
                    Icons.accessibility_new,
                    'Accessibility',
                  ),

                  _buildCommandCard(
                    Icons.emergency,
                    'Emergency help',
                    isEmergency: true,
                  ),

                  _buildCommandCard(
                    Icons.feedback,
                    'Feedback',
                  ),

                  _buildCommandCard(
                    Icons.repeat,
                    'Repeat',
                  ),

                  _buildCommandCard(
                    Icons.arrow_back,
                    'Go back',
                  ),

                  _buildCommandCard(
                    Icons.home,
                    'Go back to dashboard',
                  ),

                  _buildCommandCard(
                    Icons.logout,
                    'Logout',
                  ),

                  const SizedBox(
                    height: 22,
                  ),

                  // ==================================================
                  // VOICE-ONLY CARD
                  // ==================================================

                  Semantics(
                    label:
                        'Vision Guide is voice controlled. '
                        'No buttons are required.',

                    child: Container(
                      width:
                          double.infinity,

                      padding:
                          const EdgeInsets
                              .all(
                        20,
                      ),

                      decoration:
                          BoxDecoration(
                        color: softBlue,

                        borderRadius:
                            BorderRadius.circular(
                          20,
                        ),

                        border: Border.all(
                          color: primaryBlue,
                          width: 2,
                        ),
                      ),

                      child: Column(
                        children: [
                          Container(
                            width: 62,
                            height: 62,

                            decoration:
                                const BoxDecoration(
                              color: primaryBlue,
                              shape:
                                  BoxShape.circle,
                            ),

                            child:
                                const Icon(
                              Icons.mic_none,
                              size: 34,
                              color: white,
                            ),
                          ),

                          const SizedBox(
                            height: 12,
                          ),

                          const Text(
                            'VOICE-FIRST CONTROL',

                            textAlign:
                                TextAlign.center,

                            style: TextStyle(
                              fontSize: 20,
                              fontWeight:
                                  FontWeight.w900,
                              color: darkBlue,
                              letterSpacing:
                                  0.7,
                            ),
                          ),

                          const SizedBox(
                            height: 8,
                          ),

                          const Text(
                            'You do not need to press buttons. '
                            'Speak naturally and Vision Guide '
                            'will respond to your command.',

                            textAlign:
                                TextAlign.center,

                            style: TextStyle(
                              fontSize: 17,
                              fontWeight:
                                  FontWeight.w600,
                              color: black,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(
                    height: 18,
                  ),

                  // ==================================================
                  // ACCESSIBILITY FOOTER
                  // ==================================================

                  const Text(
                    'DESIGNED FOR ACCESSIBLE CAMPUS NAVIGATION',

                    textAlign:
                        TextAlign.center,

                    style: TextStyle(
                      fontSize: 13,
                      fontWeight:
                          FontWeight.bold,
                      color:
                          Colors.white70,
                      letterSpacing:
                          1.1,
                    ),
                  ),

                  const SizedBox(
                    height: 6,
                  ),

                  const Text(
                    'CUT BLOEMFONTEIN',

                    textAlign:
                        TextAlign.center,

                    style: TextStyle(
                      fontSize: 13,
                      color:
                          Colors.white54,
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

  // ==========================================================
  // COMMAND CARD
  // ==========================================================

  Widget _buildCommandCard(
    IconData icon,
    String command, {
    bool isEmergency = false,
  }) {
    return Container(
      width:
          double.infinity,

      margin:
          const EdgeInsets.only(
        bottom: 10,
      ),

      padding:
          const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 14,
      ),

      decoration:
          BoxDecoration(
        color: isEmergency
            ? lightYellow
            : white,

        borderRadius:
            BorderRadius.circular(
          16,
        ),

        border: Border.all(
          color: isEmergency
              ? yellow
              : primaryBlue,
          width: 2,
        ),

        boxShadow: const [
          BoxShadow(
            color:
                Colors.black12,
            blurRadius: 6,
            offset:
                Offset(0, 3),
          ),
        ],
      ),

      child: Semantics(
        label:
            'Voice command: $command',

        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,

              decoration:
                  BoxDecoration(
                color: isEmergency
                    ? yellow
                    : softBlue,

                shape:
                    BoxShape.circle,
              ),

              child: Icon(
                icon,

                size: 28,

                color: isEmergency
                    ? darkBlue
                    : primaryBlue,
              ),
            ),

            const SizedBox(
              width: 15,
            ),

            Expanded(
              child: Text(
                '“$command”',

                style:
                    const TextStyle(
                  fontSize: 19,
                  fontWeight:
                      FontWeight.w700,
                  color: black,
                ),
              ),
            ),

            const Icon(
              Icons.mic_none,
              size: 25,
              color: primaryBlue,
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // DISPOSE
  // ==========================================================

  @override
  void dispose() {
    _isDisposed = true;

    _clockTimer?.cancel();
    _clockTimer = null;

    unawaited(
      _assistant.stop(),
    );

    super.dispose();
  }
}