import 'package:shared_preferences/shared_preferences.dart';

class UserPreferences {
  static const String _userIdKey = 'user_id';

  Future<void> setUserId(int userId) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    // Store userId as String
    prefs.setString(_userIdKey, userId.toString());
  }

  Future<String> getUserId() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    // Retrieve userId as String
    return prefs.get(_userIdKey)?.toString() ?? '';
  }
}