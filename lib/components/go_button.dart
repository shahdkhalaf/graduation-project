// lib/components/go_button.dart

import 'dart:convert';
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

/// GO button: finds nearest station, draws walking route if needed,
/// then calls backend APIs to get price and wait time, then displays result.
Widget buildGoButton({
  required BuildContext context,
  required MapboxMap mapController,
  required Point? currentLocation,
  required String startingPoint, // required, station name
  required String endingPoint,   // required, station name
  required Function(String estimatedTime, String estimatedWait, String price)? onShowRouteConfirmation,
}) {
  return ElevatedButton(
    onPressed: () async {
      // Validate station names
      if (!_stationCoords.containsKey(startingPoint) || !_stationCoords.containsKey(endingPoint)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please select valid stations.")),
        );
        return;
      }

      // Remove previous route layers/sources if exist
      for (final id in [
        "walk-route-layer", "walk-route-source",
        "bus-route-layer", "bus-route-source"
      ]) {
        try { await mapController.style.removeStyleLayer(id); } catch (_) {}
        try { await mapController.style.removeStyleSource(id); } catch (_) {}
      }

      // 1. Dashed Green Walking Line: userLocation → startingPoint
      if (currentLocation != null) {
        final userCoords = currentLocation.coordinates.toJson();
        final startCoords = _stationCoords[startingPoint]!;
        final walkUrl = Uri.parse(
          'https://api.mapbox.com/directions/v5/mapbox/walking/'
          '${userCoords[0]},${userCoords[1]};${startCoords[0]},${startCoords[1]}'
          '?geometries=geojson'
          '&access_token=$_MAPBOX_TOKEN'
        );
        final resp1 = await http.get(walkUrl);
        if (resp1.statusCode == 200) {
          final data1 = jsonDecode(resp1.body);
          final coords1 = (data1['routes'][0]['geometry']['coordinates'] as List)
              .cast<List<dynamic>>()
              .map((pt) => pt.cast<double>())
              .toList();

          final geojson1 = jsonEncode({
            "type": "FeatureCollection",
            "features": [
              {
                "type": "Feature",
                "geometry": {
                  "type": "LineString",
                  "coordinates": coords1,
                }
              }
            ]
          });
          await mapController.style.addSource(
            GeoJsonSource(id: "walk-route-source", data: geojson1),
          );
          await mapController.style.addLayer(
            LineLayer(
              id: "walk-route-layer",
              sourceId: "walk-route-source",
              lineColor: 0xFF00C853, // green
              lineWidth: 4.0,
              lineDasharray: [2.0, 2.0], // dashed
              lineJoin: LineJoin.ROUND,
              lineCap: LineCap.ROUND,
            ),
          );
        }
      }

      // 2. Solid Blue Bus Line: startingPoint → endingPoint
      final startCoords = _stationCoords[startingPoint]!;
      final endCoords = _stationCoords[endingPoint]!;
      final busUrl = Uri.parse(
        'https://api.mapbox.com/directions/v5/mapbox/driving/'
        '${startCoords[0]},${startCoords[1]};${endCoords[0]},${endCoords[1]}'
        '?geometries=geojson'
        '&access_token=$_MAPBOX_TOKEN'
      );
      final resp2 = await http.get(busUrl);
      if (resp2.statusCode == 200) {
        final data2 = jsonDecode(resp2.body);
        final coords2 = (data2['routes'][0]['geometry']['coordinates'] as List)
            .cast<List<dynamic>>()
            .map((pt) => pt.cast<double>())
            .toList();

        final geojson2 = jsonEncode({
          "type": "FeatureCollection",
          "features": [
            {
              "type": "Feature",
              "geometry": {
                "type": "LineString",
                "coordinates": coords2,
              }
            }
          ]
        });
        await mapController.style.addSource(
          GeoJsonSource(id: "bus-route-source", data: geojson2),
        );
        await mapController.style.addLayer(
          LineLayer(
            id: "bus-route-layer",
            sourceId: "bus-route-source",
            lineColor: 0xFF175579, // blue
            lineWidth: 4.0,
            lineJoin: LineJoin.ROUND,
            lineCap: LineCap.ROUND,
          ),
        );
      }

      // Time bucket
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

      // Fetch wait time and price
      final waitResult = await ApiService.fetchWaitingTimeFull(
        age: 23,
        gender: "female",
        from: startingPoint,
        to: endingPoint,
        time: timeBucket,
        isRainy: "no",
        isWeekend: isWeekend,
      );

      final price = await ApiService.fetchPrice(from: startingPoint, to: endingPoint);

      if (waitResult == null) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to fetch waiting time")),
        );
        return;
      }

      final q25 = (waitResult['Q25_prediction'] as List).first as num;
      final q50 = (waitResult['Q50_prediction'] as List).first as num;
      final q75 = (waitResult['Q75_prediction'] as List).first as num;

      if (onShowRouteConfirmation != null) {
        onShowRouteConfirmation(
          "${q50.toInt()} mins",
          "${q25.toInt()}–${q75.toInt()} mins",
          price ?? "N/A",
        );
        return;
      }

      final msg = StringBuffer()
        ..writeln("Wait-time to $endingPoint:")
        ..writeln(" • Median: ${q50.toInt()} mins")
        ..writeln(" • IQR: ${q25.toInt()}–${q75.toInt()} mins")
        ..writeln("💰 Route Price: ${price ?? 'N/A'}");

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