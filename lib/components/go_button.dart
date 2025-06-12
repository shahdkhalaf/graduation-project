// go_button.dart
import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import '../api/api_service.dart';

/// GO button: uses your last-known Mapbox [Point]? or falls back to a place name.
Widget buildGoButton({
  required BuildContext context,
  required String startingPoint,
  required String destination,
  Point? currentLocation,
}) {
  return ElevatedButton(
    onPressed: () async {
      // 1) Time bucket
      final hour = DateTime.now().hour;
      final timeOfDay = hour < 9
          ? 'From 6 AM To 9 AM'
          : hour < 12
          ? 'From 9 AM To 12 PM'
          : hour < 15
          ? 'From 12 PM To 3 PM'
          : hour < 18
          ? 'From 3 PM To 6 PM'
          : 'From 6 PM To 9 PM';

      // 2) Weekend check
      final now = DateTime.now();
      final isWeekend = (now.weekday == DateTime.friday || now.weekday == DateTime.saturday)
          ? 'yes'
          : 'no';

      // 3) Demographics (hard-coded)
      const age = 23;
      const gender = 'female';

      // 4) Decide "from":
      String from = startingPoint;
      if (currentLocation != null) {
        // Position.toJson() returns [lng, lat]
        final coords = currentLocation.coordinates.toJson();
        final lng = coords[0];
        final lat = coords[1];
        from = '${lat.toStringAsFixed(5)},${lng.toStringAsFixed(5)}';
      }

      // 5) Call API
      final result = await ApiService.fetchWaitingTime(
        age: age,
        gender: gender,
        from: from,
        to: destination,
        time: timeOfDay,
        isRainy: 'no',
        isWeekend: isWeekend,
      );

      // 6) Show outcome
      if (!context.mounted) return;
      if (result != null) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Estimated Waiting Time'),
            content: Text(result),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to get waiting time prediction')),
        );
      }
    },
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF175579),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      padding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 24.0),
    ),
    child: const Text('GO', style: TextStyle(fontSize: 16, color: Colors.white)),
  );
}


