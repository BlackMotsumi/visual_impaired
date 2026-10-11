import 'package:geolocator/geolocator.dart';

class LocationService {
  // ============================================================
  // CHECK LOCATION SERVICE
  // ============================================================

  static Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  // ============================================================
  // CHECK AND REQUEST PERMISSION
  // ============================================================

  static Future<LocationPermission> requestPermission() async {
    LocationPermission permission =
        await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission =
          await Geolocator.requestPermission();
    }

    return permission;
  }

  // ============================================================
  // GET CURRENT LOCATION
  // ============================================================

  static Future<Position?> getCurrentLocation() async {
    try {
      final serviceEnabled =
          await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        print(
          'LOCATION ERROR: Location services are disabled.',
        );

        return null;
      }

      LocationPermission permission =
          await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission =
            await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        print(
          'LOCATION ERROR: Permission denied.',
        );

        return null;
      }

      if (permission ==
          LocationPermission.deniedForever) {
        print(
          'LOCATION ERROR: Location permission permanently denied.',
        );

        return null;
      }

      final position =
          await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      print(
        'CURRENT LOCATION: '
        '${position.latitude}, '
        '${position.longitude}',
      );

      return position;
    } catch (e) {
      print(
        'LOCATION ERROR: $e',
      );

      return null;
    }
  }
}