import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapView extends StatefulWidget {
  final void Function(GoogleMapController) onMapCreated;
  const MapView({Key? key, required this.onMapCreated}) : super(key: key);

  @override
  State<MapView> createState() => _MapViewState();
}

class _MapViewState extends State<MapView> {
  @override
  Widget build(BuildContext context) {
    return GoogleMap(
      onMapCreated: widget.onMapCreated,
      initialCameraPosition: const CameraPosition(
        target: LatLng(31.2001, 29.9187), // Alexandria
        zoom: 13,
      ),
      myLocationEnabled: true,
      myLocationButtonEnabled: true,
      zoomControlsEnabled: false,
    );
  }

// Do NOT override dispose() here—let the plugin clean itself up.
}
