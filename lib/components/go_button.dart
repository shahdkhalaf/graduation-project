// lib/components/go_button.dart

import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import '../api/api_service.dart';

/// Mapping from station names to [longitude, latitude].
const Map<String, List<double>> _stationCoords = {
  'الكيلو 21'   : [29.732364031977227, 31.076940002163834],
  'الهانوفيل'  : [29.7737962897978,   31.100660476700302],
  'البيطاش'    : [29.794616029183466, 31.114673018531825],
  'المحطة'    : [29.77419867844223,  31.102908974291907],
  'الموقف'     : [29.91418429325476,  31.177764223393417],
  'سموحة'      : [29.941992632377847, 31.215586816840094],
  'محطة الرمل' : [29.89918175001191,  31.200467931344026],
  'الشاطبي'    : [29.909911356144615, 31.205853504540226],
  'العوايد'    : [29.993849433492482, 31.22019370556297],
  'العصافرة 45': [30.00586772502079,  31.26402506209855],
};

/// Your Mapbox access token
const _MAPBOX_TOKEN = 'pk.eyJ1IjoiaWhhZGl3bWljdCIsImEiOiJjbWJqMm9vYTgwYm5kMmlyMWEyNDh5MmYyIn0.MMoxVJcxIh23nh9G9KIaew';

/// GO button: finds nearest station A, optionally draws walking route to A,
/// then fetches and displays waiting-time from A -> chosen destination B.
Widget buildGoButton({
  required BuildContext context,
  required MapboxMap mapController,
  required Point? currentLocation,
  required String destination,
}) {
  return ElevatedButton(
    onPressed: () async {
      // 1) Ensure destination B is valid
      if (!_stationCoords.containsKey(destination)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please select a valid destination station.")),
        );
        return;
      }

      // 2) Find nearest station A to currentLocation
      String? nearestName;
      double? nearestDist;
      List<double>? nearestCoords;
      if (currentLocation != null) {
        // currentLocation.coordinates.toJson() is [lng, lat]
        final curr = currentLocation.coordinates.toJson();
        for (var entry in _stationCoords.entries) {
          final name = entry.key;
          final coords = entry.value;
          final dx = (curr[0] - coords[0]).abs();
          final dy = (curr[1] - coords[1]).abs();
          final meters = sqrt(dx * dx + dy * dy) * 111000;
          if (nearestDist == null || meters < nearestDist) {
            nearestDist = meters;
            nearestName = name;
            nearestCoords = coords;
          }
        }
      }

      if (nearestName == null || nearestCoords == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Could not determine your nearest station.")),
        );
        return;
      }

      // 3) Check if already at station A (within ~50m)
      final atStation = nearestDist! < 50;

      // 4) If not at station A, fetch and draw walking route to A
      if (!atStation && currentLocation != null) {
        final startCoords = currentLocation.coordinates.toJson();
        final start = "${startCoords[0]},${startCoords[1]}";
        final end   = "${nearestCoords[0]},${nearestCoords[1]}";

        final url = Uri.parse(
            'https://api.mapbox.com/directions/v5/mapbox/walking/'
                '$start;$end'
                '?geometries=geojson'
                '&access_token=$_MAPBOX_TOKEN'
        );
        final resp = await http.get(url);
        if (resp.statusCode == 200) {
          final data = jsonDecode(resp.body);
          final coords = (data['routes'][0]['geometry']['coordinates'] as List)
              .cast<List<dynamic>>()
              .map((pt) => pt.cast<double>())
              .toList();

          // remove any existing route
          try { await mapController.style.removeStyleLayer("route-layer"); } catch (_) {}
          try { await mapController.style.removeStyleSource("route-source"); } catch (_) {}

          // add the new route
          final geojson = jsonEncode({
            "type": "FeatureCollection",
            "features": [
              {
                "type": "Feature",
                "geometry": {
                  "type": "LineString",
                  "coordinates": coords,
                }
              }
            ]
          });
          await mapController.style.addSource(
            GeoJsonSource(id: "route-source", data: geojson),
          );
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
      }

      // 5) Fetch waiting-time percentiles from A -> B
      final h = DateTime.now().hour;
      final timeBucket = h < 9
          ? "From 6 AM To 9 AM"
          : h < 12
          ? "From 9 AM To 12 PM"
          : h < 15
          ? "From 12 PM To 3 PM"
          : h < 18
          ? "From 3 PM To 6 PM"
          : "From 6 PM To 9 PM";
      final wd = DateTime.now().weekday;
      final isWeekend = (wd == DateTime.friday || wd == DateTime.saturday)
          ? "yes" : "no";

      final raw = await ApiService.fetchWaitingTime(
        age: 23,
        gender: "female",
        from: nearestName,
        to: destination,
        time: timeBucket,
        isRainy: "no",
        isWeekend: isWeekend,
      );
      if (raw == null) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to fetch waiting time")),
        );
        return;
      }

      final body = jsonDecode(raw) as Map<String, dynamic>;
      final q25 = (body['Q25_prediction'] as List).first as num;
      final q50 = (body['Q50_prediction'] as List).first as num;
      final q75 = (body['Q75_prediction'] as List).first as num;

      // 6) Show results
      final header = atStation
          ? "You’re already at $nearestName."
          : "Closest station is $nearestName.";
      final msg = StringBuffer()
        ..writeln(header)
        ..writeln("Wait-time to $destination:")
        ..writeln(" • Median: ${q50.toInt()} mins")
        ..writeln(" • IQR: ${q25.toInt()}–${q75.toInt()} mins");

      if (!context.mounted) return;
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Station ETA"),
          content: Text(msg.toString()),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"),
            )
          ],
        ),
      );
    },
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF175579),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
    ),
    child: const Text("GO", style: TextStyle(fontSize: 16, color: Colors.white)),
  );
}