import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SignUpPage extends StatefulWidget {
  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  String? _username;
  String? _password;

  Future<void> _signUp() async {
    final FormState? form = _formKey.currentState;
    if (form != null && form.validate()) {
      form.save();
      // Assuming userId is obtained after successful sign up
      int userId = await _registerUser(_username ?? '', _password ?? '');
      SharedPreferences prefs = await SharedPreferences.getInstance();
      // Ensure user_id is stored as a String
      await prefs.setString('user_id', userId.toString());
      // Navigate to the next page or show a success message
    }
  }

  Future<int> _registerUser(String username, String password) async {
    // Dummy user registration logic
    return Future.delayed(Duration(seconds: 2), () => 1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sign Up'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: <Widget>[
              TextFormField(
                decoration: InputDecoration(labelText: 'Username'),
                validator: (String? value) {
                  if (value == null || value.isEmpty) {
                    return 'Username is required';
                  }
                  return null;
                },
                onSaved: (String? value) {
                  _username = value;
                },
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Password'),
                obscureText: true,
                validator: (String? value) {
                  if (value == null || value.isEmpty) {
                    return 'Password is required';
                  }
                  return null;
                },
                onSaved: (String? value) {
                  _password = value;
                },
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _signUp,
                child: Text('Sign Up'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}