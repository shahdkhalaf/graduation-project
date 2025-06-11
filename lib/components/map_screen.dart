// lib/map_screen.dart
import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

import '../mapbox_view.dart'; // our helper from earlier

class MapScreen extends StatefulWidget {
  const MapScreen({Key? key}) : super(key: key);

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  MapboxMap? mapController;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Map'),
        backgroundColor: const Color(0xFF175579),
      ),
      body: MapboxView(
        onMapCreated: (MapboxMap controller) {
          mapController = controller;
          // e.g. if you want, load a different style later:
          // mapController!.loadStyleURI(StyleURI.SATELLITE);
        },
        styleUri: "mapbox://styles/mapbox/streets-v11",
        cameraOptions: CameraOptions(
          center: Point(coordinates: Position(29.9187, 31.2001)),
          zoom: 12.0,
        ),
      ),
    );
  }
}

