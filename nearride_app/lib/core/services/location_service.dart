import 'package:geolocator/geolocator.dart';

class LocationResult {
  const LocationResult({this.position, this.message});

  final Position? position;
  final String? message;
}

class LocationService {
  Future<LocationResult> current() async {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      return const LocationResult(
        message:
            'Location permission was denied. Tap detect location to retry.',
      );
    }
    if (permission == LocationPermission.deniedForever) {
      return const LocationResult(
        message:
            'Location permission is permanently denied. Enable it in app settings.',
      );
    }
    if (!await Geolocator.isLocationServiceEnabled()) {
      return const LocationResult(
        message: 'Device location is turned off. Enable GPS and try again.',
      );
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      ).timeout(const Duration(seconds: 20));
      return LocationResult(position: position);
    } catch (_) {
      final lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null) {
        return LocationResult(
          position: lastKnown,
          message: 'Using your last known location. Tap detect to refresh it.',
        );
      }
      return const LocationResult(
        message:
            'Could not get your GPS location. Move outdoors and tap detect again.',
      );
    }
  }

  Future<void> openAppSettings() => Geolocator.openAppSettings();

  Future<void> openLocationSettings() => Geolocator.openLocationSettings();
}
