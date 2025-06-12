// lib/services/location_service.dart

import 'package:geolocator/geolocator.dart';

class LocationService {
  /// Request permission (if needed) and return one‐shot current position.
  static Future<Position> getCurrentLocation() async {
    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied) {
        throw Exception('Location permission denied');
      }
    }
    if (perm == LocationPermission.deniedForever) {
      throw Exception('Location permissions permanently denied');
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.best,
    );
  }
}
