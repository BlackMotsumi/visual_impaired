import 'package:flutter/material.dart';

import 'package:visual_impaired/services/voice_assistant_service.dart';
import 'package:visual_impaired/theme/app_theme.dart';

/// ============================================================
/// ACCESSIBILITY SCREEN
/// ============================================================
///
/// Voice-controlled accessibility settings for Vision Guide.
///
/// Users can speak commands such as:
///
/// "turn on vibration"
/// "turn off vibration"
/// "increase speech rate"
/// "decrease speech rate"
/// "faster speech"
/// "slower speech"
/// "louder"
/// "quieter"
/// "turn on high contrast"
/// "turn off high contrast"
/// "turn on large text"
/// "turn off large text"
/// "turn on screen reader"
/// "turn off screen reader"
/// "repeat"
/// "help"
/// "go back"
///
/// The actual voice engine is provided by:
///
/// lib/services/voice_assistant_service.dart
///
/// IMPORTANT:
/// This screen does NOT declare another VoiceAssistantService.
/// ============================================================

class AccessibilityScreen extends StatefulWidget {
  const AccessibilityScreen({super.key});

  @override
  State<AccessibilityScreen> createState() =>
      _AccessibilityScreenState();
}

class _AccessibilityScreenState
    extends State<AccessibilityScreen> {
  // ============================================================
  // VOICE ASSISTANT
  // ============================================================

  final VoiceAssistantService _voiceAssistant =
      VoiceAssistantService();

  // ============================================================
  // SETTINGS
  // ============================================================

  bool _vibrationEnabled = true;

  bool _highContrastEnabled = true;

  bool _screenReaderEnabled = true;

  bool _largeTextEnabled = true;

  double _speechRate = 0.45;

  double _speechVolume = 1.0;

  // ============================================================
  // STATE
  // ============================================================

  bool _isLoading = true;

  bool _isListening = false;

  bool _isProcessing = false;

  String _statusText =
      'Starting accessibility assistant...';

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

      _startAccessibility();
    });
  }

  // ============================================================
  // START ACCESSIBILITY
  // ============================================================

  Future<void> _startAccessibility() async {
    try {
      setState(() {
        _isLoading = true;
        _statusText =
            'Starting accessibility assistant...';
      });

      await _voiceAssistant.initialize();

      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _statusText =
            'Accessibility assistant ready.';
      });

      await _voiceAssistant.speak(
        'Accessibility settings are ready. '
        'You can say vibration, speech rate, volume, '
        'high contrast, large text, help, repeat, or go back.',
      );

      if (!mounted) {
        return;
      }

      await Future.delayed(
        const Duration(milliseconds: 500),
      );

      _listenForCommand();
    } catch (e) {
      debugPrint(
        'ACCESSIBILITY START ERROR: $e',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _statusText =
            'Voice assistant could not start.';
      });
    }
  }

  // ============================================================
  // LISTEN FOR COMMAND
  // ============================================================

  Future<void> _listenForCommand() async {
    if (!mounted) {
      return;
    }

    if (_isListening || _isProcessing) {
      return;
    }

    setState(() {
      _isListening = true;
      _statusText = 'Listening...';
    });

    try {
      final String? speech =
          await _voiceAssistant.listenForSpeech();

      if (!mounted) {
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
          'I did not hear anything. Please try again.',
        );

        if (!mounted) {
          return;
        }

        await Future.delayed(
          const Duration(milliseconds: 400),
        );

        _listenForCommand();

        return;
      }

      final String command =
          speech.toLowerCase().trim();

      debugPrint(
        'ACCESSIBILITY COMMAND: "$command"',
      );

      setState(() {
        _statusText = 'Heard: $speech';
        _isProcessing = true;
      });

      await _processCommand(command);
    } catch (e) {
      debugPrint(
        'ACCESSIBILITY LISTEN ERROR: $e',
      );

      if (!mounted) {
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

      if (!mounted) {
        return;
      }

      await Future.delayed(
        const Duration(milliseconds: 500),
      );

      _listenForCommand();
    }
  }

  // ============================================================
  // PROCESS COMMAND
  // ============================================================

  Future<void> _processCommand(
    String speech,
  ) async {
    try {
      final String command =
          speech.toLowerCase().trim();

      // --------------------------------------------------------
      // BACK
      // --------------------------------------------------------

      if (_matchesAny(command, [
        'back',
        'go back',
        'take me back',
        'return',
      ])) {
        await _voiceAssistant.speak(
          'Going back to the dashboard.',
        );

        await Future.delayed(
          const Duration(milliseconds: 300),
        );

        if (!mounted) {
          return;
        }

        await _voiceAssistant.stopListening();

        Navigator.pop(context);

        return;
      }

      // --------------------------------------------------------
      // HELP
      // --------------------------------------------------------

      if (_matchesAny(command, [
        'help',
        'what can i say',
        'what can I say',
        'commands',
      ])) {
        await _speakHelp();

        if (!mounted) {
          return;
        }

        setState(() {
          _isProcessing = false;
        });

        await Future.delayed(
          const Duration(milliseconds: 300),
        );

        _listenForCommand();

        return;
      }

      // --------------------------------------------------------
      // REPEAT
      // --------------------------------------------------------

      if (_matchesAny(command, [
        'repeat',
        'repeat that',
        'say that again',
      ])) {
        await _voiceAssistant.speak(
          'You are in accessibility settings. '
          'You can change vibration, speech rate, volume, '
          'high contrast, and large text.',
        );

        if (!mounted) {
          return;
        }

        setState(() {
          _isProcessing = false;
        });

        await Future.delayed(
          const Duration(milliseconds: 300),
        );

        _listenForCommand();

        return;
      }

      // --------------------------------------------------------
      // VIBRATION
      // --------------------------------------------------------

      if (_matchesAny(command, [
        'turn on vibration',
        'enable vibration',
        'activate vibration',
        'vibration on',
      ])) {
        await _setVibration(true);
        return;
      }

      if (_matchesAny(command, [
        'turn off vibration',
        'disable vibration',
        'deactivate vibration',
        'vibration off',
      ])) {
        await _setVibration(false);
        return;
      }

      // --------------------------------------------------------
      // HIGH CONTRAST
      // --------------------------------------------------------

      if (_matchesAny(command, [
        'turn on high contrast',
        'enable high contrast',
        'high contrast on',
      ])) {
        await _setHighContrast(true);
        return;
      }

      if (_matchesAny(command, [
        'turn off high contrast',
        'disable high contrast',
        'high contrast off',
      ])) {
        await _setHighContrast(false);
        return;
      }

      // --------------------------------------------------------
      // LARGE TEXT
      // --------------------------------------------------------

      if (_matchesAny(command, [
        'turn on large text',
        'enable large text',
        'large text on',
        'increase text size',
      ])) {
        await _setLargeText(true);
        return;
      }

      if (_matchesAny(command, [
        'turn off large text',
        'disable large text',
        'large text off',
      ])) {
        await _setLargeText(false);
        return;
      }

      // --------------------------------------------------------
      // SCREEN READER
      // --------------------------------------------------------

      if (_matchesAny(command, [
        'turn on screen reader',
        'enable screen reader',
        'screen reader on',
      ])) {
        await _setScreenReader(true);
        return;
      }

      if (_matchesAny(command, [
        'turn off screen reader',
        'disable screen reader',
        'screen reader off',
      ])) {
        await _setScreenReader(false);
        return;
      }

      // --------------------------------------------------------
      // SPEECH RATE
      // --------------------------------------------------------

      if (_matchesAny(command, [
        'increase speech rate',
        'increase speech speed',
        'faster speech',
        'speak faster',
        'speed up speech',
        'make speech faster',
      ])) {
        await _changeSpeechRate(
          increase: true,
        );

        return;
      }

      if (_matchesAny(command, [
        'decrease speech rate',
        'decrease speech speed',
        'slower speech',
        'speak slower',
        'slow down speech',
        'make speech slower',
      ])) {
        await _changeSpeechRate(
          increase: false,
        );

        return;
      }

      // --------------------------------------------------------
      // VOLUME
      // --------------------------------------------------------

      if (_matchesAny(command, [
        'increase volume',
        'increase speech volume',
        'louder',
        'speak louder',
        'make it louder',
      ])) {
        await _changeVolume(
          increase: true,
        );

        return;
      }

      if (_matchesAny(command, [
        'decrease volume',
        'decrease speech volume',
        'quieter',
        'speak quieter',
        'make it quieter',
        'lower volume',
      ])) {
        await _changeVolume(
          increase: false,
        );

        return;
      }

      // --------------------------------------------------------
      // UNKNOWN COMMAND
      // --------------------------------------------------------

      await _voiceAssistant.speak(
        'I did not understand that command. '
        'Say help to hear the available commands.',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _isProcessing = false;
        _statusText =
            'Command not recognised.';
      });

      await Future.delayed(
        const Duration(milliseconds: 500),
      );

      _listenForCommand();
    } catch (e) {
      debugPrint(
        'ACCESSIBILITY COMMAND PROCESSING ERROR: $e',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _isProcessing = false;
      });

      await _voiceAssistant.speak(
        'An error occurred while processing your command.',
      );

      if (!mounted) {
        return;
      }

      _listenForCommand();
    }
  }

  // ============================================================
  // VIBRATION
  // ============================================================

  Future<void> _setVibration(
    bool enabled,
  ) async {
    setState(() {
      _vibrationEnabled = enabled;
      _isProcessing = false;
      _statusText = enabled
          ? 'Vibration enabled.'
          : 'Vibration disabled.';
    });

    await _voiceAssistant.speak(
      enabled
          ? 'Vibration is now enabled.'
          : 'Vibration is now disabled.',
    );

    await _continueListening();
  }

  // ============================================================
  // HIGH CONTRAST
  // ============================================================

  Future<void> _setHighContrast(
    bool enabled,
  ) async {
    setState(() {
      _highContrastEnabled = enabled;
      _isProcessing = false;
      _statusText = enabled
          ? 'High contrast enabled.'
          : 'High contrast disabled.';
    });

    await _voiceAssistant.speak(
      enabled
          ? 'High contrast is now enabled.'
          : 'High contrast is now disabled.',
    );

    await _continueListening();
  }

  // ============================================================
  // LARGE TEXT
  // ============================================================

  Future<void> _setLargeText(
    bool enabled,
  ) async {
    setState(() {
      _largeTextEnabled = enabled;
      _isProcessing = false;
      _statusText = enabled
          ? 'Large text enabled.'
          : 'Large text disabled.';
    });

    await _voiceAssistant.speak(
      enabled
          ? 'Large text is now enabled.'
          : 'Large text is now disabled.',
    );

    await _continueListening();
  }

  // ============================================================
  // SCREEN READER
  // ============================================================

  Future<void> _setScreenReader(
    bool enabled,
  ) async {
    setState(() {
      _screenReaderEnabled = enabled;
      _isProcessing = false;
      _statusText = enabled
          ? 'Screen reader enabled.'
          : 'Screen reader disabled.';
    });

    await _voiceAssistant.speak(
      enabled
          ? 'Screen reader is now enabled.'
          : 'Screen reader is now disabled.',
    );

    await _continueListening();
  }

  // ============================================================
  // SPEECH RATE
  // ============================================================

  Future<void> _changeSpeechRate({
    required bool increase,
  }) async {
    if (increase) {
      _speechRate += 0.05;
    } else {
      _speechRate -= 0.05;
    }

    if (_speechRate < 0.2) {
      _speechRate = 0.2;
    }

    if (_speechRate > 0.8) {
      _speechRate = 0.8;
    }

    final String description =
        _speechRate < 0.35
            ? 'slow'
            : _speechRate < 0.55
                ? 'normal'
                : 'fast';

    setState(() {
      _isProcessing = false;
      _statusText =
          'Speech rate set to $description.';
    });

    await _voiceAssistant.speak(
      'Speech rate set to $description.',
    );

    await _continueListening();
  }

  // ============================================================
  // VOLUME
  // ============================================================

  Future<void> _changeVolume({
    required bool increase,
  }) async {
    if (increase) {
      _speechVolume += 0.1;
    } else {
      _speechVolume -= 0.1;
    }

    if (_speechVolume < 0.2) {
      _speechVolume = 0.2;
    }

    if (_speechVolume > 1.0) {
      _speechVolume = 1.0;
    }

    final String description =
        _speechVolume <= 0.4
            ? 'low'
            : _speechVolume <= 0.7
                ? 'medium'
                : 'high';

    setState(() {
      _isProcessing = false;
      _statusText =
          'Volume set to $description.';
    });

    await _voiceAssistant.speak(
      'Volume set to $description.',
    );

    await _continueListening();
  }

  // ============================================================
  // CONTINUE LISTENING
  // ============================================================

  Future<void> _continueListening() async {
    if (!mounted) {
      return;
    }

    await Future.delayed(
      const Duration(milliseconds: 500),
    );

    if (!mounted) {
      return;
    }

    _listenForCommand();
  }

  // ============================================================
  // HELP
  // ============================================================

  Future<void> _speakHelp() async {
    await _voiceAssistant.speak(
      'Accessibility commands are available. '
      'Say turn on vibration or turn off vibration. '
      'Say increase speech rate or decrease speech rate. '
      'Say louder or quieter. '
      'Say turn on high contrast or turn off high contrast. '
      'Say turn on large text or turn off large text. '
      'Say turn on screen reader or turn off screen reader. '
      'You can also say repeat, help, or go back.',
    );
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
      if (normalized == command.toLowerCase()) {
        return true;
      }

      if (normalized.contains(
        command.toLowerCase(),
      )) {
        return true;
      }
    }

    return false;
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final double textScale =
        _largeTextEnabled ? 1.25 : 1.0;

    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: TextScaler.linear(
          textScale,
        ),
      ),
      child: Scaffold(
        backgroundColor: AppColors.primaryBlue,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              20,
              22,
              20,
              32,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 720,
                ),
                child: Column(
                  children: [
                    _buildHeader(),

                    const SizedBox(height: 20),

                    _buildVoiceStatus(),

                    const SizedBox(height: 18),

                    _buildSettingsCard(),

                    const SizedBox(height: 18),

                    _buildSpeechControlsCard(),

                    const SizedBox(height: 18),

                    _buildVoiceCommandsCard(),

                    const SizedBox(height: 18),

                    _buildAccessibilityInfoCard(),

                    const SizedBox(height: 24),

                    _buildFooter(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader() {
    return Semantics(
      container: true,
      header: true,
      label: 'Vision Guide accessibility settings',
      child: Column(
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: AppColors.white,
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.primaryYellow,
                width: 5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(
                    alpha: 0.25,
                  ),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Icon(
              Icons.accessibility_new,
              color: AppColors.primaryBlue,
              size: 58,
            ),
          ),

          const SizedBox(height: 16),

          const Text(
            'ACCESSIBILITY',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.white,
              fontSize: 32,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),

          const SizedBox(height: 5),

          const Text(
            'PERSONALISED VOICE SETTINGS',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.primaryYellow,
              fontSize: 14,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.3,
            ),
          ),

          const SizedBox(height: 5),

          const Text(
            'VISION GUIDE',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // VOICE STATUS
  // ============================================================

  Widget _buildVoiceStatus() {
    final bool listening = _isListening;

    final Color cardColor =
        listening
            ? AppColors.primaryYellow
            : AppColors.white;

    final Color iconColor =
        listening
            ? AppColors.black
            : AppColors.primaryBlue;

    final Color titleColor =
        listening
            ? AppColors.black
            : AppColors.darkBlue;

    return Semantics(
      container: true,
      liveRegion: true,
      label: _statusText,
      child: AnimatedContainer(
        duration:
            const Duration(milliseconds: 250),
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius:
              BorderRadius.circular(28),
          border: Border.all(
            color: listening
                ? AppColors.white
                : AppColors.lightBlue,
            width: 4,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(
                alpha: 0.22,
              ),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 104,
              height: 104,
              decoration: BoxDecoration(
                color: listening
                    ? AppColors.white
                    : const Color(0xFFEAF2FF),
                shape: BoxShape.circle,
                border: Border.all(
                  color: listening
                      ? AppColors.black
                      : AppColors.primaryBlue,
                  width: 4,
                ),
              ),
              child: Icon(
                listening
                    ? Icons.mic
                    : Icons.record_voice_over,
                color: iconColor,
                size: 56,
              ),
            ),

            const SizedBox(height: 18),

            Text(
              listening
                  ? 'LISTENING'
                  : _isLoading
                      ? 'STARTING ASSISTANT'
                      : 'VOICE ASSISTANT READY',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: titleColor,
                fontSize: 24,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              _statusText,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: listening
                    ? AppColors.black
                    : AppColors.darkBlue,
                fontSize: 18,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              listening
                  ? 'Speak your command now.'
                  : 'Say a command whenever you are ready.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: listening
                    ? AppColors.black
                    : AppColors.darkBlue,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),

            if (_isLoading) ...[
              const SizedBox(height: 18),
              const SizedBox(
                width: 30,
                height: 30,
                child:
                    CircularProgressIndicator(
                  strokeWidth: 3,
                  color: AppColors.primaryBlue,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ============================================================
  // SETTINGS CARD
  // ============================================================

  Widget _buildSettingsCard() {
    return Semantics(
      container: true,
      label:
          'Accessibility settings. '
          'Vibration is ${_vibrationEnabled ? 'on' : 'off'}. '
          'High contrast is ${_highContrastEnabled ? 'on' : 'off'}. '
          'Large text is ${_largeTextEnabled ? 'on' : 'off'}. '
          'Screen reader is ${_screenReaderEnabled ? 'on' : 'off'}.',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius:
              BorderRadius.circular(28),
          border: Border.all(
            color: AppColors.primaryYellow,
            width: 3,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(
                alpha: 0.18,
              ),
              blurRadius: 18,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            _buildSectionTitle(
              icon: Icons.tune,
              title: 'ACCESSIBILITY SETTINGS',
              dark: true,
            ),

            const SizedBox(height: 18),

            _buildSettingTile(
              icon: Icons.vibration,
              title: 'Vibration',
              description:
                  'Provides vibration feedback.',
              enabled: _vibrationEnabled,
            ),

            _buildSettingTile(
              icon: Icons.contrast,
              title: 'High Contrast',
              description:
                  'Uses stronger colour contrast.',
              enabled: _highContrastEnabled,
            ),

            _buildSettingTile(
              icon: Icons.text_fields,
              title: 'Large Text',
              description:
                  'Uses larger text throughout this screen.',
              enabled: _largeTextEnabled,
            ),

            _buildSettingTile(
              icon: Icons.record_voice_over,
              title: 'Screen Reader',
              description:
                  'Screen reader accessibility is enabled.',
              enabled: _screenReaderEnabled,
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // SPEECH CONTROLS
  // ============================================================

  Widget _buildSpeechControlsCard() {
    final int speechPercentage =
        ((_speechRate - 0.2) / 0.6 * 100)
            .round()
            .clamp(0, 100);

    final int volumePercentage =
        (_speechVolume * 100)
            .round()
            .clamp(0, 100);

    return Semantics(
      container: true,
      label:
          'Speech controls. '
          'Speech rate is $speechPercentage percent. '
          'Speech volume is $volumePercentage percent.',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: AppColors.darkBlue,
          borderRadius:
              BorderRadius.circular(28),
          border: Border.all(
            color: AppColors.primaryYellow,
            width: 3,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(
                alpha: 0.2,
              ),
              blurRadius: 18,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            _buildSectionTitle(
              icon: Icons.record_voice_over,
              title: 'VOICE CONTROLS',
              dark: false,
            ),

            const SizedBox(height: 20),

            _buildVoiceControl(
              icon: Icons.speed,
              title: 'Speech Rate',
              value: _speechRateDescription(),
              percentage: speechPercentage,
            ),

            const SizedBox(height: 16),

            _buildVoiceControl(
              icon: Icons.volume_up,
              title: 'Speech Volume',
              value: _volumeDescription(),
              percentage: volumePercentage,
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // SPEECH RATE DESCRIPTION
  // ============================================================

  String _speechRateDescription() {
    if (_speechRate < 0.35) {
      return 'Slow';
    }

    if (_speechRate < 0.55) {
      return 'Normal';
    }

    return 'Fast';
  }

  // ============================================================
  // VOLUME DESCRIPTION
  // ============================================================

  String _volumeDescription() {
    if (_speechVolume <= 0.4) {
      return 'Low';
    }

    if (_speechVolume <= 0.7) {
      return 'Medium';
    }

    return 'High';
  }

  // ============================================================
  // VOICE COMMANDS CARD
  // ============================================================

  Widget _buildVoiceCommandsCard() {
    return Semantics(
      container: true,
      label:
          'Available accessibility voice commands.',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius:
              BorderRadius.circular(28),
          border: Border.all(
            color: AppColors.lightBlue,
            width: 3,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(
                alpha: 0.18,
              ),
              blurRadius: 18,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            _buildSectionTitle(
              icon: Icons.mic,
              title: 'VOICE COMMANDS',
              dark: true,
            ),

            const SizedBox(height: 16),

            _buildCommandRow(
              '“Vibration on”',
            ),

            _buildCommandRow(
              '“Vibration off”',
            ),

            _buildCommandRow(
              '“Faster speech”',
            ),

            _buildCommandRow(
              '“Slower speech”',
            ),

            _buildCommandRow(
              '“Louder”',
            ),

            _buildCommandRow(
              '“Quieter”',
            ),

            _buildCommandRow(
              '“High contrast on”',
            ),

            _buildCommandRow(
              '“High contrast off”',
            ),

            _buildCommandRow(
              '“Large text on”',
            ),

            _buildCommandRow(
              '“Large text off”',
            ),

            _buildCommandRow(
              '“Screen reader on”',
            ),

            _buildCommandRow(
              '“Screen reader off”',
            ),

            _buildCommandRow(
              '“Repeat”',
            ),

            _buildCommandRow(
              '“Help”',
            ),

            _buildCommandRow(
              '“Go back”',
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // ACCESSIBILITY INFORMATION CARD
  // ============================================================

  Widget _buildAccessibilityInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.primaryYellow,
        borderRadius:
            BorderRadius.circular(28),
        border: Border.all(
          color: AppColors.white,
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: 0.18,
            ),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: const BoxDecoration(
              color: AppColors.darkBlue,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.accessibility_new,
              color: AppColors.white,
              size: 34,
            ),
          ),

          const SizedBox(width: 16),

          const Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'VOICE-FIRST ACCESSIBILITY',
                  style: TextStyle(
                    color: AppColors.darkBlue,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),

                SizedBox(height: 6),

                Text(
                  'You do not need to touch the screen. '
                  'Speak a command and Vision Guide '
                  'will respond.',
                  style: TextStyle(
                    color: AppColors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SECTION TITLE
  // ============================================================

  Widget _buildSectionTitle({
    required IconData icon,
    required String title,
    required bool dark,
  }) {
    return Row(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: AppColors.primaryYellow,
            shape: BoxShape.circle,
            border: dark
                ? Border.all(
                    color: AppColors.primaryBlue,
                    width: 2,
                  )
                : null,
          ),
          child: Icon(
            icon,
            color: AppColors.black,
            size: 29,
          ),
        ),

        const SizedBox(width: 14),

        Expanded(
          child: Text(
            title,
            style: TextStyle(
              color: dark
                  ? AppColors.darkBlue
                  : AppColors.white,
              fontSize: 21,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.4,
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // SETTING TILE
  // ============================================================

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required String description,
    required bool enabled,
  }) {
    return Container(
      width: double.infinity,
      margin:
          const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF2FF),
        borderRadius:
            BorderRadius.circular(16),
        border: Border.all(
          color: enabled
              ? AppColors.primaryBlue
              : AppColors.grey,
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: enabled
                  ? AppColors.primaryBlue
                  : AppColors.grey,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: enabled
                  ? AppColors.white
                  : AppColors.black,
              size: 25,
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.darkBlue,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  description,
                  style: const TextStyle(
                    color: AppColors.black,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 10),

          Icon(
            enabled
                ? Icons.check_circle
                : Icons.cancel,
            color: enabled
                ? AppColors.success
                : AppColors.primaryRed,
            size: 32,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // VOICE CONTROL
  // ============================================================

  Widget _buildVoiceControl({
    required IconData icon,
    required String title,
    required String value,
    required int percentage,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(
          alpha: 0.09,
        ),
        borderRadius:
            BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withValues(
            alpha: 0.18,
          ),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: const BoxDecoration(
                  color: AppColors.primaryYellow,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: AppColors.black,
                  size: 25,
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),

              Text(
                value,
                style: const TextStyle(
                  color: AppColors.primaryYellow,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          ClipRRect(
            borderRadius:
                BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: percentage / 100,
              minHeight: 10,
              backgroundColor:
                  Colors.white24,
              color: AppColors.primaryYellow,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // COMMAND ROW
  // ============================================================

  Widget _buildCommandRow(
    String command,
  ) {
    return Container(
      width: double.infinity,
      margin:
          const EdgeInsets.only(bottom: 8),
      padding:
          const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF2FF),
        borderRadius:
            BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.lightBlue,
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.mic,
            color: AppColors.primaryBlue,
            size: 24,
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Text(
              command,
              style: const TextStyle(
                color: AppColors.darkBlue,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // FOOTER
  // ============================================================

  Widget _buildFooter() {
    return Column(
      children: [
        Container(
          height: 4,
          width: 80,
          decoration: BoxDecoration(
            color: AppColors.primaryYellow,
            borderRadius:
                BorderRadius.circular(10),
          ),
        ),

        const SizedBox(height: 12),

        const Text(
          'VISION GUIDE',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.white,
            fontSize: 14,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
          ),
        ),

        const SizedBox(height: 4),

        const Text(
          'ACCESSIBLE • VOICE-FIRST • CAMPUS ASSISTANCE',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white70,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _voiceAssistant.stopListening();

    super.dispose();
  }
}