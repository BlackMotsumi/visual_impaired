import 'package:flutter/material.dart';

import 'package:visual_impaired/services/voice_assistant_service.dart';
import 'package:visual_impaired/theme/app_theme.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  // ============================================================
  // VOICE ASSISTANT
  // ============================================================

  final VoiceAssistantService _voiceAssistant =
      VoiceAssistantService();

  // ============================================================
  // CONTROLLERS
  // ============================================================

  final TextEditingController _feedbackController =
      TextEditingController();

  // ============================================================
  // STATE
  // ============================================================

  bool _isListening = false;
  bool _isSpeaking = false;
  bool _isProcessing = false;
  bool _isSubmitting = false;
  bool _voiceReady = false;

  int _rating = 0;

  String _statusText = 'Starting feedback assistant...';

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _startFeedbackAssistant();
      }
    });
  }

  // ============================================================
  // START VOICE ASSISTANT
  // ============================================================

  Future<void> _startFeedbackAssistant() async {
    if (!mounted) return;

    try {
      setState(() {
        _statusText = 'Starting voice assistant...';
      });

      await _voiceAssistant.initialize();

      if (!mounted) return;

      setState(() {
        _voiceReady = true;
        _statusText = 'Voice assistant ready.';
      });

      await _speak(
        'Welcome to the feedback page. '
        'You can rate your experience and tell us what you think. '
        'You can use your voice to give feedback. '
        'Say give feedback to start speaking. '
        'Say submit feedback when you are finished. '
        'You can also say help, repeat, or go back.',
      );

      if (!mounted) return;

      await Future.delayed(
        const Duration(milliseconds: 700),
      );

      if (!mounted) return;

      await _listenForCommand();
    } catch (e) {
      debugPrint(
        'FEEDBACK ASSISTANT START ERROR: $e',
      );

      if (!mounted) return;

      setState(() {
        _voiceReady = false;
        _statusText =
            'Voice assistant could not start.';
      });
    }
  }

  // ============================================================
  // SPEAK
  // ============================================================

  Future<void> _speak(String message) async {
    if (!mounted) return;

    try {
      setState(() {
        _isSpeaking = true;
        _statusText = message;
      });

      await _voiceAssistant.speak(message);

      if (!mounted) return;

      setState(() {
        _isSpeaking = false;
      });
    } catch (e) {
      debugPrint(
        'FEEDBACK SPEAK ERROR: $e',
      );

      if (!mounted) return;

      setState(() {
        _isSpeaking = false;
      });
    }
  }

  // ============================================================
  // STOP VOICE
  // ============================================================

  Future<void> _stopVoice() async {
    try {
      await _voiceAssistant.stop();
    } catch (e) {
      debugPrint(
        'FEEDBACK STOP VOICE ERROR: $e',
      );
    }

    if (!mounted) return;

    setState(() {
      _isSpeaking = false;
      _isListening = false;
    });
  }

  // ============================================================
  // LISTEN FOR COMMAND
  // ============================================================

  Future<void> _listenForCommand() async {
    if (!mounted ||
        !_voiceReady ||
        _isListening ||
        _isProcessing ||
        _isSubmitting) {
      return;
    }

    try {
      setState(() {
        _isListening = true;
        _statusText = 'Listening...';
      });

      debugPrint(
        'FEEDBACK: Listening for command.',
      );

      final String? speech =
          await _voiceAssistant.listenForSpeech();

      if (!mounted) return;

      setState(() {
        _isListening = false;
      });

      if (speech == null ||
          speech.trim().isEmpty) {
        await _speak(
          'I did not hear anything. '
          'Please try again.',
        );

        if (!mounted) return;

        await Future.delayed(
          const Duration(milliseconds: 500),
        );

        _listenForCommand();

        return;
      }

      final String command =
          speech.toLowerCase().trim();

      debugPrint(
        'FEEDBACK COMMAND: "$command"',
      );

      setState(() {
        _isProcessing = true;
        _statusText = 'Heard: $speech';
      });

      await _processCommand(command);
    } catch (e) {
      debugPrint(
        'FEEDBACK LISTEN ERROR: $e',
      );

      if (!mounted) return;

      setState(() {
        _isListening = false;
        _isProcessing = false;
      });

      await _speak(
        'There was a problem understanding you. '
        'Please try again.',
      );

      if (!mounted) return;

      await Future.delayed(
        const Duration(milliseconds: 500),
      );

      _listenForCommand();
    }
  }

  // ============================================================
  // PROCESS COMMAND
  // ============================================================

  Future<void> _processCommand(String command) async {
    try {
      final String text =
          command.toLowerCase().trim();

      // --------------------------------------------------------
      // GIVE FEEDBACK
      // --------------------------------------------------------

      if (_containsAny(text, [
        'give feedback',
        'start feedback',
        'speak feedback',
        'write feedback',
        'feedback',
        'tell you my feedback',
        'i want to give feedback',
      ])) {
        await _startVoiceFeedback();
        return;
      }

      // --------------------------------------------------------
      // SUBMIT
      // --------------------------------------------------------

      if (_containsAny(text, [
        'submit feedback',
        'submit',
        'send feedback',
        'send my feedback',
        'finish feedback',
      ])) {
        setState(() {
          _isProcessing = false;
        });

        await _submitFeedback();
        return;
      }

      // --------------------------------------------------------
      // RATING
      // --------------------------------------------------------

      if (_containsAny(text, [
        'one star',
        'one',
        'rate one',
      ])) {
        await _selectRating(1);
        return;
      }

      if (_containsAny(text, [
        'two stars',
        'two star',
        'rate two',
      ])) {
        await _selectRating(2);
        return;
      }

      if (_containsAny(text, [
        'three stars',
        'three star',
        'rate three',
      ])) {
        await _selectRating(3);
        return;
      }

      if (_containsAny(text, [
        'four stars',
        'four star',
        'rate four',
      ])) {
        await _selectRating(4);
        return;
      }

      if (_containsAny(text, [
        'five stars',
        'five star',
        'rate five',
      ])) {
        await _selectRating(5);
        return;
      }

      // --------------------------------------------------------
      // HELP
      // --------------------------------------------------------

      if (_containsAny(text, [
        'help',
        'what can i say',
        'commands',
      ])) {
        await _speakHelp();

        if (!mounted) return;

        setState(() {
          _isProcessing = false;
        });

        await Future.delayed(
          const Duration(milliseconds: 400),
        );

        _listenForCommand();

        return;
      }

      // --------------------------------------------------------
      // REPEAT
      // --------------------------------------------------------

      if (_containsAny(text, [
        'repeat',
        'repeat that',
        'say that again',
      ])) {
        await _speak(
          'You are on the feedback page. '
          'You can say give feedback to speak your feedback, '
          'say one to five stars to select a rating, '
          'say submit feedback to submit, '
          'or say go back to return to the dashboard.',
        );

        if (!mounted) return;

        setState(() {
          _isProcessing = false;
        });

        await Future.delayed(
          const Duration(milliseconds: 400),
        );

        _listenForCommand();

        return;
      }

      // --------------------------------------------------------
      // BACK
      // --------------------------------------------------------

      if (_containsAny(text, [
        'back',
        'go back',
        'return',
        'return to dashboard',
        'go back to dashboard',
        'dashboard',
      ])) {
        await _goBack();

        return;
      }

      // --------------------------------------------------------
      // UNKNOWN
      // --------------------------------------------------------

      await _speak(
        'I did not understand that command. '
        'Say help to hear the available commands.',
      );

      if (!mounted) return;

      setState(() {
        _isProcessing = false;
      });

      await Future.delayed(
        const Duration(milliseconds: 500),
      );

      _listenForCommand();
    } catch (e) {
      debugPrint(
        'FEEDBACK COMMAND ERROR: $e',
      );

      if (!mounted) return;

      setState(() {
        _isProcessing = false;
      });

      await _speak(
        'An error occurred. Please try again.',
      );

      if (!mounted) return;

      _listenForCommand();
    }
  }

  // ============================================================
  // START VOICE FEEDBACK
  // ============================================================

  Future<void> _startVoiceFeedback() async {
    if (!mounted || _isListening) return;

    try {
      await _voiceAssistant.stop();

      if (!mounted) return;

      setState(() {
        _isListening = false;
        _isProcessing = false;
        _feedbackController.clear();
        _statusText =
            'Preparing to record your feedback...';
      });

      await _speak(
        'Please tell me your feedback now. '
        'You can speak about navigation, accessibility, '
        'voice assistance, maps, or anything you would like us to improve. '
        'Start speaking after the message.',
      );

      if (!mounted) return;

      await Future.delayed(
        const Duration(milliseconds: 600),
      );

      if (!mounted) return;

      setState(() {
        _isListening = true;
        _statusText =
            'Listening for your feedback...';
      });

      final String? feedback =
          await _voiceAssistant.listenForSpeech();

      if (!mounted) return;

      setState(() {
        _isListening = false;
      });

      if (feedback == null ||
          feedback.trim().isEmpty) {
        setState(() {
          _statusText = 'No feedback detected.';
        });

        await _speak(
          'I did not hear your feedback. '
          'Please say give feedback and try again.',
        );

        if (!mounted) return;

        setState(() {
          _isProcessing = false;
        });

        await Future.delayed(
          const Duration(milliseconds: 500),
        );

        _listenForCommand();

        return;
      }

      final String cleanFeedback =
          feedback.trim();

      debugPrint(
        'FEEDBACK VOICE RESULT: $cleanFeedback',
      );

      _feedbackController.text =
          cleanFeedback;

      _feedbackController.selection =
          TextSelection.fromPosition(
        TextPosition(
          offset:
              _feedbackController.text.length,
        ),
      );

      if (!mounted) return;

      setState(() {
        _isProcessing = false;
        _statusText =
            'Feedback captured successfully.';
      });

      await _speak(
        'I heard your feedback. '
        'You can review it and change the text if necessary. '
        'Say submit feedback when you are ready.',
      );

      if (!mounted) return;

      await Future.delayed(
        const Duration(milliseconds: 500),
      );

      _listenForCommand();
    } catch (e) {
      debugPrint(
        'FEEDBACK VOICE INPUT ERROR: $e',
      );

      if (!mounted) return;

      setState(() {
        _isListening = false;
        _isProcessing = false;
      });

      await _speak(
        'There was a problem recording your feedback. '
        'Please try again.',
      );

      if (!mounted) return;

      await Future.delayed(
        const Duration(milliseconds: 500),
      );

      _listenForCommand();
    }
  }

  // ============================================================
  // SELECT RATING
  // ============================================================

  Future<void> _selectRating(int rating) async {
    if (!mounted) return;

    setState(() {
      _rating = rating;
      _isProcessing = false;
      _statusText =
          'Rating selected: $rating out of 5.';
    });

    String ratingText;

    switch (rating) {
      case 1:
        ratingText = 'one star';
        break;
      case 2:
        ratingText = 'two stars';
        break;
      case 3:
        ratingText = 'three stars';
        break;
      case 4:
        ratingText = 'four stars';
        break;
      case 5:
        ratingText = 'five stars';
        break;
      default:
        ratingText = '$rating stars';
    }

    await _speak(
      'You selected $ratingText.',
    );

    if (!mounted) return;

    await Future.delayed(
      const Duration(milliseconds: 400),
    );

    _listenForCommand();
  }

  // ============================================================
  // SUBMIT FEEDBACK
  // ============================================================

  Future<void> _submitFeedback() async {
    if (_isSubmitting) return;

    final String feedback =
        _feedbackController.text.trim();

    if (_rating == 0) {
      await _speak(
        'Please select a rating from one to five stars '
        'before submitting your feedback.',
      );

      if (!mounted) return;

      setState(() {
        _isProcessing = false;
      });

      await Future.delayed(
        const Duration(milliseconds: 400),
      );

      _listenForCommand();

      return;
    }

    if (feedback.isEmpty) {
      await _speak(
        'Please tell me your feedback before submitting.',
      );

      if (!mounted) return;

      setState(() {
        _isProcessing = false;
      });

      await Future.delayed(
        const Duration(milliseconds: 400),
      );

      _listenForCommand();

      return;
    }

    try {
      if (!mounted) return;

      setState(() {
        _isSubmitting = true;
        _isProcessing = false;
        _statusText =
            'Submitting feedback...';
      });

      await _voiceAssistant.stop();

      await _speak(
        'Thank you. '
        'Your feedback has been recorded. '
        'It will help us improve Vision Guide.',
      );

      if (!mounted) return;

      await Future.delayed(
        const Duration(milliseconds: 1000),
      );

      if (!mounted) return;

      setState(() {
        _isSubmitting = false;
        _statusText =
            'Feedback submitted successfully.';
      });

      _showSubmittedDialog();
    } catch (e) {
      debugPrint(
        'FEEDBACK SUBMIT ERROR: $e',
      );

      if (!mounted) return;

      setState(() {
        _isSubmitting = false;
      });

      await _speak(
        'I could not complete the submission. '
        'Please try again.',
      );

      if (!mounted) return;

      _listenForCommand();
    }
  }

  // ============================================================
  // SUBMITTED DIALOG
  // ============================================================

  void _showSubmittedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Row(
            children: [
              const Icon(
                Icons.check_circle,
                color: AppColors.primaryBlue,
                size: 32,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Feedback Submitted',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkBlue,
                    fontSize: 21,
                  ),
                ),
              ),
            ],
          ),
          content: const Text(
            'Thank you for helping us improve Vision Guide.',
            style: TextStyle(
              fontSize: 17,
              height: 1.4,
              color: AppColors.black,
            ),
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(dialogContext);

                  if (mounted) {
                    Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      AppColors.primaryBlue,
                  foregroundColor:
                      AppColors.white,
                  minimumSize:
                      const Size(
                    double.infinity,
                    52,
                  ),
                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(15),
                  ),
                ),
                child: const Text(
                  'DONE',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // HELP
  // ============================================================

  Future<void> _speakHelp() async {
    await _speak(
      'Feedback commands. '
      'Say give feedback to speak your feedback. '
      'Say one star, two stars, three stars, four stars, '
      'or five stars to select your rating. '
      'Say submit feedback when you are ready. '
      'Say repeat to hear the instructions again. '
      'Say go back to return to the dashboard.',
    );
  }

  // ============================================================
  // BACK TO DASHBOARD
  // ============================================================

  Future<void> _goBack() async {
    if (!mounted) return;

    try {
      setState(() {
        _isProcessing = true;
        _isListening = false;
        _statusText =
            'Returning to dashboard...';
      });

      await _voiceAssistant.stop();

      await Future.delayed(
        const Duration(milliseconds: 300),
      );

      if (!mounted) return;

      await _voiceAssistant.speak(
        'Going back to the dashboard.',
      );

      await Future.delayed(
        const Duration(milliseconds: 400),
      );

      if (!mounted) return;

      Navigator.pop(context);
    } catch (e) {
      debugPrint(
        'FEEDBACK BACK ERROR: $e',
      );

      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  // ============================================================
  // PHRASE MATCHING
  // ============================================================

  bool _containsAny(
    String text,
    List<String> phrases,
  ) {
    final String normalized =
        text.toLowerCase().trim();

    for (final String phrase in phrases) {
      if (normalized == phrase) {
        return true;
      }

      if (normalized.contains(phrase)) {
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
    final bool isListening = _isListening;
    final bool isSpeaking = _isSpeaking;
    final bool isReady = _voiceReady;

    return Scaffold(
      backgroundColor: AppColors.primaryBlue,

      // ==========================================================
      // APP BAR
      // ==========================================================

      appBar: AppBar(
        backgroundColor:
            AppColors.primaryBlue,
        foregroundColor:
            AppColors.white,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,

        title: const Text(
          'FEEDBACK',
          style: TextStyle(
            fontSize: 22,
            fontWeight:
                FontWeight.bold,
            color: AppColors.white,
          ),
        ),

        actions: [
          Semantics(
            label:
                'Read feedback instructions',
            button: true,
            child: IconButton(
              tooltip:
                  'Read feedback instructions',
              onPressed: () {
                _speak(
                  'Feedback page. '
                  'You can select a rating, '
                  'give feedback using your voice, '
                  'type your feedback, '
                  'or submit your feedback.',
                );
              },
              icon: const Icon(
                Icons.volume_up,
                size: 28,
                color:
                    AppColors.primaryYellow,
              ),
            ),
          ),
        ],
      ),

      // ==========================================================
      // BODY
      // ==========================================================

      body: SafeArea(
        child: SingleChildScrollView(
          padding:
              const EdgeInsets.fromLTRB(
            18,
            18,
            18,
            30,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints:
                  const BoxConstraints(
                maxWidth: 700,
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.stretch,
                children: [
                  // ==================================================
                  // HEADER CARD
                  // ==================================================

                  Semantics(
                    container: true,
                    header: true,
                    label:
                        'Vision Guide feedback',
                    child: Container(
                      padding:
                          const EdgeInsets.fromLTRB(
                        22,
                        24,
                        22,
                        24,
                      ),
                      decoration:
                          BoxDecoration(
                        color:
                            AppColors.white,
                        borderRadius:
                            BorderRadius.circular(
                          28,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            blurRadius: 12,
                            offset:
                                Offset(0, 5),
                            color:
                                Colors.black26,
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 82,
                            height: 82,
                            decoration:
                                BoxDecoration(
                              shape:
                                  BoxShape.circle,
                              color:
                                  AppColors.white,
                              border:
                                  Border.all(
                                color: AppColors
                                    .primaryYellow,
                                width: 5,
                              ),
                            ),
                            child:
                                const Icon(
                              Icons.feedback,
                              size: 46,
                              color: AppColors
                                  .primaryBlue,
                            ),
                          ),

                          const SizedBox(
                            height: 14,
                          ),

                          const Text(
                            'HELP US IMPROVE',
                            textAlign:
                                TextAlign.center,
                            style: TextStyle(
                              fontSize: 29,
                              fontWeight:
                                  FontWeight.w800,
                              color: AppColors
                                  .primaryBlue,
                              letterSpacing:
                                  0.3,
                            ),
                          ),

                          const SizedBox(
                            height: 6,
                          ),

                          const Text(
                            'VISION GUIDE',
                            textAlign:
                                TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight:
                                  FontWeight.bold,
                              color: AppColors
                                  .primaryRed,
                              letterSpacing:
                                  2,
                            ),
                          ),

                          const SizedBox(
                            height: 12,
                          ),

                          const Text(
                            'Your feedback helps us make '
                            'the application better, '
                            'safer and easier to use.',
                            textAlign:
                                TextAlign.center,
                            style: TextStyle(
                              fontSize: 17,
                              height: 1.45,
                              color:
                                  AppColors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  // ==================================================
                  // VOICE STATUS
                  // ==================================================

                  Semantics(
                    liveRegion: true,
                    label: _statusText,
                    container: true,
                    child: Container(
                      padding:
                          const EdgeInsets.all(
                        20,
                      ),
                      decoration:
                          BoxDecoration(
                        color: isListening
                            ? AppColors
                                .primaryYellow
                            : AppColors.white,
                        borderRadius:
                            BorderRadius.circular(
                          22,
                        ),
                        border:
                            Border.all(
                          color: isListening
                              ? AppColors
                                  .primaryYellow
                              : AppColors
                                  .darkBlue,
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
                            width: 72,
                            height: 72,
                            decoration:
                                BoxDecoration(
                              shape:
                                  BoxShape.circle,
                              color: isListening
                                  ? AppColors
                                      .darkBlue
                                  : AppColors
                                      .lightBlue,
                            ),
                            child: Icon(
                              isListening
                                  ? Icons.mic
                                  : isSpeaking
                                      ? Icons
                                          .record_voice_over
                                      : isReady
                                          ? Icons
                                              .record_voice_over
                                          : Icons
                                              .hourglass_top,
                              color:
                                  AppColors.white,
                              size: 38,
                            ),
                          ),

                          const SizedBox(
                            height: 12,
                          ),

                          Text(
                            isListening
                                ? 'LISTENING'
                                : isSpeaking
                                    ? 'SPEAKING'
                                    : isReady
                                        ? 'VOICE ASSISTANT READY'
                                        : 'STARTING',
                            textAlign:
                                TextAlign.center,
                            style: TextStyle(
                              fontSize: 19,
                              fontWeight:
                                  FontWeight.w800,
                              color: isListening
                                  ? AppColors
                                      .darkBlue
                                  : AppColors
                                      .primaryBlue,
                            ),
                          ),

                          const SizedBox(
                            height: 8,
                          ),

                          Text(
                            _statusText,
                            textAlign:
                                TextAlign.center,
                            style:
                                const TextStyle(
                              fontSize: 16,
                              height: 1.4,
                              color:
                                  AppColors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  // ==================================================
                  // VOICE INSTRUCTION CARD
                  // ==================================================

                  Container(
                    padding:
                        const EdgeInsets.all(
                      20,
                    ),
                    decoration:
                        BoxDecoration(
                      color:
                          AppColors.darkBlue,
                      borderRadius:
                          BorderRadius.circular(
                        22,
                      ),
                      border:
                          Border.all(
                        color:
                            AppColors
                                .primaryYellow,
                        width: 2,
                      ),
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.mic,
                          color:
                              AppColors
                                  .primaryYellow,
                          size: 38,
                        ),

                        const SizedBox(
                          height: 8,
                        ),

                        const Text(
                          'VOICE-FIRST FEEDBACK',
                          textAlign:
                              TextAlign.center,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight:
                                FontWeight.w800,
                            color: AppColors
                                .primaryYellow,
                          ),
                        ),

                        const SizedBox(
                          height: 10,
                        ),

                        const Text(
                          'You can control this page '
                          'using your voice.',
                          textAlign:
                              TextAlign.center,
                          style: TextStyle(
                            fontSize: 17,
                            height: 1.4,
                            color:
                                AppColors.white,
                          ),
                        ),

                        const SizedBox(
                          height: 14,
                        ),

                        _voiceCommand(
                          '“Give feedback”',
                        ),
                        _voiceCommand(
                          '“One to five stars”',
                        ),
                        _voiceCommand(
                          '“Submit feedback”',
                        ),
                        _voiceCommand(
                          '“Help”',
                        ),
                        _voiceCommand(
                          '“Repeat”',
                        ),
                        _voiceCommand(
                          '“Go back”',
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // ==================================================
                  // RATING CARD
                  // ==================================================

                  Semantics(
                    container: true,
                    label:
                        'Rate your experience. '
                        'Current rating is $_rating out of 5.',
                    child: Container(
                      padding:
                          const EdgeInsets.all(
                        20,
                      ),
                      decoration:
                          BoxDecoration(
                        color:
                            AppColors.white,
                        borderRadius:
                            BorderRadius.circular(
                          22,
                        ),
                        border:
                            Border.all(
                          color:
                              AppColors
                                  .primaryYellow,
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
                          const Icon(
                            Icons.star,
                            color: AppColors
                                .primaryYellow,
                            size: 36,
                          ),

                          const SizedBox(
                            height: 5,
                          ),

                          const Text(
                            'RATE YOUR EXPERIENCE',
                            textAlign:
                                TextAlign.center,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight:
                                  FontWeight.w800,
                              color: AppColors
                                  .primaryBlue,
                            ),
                          ),

                          const SizedBox(
                            height: 15,
                          ),

                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment
                                    .center,
                            children:
                                List.generate(
                              5,
                              (index) {
                                final int
                                    starNumber =
                                    index + 1;

                                return Semantics(
                                  label:
                                      '$starNumber star rating',
                                  button:
                                      true,
                                  selected:
                                      starNumber ==
                                          _rating,
                                  child:
                                      IconButton(
                                    onPressed:
                                        () {
                                      _selectRating(
                                        starNumber,
                                      );
                                    },
                                    iconSize:
                                        46,
                                    tooltip:
                                        '$starNumber stars',
                                    icon:
                                        Icon(
                                      starNumber <=
                                              _rating
                                          ? Icons
                                              .star
                                          : Icons
                                              .star_border,
                                      color:
                                          AppColors
                                              .primaryYellow,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),

                          const SizedBox(
                            height: 5,
                          ),

                          Container(
                            padding:
                                const EdgeInsets
                                    .symmetric(
                              horizontal: 18,
                              vertical: 9,
                            ),
                            decoration:
                                BoxDecoration(
                              color: AppColors
                                  .lightBlue
                                  .withValues(
                                alpha: 0.12,
                              ),
                              borderRadius:
                                  BorderRadius
                                      .circular(
                                12,
                              ),
                            ),
                            child: Text(
                              _rating == 0
                                  ? 'No rating selected'
                                  : '$_rating out of 5 stars',
                              style:
                                  const TextStyle(
                                fontSize: 17,
                                fontWeight:
                                    FontWeight.w700,
                                color: AppColors
                                    .darkBlue,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  // ==================================================
                  // SPEAK FEEDBACK
                  // ==================================================

                  Semantics(
                    label: _isListening
                        ? 'Stop listening'
                        : 'Speak your feedback',
                    button: true,
                    child: SizedBox(
                      height: 68,
                      child:
                          ElevatedButton.icon(
                        onPressed: !_voiceReady
                            ? null
                            : (_isListening
                                ? () async {
                                    await _voiceAssistant
                                        .stop();

                                    if (!mounted) {
                                      return;
                                    }

                                    setState(() {
                                      _isListening =
                                          false;
                                      _statusText =
                                          'Listening stopped.';
                                    });
                                  }
                                : _startVoiceFeedback),
                        icon: Icon(
                          _isListening
                              ? Icons.stop
                              : Icons.mic,
                          size: 31,
                        ),
                        label: Text(
                          _isListening
                              ? 'STOP LISTENING'
                              : 'SPEAK YOUR FEEDBACK',
                          style:
                              const TextStyle(
                            fontSize: 18,
                            fontWeight:
                                FontWeight.w800,
                          ),
                        ),
                        style:
                            ElevatedButton
                                .styleFrom(
                          backgroundColor:
                              AppColors
                                  .primaryYellow,
                          foregroundColor:
                              AppColors.black,
                          disabledBackgroundColor:
                              AppColors.grey,
                          disabledForegroundColor:
                              AppColors.black,
                          shape:
                              RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius
                                    .circular(
                              17,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ==================================================
                  // FEEDBACK TEXT FIELD CARD
                  // ==================================================

                  Container(
                    padding:
                        const EdgeInsets.all(
                      18,
                    ),
                    decoration:
                        BoxDecoration(
                      color:
                          AppColors.white,
                      borderRadius:
                          BorderRadius.circular(
                        22,
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
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .stretch,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons
                                  .edit_note,
                              color:
                                  AppColors
                                      .primaryBlue,
                              size: 30,
                            ),
                            SizedBox(
                              width: 10,
                            ),
                            Expanded(
                              child: Text(
                                'YOUR FEEDBACK',
                                style:
                                    TextStyle(
                                  fontSize: 19,
                                  fontWeight:
                                      FontWeight
                                          .w800,
                                  color:
                                      AppColors
                                          .primaryBlue,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(
                          height: 12,
                        ),

                        Semantics(
                          label:
                              'Feedback text field. '
                              'Type your feedback here '
                              'or use voice input.',
                          textField: true,
                          child: TextField(
                            controller:
                                _feedbackController,
                            maxLines: 7,
                            textInputAction:
                                TextInputAction
                                    .newline,
                            decoration:
                                InputDecoration(
                              hintText:
                                  'Tell us about your experience...',
                              hintStyle:
                                  const TextStyle(
                                color:
                                    Colors.black54,
                                fontSize: 16,
                              ),
                              filled: true,
                              fillColor:
                                  AppColors
                                      .lightBlue
                                      .withValues(
                                alpha: 0.08,
                              ),
                              border:
                                  OutlineInputBorder(
                                borderRadius:
                                    BorderRadius
                                        .circular(
                                  15,
                                ),
                                borderSide:
                                    const BorderSide(
                                  color:
                                      AppColors
                                          .primaryBlue,
                                  width: 2,
                                ),
                              ),
                              enabledBorder:
                                  OutlineInputBorder(
                                borderRadius:
                                    BorderRadius
                                        .circular(
                                  15,
                                ),
                                borderSide:
                                    const BorderSide(
                                  color:
                                      AppColors
                                          .lightBlue,
                                  width: 2,
                                ),
                              ),
                              focusedBorder:
                                  OutlineInputBorder(
                                borderRadius:
                                    BorderRadius
                                        .circular(
                                  15,
                                ),
                                borderSide:
                                    const BorderSide(
                                  color:
                                      AppColors
                                          .primaryYellow,
                                  width: 3,
                                ),
                              ),
                              contentPadding:
                                  const EdgeInsets
                                      .all(
                                16,
                              ),
                            ),
                            style:
                                const TextStyle(
                              fontSize: 17,
                              color:
                                  AppColors
                                      .black,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ==================================================
                  // SUBMIT
                  // ==================================================

                  Semantics(
                    label: _isSubmitting
                        ? 'Submitting feedback'
                        : 'Submit feedback',
                    button: true,
                    child: SizedBox(
                      height: 68,
                      child:
                          ElevatedButton.icon(
                        onPressed:
                            _isSubmitting
                                ? null
                                : _submitFeedback,
                        icon: _isSubmitting
                            ? const SizedBox(
                                width: 25,
                                height: 25,
                                child:
                                    CircularProgressIndicator(
                                  strokeWidth:
                                      3,
                                  color:
                                      AppColors
                                          .primaryBlue,
                                ),
                              )
                            : const Icon(
                                Icons.send,
                                size: 28,
                              ),
                        label: Text(
                          _isSubmitting
                              ? 'SUBMITTING...'
                              : 'SUBMIT FEEDBACK',
                          style:
                              const TextStyle(
                            fontSize: 19,
                            fontWeight:
                                FontWeight.w800,
                          ),
                        ),
                        style:
                            ElevatedButton
                                .styleFrom(
                          backgroundColor:
                              AppColors.white,
                          foregroundColor:
                              AppColors
                                  .primaryBlue,
                          disabledBackgroundColor:
                              AppColors.grey,
                          disabledForegroundColor:
                              AppColors
                                  .darkBlue,
                          side:
                              const BorderSide(
                            color:
                                AppColors
                                    .primaryYellow,
                            width: 3,
                          ),
                          shape:
                              RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius
                                    .circular(
                              17,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 15),

                  // ==================================================
                  // STOP VOICE
                  // ==================================================

                  if (_isSpeaking)
                    Semantics(
                      label:
                          'Stop voice instructions',
                      button: true,
                      child:
                          TextButton.icon(
                        onPressed:
                            _stopVoice,
                        icon: const Icon(
                          Icons.volume_off,
                          color: AppColors
                              .white,
                        ),
                        label:
                            const Text(
                          'STOP VOICE',
                          style:
                              TextStyle(
                            fontSize: 16,
                            fontWeight:
                                FontWeight.bold,
                            color:
                                AppColors
                                    .white,
                          ),
                        ),
                      ),
                    ),

                  const SizedBox(height: 10),

                  // ==================================================
                  // BACK TO DASHBOARD
                  // ==================================================

                  Semantics(
                    label:
                        'Back to dashboard',
                    button: true,
                    child: SizedBox(
                      height: 58,
                      child:
                          OutlinedButton(
                        onPressed: _goBack,
                        style:
                            OutlinedButton
                                .styleFrom(
                          foregroundColor:
                              AppColors.white,
                          side:
                              const BorderSide(
                            color:
                                AppColors.white,
                            width: 2,
                          ),
                          shape:
                              RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius
                                    .circular(
                              17,
                            ),
                          ),
                        ),
                        child:
                            const Text(
                          'BACK TO DASHBOARD',
                          style:
                              TextStyle(
                            fontSize: 17,
                            fontWeight:
                                FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ==================================================
                  // FOOTER
                  // ==================================================

                  Container(
                    padding:
                        const EdgeInsets
                            .symmetric(
                      vertical: 16,
                      horizontal: 18,
                    ),
                    decoration:
                        BoxDecoration(
                      color:
                          AppColors.darkBlue,
                      borderRadius:
                          BorderRadius.circular(
                        18,
                      ),
                      border:
                          Border.all(
                        color:
                            AppColors
                                .primaryYellow,
                        width: 1.5,
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment:
                          MainAxisAlignment
                              .center,
                      children: [
                        Icon(
                          Icons
                              .record_voice_over,
                          color: AppColors
                              .primaryYellow,
                          size: 24,
                        ),
                        SizedBox(
                          width: 10,
                        ),
                        Flexible(
                          child: Text(
                            'VOICE-FIRST ACCESSIBLE FEEDBACK',
                            textAlign:
                                TextAlign.center,
                            style:
                                TextStyle(
                              fontSize: 13,
                              fontWeight:
                                  FontWeight.bold,
                              color:
                                  AppColors
                                      .white,
                              letterSpacing:
                                  0.8,
                            ),
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
  // VOICE COMMAND DISPLAY
  // ============================================================

  Widget _voiceCommand(
    String command,
  ) {
    return Container(
      width: double.infinity,
      margin:
          const EdgeInsets.only(
        bottom: 8,
      ),
      padding:
          const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 11,
      ),
      decoration:
          BoxDecoration(
        color:
            AppColors.white,
        borderRadius:
            BorderRadius.circular(
          12,
        ),
        border:
            Border.all(
          color:
              AppColors.primaryYellow,
          width: 1.5,
        ),
      ),
      child: Text(
        command,
        textAlign:
            TextAlign.center,
        style:
            const TextStyle(
          fontSize: 16,
          fontWeight:
              FontWeight.w700,
          color:
              AppColors.darkBlue,
        ),
      ),
    );
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _feedbackController.dispose();

    _voiceAssistant.stop();

    super.dispose();
  }
}