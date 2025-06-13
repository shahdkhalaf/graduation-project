import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:location/location.dart';

import 'AccountScreen.dart';
import 'mapbox_view.dart';         // our helper widget
import 'api/api_service.dart';     // if you still need it
import 'components/go_button.dart'; // updated GO button
import 'chat.dart';
import 'make_complaint_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  String startingPoint = "My current location";
  String destination = "My Destination";

  bool isTracking = false;   // Live‐tracking flag
  String? trackingUserId;    // ID being tracked

  MapboxMap? mapboxMap;      // Map controller
  Location _location = Location(); // Location plugin
  Point? userLocation;       // Latest user location

  @override
  void initState() {
    super.initState();
    _initLocationListener();
  }

  Future<void> _initLocationListener() async {
    // 1) Ensure service & permission
    if (!await _location.serviceEnabled()) {
      if (!await _location.requestService()) return;
    }
    if (await _location.hasPermission() == PermissionStatus.denied) {
      if (await _location.requestPermission() != PermissionStatus.granted) {
        return;
      }
    }

    // 2) Listen to location updates
    _location.onLocationChanged.listen((data) {
      if (data.latitude == null || data.longitude == null) return;
      final lat = data.latitude!;
      final lng = data.longitude!;
      setState(() {
        userLocation = Point(coordinates: Position(lng, lat));
        startingPoint = "${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}";
      });
    });
  }

  void _onMapCreated(MapboxMap controller) {
    mapboxMap = controller;
    // Enable the Mapbox user-location puck:
    controller.location.updateSettings(
      LocationComponentSettings(
        enabled: true,
        pulsingEnabled: false,
      ),
    );
  }

  // ===================== Location Selection =====================
  void _selectLocation(bool isStartingPoint) async {
    final List<String> places = [
      "الكيلو 21", "الهانوفيل", "البيطاش", "المحطة", "المنشية",
      "الموقف", "سموحة", "محطة الرمل", "الشاطبي", "العوايد", "العصافرة 45"
    ];

    final Map<String, List<String>> disconnectedAreas = {
      "الكيلو 21": ["الكيلو 21", "الهانوفيل", "البيطاش"],
      "الهانوفيل": ["الكيلو 21", "الهانوفيل", "الالبيطاش"],
      "البيطاش": ["الكيلو 21", "الهانوفيل", "البيطاش"],
    };

    final List<String> urbanAreas = [
      "المحطة", "المنشية", "الموقف", "سموحة", "محطة الرمل",
      "الشاطبي", "العوايد", "العصافرة 45"
    ];

    String current = isStartingPoint ? startingPoint : destination;
    List<String> available = places.where((loc) {
      if (loc == current) return false;
      if (!isStartingPoint) {
        if (urbanAreas.contains(startingPoint)) {
          if (!disconnectedAreas["الكيلو 21"]!.contains(loc)) return false;
        } else {
          if (disconnectedAreas.containsKey(startingPoint) &&
              disconnectedAreas[startingPoint]!.contains(loc)) {
            return false;
          }
        }
      }
      if (isStartingPoint && loc == destination) return false;
      return true;
    }).toList();

    final selected = await showModalBottomSheet<String>(
      context: context,
      builder: (_) => Container(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: available.map((place) => ListTile(
            title: Text(place),
            onTap: () => Navigator.pop(context, place),
          )).toList(),
        ),
      ),
    );

    if (selected != null) {
      setState(() {
        if (isStartingPoint) {
          startingPoint = selected;
          if (disconnectedAreas.containsKey(selected) &&
              disconnectedAreas[selected]!.contains(destination)) {
            destination = "My Destination";
          }
        } else {
          destination = selected;
        }
      });
    }
  }

  // ===================== Live Tracking Dialogs =====================
  void _showLiveTrackingDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String userId = '';

        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          insetPadding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Live Tracking",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(Icons.close, color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  "To start a live location session, enter the ID of the person you want to track.\n"
                      "Once they accept your request, both of your locations will be visible on the map in real-time.",
                  style: TextStyle(fontSize: 16, color: Colors.black),
                ),
                const SizedBox(height: 17),
                TextField(
                  decoration: const InputDecoration(
                    labelText: "Enter User ID",
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding:
                    EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onChanged: (value) => userId = value,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (userId.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Please enter a User ID")),
                        );
                        return;
                      }
                      final prefs = await SharedPreferences.getInstance();
                      final myUserId = prefs.getInt('user_id') ?? 0;
                      // 1️⃣ ابعت request للـ backend
                      try {
                        final response = await http.post(
                          Uri.parse('https://YOUR_BACKEND_URL/send_tracking_request'), // عدل هنا ال link بتاعك
                          headers: {"Content-Type": "application/json"},
                          body: jsonEncode({
                            "from_user_id": myUserId, // هتحط هنا ال user_id بتاع ال user اللي عامل request (3 مثلا)
                            "to_user_id": int.parse(userId),
                          }),
                        );

                        if (response.statusCode == 201) {
                          Navigator.pop(context);
                          _startLiveTracking(userId);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Failed to send request: ${response.statusCode}")),
                          );
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Error sending request: $e")),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF175579),
                      padding: const EdgeInsets.symmetric(vertical: 14.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Text(
                      "Send Tracking Request",
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
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          insetPadding:
          const EdgeInsets.symmetric(horizontal: 25, vertical: 150),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Stack(
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      "Live Tracking",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "You’ve sent a live location tracking request to User ID: $userId.",
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 15,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 25),
                    const SizedBox(
                      width: 75,
                      height: 75,
                      child: CircularProgressIndicator(
                        color: Color(0xFF979797),
                        strokeWidth: 10,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      "We're waiting for them to accept.",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
                Positioned(
                  top: 0,
                  right: 0,
                  child:
                  GestureDetector(onTap: () => Navigator.of(context).pop(),
                      child: const Icon(Icons.close, color: Colors.black54)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showTrackingConfirmation(String userId) {
    setState(() {
      isTracking = true;
      trackingUserId = userId;
    });

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          insetPadding:
          const EdgeInsets.symmetric(horizontal: 25, vertical: 150),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 10),
                    const Text(
                      "Live Tracking Started",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 12),
                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: const TextStyle(
                          fontSize: 15,
                          color: Colors.black87,
                        ),
                        children: [
                          const TextSpan(
                              text: "You’re now sharing live locations with\n"),
                          const TextSpan(text: "User ID: "),
                          TextSpan(
                            text: userId,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const TextSpan(text: "."),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      width: 80,
                      height: 80,
                      decoration: const BoxDecoration(
                        color: Color(0xFF175579),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                          Icons.check, color: Colors.white, size: 40),
                    ),
                    const SizedBox(height: 20),
                    RichText(
                      textAlign: TextAlign.center,
                      text: const TextSpan(
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.black87,
                        ),
                        children: [
                          TextSpan(text: "This session will last for "),
                          TextSpan(
                            text: "1 hour",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          TextSpan(
                              text: ".\nYou can continue exploring the app while tracking runs in the background."),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: 10,
                right: 10,
                child:
                GestureDetector(onTap: () => Navigator.of(context).pop(),
                    child: const Icon(Icons.close, color: Colors.black54)),
              ),
            ],
          ),
        );
      },
    );
  }

  void _stopSharing() {
    setState(() {
      isTracking = false;
      trackingUserId = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Stopped sharing location")),
    );
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
      body: MediaQuery.removePadding(
        context: context,
        removeTop: true,
        removeBottom: true,
        child: Stack(
          children: [
            // Map
            Positioned.fill(
              child: MapboxView(
                onMapCreated: _onMapCreated,
                styleUri: "mapbox://styles/mapbox/streets-v11",
                cameraOptions: CameraOptions(
                  center: Point(coordinates: Position(29.9187, 31.2001)),
                  zoom: 13.0,
                ),
              ),
            ),

            // Bottom panel with GO button & selectors:
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 27),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10)],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          height: 120,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Icon(Icons.my_location, color: Colors.blue),
                              _buildDashedLine(),
                              const Icon(Icons.location_on, color: Colors.red),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              GestureDetector(
                                onTap: () => _selectLocation(true),
                                child: _buildLocationRow(
                                    "STARTING POINT", startingPoint),
                              ),
                              const SizedBox(height: 12),
                              Divider(color: Colors.grey.shade300, thickness: 1),
                              const SizedBox(height: 12),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () => _selectLocation(false),
                                      child: _buildLocationRow(
                                          "ENDING POINT", destination),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  SizedBox(
                                    width: 80,
                                    height: 50,
                                    child: mapboxMap == null
                                    // disabled until the map is ready
                                        ? ElevatedButton(
                                      onPressed: null,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.grey.shade400,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(30),
                                        ),
                                      ),
                                      child: const Text("GO", style: TextStyle(color: Colors.white)),
                                    )
                                    // once mapController is non-null, wire up the real GO button
                                        : buildGoButton(
                                      context: context,
                                      mapController:     mapboxMap!,
                                      currentLocation:   userLocation,
                                      destination:       destination,
                                    ),
                                    )],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
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

            _buildDrawerButton(Icons.chat, "Chat Assist", () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ChatAssistScreen()),
              );
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

            _buildDrawerButton(Icons.business, "Salkah Assets", () {
              Navigator.pop(context);
              // Navigate to Assets Screen
            }),

            _buildDrawerButton(Icons.account_circle, "Account", () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AccountScreen()),
              );
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
