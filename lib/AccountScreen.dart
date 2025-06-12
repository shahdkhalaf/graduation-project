import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AccountScreen extends StatefulWidget {
  const AccountScreen({Key? key}) : super(key: key);

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  String userId = "";
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
      final prefs = await SharedPreferences.getInstance();
      final savedEmail = prefs.getString('user_email') ?? '';

      if (savedEmail.isEmpty) {
        print('No saved email found!');
        return;
      }

      final response = await http.post(
        Uri.parse('https://graduation-project-production-39f0.up.railway.app/get_user'),
        body: {
          "email": savedEmail,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('Full Response Body: ${response.body}');
        if (data['success'] == true) {
          final user = data['user'];

          setState(() {
            userId = user['user_id']?.toString() ?? '';
            firstName = user['first_name'] ?? '';
            lastName = user['last_name'] ?? '';
            email = user['email'] ?? '';
            age = user['age']?.toString() ?? '';
            gender = user['gendar'] ?? '';
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
        child: SingleChildScrollView(
          child: Card(
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            color: Colors.grey[50],
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Icon(Icons.account_circle, size: 80, color: Color(0xFF175579)),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Text(
                      "$firstName $lastName",
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF175579),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      email,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                  const Divider(height: 32, thickness: 1),
                  _buildAccountRow("User ID", userId),
                  _buildAccountRow("Age", age),
                  _buildAccountRow("Gender", gender),
                  _buildAccountRow("District", district),
                ],
              ),
            ),
          ),
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
              color: Color(0xFF175579),
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
