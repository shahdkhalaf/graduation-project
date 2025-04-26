// lib/api/auth_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthService {
  // ◾ Replace with your Railway‐deployed backend’s base URL:
  static const String _baseUrl = 'https://your-railway-url.up.railway.app';

  /// Sign up a new user. Returns null on success, or an error message.
  static Future<String?> signUp({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String age,
    required String gender,
    required String district,
  }) async {
    final uri = Uri.parse("$_baseUrl/signup");
    final payload = {
      "first_name": firstName,
      "last_name": lastName,
      "email": email,
      "password": password,
      "age": age,
      "gendar": gender,
      "district": district,
    };

    try {
      final response = await http.post(
        uri,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(payload),
      );

      if (response.statusCode == 201) {
        // user created
        return null;
      } else {
        final data = jsonDecode(response.body);
        return data["error"] ?? "Signup failed (status ${response.statusCode})";
      }
    } catch (e) {
      return "Network error: $e";
    }
  }

  /// Sign in an existing user. Returns a map { "token": ..., "user": {...} } or null on failure.
  static Future<Map<String, dynamic>?> signIn({
    required String email,
    required String password,
  }) async {
    final uri = Uri.parse("$_baseUrl/signin");
    final payload = {
      "email": email,
      "password": password,
    };

    try {
      final response = await http.post(
        uri,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data; // data contains "token" and "user" fields
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }
}
