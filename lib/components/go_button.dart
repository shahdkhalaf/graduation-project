// lib/components/go_button.dart

import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import '../api/api_service.dart';

/// Mapping from station names to [lng, lat].
const Map<String, List<double>> _stationCoords = {
  'الكيلو 21'   : [29.732364031977227, 31.076940002163834],
  'الهانوفيل'  : [29.7737962897978,   31.100660476700302],
  'البيطاش'    : [29.794616029183466, 31.114673018531825],
  'محطة مصر'   : [29.902791889923858, 31.192916486699772],
  'المنشية'    : [29.77419867844223,  31.102908974291907],
  'الموقف'     : [29.91418429325476,  31.177764223393417],
  'سموحة'      : [29.941992632377847, 31.215586816840094],
  'محطة الرمل' : [29.89918175001191,  31.200467931344026],
  'الشاطبي'    : [29.909911356144615, 31.205853504540226],
  'العوايد'    : [29.993849433492482, 31.22019370556297],
  'العصافرة 45': [30.00586772502079,  31.26402506209855],
};

/// A GO button that:
/// 1) If user is >50 m from the chosen station, draws a walking route.
/// 2) Then calls your waiting‐time API and displays the result.
Widget buildGoButton({
  required BuildContext context,
  required MapboxMap mapController,
  required Point? currentLocation,
  required String destination,
}) {
  return ElevatedButton(
    onPressed: () async {
      // --- 1) Determine if user is “at” the station (within ~50 m) ---
      bool atStation = false;
      final sc = _stationCoords[destination];
      if (currentLocation != null && sc != null) {
        final curr = currentLocation.toJson(); // [lng, lat]
        final dx = (curr[0] - sc[0]).abs();
        final dy = (curr[1] - sc[1]).abs();
        final meters = sqrt(dx * dx + dy * dy) * 111000;
        atStation = meters < 50;
      }

      // --- 2) If not at station, overlay walking route ---
      if (!atStation && currentLocation != null && sc != null) {
        final geojson = jsonEncode({
          "type": "FeatureCollection",
          "features": [
            {
              "type": "Feature",
              "geometry": {
                "type": "LineString",
                "coordinates": [
                  currentLocation.toJson(),
                  sc
                ]
              }
            }
          ]
        });

        // Add or replace the GeoJSON source:
        await mapController.style.addSource(
          GeoJsonSource(id: "route-source", data: geojson),
        );

        // Add the line layer on top:
        await mapController.style.addLayer(
          LineLayer(
            id: "route-layer",
            sourceId: "route-source",
            lineColor: Color(0xFF175579).value,
            lineWidth: 4.0,
            lineJoin: LineJoin.ROUND,
            lineCap: LineCap.ROUND,
          ),
        );
      }

      // --- 3) Fetch & show waiting time at that station ---
      final hour = DateTime.now().hour;
      final timeOfDay = hour < 9
          ? "From 6 AM To 9 AM"
          : hour < 12
          ? "From 9 AM To 12 PM"
          : hour < 15
          ? "From 12 PM To 3 PM"
          : hour < 18
          ? "From 3 PM To 6 PM"
          : "From 6 PM To 9 PM";
      final now = DateTime.now();
      final isWeekend = (now.weekday == DateTime.friday ||
          now.weekday == DateTime.saturday)
          ? "yes"
          : "no";

      final result = await ApiService.fetchWaitingTime(
        age: 23,
        gender: "female",
        from: destination,
        to: destination,
        time: timeOfDay,
        isRainy: "no",
        isWeekend: isWeekend,
      );

      if (!context.mounted) return;
      if (result != null) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("Estimated Waiting Time"),
            content: Text(result),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("OK"),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to fetch waiting time")),
        );
      }
    },
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF175579),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(30),
      ),
      padding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 24.0),
    ),
    child: const Text("GO",
        style: TextStyle(fontSize: 16, color: Colors.white)),
  );
}






