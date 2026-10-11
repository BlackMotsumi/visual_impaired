import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import 'package:visual_impaired/theme/app_theme.dart';
import 'package:visual_impaired/voice/voice_service.dart';

class OfflineMapsScreen extends StatefulWidget {
  const OfflineMapsScreen({super.key});

  @override
  State<OfflineMapsScreen> createState() => _OfflineMapsScreenState();
}

class _OfflineMapsScreenState extends State<OfflineMapsScreen> {
  static const String _boxName = 'offline_routes';

  static const String _mapStyleUrl =
      'https://demotiles.maplibre.org/style.json';

  static const LatLng _campusCenter = LatLng(
    -29.1214556,
    26.2156972,
  );

  final VoiceService _voice = VoiceService();

  bool _voiceReady = false;
  bool _isListeningForCommands = false;
  bool _isProcessingVoiceCommand = false;
  bool _isSpeaking = false;

  MapLibreMapController? _mapController;

  bool _styleLoaded = false;

  bool _isDownloading = false;
  double _downloadProgress = 0.0;

  List<Map<String, dynamic>> _routes = [];

  Map<String, dynamic>? _selectedRoute;

  String? _errorMessage;

  bool _disposed = false;

  @override
  void initState() {
    super.initState();
    _initializeScreen();
  }

  @override
  void dispose() {
    _disposed = true;

    _voice.stopListening();

    super.dispose();
  }

  // ============================================================
  // INITIALIZATION
  // ============================================================

  Future<void> _initializeScreen() async {
    try {
      await _initializeVoice();
      await _loadRoutes();

      if (_disposed) return;

      await _welcome();

      if (_disposed) return;

      await _startListening();
    } catch (e) {
      debugPrint(
        'OFFLINE MAPS INITIALIZATION ERROR: $e',
      );

      if (!_disposed && mounted) {
        setState(() {
          _errorMessage =
              'Unable to initialize offline maps.';
        });
      }
    }
  }

  Future<void> _initializeVoice() async {
    try {
      await _voice.initialize();

      if (_disposed) return;

      if (mounted) {
        setState(() {
          _voiceReady = _voice.isInitialized;
        });
      }
    } catch (e) {
      debugPrint(
        'VOICE INITIALIZATION ERROR: $e',
      );

      if (!_disposed && mounted) {
        setState(() {
          _voiceReady = false;
        });
      }
    }
  }

  // ============================================================
  // VOICE
  // ============================================================

  Future<void> _welcome() async {
    if (!_voiceReady || _disposed) return;

    if (_routes.isEmpty) {
      await _speak(
        'Offline maps. There are currently no saved routes. '
        'You can say download map, open route, help, or dashboard.',
      );
    } else {
      await _speak(
        'Offline maps. You have ${_routes.length} saved '
        '${_routes.length == 1 ? 'route' : 'routes'}. '
        'You can say open route, download map, delete route, '
        'help, or dashboard.',
      );
    }
  }

  Future<void> _speak(String message) async {
    if (!_voiceReady || _disposed) return;

    try {
      if (mounted) {
        setState(() {
          _isSpeaking = true;
        });
      }

      await _voice.speak(message);
    } catch (e) {
      debugPrint(
        'VOICE SPEAK ERROR: $e',
      );
    } finally {
      if (!_disposed && mounted) {
        setState(() {
          _isSpeaking = false;
        });
      }
    }
  }

  Future<void> _startListening() async {
    if (!_voiceReady ||
        _disposed ||
        _isProcessingVoiceCommand ||
        _isDownloading) {
      return;
    }

    if (_isListeningForCommands) {
      return;
    }

    try {
      if (mounted) {
        setState(() {
          _isListeningForCommands = true;
        });
      }

      final result = await _voice.listen(
        onResult: (text) async {
          if (_disposed) return;

          final command = text.trim();

          if (command.isEmpty) {
            return;
          }

          debugPrint(
            'OFFLINE MAP VOICE COMMAND: $command',
          );

          await _handleVoiceCommand(command);
        },
      );

      if (!_disposed && mounted) {
        setState(() {
          _isListeningForCommands = false;
        });
      }

      debugPrint(
        'VOICE LISTEN RESULT: $result',
      );

      if (!_disposed &&
          _voiceReady &&
          !_isDownloading &&
          !_isProcessingVoiceCommand) {
        await Future.delayed(
          const Duration(milliseconds: 500),
        );

        if (!_disposed) {
          await _startListening();
        }
      }
    } catch (e) {
      debugPrint(
        'VOICE LISTEN ERROR: $e',
      );

      if (!_disposed && mounted) {
        setState(() {
          _isListeningForCommands = false;
        });
      }

      if (!_disposed &&
          _voiceReady &&
          !_isDownloading) {
        await Future.delayed(
          const Duration(seconds: 1),
        );

        if (!_disposed) {
          await _startListening();
        }
      }
    }
  }

  Future<void> _handleVoiceCommand(
    String command,
  ) async {
    if (_disposed ||
        _isProcessingVoiceCommand) {
      return;
    }

    _isProcessingVoiceCommand = true;

    try {
      final normalized =
          _normalizeCommand(command);

      await _voice.stopListening();

      // ----------------------------------------------------------
      // DASHBOARD / BACK
      // ----------------------------------------------------------

      if (_containsAny(normalized, [
        'dashboard',
        'go back',
        'back',
        'home',
        'main menu',
      ])) {
        await _returnToDashboard();
        return;
      }

      // ----------------------------------------------------------
      // REPEAT
      // ----------------------------------------------------------

      if (_containsAny(normalized, [
        'repeat',
        'say again',
        'again',
        'what can i say',
      ])) {
        await _welcome();
        return;
      }

      // ----------------------------------------------------------
      // STOP
      // ----------------------------------------------------------

      if (_containsAny(normalized, [
        'stop',
        'stop speaking',
        'be quiet',
        'quiet',
      ])) {
        await _voice.stopListening();

        await _speak(
          'Voice commands stopped.',
        );

        return;
      }

      // ----------------------------------------------------------
      // OPEN ROUTE
      // ----------------------------------------------------------

      if (_containsAny(normalized, [
        'open route',
        'open a route',
        'show route',
        'show a route',
      ])) {
        await _voiceOpenRoute();
        return;
      }

      // ----------------------------------------------------------
      // DOWNLOAD MAP
      // ----------------------------------------------------------

      if (_containsAny(normalized, [
        'download map',
        'download a map',
        'save map',
        'save this map',
      ])) {
        await _voiceDownloadMap();
        return;
      }

      // ----------------------------------------------------------
      // DELETE LAST ROUTE
      // ----------------------------------------------------------

      if (_containsAny(normalized, [
        'delete last route',
        'delete the last route',
        'remove last route',
      ])) {
        await _deleteLastCompleteRoute();
        return;
      }

      // ----------------------------------------------------------
      // DELETE ROUTE
      // ----------------------------------------------------------

      if (_containsAny(normalized, [
        'delete route',
        'remove route',
        'delete this route',
      ])) {
        await _voiceDeleteRoute();
        return;
      }

      // ----------------------------------------------------------
      // HELP
      // ----------------------------------------------------------

      if (_containsAny(normalized, [
        'help',
        'commands',
        'what can i do',
        'what can i say',
      ])) {
        await _speak(
          'You can say open route, download map, delete route, '
          'delete last route, repeat, stop, or dashboard.',
        );
        return;
      }

      await _speak(
        'I did not understand that command. '
        'Please say open route, download map, delete route, '
        'help, or dashboard.',
      );
    } finally {
      _isProcessingVoiceCommand = false;

      if (!_disposed &&
          _voiceReady &&
          !_isDownloading &&
          mounted) {
        setState(() {});
      }

      if (!_disposed &&
          _voiceReady &&
          !_isDownloading) {
        await Future.delayed(
          const Duration(milliseconds: 500),
        );

        if (!_disposed &&
            !_isListeningForCommands &&
            !_isProcessingVoiceCommand) {
          await _startListening();
        }
      }
    }
  }

  String _normalizeCommand(
    String command,
  ) {
    return command
        .toLowerCase()
        .replaceAll(
          RegExp(r'[^\w\s]'),
          ' ',
        )
        .replaceAll(
          RegExp(r'\s+'),
          ' ',
        )
        .trim();
  }

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

  Future<void> _returnToDashboard() async {
    await _voice.stopListening();

    await _speak(
      'Returning to the dashboard.',
    );

    if (!_disposed && mounted) {
      Navigator.of(context).pop();
    }
  }

  // ============================================================
  // VOICE ROUTE COMMANDS
  // ============================================================

  Future<void> _voiceOpenRoute() async {
    if (_routes.isEmpty) {
      await _speak(
        'There are no saved offline routes. '
        'You can download a map for a route first.',
      );
      return;
    }

    if (_routes.length == 1) {
      await _openRoute(
        _routes.first,
      );
      return;
    }

    await _speak(
      'There are ${_routes.length} saved routes. '
      'Please select a route on the screen.',
    );
  }

  Future<void> _voiceDownloadMap() async {
    if (_routes.isEmpty) {
      await _speak(
        'There are no saved routes available for offline download.',
      );
      return;
    }

    if (_selectedRoute == null) {
      if (_routes.length == 1) {
        await _downloadMapForRoute(
          _routes.first,
        );
      } else {
        await _speak(
          'Please select a route first, then say download map.',
        );
      }

      return;
    }

    await _downloadMapForRoute(
      _selectedRoute!,
    );
  }

  Future<void> _voiceDeleteRoute() async {
    if (_routes.isEmpty) {
      await _speak(
        'There are no saved routes to delete.',
      );
      return;
    }

    if (_selectedRoute == null) {
      if (_routes.length == 1) {
        await _showDeleteConfirmation(
          _routes.first,
        );
      } else {
        await _speak(
          'Please select a route first, then say delete route.',
        );
      }

      return;
    }

    await _showDeleteConfirmation(
      _selectedRoute!,
    );
  }

  // ============================================================
  // HIVE ROUTES
  // ============================================================

  Future<void> _loadRoutes() async {
    try {
      final box = await Hive.openBox(
        _boxName,
      );

      final loadedRoutes =
          <Map<String, dynamic>>[];

      for (final key in box.keys) {
        final value = box.get(key);

        if (value is Map) {
          loadedRoutes.add(
            Map<String, dynamic>.from(value),
          );
        }
      }

      if (_disposed) return;

      if (mounted) {
        setState(() {
          _routes = loadedRoutes;
        });
      }
    } catch (e) {
      debugPrint(
        'LOAD OFFLINE ROUTES ERROR: $e',
      );

      if (!_disposed && mounted) {
        setState(() {
          _errorMessage =
              'Unable to load saved offline routes.';
        });
      }
    }
  }

  Future<void> _saveRoute(
    Map<String, dynamic> route,
  ) async {
    final box = await Hive.openBox(
      _boxName,
    );

    final id =
        route['id']?.toString() ??
            DateTime.now()
                .millisecondsSinceEpoch
                .toString();

    await box.put(
      id,
      route,
    );

    await _loadRoutes();
  }

  // ============================================================
  // OPEN ROUTE
  // ============================================================

  Future<void> _openRoute(
    Map<String, dynamic> route,
  ) async {
    if (_disposed) return;

    if (mounted) {
      setState(() {
        _selectedRoute = route;
      });
    }

    await _drawSelectedRoute();

    final name =
        route['name']?.toString() ??
            'selected route';

    await _speak(
      'Opening $name.',
    );
  }

  Future<void> _drawSelectedRoute() async {
    if (_mapController == null ||
        !_styleLoaded ||
        _selectedRoute == null) {
      return;
    }

    try {
      await _mapController!.clearLines();
      await _mapController!.clearCircles();

      final route =
          _selectedRoute!;

      final startLat =
          _asDouble(
        route['startLatitude'],
      );

      final startLng =
          _asDouble(
        route['startLongitude'],
      );

      final destinationLat =
          _asDouble(
        route['destinationLatitude'],
      );

      final destinationLng =
          _asDouble(
        route['destinationLongitude'],
      );

      if (startLat == null ||
          startLng == null ||
          destinationLat == null ||
          destinationLng == null) {
        return;
      }

      final start = LatLng(
        startLat,
        startLng,
      );

      final destination = LatLng(
        destinationLat,
        destinationLng,
      );

      await _mapController!.addLine(
        LineOptions(
          geometry: [
            start,
            destination,
          ],
          lineColor: '#0047AB',
          lineWidth: 6.0,
          lineOpacity: 0.9,
        ),
      );

      await _mapController!.addCircle(
        CircleOptions(
          geometry: start,
          circleColor: '#1565C0',
          circleRadius: 9,
          circleStrokeColor: '#FFFFFF',
          circleStrokeWidth: 3,
        ),
      );

      await _mapController!.addCircle(
        CircleOptions(
          geometry: destination,
          circleColor: '#FFC72C',
          circleRadius: 10,
          circleStrokeColor: '#003477',
          circleStrokeWidth: 3,
        ),
      );

      final southwest = LatLng(
        start.latitude <
                destination.latitude
            ? start.latitude
            : destination.latitude,
        start.longitude <
                destination.longitude
            ? start.longitude
            : destination.longitude,
      );

      final northeast = LatLng(
        start.latitude >
                destination.latitude
            ? start.latitude
            : destination.latitude,
        start.longitude >
                destination.longitude
            ? start.longitude
            : destination.longitude,
      );

      await _mapController!.animateCamera(
        CameraUpdate.newLatLngBounds(
          LatLngBounds(
            southwest: southwest,
            northeast: northeast,
          ),
          left: 60,
          right: 60,
          top: 100,
          bottom: 180,
        ),
      );
    } catch (e) {
      debugPrint(
        'DRAW OFFLINE ROUTE ERROR: $e',
      );
    }
  }

  // ============================================================
  // OFFLINE MAP DOWNLOAD
  // ============================================================

  Future<void> _downloadMapForRoute(
    Map<String, dynamic> route,
  ) async {
    if (_isDownloading) return;

    if (_mapController == null) {
      await _speak(
        'The map is not ready yet. Please try again.',
      );
      return;
    }

    final startLat =
        _asDouble(
      route['startLatitude'],
    );

    final startLng =
        _asDouble(
      route['startLongitude'],
    );

    final destinationLat =
        _asDouble(
      route['destinationLatitude'],
    );

    final destinationLng =
        _asDouble(
      route['destinationLongitude'],
    );

    if (startLat == null ||
        startLng == null ||
        destinationLat == null ||
        destinationLng == null) {
      await _speak(
        'This route does not contain valid map coordinates.',
      );
      return;
    }

    final minLat =
        startLat < destinationLat
            ? startLat
            : destinationLat;

    final maxLat =
        startLat > destinationLat
            ? startLat
            : destinationLat;

    final minLng =
        startLng < destinationLng
            ? startLng
            : destinationLng;

    final maxLng =
        startLng > destinationLng
            ? startLng
            : destinationLng;

    final bounds = LatLngBounds(
      southwest: LatLng(
        minLat - 0.002,
        minLng - 0.002,
      ),
      northeast: LatLng(
        maxLat + 0.002,
        maxLng + 0.002,
      ),
    );

    if (mounted) {
      setState(() {
        _isDownloading = true;
        _downloadProgress = 0.0;
        _errorMessage = null;
      });
    }

    await _voice.stopListening();

    await _speak(
      'Starting offline map download. Please wait.',
    );

    try {
      // --------------------------------------------------------
      // MAPLIBRE 0.26.2
      //
      // IMPORTANT:
      // mapStyleUrl is used instead of styleURL.
      // pixelRatio is not supported.
      // --------------------------------------------------------

      final regionDefinition =
          OfflineRegionDefinition(
        bounds: bounds,
        minZoom: 14,
        maxZoom: 19,
        mapStyleUrl: _mapStyleUrl,
      );

      // --------------------------------------------------------
      // IMPORTANT:
      // downloadOfflineRegion is a TOP-LEVEL MapLibre function.
      // It is NOT a MapLibreMapController method.
      // --------------------------------------------------------

      final region =
          await downloadOfflineRegion(
        regionDefinition,
        metadata: {
          'routeName':
              route['name']?.toString() ??
                  'Offline Route',
        },
        onEvent: (
          DownloadRegionStatus status,
        ) {
          if (_disposed || !mounted) {
            return;
          }

          // MapLibre sends different status types.
          //
          // Only InProgress contains the resource counters.
          if (status is InProgress) {
            final required =
                status.requiredResourceCount;

            if (required > 0) {
              final progress =
                  status.completedResourceCount /
                      required;

              setState(() {
                _downloadProgress =
                    progress.clamp(
                  0.0,
                  1.0,
                );
              });
            }
          } else if (status is Success) {
            if (mounted) {
              setState(() {
                _downloadProgress = 1.0;
              });
            }
          } else if (status is Error) {
            debugPrint(
              'OFFLINE DOWNLOAD ERROR STATUS: '
              '${status.cause}',
            );
          }
        },
      );

      // --------------------------------------------------------
      // SAVE REGION ID
      // --------------------------------------------------------

      final updatedRoute =
          Map<String, dynamic>.from(
        route,
      );

      updatedRoute['offlineRegionId'] =
          region.id;

      updatedRoute['offlineDownloaded'] =
          true;

      updatedRoute['offlineDownloadedAt'] =
          DateTime.now().toIso8601String();

      await _saveRoute(
        updatedRoute,
      );

      if (!_disposed && mounted) {
        setState(() {
          _selectedRoute =
              updatedRoute;

          _isDownloading = false;

          _downloadProgress = 1.0;
        });
      }

      await _speak(
        'Offline map download complete.',
      );
    } catch (e) {
      debugPrint(
        'OFFLINE MAP DOWNLOAD ERROR: $e',
      );

      final message =
          _explainOfflineMapError(e);

      if (!_disposed && mounted) {
        setState(() {
          _isDownloading = false;
          _downloadProgress = 0.0;
          _errorMessage = message;
        });
      }

      await _speak(
        message,
      );
    }
  }

  String _explainOfflineMapError(
    Object error,
  ) {
    final message =
        error.toString().toLowerCase();

    if (message.contains('network') ||
        message.contains('internet') ||
        message.contains('connection')) {
      return 'The map could not be downloaded because of a network problem.';
    }

    if (message.contains('style') ||
        message.contains('tiles')) {
      return 'The map style or map tiles could not be downloaded.';
    }

    if (message.contains('storage') ||
        message.contains('disk')) {
      return 'There may not be enough storage space for the offline map.';
    }

    if (message.contains('permission')) {
      return 'Storage permission is required to save the offline map.';
    }

    if (message.contains('maplibre')) {
      return 'The map service reported an offline download problem.';
    }

    return 'The offline map could not be downloaded. Please try again.';
  }

  // ============================================================
  // DELETE ROUTES
  // ============================================================

  Future<void> _deleteLastCompleteRoute() async {
    if (_routes.isEmpty) {
      await _speak(
        'There are no saved routes to delete.',
      );
      return;
    }

    final route =
        _routes.last;

    await _showDeleteConfirmation(
      route,
    );
  }

  Future<void> _deleteRoute(
    Map<String, dynamic> route,
  ) async {
    try {
      final offlineRegionId =
          route['offlineRegionId'];

      if (offlineRegionId != null) {
        try {
          // ------------------------------------------------------
          // IMPORTANT:
          // deleteOfflineRegion is also a TOP-LEVEL function.
          // ------------------------------------------------------

          await deleteOfflineRegion(
            int.parse(
              offlineRegionId.toString(),
            ),
          );
        } catch (e) {
          debugPrint(
            'DELETE OFFLINE REGION ERROR: $e',
          );
        }
      }

      final box =
          await Hive.openBox(
        _boxName,
      );

      final routeId =
          route['id']?.toString();

      if (routeId != null) {
        await box.delete(
          routeId,
        );
      } else {
        dynamic keyToDelete;

        for (final key in box.keys) {
          final value =
              box.get(key);

          if (value is Map &&
              value['name'] ==
                  route['name']) {
            keyToDelete = key;
            break;
          }
        }

        if (keyToDelete != null) {
          await box.delete(
            keyToDelete,
          );
        }
      }

      if (!_disposed && mounted) {
        await _mapController
            ?.clearLines();

        await _mapController
            ?.clearCircles();

        setState(() {
          _selectedRoute = null;
        });
      }

      await _loadRoutes();

      await _speak(
        'Route deleted.',
      );
    } catch (e) {
      debugPrint(
        'DELETE ROUTE ERROR: $e',
      );

      await _speak(
        'I could not delete the route. Please try again.',
      );
    }
  }

  Future<void> _showDeleteConfirmation(
    Map<String, dynamic> route,
  ) async {
    if (_disposed || !mounted) {
      return;
    }

    final routeName =
        route['name']?.toString() ??
            'this route';

    final shouldDelete =
        await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor:
              AppColors.white,
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(
              24,
            ),
          ),
          title: const Text(
            'Delete Route?',
            style: TextStyle(
              color:
                  AppColors.darkBlue,
              fontSize: 24,
              fontWeight:
                  FontWeight.bold,
            ),
          ),
          content: Text(
            'Are you sure you want to delete $routeName?',
            style: const TextStyle(
              color:
                  AppColors.black,
              fontSize: 18,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(
                  context,
                ).pop(false);
              },
              child: const Text(
                'CANCEL',
                style: TextStyle(
                  color:
                      AppColors.primaryBlue,
                  fontWeight:
                      FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            ElevatedButton(
              style:
                  ElevatedButton.styleFrom(
                backgroundColor:
                    AppColors.primaryRed,
                foregroundColor:
                    AppColors.white,
                minimumSize:
                    const Size(
                  120,
                  52,
                ),
              ),
              onPressed: () {
                Navigator.of(
                  context,
                ).pop(true);
              },
              child:
                  const Text(
                'DELETE',
              ),
            ),
          ],
        );
      },
    );

    if (shouldDelete == true &&
        !_disposed) {
      await _deleteRoute(
        route,
      );
    }
  }

  // ============================================================
  // MAP
  // ============================================================

  void _onMapCreated(
    MapLibreMapController controller,
  ) {
    _mapController =
        controller;
  }

  Future<void> _onStyleLoaded() async {
    _styleLoaded = true;

    if (_selectedRoute != null) {
      await _drawSelectedRoute();
    }
  }

  // ============================================================
  // VOICE STOP
  // ============================================================

  Future<void> _stopSpeaking() async {
    try {
      await _voice.stopSpeaking();

      if (!_disposed && mounted) {
        setState(() {
          _isSpeaking = false;
        });
      }
    } catch (e) {
      debugPrint(
        'STOP SPEAKING ERROR: $e',
      );
    }
  }

  // ============================================================
  // FORMATTING
  // ============================================================

  String _formatDate(
    dynamic value,
  ) {
    if (value == null) {
      return 'Date unavailable';
    }

    try {
      final date =
          DateTime.parse(
        value.toString(),
      );

      final day =
          date.day
              .toString()
              .padLeft(
                2,
                '0',
              );

      final month =
          date.month
              .toString()
              .padLeft(
                2,
                '0',
              );

      final year =
          date.year.toString();

      final hour =
          date.hour
              .toString()
              .padLeft(
                2,
                '0',
              );

      final minute =
          date.minute
              .toString()
              .padLeft(
                2,
                '0',
              );

      return '$day/$month/$year $hour:$minute';
    } catch (_) {
      return value.toString();
    }
  }

  String _formatDistance(
    dynamic value,
  ) {
    final distance =
        _asDouble(value);

    if (distance == null) {
      return 'Distance unavailable';
    }

    if (distance < 1000) {
      return '${distance.round()} m';
    }

    return '${(distance / 1000).toStringAsFixed(1)} km';
  }

  double? _asDouble(
    dynamic value,
  ) {
    if (value == null) {
      return null;
    }

    if (value is double) {
      return value;
    }

    if (value is int) {
      return value.toDouble();
    }

    return double.tryParse(
      value.toString(),
    );
  }

  // ============================================================
  // UI - MAP STATUS
  // ============================================================

  Widget _buildMapStatus() {
    final isReady =
        _styleLoaded;

    return Positioned(
      top: 16,
      left: 16,
      right: 16,
      child: Semantics(
        liveRegion: true,
        label: isReady
            ? 'Map ready'
            : 'Loading map',
        child: Container(
          padding:
              const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          decoration:
              BoxDecoration(
            color:
                AppColors.white,
            borderRadius:
                BorderRadius.circular(
              18,
            ),
            border:
                Border.all(
              color: isReady
                  ? AppColors.primaryBlue
                  : AppColors.primaryYellow,
              width: 3,
            ),
            boxShadow:
                const [
              BoxShadow(
                color:
                    Colors.black26,
                blurRadius: 8,
                offset:
                    Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(
                isReady
                    ? Icons.map
                    : Icons.hourglass_top,
                color: isReady
                    ? AppColors.primaryBlue
                    : AppColors.darkBlue,
                size: 30,
              ),
              const SizedBox(
                width: 12,
              ),
              Expanded(
                child: Text(
                  isReady
                      ? 'MAP READY'
                      : 'LOADING MAP...',
                  style:
                      const TextStyle(
                    color:
                        AppColors.darkBlue,
                    fontSize: 17,
                    fontWeight:
                        FontWeight.bold,
                    letterSpacing:
                        0.5,
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
  // UI - DOWNLOAD PROGRESS
  // ============================================================

  Widget _buildDownloadProgress() {
    if (!_isDownloading) {
      return const SizedBox.shrink();
    }

    final percentage =
        (_downloadProgress * 100)
            .round();

    return Positioned(
      top: 88,
      left: 16,
      right: 16,
      child: Semantics(
        liveRegion: true,
        label:
            'Downloading offline map $percentage percent',
        child: Container(
          padding:
              const EdgeInsets.all(
            16,
          ),
          decoration:
              BoxDecoration(
            color:
                AppColors.white,
            borderRadius:
                BorderRadius.circular(
              18,
            ),
            border:
                Border.all(
              color:
                  AppColors.primaryBlue,
              width: 3,
            ),
            boxShadow:
                const [
              BoxShadow(
                color:
                    Colors.black26,
                blurRadius: 8,
                offset:
                    Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.download_for_offline,
                    color:
                        AppColors.primaryBlue,
                    size: 28,
                  ),
                  SizedBox(
                    width: 10,
                  ),
                  Expanded(
                    child: Text(
                      'DOWNLOADING OFFLINE MAP',
                      style:
                          TextStyle(
                        color:
                            AppColors.darkBlue,
                        fontSize: 16,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(
                height: 12,
              ),
              ClipRRect(
                borderRadius:
                    BorderRadius.circular(
                  10,
                ),
                child:
                    LinearProgressIndicator(
                  value:
                      _downloadProgress,
                  minHeight:
                      12,
                  backgroundColor:
                      AppColors.grey,
                  valueColor:
                      const AlwaysStoppedAnimation<
                          Color>(
                    AppColors.primaryYellow,
                  ),
                ),
              ),
              const SizedBox(
                height: 8,
              ),
              Align(
                alignment:
                    Alignment.centerRight,
                child: Text(
                  '$percentage%',
                  style:
                      const TextStyle(
                    color:
                        AppColors.darkBlue,
                    fontSize: 18,
                    fontWeight:
                        FontWeight.bold,
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
  // UI - HEADER
  // ============================================================

  Widget _buildHeroHeader() {
    return Container(
      width:
          double.infinity,
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
          24,
        ),
        border:
            Border.all(
          color:
              AppColors.primaryBlue,
          width: 2,
        ),
        boxShadow:
            const [
          BoxShadow(
            color:
                Colors.black12,
            blurRadius: 8,
            offset:
                Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 68,
            height: 68,
            decoration:
                BoxDecoration(
              color:
                  AppColors.lightBlue,
              shape:
                  BoxShape.circle,
              border:
                  Border.all(
                color:
                    AppColors.primaryYellow,
                width: 4,
              ),
            ),
            child:
                const Icon(
              Icons.map_outlined,
              color:
                  AppColors.white,
              size: 36,
            ),
          ),
          const SizedBox(
            width: 16,
          ),
          const Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'SAVED OFFLINE ROUTES',
                  style:
                      TextStyle(
                    color:
                        AppColors.darkBlue,
                    fontSize: 22,
                    fontWeight:
                        FontWeight.bold,
                    letterSpacing:
                        0.4,
                  ),
                ),
                SizedBox(
                  height: 5,
                ),
                Text(
                  'ACCESS YOUR ROUTES WITHOUT INTERNET',
                  style:
                      TextStyle(
                    color:
                        AppColors.primaryBlue,
                    fontSize: 13,
                    fontWeight:
                        FontWeight.bold,
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
  // UI - VOICE STATUS
  // ============================================================

  Widget _buildVoiceStatus() {
    Color backgroundColor;
    Color borderColor;
    Color iconColor;
    IconData icon;
    String title;
    String subtitle;

    if (_isSpeaking) {
      backgroundColor =
          AppColors.darkBlue;
      borderColor =
          AppColors.primaryYellow;
      iconColor =
          AppColors.primaryYellow;
      icon =
          Icons.volume_up;
      title =
          'VOICE SPEAKING';
      subtitle =
          'Vision Guide is speaking.';
    } else if (_isListeningForCommands) {
      backgroundColor =
          const Color(
        0xFFEAF2FF,
      );
      borderColor =
          AppColors.primaryYellow;
      iconColor =
          AppColors.primaryBlue;
      icon =
          Icons.mic;
      title =
          'LISTENING FOR COMMANDS';
      subtitle =
          'Say a command such as open route or help.';
    } else if (!_voiceReady) {
      backgroundColor =
          const Color(
        0xFFFFEBEE,
      );
      borderColor =
          AppColors.primaryRed;
      iconColor =
          AppColors.primaryRed;
      icon =
          Icons.mic_off;
      title =
          'VOICE UNAVAILABLE';
      subtitle =
          'Voice commands are currently unavailable.';
    } else {
      backgroundColor =
          AppColors.white;
      borderColor =
          AppColors.primaryBlue;
      iconColor =
          AppColors.primaryBlue;
      icon =
          Icons.mic_none;
      title =
          'VOICE READY';
      subtitle =
          'Waiting for your command.';
    }

    return Semantics(
      liveRegion: true,
      label:
          '$title. $subtitle',
      child: Container(
        width:
            double.infinity,
        padding:
            const EdgeInsets.all(
          18,
        ),
        decoration:
            BoxDecoration(
          color:
              backgroundColor,
          borderRadius:
              BorderRadius.circular(
            20,
          ),
          border:
              Border.all(
            color:
                borderColor,
            width: 3,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 58,
              height: 58,
              decoration:
                  BoxDecoration(
                color:
                    iconColor,
                shape:
                    BoxShape.circle,
                border:
                    Border.all(
                  color:
                      AppColors.white,
                  width: 3,
                ),
              ),
              child:
                  Icon(
                icon,
                color:
                    AppColors.white,
                size: 30,
              ),
            ),
            const SizedBox(
              width: 14,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style:
                        TextStyle(
                      color: _isSpeaking
                          ? AppColors.white
                          : AppColors.darkBlue,
                      fontSize: 17,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                  const SizedBox(
                    height: 4,
                  ),
                  Text(
                    subtitle,
                    style:
                        TextStyle(
                      color: _isSpeaking
                          ? AppColors.white
                          : AppColors.black,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
            if (_isSpeaking)
              Semantics(
                button: true,
                label:
                    'Stop speaking',
                child:
                    IconButton(
                  tooltip:
                      'Stop speaking',
                  onPressed:
                      _stopSpeaking,
                  icon:
                      const Icon(
                    Icons.stop_circle,
                    color:
                        AppColors.primaryYellow,
                    size: 36,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // UI - EMPTY ROUTES
  // ============================================================

  Widget _buildEmptyRoutes() {
    return Container(
      width:
          double.infinity,
      padding:
          const EdgeInsets.all(
        24,
      ),
      decoration:
          BoxDecoration(
        color:
            const Color(
          0xFFEAF2FF,
        ),
        borderRadius:
            BorderRadius.circular(
          20,
        ),
        border:
            Border.all(
          color:
              AppColors.primaryBlue,
          width: 2,
        ),
      ),
      child:
          const Column(
        children: [
          Icon(
            Icons.map_outlined,
            color:
                AppColors.primaryBlue,
            size: 52,
          ),
          SizedBox(
            height: 12,
          ),
          Text(
            'NO SAVED ROUTES',
            textAlign:
                TextAlign.center,
            style:
                TextStyle(
              color:
                  AppColors.darkBlue,
              fontSize: 20,
              fontWeight:
                  FontWeight.bold,
            ),
          ),
          SizedBox(
            height: 8,
          ),
          Text(
            'Create or save a route first, then download it for offline use.',
            textAlign:
                TextAlign.center,
            style:
                TextStyle(
              color:
                  AppColors.black,
              fontSize: 16,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // UI - ROUTE CARD
  // ============================================================

  Widget _buildRouteCard(
    Map<String, dynamic> route,
    int index,
  ) {
    final isSelected =
        identical(
              _selectedRoute,
              route,
            ) ||
            (_selectedRoute != null &&
                _selectedRoute!['id'] ==
                    route['id']);

    final routeName =
        route['name']?.toString() ??
            'Route ${index + 1}';

    final distance =
        _formatDistance(
      route['distance'],
    );

    final date =
        _formatDate(
      route['createdAt'] ??
          route['timestamp'],
    );

    final downloaded =
        route['offlineDownloaded'] ==
                true ||
            route['offlineRegionId'] !=
                null;

    return Semantics(
      container: true,
      label:
          '$routeName. Distance $distance. '
          '${downloaded ? 'Available offline.' : 'Not downloaded offline.'}',
      child: Container(
        margin:
            const EdgeInsets.only(
          bottom: 14,
        ),
        padding:
            const EdgeInsets.all(
          16,
        ),
        decoration:
            BoxDecoration(
          color: isSelected
              ? const Color(
                  0xFFEAF2FF,
                )
              : AppColors.white,
          borderRadius:
              BorderRadius.circular(
            20,
          ),
          border:
              Border.all(
            color: isSelected
                ? AppColors.primaryBlue
                : AppColors.grey,
            width:
                isSelected
                    ? 3
                    : 2,
          ),
          boxShadow:
              const [
            BoxShadow(
              color:
                  Colors.black12,
              blurRadius:
                  6,
              offset:
                  Offset(0, 2),
            ),
          ],
        ),
        child:
            Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration:
                      BoxDecoration(
                    color: isSelected
                        ? AppColors.primaryBlue
                        : AppColors.lightBlue,
                    borderRadius:
                        BorderRadius.circular(
                      14,
                    ),
                  ),
                  child:
                      const Icon(
                    Icons.route,
                    color:
                        AppColors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(
                  width: 12,
                ),
                Expanded(
                  child:
                      Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        routeName,
                        maxLines: 2,
                        overflow:
                            TextOverflow.ellipsis,
                        style:
                            const TextStyle(
                          color:
                              AppColors.darkBlue,
                          fontSize:
                              19,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                      const SizedBox(
                        height: 5,
                      ),
                      Text(
                        'Distance: $distance',
                        style:
                            const TextStyle(
                          color:
                              AppColors.black,
                          fontSize:
                              15,
                        ),
                      ),
                      const SizedBox(
                        height: 3,
                      ),
                      Text(
                        'Saved: $date',
                        style:
                            const TextStyle(
                          color:
                              Colors.black54,
                          fontSize:
                              14,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 6,
                    ),
                    decoration:
                        BoxDecoration(
                      color:
                          AppColors.primaryYellow,
                      borderRadius:
                          BorderRadius.circular(
                        12,
                      ),
                    ),
                    child:
                        const Text(
                      'SELECTED',
                      style:
                          TextStyle(
                        color:
                            AppColors.black,
                        fontSize:
                            11,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(
              height: 14,
            ),
            if (downloaded)
              Container(
                width:
                    double.infinity,
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 9,
                ),
                decoration:
                    BoxDecoration(
                  color:
                      AppColors.darkBlue,
                  borderRadius:
                      BorderRadius.circular(
                    12,
                  ),
                ),
                child:
                    const Row(
                  children: [
                    Icon(
                      Icons.offline_pin,
                      color:
                          AppColors.primaryYellow,
                      size: 22,
                    ),
                    SizedBox(
                      width: 8,
                    ),
                    Text(
                      'AVAILABLE OFFLINE',
                      style:
                          TextStyle(
                        color:
                            AppColors.white,
                        fontWeight:
                            FontWeight.bold,
                        fontSize:
                            13,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(
              height: 14,
            ),
            Row(
              children: [
                Expanded(
                  child:
                      OutlinedButton.icon(
                    onPressed:
                        _isDownloading
                            ? null
                            : () =>
                                _openRoute(
                                  route,
                                ),
                    icon:
                        const Icon(
                      Icons.route,
                    ),
                    label:
                        const Text(
                      'OPEN ROUTE',
                    ),
                    style:
                        OutlinedButton.styleFrom(
                      foregroundColor:
                          AppColors.primaryBlue,
                      minimumSize:
                          const Size(
                        0,
                        54,
                      ),
                      side:
                          const BorderSide(
                        color:
                            AppColors.primaryBlue,
                        width:
                            2,
                      ),
                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(
                          14,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(
                  width: 10,
                ),
                Expanded(
                  child:
                      ElevatedButton.icon(
                    onPressed:
                        _isDownloading
                            ? null
                            : () =>
                                _downloadMapForRoute(
                                  route,
                                ),
                    icon:
                        const Icon(
                      Icons.download,
                    ),
                    label:
                        const Text(
                      'DOWNLOAD',
                    ),
                    style:
                        ElevatedButton.styleFrom(
                      backgroundColor:
                          AppColors.primaryYellow,
                      foregroundColor:
                          AppColors.black,
                      minimumSize:
                          const Size(
                        0,
                        54,
                      ),
                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(
                          14,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(
              height: 10,
            ),
            SizedBox(
              width:
                  double.infinity,
              child:
                  OutlinedButton.icon(
                onPressed:
                    _isDownloading
                        ? null
                        : () =>
                            _showDeleteConfirmation(
                              route,
                            ),
                icon:
                    const Icon(
                  Icons.delete_outline,
                ),
                label:
                    const Text(
                  'DELETE ROUTE',
                ),
                style:
                    OutlinedButton.styleFrom(
                  foregroundColor:
                      AppColors.primaryRed,
                  minimumSize:
                      const Size(
                    double.infinity,
                    50,
                  ),
                  side:
                      const BorderSide(
                    color:
                        AppColors.primaryRed,
                    width:
                        2,
                  ),
                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(
                      14,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // UI - VOICE INSTRUCTIONS
  // ============================================================

  Widget _buildVoiceInstructions() {
    return Container(
      width:
          double.infinity,
      padding:
          const EdgeInsets.all(
        18,
      ),
      decoration:
          BoxDecoration(
        color:
            AppColors.darkBlue,
        borderRadius:
            BorderRadius.circular(
          20,
        ),
        border:
            Border.all(
          color:
              AppColors.primaryYellow,
          width: 2,
        ),
      ),
      child:
          const Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.mic,
                color:
                    AppColors.primaryYellow,
                size: 28,
              ),
              SizedBox(
                width: 10,
              ),
              Text(
                'VOICE COMMANDS',
                style:
                    TextStyle(
                  color:
                      AppColors.white,
                  fontSize: 18,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(
            height: 12,
          ),
          Text(
            'Say: “Open route”, “Download map”, '
            '“Delete route”, “Help”, “Repeat”, '
            'or “Dashboard”.',
            style:
                TextStyle(
              color:
                  AppColors.white,
              fontSize: 16,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // UI - ERROR
  // ============================================================

  Widget _buildErrorMessage() {
    if (_errorMessage == null) {
      return const SizedBox.shrink();
    }

    return Container(
      width:
          double.infinity,
      margin:
          const EdgeInsets.only(
        bottom: 14,
      ),
      padding:
          const EdgeInsets.all(
        16,
      ),
      decoration:
          BoxDecoration(
        color:
            const Color(
          0xFFFFEBEE,
        ),
        borderRadius:
            BorderRadius.circular(
          18,
        ),
        border:
            Border.all(
          color:
              AppColors.primaryRed,
          width: 2,
        ),
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.error_outline,
            color:
                AppColors.primaryRed,
            size: 28,
          ),
          const SizedBox(
            width: 10,
          ),
          Expanded(
            child: Text(
              _errorMessage!,
              style:
                  const TextStyle(
                color:
                    AppColors.black,
                fontSize: 15,
                height: 1.4,
              ),
            ),
          ),
        ],
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
    return Scaffold(
      backgroundColor:
          AppColors.primaryBlue,
      appBar: AppBar(
        backgroundColor:
            AppColors.primaryBlue,
        foregroundColor:
            AppColors.white,
        elevation: 0,
        centerTitle: true,
        title:
            const Text(
          'Offline Maps',
          style:
              TextStyle(
            color:
                AppColors.white,
            fontSize: 22,
            fontWeight:
                FontWeight.bold,
          ),
        ),
        actions: [
          Semantics(
            button: true,
            label:
                'Repeat offline map instructions',
            child:
                IconButton(
              tooltip:
                  'Repeat',
              onPressed:
                  _welcome,
              icon:
                  const Icon(
                Icons.volume_up,
                color:
                    AppColors.primaryYellow,
                size: 28,
              ),
            ),
          ),
        ],
      ),
      body:
          SafeArea(
        child:
            Column(
          children: [
            // ==================================================
            // MAP
            // ==================================================

            Expanded(
              flex: 5,
              child:
                  Container(
                margin:
                    const EdgeInsets.fromLTRB(
                  12,
                  4,
                  12,
                  0,
                ),
                clipBehavior:
                    Clip.antiAlias,
                decoration:
                    BoxDecoration(
                  color:
                      AppColors.white,
                  borderRadius:
                      const BorderRadius.only(
                    topLeft:
                        Radius.circular(
                      24,
                    ),
                    topRight:
                        Radius.circular(
                      24,
                    ),
                  ),
                  border:
                      Border.all(
                    color:
                        AppColors.primaryYellow,
                    width:
                        3,
                  ),
                ),
                child:
                    Stack(
                  children: [
                    MapLibreMap(
                      initialCameraPosition:
                          const CameraPosition(
                        target:
                            _campusCenter,
                        zoom:
                            16.0,
                      ),
                      styleString:
                          _mapStyleUrl,
                      onMapCreated:
                          _onMapCreated,
                      onStyleLoadedCallback:
                          _onStyleLoaded,
                      compassEnabled:
                          true,
                      myLocationEnabled:
                          true,
                      myLocationTrackingMode:
                          MyLocationTrackingMode
                              .tracking,
                    ),
                    _buildMapStatus(),
                    _buildDownloadProgress(),
                  ],
                ),
              ),
            ),

            // ==================================================
            // CONTENT
            // ==================================================

            Expanded(
              flex: 5,
              child:
                  Container(
                width:
                    double.infinity,
                decoration:
                    const BoxDecoration(
                  color:
                      AppColors.white,
                  borderRadius:
                      BorderRadius.only(
                    topLeft:
                        Radius.circular(
                      28,
                    ),
                    topRight:
                        Radius.circular(
                      28,
                    ),
                  ),
                ),
                child:
                    SingleChildScrollView(
                  padding:
                      const EdgeInsets.fromLTRB(
                    16,
                    20,
                    16,
                    28,
                  ),
                  child:
                      Center(
                    child:
                        ConstrainedBox(
                      constraints:
                          const BoxConstraints(
                        maxWidth:
                            700,
                      ),
                      child:
                          Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          _buildHeroHeader(),

                          const SizedBox(
                            height: 16,
                          ),

                          _buildVoiceStatus(),

                          const SizedBox(
                            height: 16,
                          ),

                          _buildErrorMessage(),

                          if (_routes.isEmpty)
                            _buildEmptyRoutes()
                          else ...[
                            const Text(
                              'YOUR SAVED ROUTES',
                              style:
                                  TextStyle(
                                color:
                                    AppColors.darkBlue,
                                fontSize:
                                    21,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),

                            const SizedBox(
                              height: 12,
                            ),

                            ...List.generate(
                              _routes.length,
                              (index) =>
                                  _buildRouteCard(
                                _routes[index],
                                index,
                              ),
                            ),

                            const SizedBox(
                              height: 4,
                            ),

                            SizedBox(
                              width:
                                  double.infinity,
                              child:
                                  ElevatedButton.icon(
                                onPressed:
                                    _isDownloading
                                        ? null
                                        : _deleteLastCompleteRoute,
                                icon:
                                    const Icon(
                                  Icons.delete_sweep,
                                ),
                                label:
                                    const Text(
                                  'DELETE LAST ROUTE',
                                ),
                                style:
                                    ElevatedButton.styleFrom(
                                  backgroundColor:
                                      AppColors.primaryRed,
                                  foregroundColor:
                                      AppColors.white,
                                  minimumSize:
                                      const Size(
                                    double.infinity,
                                    56,
                                  ),
                                  shape:
                                      RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(
                                      16,
                                    ),
                                  ),
                                  textStyle:
                                      const TextStyle(
                                    fontSize:
                                        16,
                                    fontWeight:
                                        FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],

                          const SizedBox(
                            height: 18,
                          ),

                          _buildVoiceInstructions(),

                          const SizedBox(
                            height: 18,
                          ),

                          Container(
                            width:
                                double.infinity,
                            padding:
                                const EdgeInsets.all(
                              14,
                            ),
                            decoration:
                                BoxDecoration(
                              color:
                                  AppColors.primaryBlue,
                              borderRadius:
                                  BorderRadius.circular(
                                16,
                              ),
                            ),
                            child:
                                const Center(
                              child:
                                  Text(
                                'VOICE-FIRST ACCESSIBLE OFFLINE MAPS',
                                textAlign:
                                    TextAlign.center,
                                style:
                                    TextStyle(
                                  color:
                                      AppColors.white,
                                  fontSize:
                                      13,
                                  fontWeight:
                                      FontWeight.bold,
                                  letterSpacing:
                                      0.5,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}