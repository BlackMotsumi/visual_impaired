
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../../../models/campus_building.dart';
import '../../../theme/app_theme.dart';

class NavigationScreen extends StatefulWidget {
  final CampusBuilding? destination;

  const NavigationScreen({
    super.key,
    this.destination,
  });

  @override
  State<NavigationScreen> createState() => _NavigationScreenState();
}

enum _VoiceMode {
  none,
  destination,
  navigationCommand,
  afterRoute,
}

class _NavigationScreenState extends State<NavigationScreen> {
  // ============================================================
  // VOICE
  // ============================================================

  final FlutterTts _tts = FlutterTts();
  final stt.SpeechToText _speech = stt.SpeechToText();

  bool _speechAvailable = false;
  bool _isListening = false;
  bool _isSpeaking = false;

  _VoiceMode _voiceMode = _VoiceMode.none;

  int _voiceSession = 0;

  Timer? _retryTimer;
  Timer? _listenWatchdog;

  bool _suppressVoiceRetry = false;
  bool _processingVoiceResult = false;

  // ============================================================
  // MAP
  // ============================================================

  MapLibreMapController? _mapController;

  static const LatLng _campusCenter = LatLng(
    -29.12100,
    26.21500,
  );

  Position? _currentPosition;

  bool _locationReady = false;

  // Stable map height.
  // This prevents the map from visually resizing after a
  // destination is selected or a route is calculated.
  static const double _mapHeight = 360;

  // ============================================================
  // DESTINATION
  // ============================================================

  CampusBuilding? _selectedBuilding;

  bool _loading = false;
  bool _navigationStarted = false;

  // ============================================================
  // ROUTE
  // ============================================================

  List<LatLng> _routePoints = [];

  double? _routeDistance;
  double? _routeDuration;

  // ============================================================
  // BUILDINGS
  // ============================================================

  late final List<CampusBuilding> _buildings = [
    CampusBuilding(
      name: 'Bethuel Setai Library',
      type: 'Library',
      icon: Icons.local_library,
      description: 'Bethuel Setai Library',
      seats: '240',
      openingTime: '08:00',
      closingTime: '21:00',
      latitude: -29.12128,
      longitude: 26.21563,
    ),

    CampusBuilding(
      name: 'Medical Clinic',
      type: 'Medical',
      icon: Icons.local_hospital,
      description: 'Medical Clinic',
      seats: 'N/A',
      openingTime: '08:00',
      closingTime: '16:30',
      latitude: -29.12070,
      longitude: 26.21490,
    ),

    CampusBuilding(
      name: 'ZR Mahabane Building',
      type: 'Building',
      icon: Icons.business,
      description: 'ZR Mahabane Building',
      seats: 'N/A',
      openingTime: 'N/A',
      closingTime: 'N/A',
      latitude: null,
      longitude: null,
    ),

    CampusBuilding(
      name: 'Japie van Lill Auditorium',
      type: 'Auditorium',
      icon: Icons.event_seat,
      description: 'Japie van Lill Auditorium',
      seats: 'N/A',
      openingTime: 'N/A',
      closingTime: 'N/A',
      latitude: null,
      longitude: null,
    ),

    CampusBuilding(
      name:
          'Faculty of Engineering, Built-Environment and Information Technology',
      type: 'Faculty',
      icon: Icons.engineering,
      description:
          'Faculty of Engineering, Built-Environment and Information Technology',
      seats: 'N/A',
      openingTime: 'N/A',
      closingTime: 'N/A',
      latitude: null,
      longitude: null,
    ),

    CampusBuilding(
      name: 'Engineering Technology Building',
      type: 'Building',
      icon: Icons.engineering,
      description: 'Engineering Technology Building',
      seats: 'N/A',
      openingTime: 'N/A',
      closingTime: 'N/A',
      latitude: null,
      longitude: null,
    ),

    CampusBuilding(
      name: 'BHP Billiton Lecture Block',
      type: 'Lecture Block',
      icon: Icons.school,
      description: 'BHP Billiton Lecture Block',
      seats: 'N/A',
      openingTime: 'N/A',
      closingTime: 'N/A',
      latitude: null,
      longitude: null,
    ),

    CampusBuilding(
      name: 'Main Hall',
      type: 'Hall',
      icon: Icons.account_balance,
      description: 'Main Hall',
      seats: 'N/A',
      openingTime: 'N/A',
      closingTime: 'N/A',
      latitude: null,
      longitude: null,
    ),

    CampusBuilding(
      name: 'Emergency Medical Care',
      type: 'Medical',
      icon: Icons.emergency,
      description: 'Emergency Medical Care',
      seats: 'N/A',
      openingTime: 'N/A',
      closingTime: 'N/A',
      latitude: null,
      longitude: null,
    ),

    CampusBuilding(
      name: 'Dirk Coetzee Building',
      type: 'Building',
      icon: Icons.business,
      description: 'Dirk Coetzee Building',
      seats: 'N/A',
      openingTime: 'N/A',
      closingTime: 'N/A',
      latitude: null,
      longitude: null,
    ),

    CampusBuilding(
      name: 'Prosperitas Auditorium',
      type: 'Auditorium',
      icon: Icons.event_seat,
      description: 'Prosperitas Auditorium',
      seats: 'N/A',
      openingTime: 'N/A',
      closingTime: 'N/A',
      latitude: null,
      longitude: null,
    ),

    CampusBuilding(
      name: 'Boet Troskie Hall',
      type: 'Hall',
      icon: Icons.account_balance,
      description: 'Boet Troskie Hall',
      seats: 'N/A',
      openingTime: 'N/A',
      closingTime: 'N/A',
      latitude: null,
      longitude: null,
    ),

    CampusBuilding(
      name: 'Student Academic Support Centre',
      type: 'Student Support',
      icon: Icons.support_agent,
      description: 'Student Academic Support Centre',
      seats: 'N/A',
      openingTime: 'N/A',
      closingTime: 'N/A',
      latitude: null,
      longitude: null,
    ),

    CampusBuilding(
      name: 'Tataisong Building',
      type: 'Building',
      icon: Icons.business,
      description: 'Tataisong Building',
      seats: 'N/A',
      openingTime: 'N/A',
      closingTime: 'N/A',
      latitude: null,
      longitude: null,
    ),

    CampusBuilding(
      name: 'Kopanong Building',
      type: 'Building',
      icon: Icons.business,
      description: 'Kopanong Building',
      seats: 'N/A',
      openingTime: 'N/A',
      closingTime: 'N/A',
      latitude: null,
      longitude: null,
    ),

    CampusBuilding(
      name: 'Science Park',
      type: 'Science',
      icon: Icons.science,
      description: 'Science Park',
      seats: 'N/A',
      openingTime: 'N/A',
      closingTime: 'N/A',
      latitude: null,
      longitude: null,
    ),
  ];

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _selectedBuilding = widget.destination;

    _initializeTts();
    _initializeSpeech();
    _initializeLocation();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startVoiceNavigation();
    });
  }

  // ============================================================
  // TTS
  // ============================================================

  Future<void> _initializeTts() async {
    try {
      await _tts.setLanguage('en-ZA');
      await _tts.setSpeechRate(0.45);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);
      await _tts.awaitSpeakCompletion(true);
    } catch (e) {
      debugPrint('TTS initialization error: $e');
    }
  }

  Future<void> _speak(String text) async {
    _cancelVoiceRetry();
    _cancelListenWatchdog();

    _suppressVoiceRetry = true;

    try {
      if (_isListening) {
        await _speech.stop();
        _isListening = false;
      }

      await _tts.stop();

      if (mounted) {
        setState(() {});
      }

      _isSpeaking = true;

      if (mounted) {
        setState(() {});
      }

      await _tts.speak(text);
    } catch (e) {
      debugPrint('TTS error: $e');
    } finally {
      _isSpeaking = false;
      _suppressVoiceRetry = false;

      if (mounted) {
        setState(() {});
      }
    }
  }

  // ============================================================
  // SPEECH INITIALIZATION
  // ============================================================

  Future<void> _initializeSpeech() async {
    try {
      _speechAvailable = await _speech.initialize(
        onStatus: (status) {
          debugPrint('Speech status: $status');

          if (status == 'listening') {
            _isListening = true;

            if (mounted) {
              setState(() {});
            }
          }

          if (status == 'notListening' ||
              status == 'done') {
            _isListening = false;

            if (mounted) {
              setState(() {});
            }

            // Automatically listen again.
            //
            // We intentionally do NOT speak another prompt here.
            // This gives the user continuous voice interaction.
            if (!_suppressVoiceRetry &&
                !_processingVoiceResult &&
                _voiceMode != _VoiceMode.none) {
              _scheduleVoiceRetry();
            }
          }
        },
        onError: (error) {
          debugPrint('Speech error: $error');

          _isListening = false;

          if (mounted) {
            setState(() {});
          }

          if (!_suppressVoiceRetry &&
              !_processingVoiceResult &&
              _voiceMode != _VoiceMode.none) {
            _scheduleVoiceRetry();
          }
        },
      );

      debugPrint('Speech available: $_speechAvailable');

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      debugPrint('Speech initialization error: $e');
    }
  }

  // ============================================================
  // START VOICE NAVIGATION
  // ============================================================

  Future<void> _startVoiceNavigation() async {
    if (!mounted) return;

    if (_selectedBuilding != null) {
      await _speak(
        'Welcome to Vision Guide campus navigation. '
        'Your destination is ${_selectedBuilding!.name}. '
        'Say start navigation, change destination, repeat, '
        'or say back to return to the dashboard.',
      );

      if (!mounted) return;

      await _startListeningFor(
        _VoiceMode.navigationCommand,
      );
    } else {
      await _speak(
        'Welcome to Vision Guide campus navigation. '
        'Please say the name of the building you want to go to. '
        'You can say back to return to the dashboard.',
      );

      if (!mounted) return;

      await _startListeningFor(
        _VoiceMode.destination,
      );
    }
  }

  // ============================================================
  // START LISTENING
  // ============================================================

  Future<void> _startListeningFor(
    _VoiceMode mode,
  ) async {
    if (!mounted) return;

    _cancelVoiceRetry();
    _cancelListenWatchdog();

    if (!_speechAvailable) {
      await _initializeSpeech();
    }

    if (!_speechAvailable) {
      await _speak(
        'Voice recognition is not available. '
        'Please check microphone permission.',
      );
      return;
    }

    try {
      await _speech.stop();

      final int currentSession = ++_voiceSession;

      _voiceMode = mode;
      _processingVoiceResult = false;
      _isListening = true;

      if (mounted) {
        setState(() {});
      }

      await _speech.listen(
        localeId: 'en_ZA',
        listenMode: stt.ListenMode.dictation,
        listenFor: const Duration(seconds: 12),
        pauseFor: const Duration(seconds: 4),
        partialResults: false,
        onResult: (result) async {
          if (currentSession != _voiceSession) {
            return;
          }

          if (!result.finalResult) {
            return;
          }

          final String words = result.recognizedWords.trim();

          if (words.isEmpty) {
            return;
          }

          await _handleVoiceResult(
            words,
            currentSession,
          );
        },
      );

      _listenWatchdog = Timer(
        const Duration(seconds: 14),
        () {
          if (!mounted) return;

          if (currentSession != _voiceSession) {
            return;
          }

          if (_isListening &&
              !_processingVoiceResult &&
              !_suppressVoiceRetry) {
            debugPrint(
              'VOICE: watchdog restarting listening',
            );

            _speech.stop();

            _isListening = false;

            if (mounted) {
              setState(() {});
            }

            _scheduleVoiceRetry();
          }
        },
      );
    } catch (e) {
      debugPrint('Listening error: $e');

      _isListening = false;

      if (mounted) {
        setState(() {});
      }

      if (!_suppressVoiceRetry) {
        _scheduleVoiceRetry();
      }
    }
  }

  // ============================================================
  // VOICE RESULT
  // ============================================================

  Future<void> _handleVoiceResult(
    String words,
    int session,
  ) async {
    if (!mounted) return;

    if (session != _voiceSession) {
      return;
    }

    if (_processingVoiceResult) {
      return;
    }

    _processingVoiceResult = true;

    _cancelVoiceRetry();
    _cancelListenWatchdog();

    _isListening = false;

    try {
      await _speech.stop();

      final String command = _normalize(words);

      debugPrint(
        'VOICE RESULT: "$words" -> "$command"',
      );

      if (command.isEmpty) {
        _processingVoiceResult = false;

        if (_voiceMode != _VoiceMode.none) {
          await _startListeningFor(_voiceMode);
        }

        return;
      }

      switch (_voiceMode) {
        case _VoiceMode.destination:
          await _processDestination(command);
          break;

        case _VoiceMode.navigationCommand:
          await _processNavigationCommand(command);
          break;

        case _VoiceMode.afterRoute:
          await _processAfterRouteCommand(command);
          break;

        case _VoiceMode.none:
          break;
      }
    } catch (e) {
      debugPrint(
        'Voice result processing error: $e',
      );
    } finally {
      _processingVoiceResult = false;

      if (mounted) {
        setState(() {});
      }
    }
  }

  // ============================================================
  // DESTINATION PROCESSING
  // ============================================================

  Future<void> _processDestination(
    String command,
  ) async {
    if (_containsAny(command, [
      'back',
      'go back',
      'dashboard',
      'return',
      'exit',
    ])) {
      await _returnToDashboard();
      return;
    }

    if (_containsAny(command, [
      'stop',
      'cancel',
      'never mind',
    ])) {
      await _speak(
        'Destination selection cancelled. '
        'Please say another destination.',
      );

      await _startListeningFor(
        _VoiceMode.destination,
      );

      return;
    }

    final CampusBuilding? building =
        _findBuilding(command);

    if (building == null) {
      await _speak(
        'I could not find that building. '
        'Please say the building name again.',
      );

      await _startListeningFor(
        _VoiceMode.destination,
      );

      return;
    }

    await _selectBuilding(building);
  }

  // ============================================================
  // FIND BUILDING
  // ============================================================

  CampusBuilding? _findBuilding(
    String command,
  ) {
    final String normalizedCommand =
        _normalize(command);

    for (final building in _buildings) {
      final String buildingName =
          _normalize(building.name);

      if (normalizedCommand == buildingName ||
          normalizedCommand.contains(buildingName) ||
          buildingName.contains(normalizedCommand)) {
        return building;
      }
    }

    if (_containsAny(normalizedCommand, [
      'library',
      'bethuel',
      'setai',
    ])) {
      return _buildings[0];
    }

    if (_containsAny(normalizedCommand, [
      'clinic',
      'medical clinic',
      'medical',
    ])) {
      return _buildings[1];
    }

    if (_containsAny(normalizedCommand, [
      'mahabane',
      'zr',
    ])) {
      return _buildings[2];
    }

    if (_containsAny(normalizedCommand, [
      'japie',
      'van lill',
    ])) {
      return _buildings[3];
    }

    if (_containsAny(normalizedCommand, [
      'faculty',
      'information technology',
      'it faculty',
      'engineering faculty',
    ])) {
      return _buildings[4];
    }

    if (_containsAny(normalizedCommand, [
      'engineering technology',
      'engineering tech',
    ])) {
      return _buildings[5];
    }

    if (_containsAny(normalizedCommand, [
      'bhp',
      'billiton',
      'bhp billiton',
    ])) {
      return _buildings[6];
    }

    if (_containsAny(normalizedCommand, [
      'main hall',
      'main',
    ])) {
      return _buildings[7];
    }

    if (_containsAny(normalizedCommand, [
      'emergency',
      'emergency medical',
    ])) {
      return _buildings[8];
    }

    if (_containsAny(normalizedCommand, [
      'dirk',
      'coetzee',
    ])) {
      return _buildings[9];
    }

    if (_containsAny(normalizedCommand, [
      'prosperitas',
      'prosper',
    ])) {
      return _buildings[10];
    }

    if (_containsAny(normalizedCommand, [
      'boet',
      'troskie',
    ])) {
      return _buildings[11];
    }

    if (_containsAny(normalizedCommand, [
      'student academic',
      'academic support',
      'support centre',
      'support center',
    ])) {
      return _buildings[12];
    }

    if (_containsAny(normalizedCommand, [
      'tataisong',
    ])) {
      return _buildings[13];
    }

    if (_containsAny(normalizedCommand, [
      'kopanong',
    ])) {
      return _buildings[14];
    }

    if (_containsAny(normalizedCommand, [
      'science park',
      'science',
    ])) {
      return _buildings[15];
    }

    return null;
  }

  // ============================================================
  // SELECT BUILDING
  // ============================================================

  Future<void> _selectBuilding(
    CampusBuilding building,
  ) async {
    await _stopListeningOnly();

    if (!mounted) return;

    setState(() {
      _selectedBuilding = building;
      _routePoints = [];
      _routeDistance = null;
      _routeDuration = null;
      _navigationStarted = false;
      _loading = false;
    });

    await _showSelectedBuildingOnMap();

    await _speak(
      '${building.name} selected. '
      'Say start navigation to begin, '
      'change destination to choose another building, '
      'repeat to hear this again, '
      'or back to return to the dashboard.',
    );

    if (!mounted) return;

    await _startListeningFor(
      _VoiceMode.navigationCommand,
    );
  }

  // ============================================================
  // NAVIGATION COMMAND
  // ============================================================

  Future<void> _processNavigationCommand(
    String command,
  ) async {
    if (_containsAny(command, [
      'back',
      'go back',
      'dashboard',
      'return',
      'exit',
    ])) {
      await _returnToDashboard();
      return;
    }

    if (_containsAny(command, [
      'start navigation',
      'start',
      'navigate',
      'go',
      'begin navigation',
      'begin',
    ])) {
      await _startNavigation();
      return;
    }

    if (_containsAny(command, [
      'change destination',
      'change',
      'new destination',
      'choose another',
    ])) {
      await _speak(
        'Please say the name of your new destination.',
      );

      await _startListeningFor(
        _VoiceMode.destination,
      );

      return;
    }

    if (_containsAny(command, [
      'repeat',
      'say again',
      'again',
    ])) {
      if (_selectedBuilding != null) {
        await _speak(
          'Your destination is ${_selectedBuilding!.name}. '
          'Say start navigation to begin, '
          'change destination to choose another building, '
          'or back to return to the dashboard.',
        );
      }

      await _startListeningFor(
        _VoiceMode.navigationCommand,
      );

      return;
    }

    if (_containsAny(command, [
      'stop',
      'cancel',
    ])) {
      await _speak(
        'Navigation stopped. '
        'You can say start navigation to continue, '
        'change destination, or back.',
      );

      await _startListeningFor(
        _VoiceMode.navigationCommand,
      );

      return;
    }

    await _speak(
      'I did not understand that command. '
      'Please say start navigation, '
      'change destination, repeat, or back.',
    );

    await _startListeningFor(
      _VoiceMode.navigationCommand,
    );
  }

  // ============================================================
  // START NAVIGATION
  // ============================================================

  Future<void> _startNavigation() async {
    if (_selectedBuilding == null) {
      await _speak(
        'Please select a destination first.',
      );

      await _startListeningFor(
        _VoiceMode.destination,
      );

      return;
    }

    if (_selectedBuilding!.latitude == null ||
        _selectedBuilding!.longitude == null) {
      await _speak(
        'I do not currently have map coordinates for '
        '${_selectedBuilding!.name}. '
        'Please choose another destination.',
      );

      await _startListeningFor(
        _VoiceMode.destination,
      );

      return;
    }

    if (_currentPosition == null) {
      await _speak(
        'I cannot determine your current location yet. '
        'Please wait while GPS location is obtained.',
      );

      await _initializeLocation();

      if (_currentPosition == null) {
        await _speak(
          'I still cannot determine your current location. '
          'Please check that location services are enabled.',
        );

        await _startListeningFor(
          _VoiceMode.navigationCommand,
        );

        return;
      }
    }

    if (!mounted) return;

    setState(() {
      _loading = true;
      _navigationStarted = true;
    });

    await _speak(
      'Calculating your walking route to '
      '${_selectedBuilding!.name}. Please wait.',
    );

    try {
      final double startLat =
          _currentPosition!.latitude;

      final double startLng =
          _currentPosition!.longitude;

      final double destinationLat =
          _selectedBuilding!.latitude!;

      final double destinationLng =
          _selectedBuilding!.longitude!;

      final String url =
          'https://router.project-osrm.org/route/v1/foot/'
          '$startLng,$startLat;'
          '$destinationLng,$destinationLat'
          '?overview=full&geometries=geojson&steps=true';

      debugPrint('ROUTE URL: $url');

      final response = await http.get(
        Uri.parse(url),
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Route request failed: ${response.statusCode}',
        );
      }

      final Map<String, dynamic> data =
          jsonDecode(response.body);

      final List routes =
          data['routes'] as List;

      if (routes.isEmpty) {
        throw Exception(
          'No route found.',
        );
      }

      final Map<String, dynamic> route =
          routes.first as Map<String, dynamic>;

      final double distance =
          (route['distance'] as num).toDouble();

      final double duration =
          (route['duration'] as num).toDouble();

      final Map<String, dynamic> geometry =
          route['geometry']
              as Map<String, dynamic>;

      final List coordinates =
          geometry['coordinates'] as List;

      final List<LatLng> points =
          coordinates.map<LatLng>((coordinate) {
        return LatLng(
          (coordinate[1] as num).toDouble(),
          (coordinate[0] as num).toDouble(),
        );
      }).toList();

      if (points.isEmpty) {
        throw Exception(
          'Route contains no coordinates.',
        );
      }

      _routePoints = points;
      _routeDistance = distance;
      _routeDuration = duration;

      // Draw the route first.
      await _drawRoute();

      if (!mounted) return;

      setState(() {
        _loading = false;
      });

      final double distanceKm =
          distance / 1000;

      final int minutes =
          (duration / 60).round();

      final String distanceText =
          distanceKm < 1
              ? '${distance.round()} metres'
              : '${distanceKm.toStringAsFixed(1)} kilometres';

      await _speak(
        'Route calculated. '
        'The distance is $distanceText. '
        'Estimated walking time is $minutes minutes. '
        'The complete route is now visible on the map. '
        'You can say repeat, change destination, '
        'stop, or back.',
      );

      if (!mounted) return;

      await _startListeningFor(
        _VoiceMode.afterRoute,
      );
    } catch (e) {
      debugPrint(
        'Route error: $e',
      );

      if (!mounted) return;

      setState(() {
        _loading = false;
      });

      await _speak(
        'I could not calculate the walking route. '
        'Please check your internet connection and try again.',
      );

      await _startListeningFor(
        _VoiceMode.navigationCommand,
      );
    }
  }

  // ============================================================
  // DRAW ROUTE
  // ============================================================

  Future<void> _drawRoute() async {
    if (_mapController == null ||
        _routePoints.isEmpty) {
      debugPrint(
        'DRAW ROUTE: map controller or route unavailable',
      );
      return;
    }

    try {
      await _mapController!.clearLines();

      await _mapController!.addLine(
  LineOptions(
    geometry: _routePoints,
    lineColor: '#0057A8',
    lineWidth: 5.5,
    lineOpacity: 0.95,
  ),
);

      // Give MapLibre one frame to render the line before
      // fitting the camera.
      await Future.delayed(
        const Duration(milliseconds: 150),
      );

      if (!mounted || _mapController == null) {
        return;
      }

      await _fitRouteToMap();
    } catch (e) {
      debugPrint(
        'Draw route error: $e',
      );
    }
  }

  // ============================================================
  // FIT COMPLETE ROUTE ON MAP
  // ============================================================

  Future<void> _fitRouteToMap() async {
    if (_mapController == null ||
        _routePoints.isEmpty) {
      return;
    }

    try {
      final LatLngBounds bounds =
          _calculateBounds(_routePoints);

      // Larger padding makes the route easier to see and prevents
      // the route from touching the edge of the map.
      await _mapController!.animateCamera(
        CameraUpdate.newLatLngBounds(
          bounds,
          left: 65,
          top: 65,
          right: 65,
          bottom: 65,
        ),
      );
    } catch (e) {
      debugPrint(
        'Fit route error: $e',
      );

      // Fallback: center on the route midpoint.
      try {
        final LatLng midpoint =
            _routePoints[
                (_routePoints.length / 2).floor()];

        await _mapController!.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: midpoint,
              zoom: 16.5,
            ),
          ),
        );
      } catch (fallbackError) {
        debugPrint(
          'Route camera fallback error: $fallbackError',
        );
      }
    }
  }

  // ============================================================
  // SHOW SELECTED BUILDING
  // ============================================================

  Future<void> _showSelectedBuildingOnMap() async {
    if (_mapController == null ||
        _selectedBuilding == null ||
        _selectedBuilding!.latitude == null ||
        _selectedBuilding!.longitude == null) {
      return;
    }

    try {
      await Future.delayed(
        const Duration(milliseconds: 100),
      );

      if (!mounted || _mapController == null) {
        return;
      }

      await _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(
              _selectedBuilding!.latitude!,
              _selectedBuilding!.longitude!,
            ),
            zoom: 16.5,
          ),
        ),
      );
    } catch (e) {
      debugPrint(
        'Show selected building error: $e',
      );
    }
  }

  // ============================================================
  // AFTER ROUTE COMMAND
  // ============================================================

  Future<void> _processAfterRouteCommand(
    String command,
  ) async {
    if (_containsAny(command, [
      'back',
      'go back',
      'dashboard',
      'return',
      'exit',
    ])) {
      await _returnToDashboard();
      return;
    }

    if (_containsAny(command, [
      'repeat',
      'again',
      'say again',
    ])) {
      if (_selectedBuilding != null &&
          _routeDistance != null &&
          _routeDuration != null) {
        final double distanceKm =
            _routeDistance! / 1000;

        final int minutes =
            (_routeDuration! / 60).round();

        final String distanceText =
            distanceKm < 1
                ? '${_routeDistance!.round()} metres'
                : '${distanceKm.toStringAsFixed(1)} kilometres';

        await _speak(
          'Your destination is '
          '${_selectedBuilding!.name}. '
          'The route is $distanceText. '
          'Estimated walking time is $minutes minutes. '
          'You can say repeat, change destination, '
          'stop, or back.',
        );
      }

      await _startListeningFor(
        _VoiceMode.afterRoute,
      );

      return;
    }

    if (_containsAny(command, [
      'change destination',
      'change',
      'new destination',
    ])) {
      await _speak(
        'Please say the name of your new destination.',
      );

      await _startListeningFor(
        _VoiceMode.destination,
      );

      return;
    }

    if (_containsAny(command, [
      'stop',
      'cancel',
    ])) {
      await _speak(
        'Navigation stopped. '
        'You can say repeat, change destination, '
        'or back.',
      );

      await _startListeningFor(
        _VoiceMode.afterRoute,
      );

      return;
    }

    await _speak(
      'I did not understand that command. '
      'Please say repeat, change destination, '
      'stop, or back.',
    );

    await _startListeningFor(
      _VoiceMode.afterRoute,
    );
  }

  // ============================================================
  // RETURN TO DASHBOARD
  // ============================================================

  Future<void> _returnToDashboard() async {
    await _stopListeningOnly();

    _voiceMode = _VoiceMode.none;

    try {
      await _tts.stop();
    } catch (_) {}

    await _speak(
      'Returning to the dashboard.',
    );

    if (!mounted) return;

    Navigator.of(context).pop();
  }

  // ============================================================
  // LOCATION
  // ============================================================

  Future<void> _initializeLocation() async {
    try {
      final bool serviceEnabled =
          await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        debugPrint(
          'Location services are disabled.',
        );
        return;
      }

      LocationPermission permission =
          await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission =
            await Geolocator.requestPermission();
      }

      if (permission ==
              LocationPermission.denied ||
          permission ==
              LocationPermission.deniedForever) {
        debugPrint(
          'Location permission denied.',
        );
        return;
      }

      final Position position =
          await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      if (!mounted) return;

      setState(() {
        _currentPosition = position;
        _locationReady = true;
      });

      debugPrint(
        'LOCATION: ${position.latitude}, '
        '${position.longitude}',
      );
    } catch (e) {
      debugPrint(
        'Location initialization error: $e',
      );
    }
  }

  // ============================================================
  // MAP CREATED
  // ============================================================

  Future<void> _onMapCreated(
    MapLibreMapController controller,
  ) async {
    _mapController = controller;

    debugPrint(
      'MAP: MapLibre controller created',
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      _showSelectedBuildingOnMap();
    });
  }

  // ============================================================
  // NORMALIZE VOICE
  // ============================================================

  String _normalize(String value) {
    return value
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ');
  }

  bool _containsAny(
    String value,
    List<String> values,
  ) {
    for (final item in values) {
      if (value.contains(item)) {
        return true;
      }
    }

    return false;
  }

  // ============================================================
  // STOP LISTENING
  // ============================================================

  Future<void> _stopListeningOnly() async {
    _voiceSession++;

    _cancelVoiceRetry();
    _cancelListenWatchdog();

    try {
      await _speech.stop();
    } catch (e) {
      debugPrint(
        'Stop speech error: $e',
      );
    }

    _isListening = false;

    if (mounted) {
      setState(() {});
    }
  }

  // ============================================================
  // RETRY LISTENING
  // ============================================================

  void _scheduleVoiceRetry() {
    if (!mounted ||
        _suppressVoiceRetry ||
        _processingVoiceResult ||
        _voiceMode == _VoiceMode.none) {
      return;
    }

    _cancelVoiceRetry();

    _retryTimer = Timer(
      const Duration(milliseconds: 700),
      () {
        if (!mounted ||
            _suppressVoiceRetry ||
            _processingVoiceResult ||
            _voiceMode == _VoiceMode.none) {
          return;
        }

        debugPrint(
          'VOICE: automatically restarting listening',
        );

        _startListeningFor(_voiceMode);
      },
    );
  }

  void _cancelVoiceRetry() {
    _retryTimer?.cancel();
    _retryTimer = null;
  }

  void _cancelListenWatchdog() {
    _listenWatchdog?.cancel();
    _listenWatchdog = null;
  }

  // ============================================================
  // MAP
  // ============================================================

  Widget _map() {
    return SizedBox(
      height: _mapHeight,
      width: double.infinity,
      child: MapLibreMap(
        styleString:
            'https://tiles.openfreemap.org/styles/liberty',
        initialCameraPosition:
            const CameraPosition(
          target: _campusCenter,
          zoom: 16,
        ),
        onMapCreated: _onMapCreated,
        myLocationEnabled: true,
        myLocationTrackingMode:
            MyLocationTrackingMode.none,
      ),
    );
  }

  // ============================================================
  // VOICE STATUS CARD
  // ============================================================

  Widget _voiceStatusCard() {
    final String statusText = _isListening
        ? 'Listening...'
        : _isSpeaking
            ? 'Speaking...'
            : 'Voice navigation ready';

    final IconData statusIcon = _isListening
        ? Icons.mic
        : _isSpeaking
            ? Icons.volume_up
            : Icons.mic_none;

    return Card(
      elevation: 2,
      color: AppColors.primaryBlue,
      margin: const EdgeInsets.fromLTRB(
        16,
        16,
        16,
        12,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
        child: IconTheme(
          data: const IconThemeData(
            color: AppColors.white,
          ),
          child: DefaultTextStyle(
            style: const TextStyle(
              color: AppColors.white,
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                    color: AppColors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    statusIcon,
                    color: AppColors.primaryBlue,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'VOICE ASSISTANT',
                        style: TextStyle(
                          color: AppColors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        statusText,
                        style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_isListening)
                  const Icon(
                    Icons.graphic_eq,
                    color: AppColors.primaryYellow,
                    size: 28,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // SELECTED DESTINATION
  // ============================================================

  Widget _selectedDestinationCard() {
    if (_selectedBuilding == null) {
      return const SizedBox.shrink();
    }

    return Card(
      color: AppColors.white,
      elevation: 2,
      margin: const EdgeInsets.fromLTRB(
        16,
        12,
        16,
        12,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(
          color: AppColors.primaryBlue,
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: const BoxDecoration(
                color: AppColors.primaryBlue,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.location_on,
                color: AppColors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  const Text(
                    'DESTINATION',
                    style: TextStyle(
                      color: AppColors.primaryBlue,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _selectedBuilding!.name,
                    style: const TextStyle(
                      color: AppColors.darkBlue,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
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
  // VOICE COMMAND TEXT
  // ============================================================

  Widget _voiceCommandText(
  String command,
  String description,
) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 3),
          child: Icon(
            Icons.mic,
            color: AppColors.primaryBlue,
            size: 20,
          ),
        ),

        const SizedBox(width: 10),

        Expanded(
          child: RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: '"$command"',
                  style: const TextStyle(
                    color: AppColors.darkBlue,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextSpan(
                  text: ' — $description',
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 14,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}


// ============================================================
// VOICE COMMANDS CARD
// ============================================================

Widget _voiceCommandsCard() {
  return Container(
    width: double.infinity,
    margin: const EdgeInsets.fromLTRB(
      16,
      4,
      16,
      12,
    ),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: AppColors.primaryBlue,
        width: 2,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.08),
          blurRadius: 6,
          offset: const Offset(0, 3),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ------------------------------------------------------
        // HEADER
        // ------------------------------------------------------
        const Row(
          children: [
            Icon(
              Icons.record_voice_over,
              color: AppColors.primaryBlue,
              size: 26,
            ),
            SizedBox(width: 10),
            Text(
              'VOICE COMMANDS',
              style: TextStyle(
                color: AppColors.primaryBlue,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // ------------------------------------------------------
        // COMMANDS
        // ------------------------------------------------------

        _voiceCommandText(
          'Start navigation',
          'begin walking navigation',
        ),

        _voiceCommandText(
          'Change destination',
          'choose another building',
        ),

        _voiceCommandText(
          'Repeat',
          'hear the route information again',
        ),

        _voiceCommandText(
          'Stop',
          'stop the current navigation',
        ),

        _voiceCommandText(
          'Back',
          'return to the dashboard',
        ),
      ],
    ),
  );
}

  // ============================================================
  // ROUTE INFORMATION
  // ============================================================

  Widget _routeInformationCard() {
    if (_routeDistance == null ||
        _routeDuration == null) {
      return const SizedBox.shrink();
    }

    final double distanceKm =
        _routeDistance! / 1000;

    final int minutes =
        (_routeDuration! / 60).round();

    final String distanceText =
        distanceKm < 1
            ? '${_routeDistance!.round()} m'
            : '${distanceKm.toStringAsFixed(1)} km';

    return Card(
      color: AppColors.white,
      elevation: 2,
      margin: const EdgeInsets.fromLTRB(
        16,
        4,
        16,
        12,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(
          color: AppColors.primaryBlue,
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.route,
                  color: AppColors.primaryBlue,
                  size: 24,
                ),
                SizedBox(width: 10),
                Text(
                  'ROUTE INFORMATION',
                  style: TextStyle(
                    color: AppColors.primaryBlue,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(
                  Icons.straighten,
                  color: AppColors.primaryBlue,
                  size: 25,
                ),
                const SizedBox(width: 12),
                const Text(
                  'Distance',
                  style: TextStyle(
                    color: AppColors.grey,
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
                Text(
                  distanceText,
                  style: const TextStyle(
                    color: AppColors.darkBlue,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(
                  Icons.access_time,
                  color: AppColors.primaryYellow,
                  size: 25,
                ),
                const SizedBox(width: 12),
                const Text(
                  'Walking time',
                  style: TextStyle(
                    color: AppColors.grey,
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
                Text(
                  '$minutes min',
                  style: const TextStyle(
                    color: AppColors.darkBlue,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // BOUNDS
  // ============================================================

  LatLngBounds _calculateBounds(
    List<LatLng> points,
  ) {
    double minLat =
        points.first.latitude;

    double maxLat =
        points.first.latitude;

    double minLng =
        points.first.longitude;

    double maxLng =
        points.first.longitude;

    for (final point in points) {
      if (point.latitude < minLat) {
        minLat = point.latitude;
      }

      if (point.latitude > maxLat) {
        maxLat = point.latitude;
      }

      if (point.longitude < minLng) {
        minLng = point.longitude;
      }

      if (point.longitude > maxLng) {
        maxLng = point.longitude;
      }
    }

    // Prevent extremely small bounds from causing MapLibre
    // to zoom excessively close on very short routes.
    final double latDifference =
        maxLat - minLat;

    final double lngDifference =
        maxLng - minLng;

    if (latDifference < 0.0005) {
      final double extra =
          (0.0005 - latDifference) / 2;

      minLat -= extra;
      maxLat += extra;
    }

    if (lngDifference < 0.0005) {
      final double extra =
          (0.0005 - lngDifference) / 2;

      minLng -= extra;
      maxLng += extra;
    }

    return LatLngBounds(
      southwest: LatLng(
        minLat,
        minLng,
      ),
      northeast: LatLng(
        maxLat,
        maxLng,
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,

      // ========================================================
      // APP BAR
      // ========================================================

      appBar: AppBar(
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: AppColors.white,
        elevation: 0,
        iconTheme: const IconThemeData(
          color: AppColors.white,
        ),
        title: const Text(
          'Campus Navigation',
          style: TextStyle(
            color: AppColors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.stretch,
            children: [
              // ==================================================
              // VOICE STATUS
              // ==================================================

              _voiceStatusCard(),

              // ==================================================
              // MAP
              // ==================================================

              ClipRRect(
                borderRadius:
                    BorderRadius.zero,
                child: _map(),
              ),

              // ==================================================
              // DESTINATION
              // ==================================================

              _selectedDestinationCard(),

              // ==================================================
              // LOADING
              // ==================================================

              if (_loading)
                const Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  child: Column(
                    children: [
                      CircularProgressIndicator(
                        color:
                            AppColors.primaryBlue,
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Calculating route...',
                        style: TextStyle(
                          color:
                              AppColors.darkBlue,
                          fontSize: 15,
                          fontWeight:
                              FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

              // ==================================================
              // VOICE COMMANDS
              // ==================================================

              _voiceCommandsCard(),

              // ==================================================
              // ROUTE INFORMATION
              // ==================================================

              _routeInformationCard(),

              // ==================================================
              // FOOTER
              // ==================================================

              Padding(
                padding:
                    const EdgeInsets.fromLTRB(
                  24,
                  4,
                  24,
                  24,
                ),
                child: Text(
                  _navigationStarted
                      ? 'Use voice commands to control your navigation.'
                      : 'Vision Guide is ready to assist you.',
                  textAlign:
                      TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.grey,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _voiceSession++;

    _voiceMode = _VoiceMode.none;

    _cancelVoiceRetry();
    _cancelListenWatchdog();

    _speech.stop();
    _tts.stop();

    super.dispose();
  }
}

