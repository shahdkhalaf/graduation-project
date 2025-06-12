import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AccountScreen extends StatefulWidget {
  const AccountScreen({Key? key}) : super(key: key);

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  // هنا هتحط متغيرات البيانات
  String firstName = "";
  String lastName = "";
  String email = "";
  String age = "";
  String gender = "";
  String district = "";

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      final response = await http.post(
        Uri.parse('https://graduation-project-production-39f0.up.railway.app/get_user'), // ← حط هنا لينك السيرفر بتاعك
        body: {
          "email": "mohamed.mahmoud.elgazzar@gmail.com", // هنا حط Email اليوزر (ممكن تجيبه من SharedPreferences بعدين)
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final user = data['user'];

          setState(() {
            firstName = user['first_name'] ?? '';
            lastName = user['last_name'] ?? '';
            email = user['email'] ?? '';
            age = user['age']?.toString() ?? '';
            gender = user['gendar'] ?? ''; // خد بالك هنا الكولمن اسمه gendar في db
            district = user['district'] ?? '';
          });
        } else {
          print('API Error: ${data['error'] ?? data['message']}');
        }
      } else {
        print('HTTP Error: ${response.statusCode}');
      }
    } catch (e) {
      print('Exception: $e');
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF175579),
        title: const Text("My Account"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAccountRow("First Name", firstName),
            _buildAccountRow("Last Name", lastName),
            _buildAccountRow("Email", email),
            _buildAccountRow("Age", age),
            _buildAccountRow("Gender", gender),
            _buildAccountRow("District", district),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$label: ",
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}
