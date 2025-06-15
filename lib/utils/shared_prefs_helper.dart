import 'package:shared_preferences/shared_preferences.dart';

class SharedPrefsHelper {
  // ...existing code...

  static Future<String> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.get('user_id')?.toString() ?? '';
  }

  // ...existing code...
}