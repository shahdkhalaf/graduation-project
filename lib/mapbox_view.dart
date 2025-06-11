// lib/mapbox_view.dart

import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

/// A small wrapper around the native `MapWidget` that Mapbox provides.
/// It exposes:
///   • onMapCreated → callback(MapboxMap controller)
///   • styleUri       → a valid style (e.g. "mapbox://styles/mapbox/streets-v11")
///   • cameraOptions  → initial camera (e.g. center & zoom)
class MapboxView extends StatelessWidget {
  final void Function(MapboxMap) onMapCreated;
  final String styleUri;
  final CameraOptions cameraOptions;

  const MapboxView({
    super.key,
    required this.onMapCreated,
    required this.styleUri,
    required this.cameraOptions,
  });

  @override
  Widget build(BuildContext context) {
    return MapWidget(
      key: const ValueKey("mapbox_view"),

      // ① When the platform view is created, MapWidget supplies a MapboxMap object:
      onMapCreated: (map) {
        onMapCreated(map);
      },

      // ② Set a valid Mapbox style URI (e.g. "mapbox://styles/mapbox/streets-v11"):
      styleUri: styleUri,

      // ③ Initial camera position:
      cameraOptions: cameraOptions,
    );
  }
}


