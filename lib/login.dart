import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _userIdController = TextEditingController();

  // --- Rate limiting state ---
  static const int loginLimit = 10;
  static const int windowMinutes = 10;
  List<int> _loginAttempts = [];

  @override
  void initState() {
    super.initState();
    _loadUserId();
    _loadLoginAttempts();
  }

  Future<void> _loadUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String userId = prefs.get('user_id')?.toString() ?? '';
    _userIdController.text = userId;
  }

  Future<void> _loadLoginAttempts() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? attempts = prefs.getStringList('login_attempts');
    if (attempts != null) {
      _loginAttempts = attempts.map((e) => int.tryParse(e) ?? 0).toList();
    }
  }

  Future<void> _saveLoginAttempts() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setStringList('login_attempts', _loginAttempts.map((e) => e.toString()).toList());
  }

  bool _isRateLimited() {
    int now = DateTime.now().millisecondsSinceEpoch;
    int windowMs = windowMinutes * 60 * 1000;
    _loginAttempts = _loginAttempts.where((ts) => now - ts < windowMs).toList();
    return _loginAttempts.length >= loginLimit;
  }

  Future<void> _login() async {
    await _loadLoginAttempts();
    if (_isRateLimited()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Too many login attempts. Please try again later.')),
      );
      return;
    }
    int now = DateTime.now().millisecondsSinceEpoch;
    _loginAttempts.add(now);
    await _saveLoginAttempts();

    String userId = _userIdController.text;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_id', userId);
    // Proceed with the login process
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Login'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            TextField(
              controller: _userIdController,
              decoration: InputDecoration(labelText: 'User ID'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _login,
              child: Text('Login'),
            ),
          ],
        ),
      ),
    );
  }
}
