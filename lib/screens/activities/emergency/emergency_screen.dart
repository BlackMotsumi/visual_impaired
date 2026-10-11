import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:visual_impaired/services/voice_assistant_service.dart';
import 'package:visual_impaired/theme/app_theme.dart';

/// ============================================================
/// EMERGENCY SCREEN
/// ============================================================
///
/// Voice-first emergency assistance for Vision Guide.
///
/// Primary interaction is through voice.
/// Physical controls remain available as a backup.
///
/// Voice commands:
///
/// "call security"
/// "medical emergency"
/// "call emergency services"
/// "help"
/// "repeat"
/// "go back"
///
/// Confirmation:
///
/// "yes"
/// "confirm"
/// "call"
///
/// "no"
/// "cancel"
///
/// ============================================================

class EmergencyScreen extends StatefulWidget {
  const EmergencyScreen({super.key});

  @override
  State<EmergencyScreen> createState() =>
      _EmergencyScreenState();
}

class _EmergencyScreenState extends State<EmergencyScreen> {
  // ============================================================
  // VOICE ASSISTANT
  // ============================================================

  final VoiceAssistantService _voiceAssistant =
      VoiceAssistantService();

  // ============================================================
  // STATE
  // ============================================================

  bool _assistantReady = false;
  bool _isListening = false;
  bool _isProcessing = false;
  bool _isLeaving = false;

  String _statusText =
      'Starting emergency assistant...';

  // ============================================================
  // PENDING CALL
  // ============================================================

  String? _pendingNumber;
  String? _pendingService;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      _startEmergencyAssistant();
    });
  }

  // ============================================================
  // START ASSISTANT
  // ============================================================

  Future<void> _startEmergencyAssistant() async {
    if (!mounted || _isLeaving) {
      return;
    }

    try {
      setState(() {
        _statusText =
            'Starting emergency assistant...';
      });

      print(
        'EMERGENCY: Initializing voice assistant.',
      );

      await _voiceAssistant.initialize();

      if (!mounted || _isLeaving) {
        return;
      }

      setState(() {
        _assistantReady = true;
        _statusText =
            'Emergency assistant ready.';
      });

      await _voiceAssistant.speak(
        'Welcome to Emergency Help. '
        'I am ready to assist you. '
        'You can say call security, '
        'medical emergency, '
        'or call emergency services. '
        'You can also say help, repeat, '
        'or go back.',
      );

      if (!mounted || _isLeaving) {
        return;
      }

      await Future.delayed(
        const Duration(milliseconds: 700),
      );

      if (!mounted || _isLeaving) {
        return;
      }

      await _listenForCommand();
    } catch (e) {
      print(
        'EMERGENCY: Assistant start error: $e',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _assistantReady = false;
        _statusText =
            'Voice assistant could not start.';
      });
    }
  }

  // ============================================================
  // LISTEN FOR COMMAND
  // ============================================================

  Future<void> _listenForCommand() async {
    if (!mounted ||
        _isLeaving ||
        !_assistantReady ||
        _isListening ||
        _isProcessing) {
      return;
    }

    try {
      setState(() {
        _isListening = true;
        _statusText =
            'Listening for your emergency command...';
      });

      print(
        'EMERGENCY: Listening for command.',
      );

      final String? speech =
          await _voiceAssistant.listenForSpeech();

      if (!mounted || _isLeaving) {
        return;
      }

      setState(() {
        _isListening = false;
      });

      if (speech == null ||
          speech.trim().isEmpty) {
        setState(() {
          _statusText =
              'I did not hear anything.';
        });

        await _voiceAssistant.speak(
          'I did not hear anything. '
          'Please say help if you need assistance.',
        );

        await _continueListening();

        return;
      }

      final String command =
          speech.toLowerCase().trim();

      print(
        'EMERGENCY: Voice command: "$command"',
      );

      setState(() {
        _isProcessing = true;
        _statusText =
            'Heard: $speech';
      });

      await _processCommand(command);
    } catch (e) {
      print(
        'EMERGENCY: Listening error: $e',
      );

      if (!mounted || _isLeaving) {
        return;
      }

      setState(() {
        _isListening = false;
        _isProcessing = false;
        _statusText =
            'Voice recognition error.';
      });

      await _voiceAssistant.speak(
        'There was a problem understanding you. '
        'Please try again.',
      );

      await _continueListening();
    }
  }

  // ============================================================
  // PROCESS COMMAND
  // ============================================================

  Future<void> _processCommand(
    String command,
  ) async {
    final String text =
        command.toLowerCase().trim();

    print(
      'EMERGENCY: Processing "$text"',
    );

    // ----------------------------------------------------------
    // BACK
    // ----------------------------------------------------------

    if (_matchesAny(text, [
      'back',
      'go back',
      'take me back',
      'return',
      'return to dashboard',
      'go back to dashboard',
      'dashboard',
    ])) {
      await _goBack();

      return;
    }

    // ----------------------------------------------------------
    // HELP
    // ----------------------------------------------------------

    if (_matchesAny(text, [
      'help',
      'what can i say',
      'commands',
      'what can i do',
    ])) {
      await _speakHelp();

      if (!mounted || _isLeaving) {
        return;
      }

      setState(() {
        _isProcessing = false;
      });

      await _continueListening();

      return;
    }

    // ----------------------------------------------------------
    // REPEAT
    // ----------------------------------------------------------

    if (_matchesAny(text, [
      'repeat',
      'repeat that',
      'say that again',
      'repeat please',
    ])) {
      await _voiceAssistant.speak(
        'You are in Emergency Help. '
        'You can say call security, '
        'medical emergency, '
        'or call emergency services. '
        'You can also say go back.',
      );

      if (!mounted || _isLeaving) {
        return;
      }

      setState(() {
        _isProcessing = false;
      });

      await _continueListening();

      return;
    }

    // ----------------------------------------------------------
    // SECURITY
    // ----------------------------------------------------------

    if (_matchesAny(text, [
      'security',
      'campus security',
      'call security',
      'security help',
      'call campus security',
    ])) {
      await _prepareEmergencyCall(
        title: 'Campus Security',
        number: 'YOUR_SECURITY_NUMBER',
        description:
            'You selected Campus Security.',
      );

      return;
    }

    // ----------------------------------------------------------
    // MEDICAL
    // ----------------------------------------------------------

    if (_matchesAny(text, [
      'medical',
      'medical emergency',
      'medical help',
      'clinic',
      'ambulance',
      'call medical',
      'call ambulance',
    ])) {
      await _prepareEmergencyCall(
        title: 'Medical Emergency',
        number: 'YOUR_MEDICAL_NUMBER',
        description:
            'You selected Medical Emergency assistance.',
      );

      return;
    }

    // ----------------------------------------------------------
    // GENERAL EMERGENCY
    // ----------------------------------------------------------

    if (_matchesAny(text, [
      'emergency services',
      'call emergency',
      'call emergency services',
      'general emergency',
      'police',
      'fire',
      'call police',
      'call fire department',
    ])) {
      await _prepareEmergencyCall(
        title: 'Emergency Services',
        number: '10111',
        description:
            'You selected Emergency Services.',
      );

      return;
    }

    // ----------------------------------------------------------
    // UNKNOWN
    // ----------------------------------------------------------

    await _voiceAssistant.speak(
      'I did not understand your emergency request. '
      'Please say call security, '
      'medical emergency, '
      'or call emergency services.',
    );

    if (!mounted || _isLeaving) {
      return;
    }

    setState(() {
      _isProcessing = false;
      _statusText =
          'Command not recognised.';
    });

    await _continueListening();
  }

  // ============================================================
  // PREPARE EMERGENCY CALL
  // ============================================================

  Future<void> _prepareEmergencyCall({
    required String title,
    required String number,
    required String description,
  }) async {
    if (!mounted || _isLeaving) {
      return;
    }

    _pendingNumber = number;
    _pendingService = title;

    await _voiceAssistant.stop();

    if (!mounted || _isLeaving) {
      return;
    }

    setState(() {
      _isListening = false;
      _isProcessing = true;
      _statusText =
          'Confirming $title...';
    });

    await _voiceAssistant.speak(
      '$description '
      'The emergency number is $number. '
      'Do you want to call $title? '
      'Please say yes to call, '
      'or no to cancel.',
    );

    if (!mounted || _isLeaving) {
      return;
    }

    await Future.delayed(
      const Duration(milliseconds: 700),
    );

    if (!mounted || _isLeaving) {
      return;
    }

    await _listenForConfirmation(
      title: title,
      number: number,
      description: description,
    );
  }

  // ============================================================
  // VOICE CONFIRMATION
  // ============================================================

  Future<void> _listenForConfirmation({
    required String title,
    required String number,
    required String description,
  }) async {
    if (!mounted ||
        _isLeaving ||
        !_assistantReady ||
        _isListening) {
      return;
    }

    try {
      setState(() {
        _isListening = true;
        _statusText =
            'Waiting for your confirmation...';
      });

      final String? response =
          await _voiceAssistant.listenForSpeech();

      if (!mounted || _isLeaving) {
        return;
      }

      setState(() {
        _isListening = false;
      });

      if (response == null ||
          response.trim().isEmpty) {
        await _voiceAssistant.speak(
          'I did not hear your answer. '
          'Please say yes to call, '
          'or no to cancel.',
        );

        await Future.delayed(
          const Duration(milliseconds: 500),
        );

        await _listenForConfirmation(
          title: title,
          number: number,
          description: description,
        );

        return;
      }

      final String answer =
          response.toLowerCase().trim();

      print(
        'EMERGENCY: Confirmation response: "$answer"',
      );

      // --------------------------------------------------------
      // YES
      // --------------------------------------------------------

      if (_matchesAny(answer, [
        'yes',
        'yes please',
        'confirm',
        'confirmed',
        'call',
        'call now',
        'make the call',
      ])) {
        await _makeCall(
          number,
          title,
        );

        return;
      }

      // --------------------------------------------------------
      // NO
      // --------------------------------------------------------

      if (_matchesAny(answer, [
        'no',
        'no please',
        'cancel',
        'cancel call',
        'do not call',
        'dont call',
        'stop',
      ])) {
        _pendingNumber = null;
        _pendingService = null;

        setState(() {
          _isProcessing = false;
          _statusText =
              'Emergency call cancelled.';
        });

        await _voiceAssistant.speak(
          'The emergency call has been cancelled. '
          'I am ready for your next command.',
        );

        await _continueListening();

        return;
      }

      // --------------------------------------------------------
      // UNKNOWN ANSWER
      // --------------------------------------------------------

      await _voiceAssistant.speak(
        'I did not understand your answer. '
        'Please say yes to call, '
        'or no to cancel.',
      );

      await Future.delayed(
        const Duration(milliseconds: 500),
      );

      await _listenForConfirmation(
        title: title,
        number: number,
        description: description,
      );
    } catch (e) {
      print(
        'EMERGENCY: Confirmation error: $e',
      );

      if (!mounted || _isLeaving) {
        return;
      }

      setState(() {
        _isListening = false;
        _isProcessing = false;
      });

      await _voiceAssistant.speak(
        'I could not receive your confirmation. '
        'Please try again.',
      );

      await _continueListening();
    }
  }

  // ============================================================
  // MAKE CALL
  // ============================================================

  Future<void> _makeCall(
    String number,
    String service,
  ) async {
    if (!mounted || _isLeaving) {
      return;
    }

    await _voiceAssistant.stop();

    if (!mounted || _isLeaving) {
      return;
    }

    setState(() {
      _isListening = false;
      _isProcessing = true;
      _statusText =
          'Preparing $service call...';
    });

    // ----------------------------------------------------------
    // NUMBER NOT CONFIGURED
    // ----------------------------------------------------------

    if (number.startsWith('YOUR_')) {
      await _voiceAssistant.speak(
        '$service has not been configured yet. '
        'Please add the correct emergency number '
        'in the application settings.',
      );

      if (!mounted || _isLeaving) {
        return;
      }

      setState(() {
        _isProcessing = false;
        _statusText =
            '$service number not configured.';
      });

      await _continueListening();

      return;
    }

    final Uri phoneUri =
        Uri.parse('tel:$number');

    try {
      final bool canCall =
          await canLaunchUrl(phoneUri);

      if (!canCall) {
        await _voiceAssistant.speak(
          'I could not open the phone application. '
          'Please dial $number manually.',
        );

        if (!mounted || _isLeaving) {
          return;
        }

        setState(() {
          _isProcessing = false;
          _statusText =
              'Could not open phone application.';
        });

        await _continueListening();

        return;
      }

      await _voiceAssistant.speak(
        'Calling $service now.',
      );

      await Future.delayed(
        const Duration(milliseconds: 500),
      );

      if (!mounted || _isLeaving) {
        return;
      }

      await launchUrl(
        phoneUri,
        mode: LaunchMode.externalApplication,
      );

      if (!mounted || _isLeaving) {
        return;
      }

      setState(() {
        _isProcessing = false;
        _statusText =
            'Calling $service.';
      });
    } catch (e) {
      print(
        'EMERGENCY: Call error: $e',
      );

      if (!mounted || _isLeaving) {
        return;
      }

      await _voiceAssistant.speak(
        'I could not start the phone call. '
        'Please dial $number manually.',
      );

      setState(() {
        _isProcessing = false;
        _statusText =
            'Unable to start call.';
      });

      await _continueListening();
    }
  }

  // ============================================================
  // BUTTON CALL
  // ============================================================

  Future<void> _buttonEmergencyCall({
    required String title,
    required String number,
    required String description,
  }) async {
    if (_isLeaving) {
      return;
    }

    await _voiceAssistant.stop();

    if (!mounted || _isLeaving) {
      return;
    }

    setState(() {
      _isListening = false;
      _isProcessing = true;
      _statusText =
          'Confirming $title...';
    });

    await _showConfirmationDialog(
      title: title,
      number: number,
      description: description,
    );
  }

  // ============================================================
  // VISUAL CONFIRMATION
  // ============================================================

  Future<void> _showConfirmationDialog({
    required String title,
    required String number,
    required String description,
  }) async {
    await _voiceAssistant.speak(
      '$description '
      'The emergency number is $number. '
      'Please confirm the call.',
    );

    if (!mounted || _isLeaving) {
      return;
    }

    final bool? confirmed =
        await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Row(
            children: [
              const Icon(
                Icons.warning_rounded,
                color: AppColors.primaryRed,
                size: 32,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.darkBlue,
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            '$description\n\n'
            'Number: $number\n\n'
            'Do you want to make this call?',
            style: const TextStyle(
              color: AppColors.black,
              fontSize: 18,
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  false,
                );
              },
              child: const Text(
                'CANCEL',
                style: TextStyle(
                  color: AppColors.primaryBlue,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  true,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    AppColors.primaryRed,
                foregroundColor:
                    AppColors.white,
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'CALL NOW',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (!mounted || _isLeaving) {
      return;
    }

    if (confirmed == true) {
      await _makeCall(
        number,
        title,
      );
    } else {
      await _voiceAssistant.speak(
        'The emergency call has been cancelled.',
      );

      if (!mounted || _isLeaving) {
        return;
      }

      setState(() {
        _isProcessing = false;
        _statusText =
            'Emergency call cancelled.';
      });

      await _continueListening();
    }
  }

  // ============================================================
  // HELP
  // ============================================================

  Future<void> _speakHelp() async {
    await _voiceAssistant.speak(
      'Emergency voice commands are available. '
      'Say call security for campus security. '
      'Say medical emergency for medical assistance. '
      'Say call emergency services for emergency services. '
      'You can say repeat to hear this again, '
      'or go back to return to the dashboard.',
    );
  }

  // ============================================================
  // CONTINUE LISTENING
  // ============================================================

  Future<void> _continueListening() async {
    if (!mounted || _isLeaving) {
      return;
    }

    await Future.delayed(
      const Duration(milliseconds: 700),
    );

    if (!mounted || _isLeaving) {
      return;
    }

    await _listenForCommand();
  }

  // ============================================================
  // GO BACK
  // ============================================================

  Future<void> _goBack() async {
    if (!mounted || _isLeaving) {
      return;
    }

    _isLeaving = true;

    setState(() {
      _isListening = false;
      _isProcessing = true;
      _statusText =
          'Returning to dashboard...';
    });

    await _voiceAssistant.stop();

    if (!mounted) {
      return;
    }

    Navigator.pop(context);
  }

  // ============================================================
  // MATCH COMMAND
  // ============================================================

  bool _matchesAny(
    String value,
    List<String> commands,
  ) {
    final String normalized =
        value.toLowerCase().trim();

    for (final String command in commands) {
      final String normalizedCommand =
          command.toLowerCase();

      if (normalized == normalizedCommand) {
        return true;
      }

      if (normalized.contains(
        normalizedCommand,
      )) {
        return true;
      }
    }

    return false;
  }

  // ============================================================
  // EMERGENCY BUTTON
  // ============================================================

  Widget _emergencyButton({
    required IconData icon,
    required String title,
    required String description,
    required String number,
    required Color color,
  }) {
    return Semantics(
      button: true,
      label:
          '$title. $description. '
          '${number.startsWith('YOUR_') ? 'Number not configured.' : 'Number $number.'}',
      child: Material(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(22),
        elevation: 4,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () {
            _buttonEmergencyCall(
              title: title,
              number: number,
              description: description,
            );
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius:
                  BorderRadius.circular(22),
              border: Border.all(
                color: color,
                width: 2.5,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: AppColors.white,
                    size: 34,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style:
                            const TextStyle(
                          color:
                              AppColors.darkBlue,
                          fontSize: 19,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        description,
                        style:
                            const TextStyle(
                          color:
                              AppColors.black,
                          fontSize: 14,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding:
                            const EdgeInsets
                                .symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration:
                            BoxDecoration(
                          color: color.withValues(
                            alpha: 0.10,
                          ),
                          borderRadius:
                              BorderRadius.circular(
                            8,
                          ),
                        ),
                        child: Text(
                          number.startsWith(
                            'YOUR_',
                          )
                              ? 'NUMBER NOT CONFIGURED'
                              : number,
                          style:
                              TextStyle(
                            color: color,
                            fontSize: 15,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.phone_in_talk_rounded,
                  color: color,
                  size: 30,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    final bool statusListening =
        _isListening;

    final bool statusProcessing =
        _isProcessing;

    final Color statusBackground =
        statusListening
            ? AppColors.primaryYellow
            : statusProcessing
                ? AppColors.lightBlue
                : AppColors.white;

    final Color statusBorder =
        statusListening
            ? AppColors.primaryYellow
            : statusProcessing
                ? AppColors.lightBlue
                : AppColors.white;

    final Color statusIcon =
        statusListening
            ? AppColors.black
            : AppColors.primaryBlue;

    final Color statusTextColor =
        statusListening
            ? AppColors.black
            : AppColors.darkBlue;

    return Scaffold(
      backgroundColor:
          AppColors.primaryBlue,

      // ========================================================
      // APP BAR
      // ========================================================

      appBar: AppBar(
        backgroundColor:
            AppColors.primaryBlue,
        foregroundColor:
            AppColors.white,
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: const Text(
          'EMERGENCY HELP',
          style: TextStyle(
            color: AppColors.white,
            fontSize: 21,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        actions: [
          Semantics(
            label:
                'Read emergency instructions',
            child: IconButton(
              tooltip:
                  'Read emergency instructions',
              onPressed: _welcomeUser,
              icon: const Icon(
                Icons.volume_up_rounded,
                color: AppColors.primaryYellow,
                size: 28,
              ),
            ),
          ),
        ],
      ),

      // ========================================================
      // BODY
      // ========================================================

      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints:
                const BoxConstraints(
              maxWidth: 700,
            ),
            child: SingleChildScrollView(
              padding:
                  const EdgeInsets.fromLTRB(
                16,
                10,
                16,
                30,
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.stretch,
                children: [
                  // ==================================================
                  // EMERGENCY HERO CARD
                  // ==================================================

                  Semantics(
                    container: true,
                    label:
                        'Emergency Assistance. '
                        'Use voice commands to request urgent help.',
                    child: Container(
                      padding:
                          const EdgeInsets.all(24),
                      decoration:
                          BoxDecoration(
                        color: AppColors.white,
                        borderRadius:
                            BorderRadius.circular(
                          28,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            blurRadius: 12,
                            offset: Offset(0, 5),
                            color:
                                Colors.black26,
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 92,
                            height: 92,
                            decoration:
                                BoxDecoration(
                              color:
                                  AppColors.primaryRed,
                              shape:
                                  BoxShape.circle,
                              border:
                                  Border.all(
                                color:
                                    AppColors.primaryYellow,
                                width: 5,
                              ),
                            ),
                            child:
                                const Icon(
                              Icons
                                  .emergency_rounded,
                              color:
                                  AppColors.white,
                              size: 54,
                            ),
                          ),

                          const SizedBox(
                            height: 16,
                          ),

                          const Text(
                            'EMERGENCY ASSISTANCE',
                            textAlign:
                                TextAlign.center,
                            style:
                                TextStyle(
                              color:
                                  AppColors.primaryRed,
                              fontSize: 27,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),

                          const SizedBox(
                            height: 8,
                          ),

                          Container(
                            padding:
                                const EdgeInsets
                                    .symmetric(
                              horizontal: 14,
                              vertical: 7,
                            ),
                            decoration:
                                BoxDecoration(
                              color:
                                  AppColors.primaryYellow,
                              borderRadius:
                                  BorderRadius.circular(
                                20,
                              ),
                            ),
                            child:
                                const Text(
                              'VOICE-FIRST SAFETY',
                              style:
                                  TextStyle(
                                color:
                                    AppColors.black,
                                fontSize: 13,
                                fontWeight:
                                    FontWeight.bold,
                                letterSpacing:
                                    0.8,
                              ),
                            ),
                          ),

                          const SizedBox(
                            height: 14,
                          ),

                          const Text(
                            'If you are in danger or need urgent assistance, use your voice to request help.',
                            textAlign:
                                TextAlign.center,
                            style:
                                TextStyle(
                              color:
                                  AppColors.black,
                              fontSize: 17,
                              height: 1.45,
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
                  // VOICE STATUS
                  // ==================================================

                  Semantics(
                    container: true,
                    liveRegion: true,
                    label: _statusText,
                    child: AnimatedContainer(
                      duration:
                          const Duration(
                        milliseconds: 250,
                      ),
                      padding:
                          const EdgeInsets.all(20),
                      decoration:
                          BoxDecoration(
                        color:
                            statusBackground,
                        borderRadius:
                            BorderRadius.circular(
                          24,
                        ),
                        border: Border.all(
                          color:
                              statusBorder,
                          width: 3,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            blurRadius: 8,
                            offset:
                                Offset(0, 4),
                            color:
                                Colors.black26,
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 76,
                            height: 76,
                            decoration:
                                BoxDecoration(
                              color:
                                  statusIcon,
                              shape:
                                  BoxShape.circle,
                            ),
                            child: Icon(
                              statusListening
                                  ? Icons.mic_rounded
                                  : statusProcessing
                                      ? Icons
                                          .hourglass_top_rounded
                                      : Icons
                                          .record_voice_over_rounded,
                              color:
                                  statusListening
                                      ? AppColors
                                          .primaryYellow
                                      : AppColors
                                          .white,
                              size: 40,
                            ),
                          ),

                          const SizedBox(
                            height: 12,
                          ),

                          Text(
                            _statusText,
                            textAlign:
                                TextAlign.center,
                            style:
                                TextStyle(
                              color:
                                  statusTextColor,
                              fontSize: 18,
                              fontWeight:
                                  FontWeight.bold,
                              height: 1.3,
                            ),
                          ),

                          const SizedBox(
                            height: 6,
                          ),

                          Text(
                            _assistantReady
                                ? statusListening
                                    ? 'Speak your emergency command now.'
                                    : statusProcessing
                                        ? 'Please wait while I process your request.'
                                        : 'Voice assistant is ready.'
                                : 'Preparing voice assistance...',
                            textAlign:
                                TextAlign.center,
                            style:
                                TextStyle(
                              color:
                                  statusTextColor,
                              fontSize: 15,
                              height: 1.3,
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
                  // VOICE INSTRUCTION
                  // ==================================================

                  Container(
                    padding:
                        const EdgeInsets.all(20),
                    decoration:
                        BoxDecoration(
                      color:
                          AppColors.darkBlue,
                      borderRadius:
                          BorderRadius.circular(
                        24,
                      ),
                      border: Border.all(
                        color:
                            AppColors.primaryYellow,
                        width: 2,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons
                              .record_voice_over_rounded,
                          color:
                              AppColors.primaryYellow,
                          size: 38,
                        ),
                        const SizedBox(
                          width: 14,
                        ),
                        const Expanded(
                          child: Text(
                            'Say what you need. For example: "Call security" or "Medical emergency".',
                            style:
                                TextStyle(
                              color:
                                  AppColors.white,
                              fontSize: 17,
                              fontWeight:
                                  FontWeight.w600,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(
                    height: 22,
                  ),

                  // ==================================================
                  // EMERGENCY SERVICES
                  // ==================================================

                  const Text(
                    'URGENT CONTACTS',
                    style:
                        TextStyle(
                      color:
                          AppColors.white,
                      fontSize: 21,
                      fontWeight:
                          FontWeight.bold,
                      letterSpacing:
                          0.6,
                    ),
                  ),

                  const SizedBox(
                    height: 4,
                  ),

                  const Text(
                    'Voice is recommended. These controls are available as a backup.',
                    style:
                        TextStyle(
                      color:
                          Colors.white70,
                      fontSize: 15,
                      height: 1.3,
                    ),
                  ),

                  const SizedBox(
                    height: 12,
                  ),

                  // ==================================================
                  // EMERGENCY SERVICES
                  // ==================================================

                  _emergencyButton(
                    icon:
                        Icons.emergency_rounded,
                    title:
                        'Emergency Services',
                    description:
                        'Police, fire or other emergency services',
                    number: '10111',
                    color:
                        AppColors.primaryRed,
                  ),

                  const SizedBox(
                    height: 14,
                  ),

                  // ==================================================
                  // CAMPUS SECURITY
                  // ==================================================

                  _emergencyButton(
                    icon:
                        Icons.security_rounded,
                    title:
                        'Campus Security',
                    description:
                        'Contact CUT campus security',
                    number:
                        'YOUR_SECURITY_NUMBER',
                    color:
                        AppColors.primaryBlue,
                  ),

                  const SizedBox(
                    height: 14,
                  ),

                  // ==================================================
                  // MEDICAL
                  // ==================================================

                  _emergencyButton(
                    icon:
                        Icons.local_hospital_rounded,
                    title:
                        'Medical Emergency',
                    description:
                        'Request medical assistance',
                    number:
                        'YOUR_MEDICAL_NUMBER',
                    color:
                        AppColors.primaryRed,
                  ),

                  const SizedBox(
                    height: 22,
                  ),

                  // ==================================================
                  // VOICE COMMANDS
                  // ==================================================

                  Semantics(
                    container: true,
                    label:
                        'Available emergency voice commands.',
                    child: Container(
                      padding:
                          const EdgeInsets.all(20),
                      decoration:
                          BoxDecoration(
                        color:
                            AppColors.white,
                        borderRadius:
                            BorderRadius.circular(
                          24,
                        ),
                        border: Border.all(
                          color:
                              AppColors.primaryYellow,
                          width: 3,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            blurRadius: 8,
                            offset:
                                Offset(0, 4),
                            color:
                                Colors.black26,
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 62,
                            height: 62,
                            decoration:
                                const BoxDecoration(
                              color:
                                  AppColors.primaryBlue,
                              shape:
                                  BoxShape.circle,
                            ),
                            child:
                                const Icon(
                              Icons
                                  .record_voice_over_rounded,
                              color:
                                  AppColors.white,
                              size: 34,
                            ),
                          ),

                          const SizedBox(
                            height: 12,
                          ),

                          const Text(
                            'VOICE COMMANDS',
                            textAlign:
                                TextAlign.center,
                            style:
                                TextStyle(
                              color:
                                  AppColors.darkBlue,
                              fontSize: 21,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),

                          const SizedBox(
                            height: 6,
                          ),

                          const Text(
                            'You can say:',
                            style:
                                TextStyle(
                              color:
                                  AppColors.black,
                              fontSize: 16,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),

                          const SizedBox(
                            height: 12,
                          ),

                          _voiceCommand(
                            '"Call security"',
                          ),
                          _voiceCommand(
                            '"Medical emergency"',
                          ),
                          _voiceCommand(
                            '"Call emergency services"',
                          ),
                          _voiceCommand(
                            '"Help"',
                          ),
                          _voiceCommand(
                            '"Repeat"',
                          ),
                          _voiceCommand(
                            '"Go back"',
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(
                    height: 20,
                  ),

                  // ==================================================
                  // STOP VOICE
                  // ==================================================

                  if (_isProcessing ||
                      _isListening)
                    Semantics(
                      button: true,
                      label:
                          'Stop voice assistant',
                      child: TextButton(
                        onPressed: () async {
                          await _voiceAssistant
                              .stop();

                          if (!mounted) {
                            return;
                          }

                          setState(() {
                            _isListening =
                                false;
                            _isProcessing =
                                false;
                            _statusText =
                                'Voice assistant stopped.';
                          });
                        },
                        child:
                            const Text(
                          'STOP VOICE',
                          style:
                              TextStyle(
                            color:
                                AppColors.primaryYellow,
                            fontSize: 16,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                  const SizedBox(
                    height: 5,
                  ),

                  // ==================================================
                  // BACK TO DASHBOARD
                  // ==================================================

                  Semantics(
                    button: true,
                    label:
                        'Return to dashboard',
                    child: SizedBox(
                      height: 58,
                      child:
                          OutlinedButton(
                        onPressed:
                            _goBack,
                        style:
                            OutlinedButton
                                .styleFrom(
                          foregroundColor:
                              AppColors
                                  .white,
                          side:
                              const BorderSide(
                            color:
                                AppColors
                                    .primaryYellow,
                            width: 2,
                          ),
                          shape:
                              RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius
                                    .circular(
                              16,
                            ),
                          ),
                        ),
                        child:
                            const Text(
                          'BACK TO DASHBOARD',
                          style:
                              TextStyle(
                            color:
                                AppColors
                                    .white,
                            fontSize: 17,
                            fontWeight:
                                FontWeight
                                    .bold,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(
                    height: 18,
                  ),

                  // ==================================================
                  // FOOTER
                  // ==================================================

                  Container(
                    padding:
                        const EdgeInsets.all(14),
                    decoration:
                        BoxDecoration(
                      color:
                          AppColors.darkBlue,
                      borderRadius:
                          BorderRadius.circular(
                        16,
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment:
                          MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons
                              .accessibility_new_rounded,
                          color:
                              AppColors
                                  .primaryYellow,
                          size: 22,
                        ),
                        SizedBox(
                          width: 8,
                        ),
                        Text(
                          'VISION GUIDE • VOICE-FIRST ACCESS',
                          textAlign:
                              TextAlign.center,
                          style:
                              TextStyle(
                            color:
                                AppColors
                                    .white,
                            fontSize: 12,
                            fontWeight:
                                FontWeight.bold,
                            letterSpacing:
                                0.5,
                          ),
                        ),
                      ],
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

  // ============================================================
  // WELCOME BUTTON
  // ============================================================

  Future<void> _welcomeUser() async {
    if (!mounted || _isLeaving) {
      return;
    }

    await _voiceAssistant.stop();

    if (!mounted || _isLeaving) {
      return;
    }

    await _voiceAssistant.speak(
      'Welcome to Emergency Help. '
      'You can say call security, '
      'medical emergency, '
      'or call emergency services. '
      'You can also say help, repeat, '
      'or go back.',
    );

    if (!mounted || _isLeaving) {
      return;
    }

    await Future.delayed(
      const Duration(milliseconds: 600),
    );

    await _listenForCommand();
  }

  // ============================================================
  // VOICE COMMAND DISPLAY
  // ============================================================

  Widget _voiceCommand(
    String command,
  ) {
    return Container(
      width: double.infinity,
      margin:
          const EdgeInsets.only(
        bottom: 9,
      ),
      padding:
          const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 12,
      ),
      decoration:
          BoxDecoration(
        color:
            AppColors.surfaceBlue,
        borderRadius:
            BorderRadius.circular(
          12,
        ),
        border: Border.all(
          color:
              AppColors.lightBlue,
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.mic_rounded,
            color:
                AppColors.primaryBlue,
            size: 23,
          ),
          const SizedBox(
            width: 10,
          ),
          Expanded(
            child: Text(
              command,
              style:
                  const TextStyle(
                color:
                    AppColors.darkBlue,
                fontSize: 16,
                fontWeight:
                    FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _isLeaving = true;

    _voiceAssistant.stop();

    super.dispose();
  }
}