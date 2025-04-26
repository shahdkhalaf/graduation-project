import 'package:flutter/material.dart';

import 'chat.dart';
import 'make_complaint_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String startingPoint = "My current location";
  String destination = "My Destination";
  bool isTracking = false; // To check if tracking is active
  String? trackingUserId; // Store the ID of the user being tracked

  // ===================== Location Selection =====================
  void _selectLocation(bool isStartingPoint) async {
    final List<String> places = [
      "الكيلو 21",
      "الهانوفيل",
      "البيطاش",
      "المحطة",
      "المنشية",
      "الموقف",
      "سموحة",
      "محطة الرمل",
      "الشاطبي",
      "العوايد",
      "العصافرة 45"
    ];

    final Map<String, List<String>> disconnectedAreas = {
      "الكيلو 21": ["الكيلو 21", "الهانوفيل", "البيطاش"],
      "الهانوفيل": ["الكيلو 21", "الهانوفيل", "البيطاش"],
      "البيطاش": ["الكيلو 21", "الهانوفيل", "البيطاش"],
    };

    final List<String> urbanAreas = [
      "المحطة",
      "المنشية",
      "الموقف",
      "سموحة",
      "محطة الرمل",
      "الشاطبي",
      "العوايد",
      "العصافرة 45"
    ];

    String currentLocation = isStartingPoint ? startingPoint : destination;
    String otherLocation = isStartingPoint ? destination : startingPoint;

    List<String> availableLocations = places.where((location) {
      if (location == currentLocation) return false;

      if (!isStartingPoint) {
        if (urbanAreas.contains(startingPoint)) {
          if (!disconnectedAreas["الكيلو 21"]!.contains(location)) {
            return false;
          }
        } else {
          if (disconnectedAreas.containsKey(startingPoint)) {
            if (disconnectedAreas[startingPoint]!.contains(location)) {
              return false;
            }
          }
        }

        if (location == startingPoint) return false;
      }

      if (isStartingPoint) {
        if (location == destination) return false;
      }

      return true;
    }).toList();

    String? selected = await showModalBottomSheet<String>(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: ListView(
            children: availableLocations
                .map((place) => ListTile(
                      title: Text(place),
                      onTap: () => Navigator.pop(context, place),
                    ))
                .toList(),
          ),
        );
      },
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
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 25, vertical: 100),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
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
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  onChanged: (value) => userId = value,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      if (userId.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text("Please enter a User ID")),
                        );
                        return;
                      }
                      Navigator.pop(context);
                      _startLiveTracking(userId);
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
    _showWaitingDialog(userId); // Pass userId here
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
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
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: const Icon(Icons.close, color: Colors.black54),
                  ),
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
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
                      child: const Icon(Icons.check,
                          color: Colors.white, size: 40),
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
                              text:
                                  ".\nYou can continue exploring the app while tracking runs in the background."),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: 10,
                right: 10,
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: const Icon(Icons.close, color: Colors.black54),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _stopSharing() {
    setState(() {
      isTracking = false; // Reset tracking status
      trackingUserId = null; // Clear the user ID
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
                    const Text("Your Route",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(Icons.close, color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text("Confirm where you are going",
                    style: TextStyle(fontSize: 14, color: Colors.grey)),
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
                    child: const Text("Confirm Route",
                        style: TextStyle(fontSize: 16, color: Colors.white)),
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
          Text(label,
              style:
                  const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          Text(value,
              style:
                  const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildDashedLine() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        6,
        (index) => Container(
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
        Text(label,
            style: const TextStyle(
                fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
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
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset('assets/map.png', fit: BoxFit.cover),
          ),
          Positioned(
            top: 40,
            left: 20,
            child: GestureDetector(
              onTap: () => _scaffoldKey.currentState?.openDrawer(),
              child: Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: Color(0xFF175579),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: SizedBox(
                    width: 37, // عرض الصورة
                    height: 37, // ارتفاع الصورة
                    child: Image.asset(
                      'assets/img_1.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (isTracking) ...[
            Positioned(
              top: 40,
              left: 78,
              right: 17,
              child: ElevatedButton(
                onPressed: _stopSharing,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF175579),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  padding: EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text(
                  "STOP SHARING",
                  style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ),

            // Add markers for both locations (example positions)
            Positioned(
              left: 100,
              top: 150,
              child: Container(
                width: 113,
                height: 113,
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.2),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.3),
                      blurRadius: 15,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(Icons.location_on, color: Colors.blue, size: 30),
                ),
              ),
            ),

            Positioned(
              left: 250,
              top: 400,
              child: Container(
                width: 113,
                height: 113,
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.2),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withOpacity(0.3),
                      blurRadius: 15,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(Icons.location_on, color: Colors.red, size: 30),
                ),
              ),
            ),
          ],
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
                                  child: ElevatedButton(
                                    onPressed: _showRouteConfirmation,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF175579),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(30),
                                      ),
                                    ),
                                    child: const Text(
                                      "GO",
                                      style: TextStyle(
                                          fontSize: 16, color: Colors.white),
                                    ),
                                  ),
                                ),
                              ],
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
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: Color(0xFF175579)),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Image.asset('assets/salkah.png', width: 250, height: 80),
                const SizedBox(width: 10),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.report),
            title: const Text("Make a complaint"),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MakeComplaintScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.chat),
            title: const Text("Chat Assist"),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ChatAssistScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.person_pin_circle),
            title: const Text("Live Tracking"),
            onTap: () {
              Navigator.pop(context);
              _showLiveTrackingDialog();
            },
          ),
        ],
      ),
    );
  }
}
