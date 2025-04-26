import 'package:flutter/material.dart';

import 'location_permission_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) => const LocationPermissionScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF175579),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/salkah.png',
              width: 260,
              height: 260,
            ),
            const SizedBox(height: 10),
            const Text(
              'Your Smart Public Transportation\n Companion',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'Righteous',
                fontSize: 15.7,
                height: 1.83,
                letterSpacing: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
