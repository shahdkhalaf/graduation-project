// lib/home.dart

import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

// alias Geolocator
import 'package:geolocator/geolocator.dart' as geolocator;
// alias Mapbox SDK
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mb;

import 'mapbox_view.dart';         // your MapboxView wrapper
import 'api/api_service.dart';     // if you still need it
import 'components/go_button.dart';// your existing “GO” button
import 'chat.dart';
import 'make_complaint_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // ─── State for your pickers & live tracking ────────────────────────────────
  String startingPoint = "My current location";
  String destination   = "My Destination";
  bool   isTracking    = false;
  String? trackingUserId;

  // ─── Mapbox + Annotations ─────────────────────────────────────────────────
  mb.MapboxMap?              mapController;
  mb.PointAnnotationManager? annotationManager;
  mb.PointAnnotation?        userAnnotation;

  // ─── Geolocator stream ────────────────────────────────────────────────────
  StreamSubscription<geolocator.Position>? _positionStream;

  @override
  void initState() {
    super.initState();
    _startLocationUpdates();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }

  /// Called by MapboxView once the map is ready
  void _onMapCreated(mb.MapboxMap controller) async {
    mapController = controller;
    annotationManager =
    await controller.annotations.createPointAnnotationManager();
  }

  /// Request permission and start streaming GPS updates
  Future<void> _startLocationUpdates() async {
    if (!await geolocator.Geolocator.isLocationServiceEnabled()) return;
    var perm = await geolocator.Geolocator.checkPermission();
    if (perm == geolocator.LocationPermission.denied) {
      perm = await geolocator.Geolocator.requestPermission();
      if (perm == geolocator.LocationPermission.denied) return;
    }
    if (perm == geolocator.LocationPermission.deniedForever) return;

    _positionStream = geolocator.Geolocator.getPositionStream(
      locationSettings: const geolocator.LocationSettings(
        accuracy: geolocator.LocationAccuracy.best,
        distanceFilter: 5,
      ),
    ).listen(_onNewPosition);
  }

  /// Handle each GPS update by drawing/updating a Mapbox annotation
  Future<void> _onNewPosition(geolocator.Position pos) async {
    if (mapController == null || annotationManager == null) return;

    // Load your marker image
    final byteData = await rootBundle.load('assets/img_1.png');
    final imageData = byteData.buffer.asUint8List();

    // Build annotation options
    final opts = mb.PointAnnotationOptions(
      geometry: mb.Point(
        coordinates: mb.Position(pos.longitude, pos.latitude),
      ),
      image: imageData,
      iconSize: 1.2,
    );

    // If we already have one, remove it
    if (userAnnotation != null) {
      await annotationManager!.delete(userAnnotation!);
      userAnnotation = null;
    }

    // Create a new one
    userAnnotation = await annotationManager!.create(opts);

    // Optional: move camera to follow the user
    // await mapController!.camera.easeTo(
    //   mb.CameraOptions(
    //     center: mb.Point(coordinates: mb.Position(pos.longitude, pos.latitude)),
    //     zoom: 15.0,
    //   ),
    // );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // LOCATION PICKER
  // ───────────────────────────────────────────────────────────────────────────
  void _selectLocation(bool isStarting) async {
    final places = [
      "الكيلو 21","الهانوفيل","البيطاش","المحطة","المنشية",
      "الموقف","سموحة","محطة الرمل","الشاطبي","العوايد","العصافرة 45"
    ];
    final disconnectedAreas = {
      "الكيلو 21": ["الكيلو 21","الهانوفيل","البيطاش"],
      "الهانوفيل": ["الكيلو 21","الهانوفيل","البيطاش"],
      "البيطاش": ["الكيلو 21","الهانوفيل","البيطاش"],
    };
    final urbanAreas = [
      "المحطة","المنشية","الموقف","سموحة","محطة الرمل",
      "الشاطبي","العوايد","العصافرة 45"
    ];

    String current = isStarting ? startingPoint : destination;
    var available = places.where((loc) {
      if (loc == current) return false;
      if (!isStarting) {
        if (urbanAreas.contains(startingPoint)) {
          if (!disconnectedAreas["الكيلو 21"]!.contains(loc)) return false;
        } else if (disconnectedAreas.containsKey(startingPoint)) {
          if (disconnectedAreas[startingPoint]!.contains(loc)) return false;
        }
      }
      return true;
    }).toList();

    String? sel = await showModalBottomSheet<String>(
      context: context,
      builder: (_) => Container(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: available.map((p) => ListTile(
            title: Text(p),
            onTap: () => Navigator.pop(context, p),
          )).toList(),
        ),
      ),
    );

    if (sel != null) {
      setState(() {
        if (isStarting) {
          startingPoint = sel;
          if (disconnectedAreas.containsKey(sel) &&
              disconnectedAreas[sel]!.contains(destination)) {
            destination = "My Destination";
          }
        } else {
          destination = sel;
        }
      });
    }
  }

  // ───────────────────────────────────────────────────────────────────────────
  // LIVE-TRACKING DIALOGS
  // ───────────────────────────────────────────────────────────────────────────
  void _showLiveTrackingDialog() {
    showDialog(
      context: context,
      builder: (ctx) {
        String userId = "";
        return Dialog(
          backgroundColor: Colors.white,
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          insetPadding:
          const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Live Tracking",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        )),
                    GestureDetector(
                        onTap: () => Navigator.pop(ctx),
                        child: const Icon(Icons.close)),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  "To start a live location session, enter the ID of the person you want to track.\n"
                      "Once they accept, you'll both be visible on the map in real-time.",
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 16),
                TextField(
                  decoration: const InputDecoration(
                    labelText: "Enter User ID",
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (v) => userId = v,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    if (userId.isEmpty) {
                      ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
                          content: Text("Please enter a User ID")));
                      return;
                    }
                    Navigator.pop(ctx);
                    _startLiveTracking(userId);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF175579),
                  ),
                  child: const Text("Send Tracking Request"),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _startLiveTracking(String userId) async {
    _showWaitingDialog(userId);
    await Future.delayed(const Duration(seconds: 5));
    Navigator.of(context, rootNavigator: true).pop();
    _showTrackingConfirmation(userId);
  }

  void _showWaitingDialog(String userId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
      shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        insetPadding: EdgeInsets.symmetric(horizontal: 25, vertical: 150),
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            CircularProgressIndicator(),
            SizedBox(height: 12),
            Text("Waiting for them to accept…"),
          ]),
        ),
      ),
    );
  }

  void _showTrackingConfirmation(String userId) {
    setState(() {
      isTracking = true;
      trackingUserId = userId;
    });
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Live Tracking Started"),
        content: Text("You’re now sharing live locations with User ID: $userId"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          )
        ],
      ),
    );
  }

  void _stopSharing() {
    setState(() {
      isTracking = false;
      trackingUserId = null;
    });
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text("Stopped sharing location")));
  }

  // ===================== Route Confirmation Dialog =====================
  void _showRouteConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          insetPadding:
          const EdgeInsets.symmetric(horizontal: 20, vertical: 100),
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Your Route",
                      style:
                      TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(Icons.close, color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  "Confirm where you are going",
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Icon(Icons.my_location, color: Colors.blue),
                        _buildDashedLine(),
                        const Icon(Icons.location_on, color: Colors.red),
                      ],
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLocationRow("STARTING POINT", startingPoint),
                          const SizedBox(height: 10),
                          _buildLocationRow("ENDING POINT", destination),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Divider(height: 1, color: Colors.grey),
                const SizedBox(height: 16),
                _buildEstimateRow("Estimated travel time", "50 mins"),
                _buildEstimateRow("Estimated waiting time", "15 mins"),
                _buildEstimateRow("Estimated price", "5.00 EGP"),
                const SizedBox(height: 20),
                Center(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF175579),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30)),
                      padding: const EdgeInsets.symmetric(
                          vertical: 14.0, horizontal: 40.0),
                    ),
                    child: const Text(
                      "Confirm Route",
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ===================== Helper Widgets =====================
  Widget _buildEstimateRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(
              fontSize: 14, fontWeight: FontWeight.bold)),
          Text(value, style: const TextStyle(
              fontSize: 14, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildDashedLine() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        6,
            (index) =>
            Container(
              width: 2,
              height: 5,
              color: Colors.grey.shade600,
              margin: const EdgeInsets.symmetric(vertical: 2),
            ),
      ),
    );
  }

  Widget _buildLocationRow(String label, String place) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          place,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: (place == "My Destination") ? Colors.grey : Colors.black,
          ),
        ),
      ],
    );
  }

  // ===================== Main Build =====================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: _buildDrawer(),
      resizeToAvoidBottomInset: false,
      body: Stack(children: [
        // 1) Full-screen Mapbox:
        Positioned.fill(
          child: MapboxView(
            onMapCreated: _onMapCreated,
            styleUri: "mapbox://styles/mapbox/streets-v11",
            cameraOptions: mb.CameraOptions(
              center: mb.Point(coordinates: mb.Position(29.9187, 31.2001)),
              zoom: 13.0,
            ),
          ),
        ),

        // 2) STOP SHARING if tracking:
        if (isTracking)
          Positioned(
            top: 40,
            left: 80,
            right: 20,
            child: ElevatedButton(
              onPressed: _stopSharing,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF175579),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30)),
              ),
              child: const Text("STOP SHARING"),
            ),
          ),

        // 3) GO‐button panel at bottom:
        Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10)],
            ),
            child: Row(children: [
              Column(children: const [
                Icon(Icons.my_location, color: Colors.blue),
                SizedBox(height: 4),
                Icon(Icons.location_on, color: Colors.red),
              ]),
              const SizedBox(width: 12),
              Expanded(
                child: Column(children: [
                  GestureDetector(
                      onTap: () => _selectLocation(true),
                      child: Text(startingPoint,
                          style: const TextStyle(fontWeight: FontWeight.bold))),
                  const Divider(),
                  GestureDetector(
                      onTap: () => _selectLocation(false),
                      child: Text(destination,
                          style: const TextStyle(fontWeight: FontWeight.bold))),
                ]),
              ),
              buildGoButton(
                context: context,
                startingPoint: startingPoint,
                destination: destination,
              ),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: Container(
        color: const Color(0xFF175579), // خلفية زرقاء
        child: Column(
          children: [
            const SizedBox(height: 60), // مسافة فوق
            Image.asset(
              'assets/salkah.png',
              width: 200,
              height: 80,
              fit: BoxFit.contain, // لضبط الصورة
            ),
            const SizedBox(height: 20),

            _buildDrawerButton(Icons.home, "Home", () {
              Navigator.pop(context);
              // Navigate to Home (لو عندك Home Screen — هنا تحط النفيجيشن بتاعها)
            }),

            _buildDrawerButton(Icons.report, "Make a Complaint", () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MakeComplaintScreen()),
              );
            }),

            _buildDrawerButton(Icons.person_pin_circle, "Live Tracking", () {
              Navigator.pop(context);
              _showLiveTrackingDialog();
            }),

            _buildDrawerButton(Icons.business, "Salkah Assist", () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ChatAssistScreen()),
              );
            }),

            _buildDrawerButton(Icons.account_circle, "Account", () {
              Navigator.pop(context);
              // Navigate to Account Screen
            }),

            const Spacer(), // يخلي الزرار اللي تحت دايما تحت

        Padding(
          padding: const EdgeInsets.all(16.0),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3E6E8C),
                foregroundColor: const Color(0xFFFFFFFF),
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.clear();
                Navigator.pushReplacementNamed(context, '/signin');
              },
              child: Padding(
                padding: const EdgeInsetsDirectional.only(start: 55), // مسافة من الحافة
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: const [
                    Icon(Icons.logout),
                    SizedBox(width: 12),
                    Text("Logout", style: TextStyle(fontSize: 16)),
                  ],
                ),
              ),
              ),
            ),
        )],
        ),
      ),
    );
  }

  Widget _buildDrawerButton(IconData icon, String text, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF3E6E8C), // الأزرق الفاتح
            foregroundColor: const Color(0xFFFFFFFF),
            padding: const EdgeInsets.symmetric(vertical: 20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          onPressed: onTap,
          child: Padding(
            padding: const EdgeInsets.only(left: 12), // مسافة من اليسار (أو من اليمين لو RTL)
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Icon(icon),
                const SizedBox(width: 12),
                Text(
                  text,
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
