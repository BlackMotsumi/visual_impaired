import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../../../models/campus_building.dart';
import '../../../theme/app_theme.dart';

class CampusInfoScreen extends StatefulWidget {
  const CampusInfoScreen({super.key});

  @override
  State<CampusInfoScreen> createState() => _CampusInfoScreenState();
}

class _CampusInfoScreenState extends State<CampusInfoScreen> {
  final FlutterTts _tts = FlutterTts();

  final stt.SpeechToText _speech = stt.SpeechToText();

  CampusBuilding? _selectedBuilding;

  bool _isSpeaking = false;
  bool _isListening = false;
  bool _speechAvailable = false;
  bool _isProcessingCommand = false;
  bool _isDisposed = false;
  bool _shouldListen = true;

  // ============================================================
  // CUT BLOEMFONTEIN CAMPUS BUILDINGS
  // ============================================================

  final List<CampusBuilding> _buildings = const [
    CampusBuilding(
      name: 'ZR Mahabane Building',
      type: 'Administration',
      icon: Icons.account_balance,
      description:
          'The ZR Mahabane Building is one of the main administrative buildings on the CUT Bloemfontein campus.',
      seats: 'Administrative facilities',
      openingTime: '08:00',
      closingTime: '16:30',
      latitude: null,
      longitude: null,
    ),
    CampusBuilding(
      name: 'Japie van Lill Auditorium',
      type: 'Auditorium',
      icon: Icons.theaters,
      description:
          'The Japie van Lill Auditorium is a university auditorium used for academic and university events.',
      seats: 'Auditorium seating',
      openingTime: '08:00',
      closingTime: '17:00',
      latitude: null,
      longitude: null,
    ),
    CampusBuilding(
      name:
          'Faculty of Engineering, Built-Environment and Information Technology',
      type: 'Faculty',
      icon: Icons.engineering,
      description:
          'This faculty provides facilities for engineering, built-environment and information technology programmes.',
      seats: 'Academic facilities',
      openingTime: '08:00',
      closingTime: '17:00',
      latitude: null,
      longitude: null,
    ),
    CampusBuilding(
      name: 'Engineering Technology Building',
      type: 'Engineering',
      icon: Icons.precision_manufacturing,
      description:
          'The Engineering Technology Building provides teaching and learning facilities for engineering technology.',
      seats: 'Lecture and laboratory facilities',
      openingTime: '08:00',
      closingTime: '17:00',
      latitude: null,
      longitude: null,
    ),
    CampusBuilding(
      name: 'BHP Billiton Lecture Block',
      type: 'Lecture Block',
      icon: Icons.school,
      description:
          'The BHP Billiton Lecture Block provides lecture and academic teaching facilities.',
      seats: 'Lecture facilities',
      openingTime: '08:00',
      closingTime: '17:00',
      latitude: null,
      longitude: null,
    ),
    CampusBuilding(
      name: 'Residence: Loggies',
      type: 'Residence',
      icon: Icons.hotel,
      description:
          'Loggies is a student residence on the CUT Bloemfontein campus.',
      seats: 'Student accommodation',
      openingTime: '00:00',
      closingTime: '23:59',
      latitude: null,
      longitude: null,
    ),
    CampusBuilding(
      name: 'Estates and Infrastructure Offices',
      type: 'Administration',
      icon: Icons.business,
      description:
          'The Estates and Infrastructure Offices support campus infrastructure and facilities management.',
      seats: 'Office facilities',
      openingTime: '08:00',
      closingTime: '16:30',
      latitude: null,
      longitude: null,
    ),
    CampusBuilding(
      name: 'Workshop',
      type: 'Workshop',
      icon: Icons.build,
      description:
          'The workshop provides practical facilities used for university technical activities.',
      seats: 'Workshop facilities',
      openingTime: '08:00',
      closingTime: '17:00',
      latitude: null,
      longitude: null,
    ),
    CampusBuilding(
      name: 'Ya Rona Building',
      type: 'Academic Building',
      icon: Icons.school,
      description:
          'The Ya Rona Building provides academic facilities on the Bloemfontein campus.',
      seats: 'Academic facilities',
      openingTime: '08:00',
      closingTime: '17:00',
      latitude: null,
      longitude: null,
    ),
    CampusBuilding(
      name: 'Exchange House',
      type: 'University Building',
      icon: Icons.business,
      description:
          'Exchange House is one of the buildings located on the CUT Bloemfontein campus.',
      seats: 'University facilities',
      openingTime: '08:00',
      closingTime: '17:00',
      latitude: null,
      longitude: null,
    ),
    CampusBuilding(
      name: 'CUT Pavilion',
      type: 'Campus Facility',
      icon: Icons.location_city,
      description:
          'The CUT Pavilion is a campus facility located on the Bloemfontein campus.',
      seats: 'Campus facility',
      openingTime: '08:00',
      closingTime: '17:00',
      latitude: null,
      longitude: null,
    ),
    CampusBuilding(
      name: 'Main Hall',
      type: 'Hall',
      icon: Icons.groups,
      description:
          'The Main Hall is a major university venue used for university activities and events.',
      seats: 'Hall seating',
      openingTime: '08:00',
      closingTime: '17:00',
      latitude: null,
      longitude: null,
    ),
    CampusBuilding(
      name: 'Emergency Medical Care',
      type: 'Medical',
      icon: Icons.emergency,
      description:
          'Emergency Medical Care provides emergency-related medical facilities on campus.',
      seats: 'Medical facilities',
      openingTime: '08:00',
      closingTime: '17:00',
      latitude: null,
      longitude: null,
    ),
    CampusBuilding(
      name: 'Dirk Coetzee Building',
      type: 'Health and Environmental Sciences',
      icon: Icons.science,
      description:
          'The Dirk Coetzee Building is associated with the Faculty of Health and Environmental Sciences.',
      seats: 'Academic facilities',
      openingTime: '08:00',
      closingTime: '17:00',
      latitude: null,
      longitude: null,
    ),
    CampusBuilding(
      name: 'Prosperitas Auditorium',
      type: 'Auditorium',
      icon: Icons.theaters,
      description:
          'The Prosperitas Auditorium is a university auditorium used for academic and university activities.',
      seats: 'Auditorium seating',
      openingTime: '08:00',
      closingTime: '17:00',
      latitude: null,
      longitude: null,
    ),
    CampusBuilding(
      name: 'School of Tourism, Hospitality and Sport',
      type: 'School',
      icon: Icons.sports,
      description:
          'The School of Tourism, Hospitality and Sport provides academic facilities for tourism, hospitality and sport-related programmes.',
      seats: 'Academic facilities',
      openingTime: '08:00',
      closingTime: '17:00',
      latitude: null,
      longitude: null,
    ),
    CampusBuilding(
      name: 'Residence: Welgemoed',
      type: 'Residence',
      icon: Icons.hotel,
      description:
          'Welgemoed is a student residence on the CUT Bloemfontein campus.',
      seats: 'Student accommodation',
      openingTime: '00:00',
      closingTime: '23:59',
      latitude: null,
      longitude: null,
    ),
    CampusBuilding(
      name: 'Medical Clinic',
      type: 'Medical',
      icon: Icons.local_hospital,
      description:
          'The university medical clinic provides healthcare and basic medical services to students and staff.',
      seats: 'Medical consultation facilities',
      openingTime: '08:00',
      closingTime: '16:30',
      latitude: -29.12070,
      longitude: 26.21490,
    ),
    CampusBuilding(
      name: 'Boet Troskie Hall',
      type: 'Hall',
      icon: Icons.groups,
      description:
          'Boet Troskie Hall is a university hall used for campus events and activities.',
      seats: 'Hall seating',
      openingTime: '08:00',
      closingTime: '17:00',
      latitude: null,
      longitude: null,
    ),
    CampusBuilding(
      name: 'Ellen Khuzwayo Building',
      type: 'Academic Building',
      icon: Icons.school,
      description:
          'The Ellen Khuzwayo Building is one of the academic buildings on the CUT Bloemfontein campus.',
      seats: 'Academic facilities',
      openingTime: '08:00',
      closingTime: '17:00',
      latitude: null,
      longitude: null,
    ),
    CampusBuilding(
      name: 'Maintenance and Central Deliveries',
      type: 'Facilities',
      icon: Icons.handyman,
      description:
          'This facility supports campus maintenance and central deliveries.',
      seats: 'Facilities services',
      openingTime: '08:00',
      closingTime: '16:30',
      latitude: null,
      longitude: null,
    ),
    CampusBuilding(
      name: 'Vehicle Park',
      type: 'Parking',
      icon: Icons.local_parking,
      description:
          'The Vehicle Park provides parking facilities on the CUT Bloemfontein campus.',
      seats: 'Parking facilities',
      openingTime: '00:00',
      closingTime: '23:59',
      latitude: null,
      longitude: null,
    ),
    CampusBuilding(
      name: 'Community Engagement and International Offices',
      type: 'University Offices',
      icon: Icons.public,
      description:
          'These offices support community engagement and international activities at CUT.',
      seats: 'Office facilities',
      openingTime: '08:00',
      closingTime: '16:30',
      latitude: null,
      longitude: null,
    ),
    CampusBuilding(
      name: 'Gym Hall / Idea Generator',
      type: 'Campus Facility',
      icon: Icons.lightbulb,
      description:
          'The Gym Hall and Idea Generator are campus facilities listed on the Bloemfontein campus map.',
      seats: 'Campus facilities',
      openingTime: '08:00',
      closingTime: '17:00',
      latitude: null,
      longitude: null,
    ),
    CampusBuilding(
      name: 'Bethuel Setai Library',
      type: 'Library',
      icon: Icons.local_library,
      description:
          'The Bethuel Setai Library and Information Services Building provides library resources, study spaces and academic support.',
      seats: '240 study seats',
      openingTime: '08:00',
      closingTime: '21:00',
      latitude: -29.12128,
      longitude: 26.21563,
    ),
    CampusBuilding(
      name: 'Centre for e-Learning and Educational Technology',
      type: 'Educational Technology',
      icon: Icons.computer,
      description:
          'The Centre for e-Learning and Educational Technology supports digital learning and educational technology.',
      seats: 'Learning technology facilities',
      openingTime: '08:00',
      closingTime: '17:00',
      latitude: null,
      longitude: null,
    ),
    CampusBuilding(
      name: 'Petrus Molemela Building',
      type: 'Academic Building',
      icon: Icons.school,
      description:
          'The Petrus Molemela Building is an academic and university building on the Bloemfontein campus.',
      seats: 'Academic and office facilities',
      openingTime: '08:00',
      closingTime: '17:00',
      latitude: null,
      longitude: null,
    ),
    CampusBuilding(
      name: 'Humanitas Office Complex',
      type: 'Office Complex',
      icon: Icons.business,
      description:
          'The Humanitas Office Complex contains university office facilities.',
      seats: 'Office facilities',
      openingTime: '08:00',
      closingTime: '16:30',
      latitude: null,
      longitude: null,
    ),
    CampusBuilding(
      name: 'Artec Hall',
      type: 'Hall',
      icon: Icons.palette,
      description:
          'Artec Hall is a campus facility listed on the CUT Bloemfontein campus map.',
      seats: 'Hall facilities',
      openingTime: '08:00',
      closingTime: '17:00',
      latitude: null,
      longitude: null,
    ),
    CampusBuilding(
      name: 'Lapeng Student Centre / Wellness Centre',
      type: 'Student Centre',
      icon: Icons.favorite,
      description:
          'Lapeng Student Centre and Wellness Centre provide student support and wellness-related facilities.',
      seats: 'Student support facilities',
      openingTime: '08:00',
      closingTime: '17:00',
      latitude: null,
      longitude: null,
    ),
    CampusBuilding(
      name: 'Filling Station and ABSA ATM',
      type: 'Campus Service',
      icon: Icons.local_gas_station,
      description:
          'The campus map lists a filling station and ABSA ATM as campus services.',
      seats: 'Campus service',
      openingTime: '00:00',
      closingTime: '23:59',
      latitude: null,
      longitude: null,
    ),
    CampusBuilding(
      name: 'Artis',
      type: 'Arts Building',
      icon: Icons.brush,
      description:
          'Artis is one of the arts-related buildings on the CUT Bloemfontein campus.',
      seats: 'Arts facilities',
      openingTime: '08:00',
      closingTime: '17:00',
      latitude: null,
      longitude: null,
    ),
    CampusBuilding(
      name: 'Amoenitas',
      type: 'Arts Building',
      icon: Icons.design_services,
      description:
          'Amoenitas is one of the buildings on the CUT Bloemfontein campus.',
      seats: 'Academic facilities',
      openingTime: '08:00',
      closingTime: '17:00',
      latitude: null,
      longitude: null,
    ),
    CampusBuilding(
      name: 'Residence: Eendrag',
      type: 'Residence',
      icon: Icons.hotel,
      description:
          'Eendrag is a student residence on the CUT Bloemfontein campus.',
      seats: 'Student accommodation',
      openingTime: '00:00',
      closingTime: '23:59',
      latitude: null,
      longitude: null,
    ),
    CampusBuilding(
      name: 'Kamelia Annex',
      type: 'Jewellery School',
      icon: Icons.diamond,
      description:
          'The Kamelia Annex is associated with the Jewellery School.',
      seats: 'Academic facilities',
      openingTime: '08:00',
      closingTime: '17:00',
      latitude: null,
      longitude: null,
    ),
    CampusBuilding(
      name: 'Residence: Technikon',
      type: 'Residence',
      icon: Icons.hotel,
      description:
          'Technikon is a student residence on the CUT Bloemfontein campus.',
      seats: 'Student accommodation',
      openingTime: '00:00',
      closingTime: '23:59',
      latitude: null,
      longitude: null,
    ),
    CampusBuilding(
      name: 'Dental Assisting and Maxillofacial Laboratories',
      type: 'Laboratory',
      icon: Icons.medical_services,
      description:
          'These laboratories support dental assisting and maxillofacial academic activities.',
      seats: 'Laboratory facilities',
      openingTime: '08:00',
      closingTime: '17:00',
      latitude: null,
      longitude: null,
    ),
    CampusBuilding(
      name: 'Student Academic Support Centre',
      type: 'Student Support',
      icon: Icons.support_agent,
      description:
          'The Student Academic Support Centre provides academic support services to students.',
      seats: 'Student support facilities',
      openingTime: '08:00',
      closingTime: '17:00',
      latitude: null,
      longitude: null,
    ),
    CampusBuilding(
      name: 'Tataisong Building',
      type: 'Academic Building',
      icon: Icons.school,
      description:
          'The Tataisong Building is an academic building on the CUT Bloemfontein campus.',
      seats: 'Academic facilities',
      openingTime: '08:00',
      closingTime: '17:00',
      latitude: null,
      longitude: null,
    ),
    CampusBuilding(
      name: 'Kopanong Building',
      type: 'Academic Building',
      icon: Icons.school,
      description:
          'The Kopanong Building is an academic building on the CUT Bloemfontein campus.',
      seats: 'Academic facilities',
      openingTime: '08:00',
      closingTime: '17:00',
      latitude: null,
      longitude: null,
    ),
    CampusBuilding(
      name: 'Residence: Graduandi House',
      type: 'Residence',
      icon: Icons.hotel,
      description:
          'Graduandi House is a student residence on the CUT Bloemfontein campus.',
      seats: 'Student accommodation',
      openingTime: '00:00',
      closingTime: '23:59',
      latitude: null,
      longitude: null,
    ),
    CampusBuilding(
      name: 'Science Park',
      type: 'Science Facility',
      icon: Icons.science,
      description:
          'Science Park is a science-related facility on the CUT Bloemfontein campus.',
      seats: 'Science facilities',
      openingTime: '08:00',
      closingTime: '17:00',
      latitude: null,
      longitude: null,
    ),
  ];

  // ============================================================
  // INITIALIZATION
  // ============================================================

  @override
  void initState() {
    super.initState();

    _initializeVoice();
  }

  Future<void> _initializeVoice() async {
    if (_isDisposed) {
      return;
    }

    await _configureTts();

    if (!mounted || _isDisposed) {
      return;
    }

    await _initializeSpeech();

    if (!mounted || _isDisposed) {
      return;
    }

    await Future<void>.delayed(
      const Duration(milliseconds: 400),
    );

    if (!mounted || _isDisposed) {
      return;
    }

    await _speakIntroduction();

    if (!mounted || _isDisposed) {
      return;
    }

    await Future<void>.delayed(
      const Duration(milliseconds: 500),
    );

    if (!mounted || _isDisposed) {
      return;
    }

    if (_speechAvailable) {
      await _voiceLoop();
    }
  }

  // ============================================================
  // TTS CONFIGURATION
  // ============================================================

  Future<void> _configureTts() async {
    try {
      await _tts.setLanguage('en-ZA');
      await _tts.setSpeechRate(0.45);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);
      await _tts.awaitSpeakCompletion(true);

      _tts.setStartHandler(() {
        if (!mounted || _isDisposed) {
          return;
        }

        setState(() {
          _isSpeaking = true;
        });
      });

      _tts.setCompletionHandler(() {
        if (!mounted || _isDisposed) {
          return;
        }

        setState(() {
          _isSpeaking = false;
        });
      });

      _tts.setCancelHandler(() {
        if (!mounted || _isDisposed) {
          return;
        }

        setState(() {
          _isSpeaking = false;
        });
      });

      _tts.setErrorHandler((message) {
        debugPrint('TTS ERROR: $message');

        if (!mounted || _isDisposed) {
          return;
        }

        setState(() {
          _isSpeaking = false;
        });
      });

      debugPrint('CAMPUS INFO TTS INITIALIZED');
    } catch (e) {
      debugPrint('TTS INITIALIZATION ERROR: $e');
    }
  }

  // ============================================================
  // SPEAK INTRODUCTION
  // ============================================================

  Future<void> _speakIntroduction() async {
    try {
      await _speak(
        'Welcome to Campus Information. '
        'This section provides information about buildings '
        'and facilities at the CUT Bloemfontein campus. '
        'You can say list buildings, '
        'or ask me about a specific building. '
        'For example, say tell me about the library, '
        'or tell me about the medical clinic. '
        'When you are finished, say go back to dashboard.',
      );
    } catch (e) {
      debugPrint('INTRODUCTION ERROR: $e');
    }
  }

  // ============================================================
  // SPEAK
  // ============================================================

  Future<void> _speak(String message) async {
    if (_isDisposed) {
      return;
    }

    try {
      await _speech.stop();

      if (mounted) {
        setState(() {
          _isListening = false;
          _isSpeaking = true;
        });
      }

      debugPrint('CAMPUS INFO SPEAK: $message');

      await _tts.stop();
      await _tts.speak(message);

      if (!mounted || _isDisposed) {
        return;
      }

      setState(() {
        _isSpeaking = false;
      });
    } catch (e) {
      debugPrint('SPEAK ERROR: $e');

      if (!mounted || _isDisposed) {
        return;
      }

      setState(() {
        _isSpeaking = false;
      });
    }
  }

  // ============================================================
  // INITIALIZE SPEECH
  // ============================================================

  Future<void> _initializeSpeech() async {
    try {
      final bool available = await _speech.initialize(
        onStatus: (String status) {
          debugPrint('CAMPUS INFO SPEECH STATUS: $status');

          if (!mounted || _isDisposed) {
            return;
          }

          if (status == 'listening') {
            setState(() {
              _isListening = true;
            });
          }

          if (status == 'notListening' || status == 'done') {
            setState(() {
              _isListening = false;
            });
          }
        },
        onError: (dynamic error) {
          debugPrint('CAMPUS INFO SPEECH ERROR: $error');

          if (!mounted || _isDisposed) {
            return;
          }

          setState(() {
            _isListening = false;
          });
        },
      );

      if (!mounted || _isDisposed) {
        return;
      }

      setState(() {
        _speechAvailable = available;
      });

      debugPrint(
        'CAMPUS INFO SPEECH AVAILABLE: $_speechAvailable',
      );
    } catch (e) {
      debugPrint('SPEECH INITIALIZATION ERROR: $e');

      if (!mounted || _isDisposed) {
        return;
      }

      setState(() {
        _speechAvailable = false;
        _isListening = false;
      });
    }
  }

  // ============================================================
  // MAIN VOICE LOOP
  // ============================================================

  Future<void> _voiceLoop() async {
    if (_isDisposed || !mounted || !_speechAvailable) {
      return;
    }

    while (mounted && !_isDisposed && _shouldListen) {
      if (_isProcessingCommand) {
        await Future<void>.delayed(
          const Duration(milliseconds: 300),
        );

        continue;
      }

      if (_isSpeaking) {
        await Future<void>.delayed(
          const Duration(milliseconds: 300),
        );

        continue;
      }

      final String? command = await _listenForCommand();

      if (!mounted || _isDisposed || !_shouldListen) {
        break;
      }

      if (command == null || command.trim().isEmpty) {
        await Future<void>.delayed(
          const Duration(milliseconds: 500),
        );

        continue;
      }

      await _processVoiceCommand(command);

      if (!mounted || _isDisposed || !_shouldListen) {
        break;
      }

      await Future<void>.delayed(
        const Duration(milliseconds: 500),
      );
    }
  }

  // ============================================================
  // LISTEN FOR ONE COMMAND
  // ============================================================

  Future<String?> _listenForCommand() async {
    if (!_speechAvailable || _isDisposed || !mounted) {
      return null;
    }

    if (_isSpeaking) {
      return null;
    }

    final StringBuffer recognizedText = StringBuffer();

    bool completed = false;

    try {
      await _speech.stop();

      if (!mounted || _isDisposed) {
        return null;
      }

      setState(() {
        _isListening = true;
      });

      debugPrint('CAMPUS INFO: START LISTENING');

      await _speech.listen(
        localeId: 'en_ZA',
        listenMode: stt.ListenMode.confirmation,
        partialResults: true,
        cancelOnError: true,
        listenFor: const Duration(seconds: 15),
        pauseFor: const Duration(seconds: 3),
        onResult: (result) {
          final String words =
              result.recognizedWords.trim();

          if (words.isNotEmpty) {
            recognizedText.clear();
            recognizedText.write(words);
          }

          debugPrint(
            'CAMPUS INFO RECOGNIZED: $words',
          );

          if (result.finalResult) {
            completed = true;
          }
        },
      );

      int attempts = 0;

      while (!completed &&
          attempts < 40 &&
          mounted &&
          !_isDisposed) {
        await Future<void>.delayed(
          const Duration(milliseconds: 250),
        );

        attempts++;
      }

      await _speech.stop();

      if (!mounted || _isDisposed) {
        return null;
      }

      setState(() {
        _isListening = false;
      });

      final String result =
          recognizedText.toString().trim();

      debugPrint(
        'CAMPUS INFO FINAL COMMAND: $result',
      );

      return result.isEmpty ? null : result;
    } catch (e) {
      debugPrint('LISTEN COMMAND ERROR: $e');

      try {
        await _speech.stop();
      } catch (_) {}

      if (!mounted || _isDisposed) {
        return null;
      }

      setState(() {
        _isListening = false;
      });

      return null;
    }
  }

  // ============================================================
  // PROCESS VOICE COMMAND
  // ============================================================

  Future<void> _processVoiceCommand(
    String command,
  ) async {
    if (_isDisposed ||
        !mounted ||
        _isProcessingCommand) {
      return;
    }

    _isProcessingCommand = true;

    try {
      await _speech.stop();

      if (mounted) {
        setState(() {
          _isListening = false;
        });
      }

      final String text =
          command.toLowerCase().trim();

      debugPrint(
        'CAMPUS INFO COMMAND: $text',
      );

      if (_isBackCommand(text)) {
        await _returnToDashboard();
        return;
      }

      if (_containsAny(text, [
        'stop',
        'be quiet',
        'quiet',
        'stop talking',
      ])) {
        await _tts.stop();

        if (mounted) {
          setState(() {
            _isSpeaking = false;
          });
        }

        return;
      }

      if (_containsAny(text, [
        'help',
        'what can i say',
        'what can i do',
        'commands',
        'options',
      ])) {
        await _speak(
          'You can say list buildings, '
          'or ask me about a building. '
          'For example, say tell me about the library, '
          'tell me about the medical clinic, '
          'or tell me about the main hall. '
          'When you are finished, say go back to dashboard.',
        );

        return;
      }

      if (_isListCommand(text)) {
        await _speakBuildingList();
        return;
      }

      final CampusBuilding? building =
          _findBuildingFromCommand(text);

      if (building != null) {
        await _showBuildingInformation(building);
        return;
      }

      await _speak(
        'I did not understand that command. '
        'You can say list buildings, '
        'tell me about the library, '
        'tell me about the medical clinic, '
        'or say go back to dashboard.',
      );
    } finally {
      _isProcessingCommand = false;
    }
  }

  // ============================================================
  // BACK COMMAND
  // ============================================================

  bool _isBackCommand(String text) {
    return _containsAny(text, [
      'go back',
      'back',
      'go back to dashboard',
      'back to dashboard',
      'return to dashboard',
      'return dashboard',
      'dashboard',
      'go to dashboard',
      'take me to dashboard',
      'exit campus information',
      'close campus information',
      'leave campus information',
    ]);
  }

  // ============================================================
  // LIST COMMAND
  // ============================================================

  bool _isListCommand(String text) {
    return _containsAny(text, [
      'list buildings',
      'list the buildings',
      'show buildings',
      'show me the buildings',
      'what buildings are there',
      'which buildings are there',
      'available buildings',
      'what buildings can i visit',
      'campus buildings',
    ]);
  }

  // ============================================================
  // SHOW BUILDING INFORMATION
  // ============================================================

  Future<void> _showBuildingInformation(
    CampusBuilding building,
  ) async {
    if (!mounted || _isDisposed) {
      return;
    }

    await _tts.stop();

    setState(() {
      _selectedBuilding = building;
    });

    final String coordinates =
        building.latitude != null &&
                building.longitude != null
            ? 'The GPS coordinates are '
                '${building.latitude} '
                'and ${building.longitude}.'
            : 'GPS coordinates are not currently configured '
                'for this location.';

    final String message =
        '${building.name}. '
        '${building.description} '
        'This location is classified as '
        '${building.type}. '
        '${building.seats}. '
        'Opening hours are from '
        '${building.openingTime} '
        'to ${building.closingTime}. '
        '$coordinates '
        'That is the information about '
        '${building.name}. '
        'You can ask about another building, '
        'say list buildings, '
        'or say go back to dashboard.';

    await _speak(message);
  }

  // ============================================================
  // SPEAK BUILDING LIST
  // ============================================================

  Future<void> _speakBuildingList() async {
    final String message =
        'Here are some of the buildings and facilities '
        'available on the CUT Bloemfontein campus. '
        'Bethuel Setai Library. '
        'Medical Clinic. '
        'ZR Mahabane Building. '
        'Japie van Lill Auditorium. '
        'Faculty of Engineering, Built-Environment '
        'and Information Technology. '
        'Engineering Technology Building. '
        'BHP Billiton Lecture Block. '
        'Main Hall. '
        'Emergency Medical Care. '
        'Dirk Coetzee Building. '
        'Prosperitas Auditorium. '
        'Boet Troskie Hall. '
        'Student Academic Support Centre. '
        'Tataisong Building. '
        'Kopanong Building. '
        'Science Park. '
        'Ya Rona Building. '
        'Petrus Molemela Building. '
        'Humanitas Office Complex. '
        'Lapeng Student Centre and Wellness Centre. '
        'Artis. '
        'Amoenitas. '
        'Kamelia Annex. '
        'Dental Assisting and Maxillofacial Laboratories. '
        'Vehicle Park. '
        'Community Engagement and International Offices. '
        'Gym Hall and Idea Generator. '
        'There are also several student residences. '
        'You can now say the name of any building '
        'to hear more information. '
        'Or say go back to dashboard.';

    await _speak(message);
  }

  // ============================================================
  // FIND BUILDING FROM COMMAND
  // ============================================================

  CampusBuilding? _findBuildingFromCommand(
    String command,
  ) {
    final String text =
        command.toLowerCase().trim();

    for (final building in _buildings) {
      final String name =
          building.name.toLowerCase();

      if (text.contains(name)) {
        return building;
      }
    }

    if (_containsAny(text, [
      'library',
      'setai',
      'bethuel',
    ])) {
      return _findByName(
        'Bethuel Setai Library',
      );
    }

    if (_containsAny(text, [
      'medical clinic',
      'clinic',
      'health clinic',
    ])) {
      return _findByName(
        'Medical Clinic',
      );
    }

    if (_containsAny(text, [
      'engineering technology',
      'engineering building',
      'engineering',
    ])) {
      return _findByName(
        'Engineering Technology Building',
      );
    }

    if (_containsAny(text, [
      'main hall',
    ])) {
      return _findByName(
        'Main Hall',
      );
    }

    if (_containsAny(text, [
      'student academic support',
      'academic support',
      'support centre',
      'support center',
    ])) {
      return _findByName(
        'Student Academic Support Centre',
      );
    }

    if (_containsAny(text, [
      'tataisong',
    ])) {
      return _findByName(
        'Tataisong Building',
      );
    }

    if (_containsAny(text, [
      'kopanong',
    ])) {
      return _findByName(
        'Kopanong Building',
      );
    }

    if (_containsAny(text, [
      'science park',
    ])) {
      return _findByName(
        'Science Park',
      );
    }

    if (_containsAny(text, [
      'ya rona',
    ])) {
      return _findByName(
        'Ya Rona Building',
      );
    }

    if (_containsAny(text, [
      'petrus molemela',
      'molemela',
    ])) {
      return _findByName(
        'Petrus Molemela Building',
      );
    }

    if (_containsAny(text, [
      'dirk coetzee',
      'dirk',
    ])) {
      return _findByName(
        'Dirk Coetzee Building',
      );
    }

    if (_containsAny(text, [
      'ellen khuzwayo',
      'ellen kuzwayo',
      'khuzwayo',
    ])) {
      return _findByName(
        'Ellen Khuzwayo Building',
      );
    }

    if (_containsAny(text, [
      'boet troskie',
      'troskie',
    ])) {
      return _findByName(
        'Boet Troskie Hall',
      );
    }

    if (_containsAny(text, [
      'prosperitas',
    ])) {
      return _findByName(
        'Prosperitas Auditorium',
      );
    }

    if (_containsAny(text, [
      'japie',
      'japie van lill',
    ])) {
      return _findByName(
        'Japie van Lill Auditorium',
      );
    }

    if (_containsAny(text, [
      'humanitas',
    ])) {
      return _findByName(
        'Humanitas Office Complex',
      );
    }

    if (_containsAny(text, [
      'lapeng',
      'wellness',
      'wellness centre',
      'wellness center',
    ])) {
      return _findByName(
        'Lapeng Student Centre / Wellness Centre',
      );
    }

    if (_containsAny(text, [
      'mahabane',
      'mahobane',
      'mahaba',
      'zr mah',
      'administration building',
    ])) {
      return _findByName(
        'ZR Mahabane Building',
      );
    }

    if (_containsAny(text, [
      'artis',
    ])) {
      return _findByName(
        'Artis',
      );
    }

    if (_containsAny(text, [
      'amoenitas',
    ])) {
      return _findByName(
        'Amoenitas',
      );
    }

    if (_containsAny(text, [
      'eendrag',
    ])) {
      return _findByName(
        'Residence: Eendrag',
      );
    }

    if (_containsAny(text, [
      'technikon',
    ])) {
      return _findByName(
        'Residence: Technikon',
      );
    }

    if (_containsAny(text, [
      'welgemoed',
    ])) {
      return _findByName(
        'Residence: Welgemoed',
      );
    }

    if (_containsAny(text, [
      'loggies',
      'loggie',
    ])) {
      return _findByName(
        'Residence: Loggies',
      );
    }

    if (_containsAny(text, [
      'graduandi',
      'graduandi house',
    ])) {
      return _findByName(
        'Residence: Graduandi House',
      );
    }

    if (_containsAny(text, [
      'bhp',
      'billiton',
      'lecture block',
    ])) {
      return _findByName(
        'BHP Billiton Lecture Block',
      );
    }

    if (_containsAny(text, [
      'exchange house',
      'exchange',
    ])) {
      return _findByName(
        'Exchange House',
      );
    }

    if (_containsAny(text, [
      'cut pavilion',
      'pavilion',
    ])) {
      return _findByName(
        'CUT Pavilion',
      );
    }

    if (_containsAny(text, [
      'emergency medical',
      'emergency care',
      'emergency medical care',
    ])) {
      return _findByName(
        'Emergency Medical Care',
      );
    }

    if (_containsAny(text, [
      'tourism',
      'hospitality',
      'sport school',
    ])) {
      return _findByName(
        'School of Tourism, Hospitality and Sport',
      );
    }

    if (_containsAny(text, [
      'vehicle park',
      'parking',
      'car park',
    ])) {
      return _findByName(
        'Vehicle Park',
      );
    }

    if (_containsAny(text, [
      'e-learning',
      'elearning',
      'educational technology',
      'educational technology centre',
    ])) {
      return _findByName(
        'Centre for e-Learning and Educational Technology',
      );
    }

    if (_containsAny(text, [
      'artec',
    ])) {
      return _findByName(
        'Artec Hall',
      );
    }

    if (_containsAny(text, [
      'kamelia',
      'jewellery',
      'jewelry',
    ])) {
      return _findByName(
        'Kamelia Annex',
      );
    }

    if (_containsAny(text, [
      'dental',
      'maxillofacial',
      'dental laboratories',
    ])) {
      return _findByName(
        'Dental Assisting and Maxillofacial Laboratories',
      );
    }

    if (_containsAny(text, [
      'maintenance',
      'central deliveries',
      'deliveries',
    ])) {
      return _findByName(
        'Maintenance and Central Deliveries',
      );
    }

    if (_containsAny(text, [
      'community engagement',
      'international offices',
      'international office',
    ])) {
      return _findByName(
        'Community Engagement and International Offices',
      );
    }

    if (_containsAny(text, [
      'gym hall',
      'idea generator',
      'gym',
    ])) {
      return _findByName(
        'Gym Hall / Idea Generator',
      );
    }

    if (_containsAny(text, [
      'filling station',
      'absa',
      'atm',
    ])) {
      return _findByName(
        'Filling Station and ABSA ATM',
      );
    }

    if (_containsAny(text, [
      'faculty of engineering',
      'built environment',
      'built-environment',
      'information technology faculty',
    ])) {
      return _findByName(
        'Faculty of Engineering, Built-Environment and Information Technology',
      );
    }

    return null;
  }

  // ============================================================
  // FIND BUILDING BY NAME
  // ============================================================

  CampusBuilding? _findByName(
    String name,
  ) {
    for (final building in _buildings) {
      if (building.name == name) {
        return building;
      }
    }

    return null;
  }

  // ============================================================
  // CHECK PHRASES
  // ============================================================

  bool _containsAny(
    String text,
    List<String> phrases,
  ) {
    for (final phrase in phrases) {
      if (text.contains(phrase)) {
        return true;
      }
    }

    return false;
  }

  // ============================================================
  // RETURN TO DASHBOARD
  // ============================================================

  Future<void> _returnToDashboard() async {
    if (_isDisposed || !mounted) {
      return;
    }

    _shouldListen = false;

    try {
      await _speech.stop();
      await _tts.stop();

      if (mounted) {
        setState(() {
          _isListening = false;
          _isSpeaking = false;
        });
      }

      await Future<void>.delayed(
        const Duration(milliseconds: 200),
      );

      if (!mounted || _isDisposed) {
        return;
      }

      await Navigator.of(context).maybePop();
    } catch (e) {
      debugPrint(
        'RETURN TO DASHBOARD ERROR: $e',
      );

      if (!mounted || _isDisposed) {
        return;
      }

      Navigator.of(context).pop();
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBlue,

      // Voice-first page.
      // No action buttons are provided.
      appBar: AppBar(
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: AppColors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'CAMPUS INFORMATION',
          style: TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.8,
          ),
        ),
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            20,
            20,
            20,
            35,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 720,
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.center,
                children: [
                  // ==================================================
                  // HEADER CARD
                  // ==================================================

                  Semantics(
                    label:
                        'Vision Guide Campus Information. '
                        'CUT Bloemfontein Campus.',
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(
                        20,
                        25,
                        20,
                        24,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius:
                            BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(
                              alpha: 0.20,
                            ),
                            blurRadius: 16,
                            offset:
                                const Offset(0, 7),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color:
                                  AppColors.primaryBlue,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color:
                                    AppColors.primaryYellow,
                                width: 5,
                              ),
                            ),
                            child: const Icon(
                              Icons.location_city,
                              color: AppColors.white,
                              size: 56,
                            ),
                          ),

                          const SizedBox(height: 18),

                          const Text(
                            'CAMPUS INFORMATION',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color:
                                  AppColors.primaryBlue,
                              fontSize: 29,
                              fontWeight:
                                  FontWeight.bold,
                              letterSpacing: 0.6,
                            ),
                          ),

                          const SizedBox(height: 7),

                          Container(
                            padding:
                                const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  AppColors.primaryYellow,
                              borderRadius:
                                  BorderRadius.circular(
                                30,
                              ),
                            ),
                            child: const Text(
                              'CUT BLOEMFONTEIN CAMPUS',
                              textAlign:
                                  TextAlign.center,
                              style: TextStyle(
                                color:
                                    AppColors.black,
                                fontSize: 15,
                                fontWeight:
                                    FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 22),

                  // ==================================================
                  // VOICE STATUS
                  // ==================================================

                  _voiceStatusCard(),

                  const SizedBox(height: 22),

                  // ==================================================
                  // VOICE INSTRUCTIONS
                  // ==================================================

                  _voiceInstructionCard(),

                  const SizedBox(height: 28),

                  // ==================================================
                  // BUILDINGS TITLE
                  // ==================================================

                  Semantics(
                    header: true,
                    child: const Text(
                      'CAMPUS BUILDINGS',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    'Say the name of a building '
                    'to hear information about it.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      height: 1.4,
                    ),
                  ),

                  const SizedBox(height: 18),

                  // ==================================================
                  // BUILDING INFORMATION CARDS
                  // ==================================================

                  ..._buildings.map(
                    (building) =>
                        _buildingInformationCard(
                      building,
                    ),
                  ),

                  const SizedBox(height: 25),

                  // ==================================================
                  // SELECTED BUILDING
                  // ==================================================

                  if (_selectedBuilding != null)
                    _selectedBuildingCard(
                      _selectedBuilding!,
                    ),

                  const SizedBox(height: 30),

                  // ==================================================
                  // VOICE FOOTER
                  // ==================================================

                  _voiceFooter(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // VOICE STATUS CARD
  // ============================================================

  Widget _voiceStatusCard() {
    String title;
    String description;
    IconData icon;
    Color cardColor;
    Color iconColor;
    Color borderColor;

    if (_isListening) {
      title = 'LISTENING...';
      description =
          'Please speak your command.';
      icon = Icons.mic;
      cardColor = AppColors.primaryYellow;
      iconColor = AppColors.black;
      borderColor = AppColors.white;
    } else if (_isSpeaking) {
      title = 'SPEAKING...';
      description =
          'Please wait. I am giving you information.';
      icon = Icons.volume_up;
      cardColor = AppColors.darkBlue;
      iconColor = AppColors.primaryYellow;
      borderColor = AppColors.primaryYellow;
    } else if (!_speechAvailable) {
      title = 'VOICE ASSISTANT UNAVAILABLE';
      description =
          'Please check microphone permission.';
      icon = Icons.mic_off;
      cardColor = AppColors.primaryRed;
      iconColor = AppColors.white;
      borderColor = AppColors.white;
    } else {
      title = 'VOICE ASSISTANT READY';
      description =
          'Speak a command when you are ready.';
      icon = Icons.mic_none;
      cardColor = AppColors.lightBlue;
      iconColor = AppColors.white;
      borderColor = AppColors.white;
    }

    return Semantics(
      container: true,
      liveRegion: true,
      label: '$title. $description',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: 22,
          vertical: 27,
        ),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius:
              BorderRadius.circular(28),
          border: Border.all(
            color: borderColor,
            width: 3,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(
                alpha: 0.20,
              ),
              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 112,
              height: 112,
              decoration: BoxDecoration(
                color: AppColors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: iconColor,
                  width: 5,
                ),
              ),
              child: Icon(
                icon,
                color: AppColors.primaryBlue,
                size: 58,
              ),
            ),

            const SizedBox(height: 18),

            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: cardColor ==
                        AppColors.primaryYellow
                    ? AppColors.black
                    : AppColors.white,
                fontSize: 25,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              description,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: cardColor ==
                        AppColors.primaryYellow
                    ? AppColors.black
                    : AppColors.white,
                fontSize: 18,
                height: 1.4,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // VOICE INSTRUCTION CARD
  // ============================================================

  Widget _voiceInstructionCard() {
    return Semantics(
      container: true,
      label:
          'Voice commands. '
          'You can say list buildings. '
          'You can ask about the library, medical clinic, '
          'main hall, engineering or any other building. '
          'Say go back to dashboard when finished.',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius:
              BorderRadius.circular(26),
          border: Border.all(
            color: AppColors.primaryYellow,
            width: 4,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(
                alpha: 0.15,
              ),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: AppColors.primaryYellow,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.record_voice_over,
                color: AppColors.black,
                size: 38,
              ),
            ),

            const SizedBox(height: 14),

            const Text(
              'SPEAK YOUR COMMAND',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryBlue,
              ),
            ),

            const SizedBox(height: 16),

            _voiceExample(
              '"List buildings"',
            ),

            _voiceExample(
              '"Tell me about the library"',
            ),

            _voiceExample(
              '"Tell me about the medical clinic"',
            ),

            _voiceExample(
              '"What is the main hall?"',
            ),

            _voiceExample(
              '"Go back to dashboard"',
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // VOICE EXAMPLE
  // ============================================================

  Widget _voiceExample(String text) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(
        bottom: 8,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 13,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF2FF),
        borderRadius:
            BorderRadius.circular(15),
        border: Border.all(
          color: AppColors.primaryBlue,
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.mic,
            color: AppColors.primaryBlue,
            size: 25,
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BUILDING INFORMATION CARD
  // ============================================================

  Widget _buildingInformationCard(
    CampusBuilding building,
  ) {
    final bool selected =
        _selectedBuilding?.name ==
            building.name;

    return Semantics(
      container: true,
      label:
          '${building.name}. '
          '${building.type}. '
          'Opening hours ${building.openingTime} '
          'to ${building.closingTime}.',
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(
          bottom: 12,
        ),
        padding: const EdgeInsets.all(17),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primaryYellow
              : AppColors.white,
          borderRadius:
              BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? AppColors.primaryYellow
                : AppColors.white,
            width: selected ? 3 : 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(
                alpha: 0.13,
              ),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment:
              CrossAxisAlignment.center,
          children: [
            Container(
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.darkBlue
                    : const Color(0xFFEAF2FF),
                borderRadius:
                    BorderRadius.circular(17),
                border: Border.all(
                  color: AppColors.primaryBlue,
                  width: 2,
                ),
              ),
              child: Icon(
                building.icon,
                color: selected
                    ? AppColors.primaryYellow
                    : AppColors.primaryBlue,
                size: 33,
              ),
            ),

            const SizedBox(width: 15),

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    building.name,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight:
                          FontWeight.bold,
                      color: selected
                          ? AppColors.darkBlue
                          : AppColors.primaryBlue,
                    ),
                  ),

                  const SizedBox(height: 5),

                  Text(
                    building.type,
                    style: TextStyle(
                      fontSize: 14,
                      color: selected
                          ? AppColors.black
                          : Colors.black54,
                      fontWeight:
                          FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 5),

                  Text(
                    '${building.openingTime} - '
                    '${building.closingTime}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight:
                          FontWeight.bold,
                      color: AppColors.black,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // SELECTED BUILDING CARD
  // ============================================================

  Widget _selectedBuildingCard(
    CampusBuilding building,
  ) {
    final String coordinates =
        building.latitude != null &&
                building.longitude != null
            ? '${building.latitude}, '
                '${building.longitude}'
            : 'GPS coordinates not configured';

    return Semantics(
      container: true,
      label:
          'Information about ${building.name}. '
          '${building.description}',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(23),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius:
              BorderRadius.circular(28),
          border: Border.all(
            color: AppColors.primaryYellow,
            width: 4,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(
                alpha: 0.20,
              ),
              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 82,
              height: 82,
              decoration: BoxDecoration(
                color: AppColors.primaryBlue,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.primaryYellow,
                  width: 4,
                ),
              ),
              child: Icon(
                building.icon,
                color: AppColors.white,
                size: 42,
              ),
            ),

            const SizedBox(height: 14),

            const Text(
              'INFORMATION',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: AppColors.darkBlue,
                letterSpacing: 0.7,
              ),
            ),

            const SizedBox(height: 6),

            Text(
              building.name,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryBlue,
              ),
            ),

            const SizedBox(height: 16),

            Text(
              building.description,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 17,
                height: 1.45,
                color: AppColors.black,
              ),
            ),

            const SizedBox(height: 20),

            _informationRow(
              Icons.category,
              'Type',
              building.type,
            ),

            const SizedBox(height: 12),

            _informationRow(
              Icons.event_seat,
              'Facilities',
              building.seats,
            ),

            const SizedBox(height: 12),

            _informationRow(
              Icons.access_time,
              'Opening hours',
              '${building.openingTime} - '
                  '${building.closingTime}',
            ),

            const SizedBox(height: 12),

            _informationRow(
              Icons.location_on,
              'Coordinates',
              coordinates,
            ),

            const SizedBox(height: 20),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: const Color(0xFFEAF2FF),
                borderRadius:
                    BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.primaryBlue,
                  width: 1.5,
                ),
              ),
              child: const Text(
                'Ask me about another building '
                'or say "Go back to dashboard".',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.darkBlue,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // INFORMATION ROW
  // ============================================================

  Widget _informationRow(
    IconData icon,
    String title,
    String value,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF2FF),
        borderRadius:
            BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: AppColors.primaryBlue,
            size: 26,
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Text(
              '$title: $value',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                height: 1.35,
                color: AppColors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // VOICE FOOTER
  // ============================================================

  Widget _voiceFooter() {
    return Semantics(
      container: true,
      label:
          'This page is voice controlled. '
          'Say go back to dashboard when finished.',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: AppColors.darkBlue,
          borderRadius:
              BorderRadius.circular(25),
          border: Border.all(
            color: AppColors.primaryYellow,
            width: 3,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(
                alpha: 0.20,
              ),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: const BoxDecoration(
                color: AppColors.primaryYellow,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.record_voice_over,
                color: AppColors.black,
                size: 38,
              ),
            ),

            const SizedBox(height: 13),

            const Text(
              'VOICE CONTROLLED',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
                color: AppColors.white,
                letterSpacing: 0.6,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'When you are finished, say:',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: AppColors.white,
              ),
            ),

            const SizedBox(height: 5),

            const Text(
              '"Go back to dashboard"',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryYellow,
              ),
            ),

            const SizedBox(height: 15),

            Container(
              width: double.infinity,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.primaryYellow,
                borderRadius:
                    BorderRadius.circular(5),
              ),
            ),

            const SizedBox(height: 14),

            const Text(
              'VISION GUIDE',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
                color: AppColors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _isDisposed = true;

    _shouldListen = false;

    _tts.stop();
    _speech.stop();

    super.dispose();
  }
}