import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';

class SignUpPage extends StatefulWidget {
  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  int _currentStep = 0;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();

  String? _district;
  String? _gender;

  final List<String> _districts = [
    'District 1',
    'District 2',
    'District 3',
    'District 4',
    'District 5'
  ];

  final List<String> _genders = ['Male', 'Female', 'Other'];

  final RegExp _emailRegex = RegExp(
    r"^[a-zA-Z0-9.!#\$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*\$",
  );

  Future<void> _signUp() async {
    if (_formKey.currentState?.validate() ?? false) {
      String email = _emailController.text.trim();
      String password = _passwordController.text.trim();
      String district = _district ?? '';
      String gender = _gender ?? '';
      String age = _ageController.text.trim();

      int userId = await _registerUser(email, password, district, gender, age);
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_id', userId.toString());

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Registration successful!')),
      );
    }
  }

  Future<int> _registerUser(String email, String password, String district, String gender, String age) async {
    // TODO: Send this data to your backend API
    return Future.delayed(Duration(seconds: 2), () => 1);
  }

  void _onGoogleSignIn() async {
    final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
    if (googleUser != null) {
      // Proceed to step 2 (collect personal data)
      setState(() {
        _emailController.text = googleUser.email;
        _currentStep = 1;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Sign Up')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Stepper(
            type: StepperType.vertical,
            currentStep: _currentStep,
            onStepContinue: () {
              if (_currentStep == 0) {
                if (_formKey.currentState?.validate() ?? false) {
                  setState(() => _currentStep = 1);
                }
              } else {
                _signUp();
              }
            },
            onStepCancel: () {
              if (_currentStep > 0) setState(() => _currentStep--);
            },
            steps: [
              Step(
                title: Text('Account Info'),
                isActive: _currentStep >= 0,
                state: _currentStep > 0 ? StepState.complete : StepState.indexed,
                content: Column(
                  children: [
                    TextFormField(
                      controller: _emailController,
                      decoration: InputDecoration(labelText: 'Email'),
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Email is required';
                        if (!_emailRegex.hasMatch(value)) return 'Enter a valid email address';
                        return null;
                      },
                    ),
                    TextFormField(
                      controller: _passwordController,
                      decoration: InputDecoration(labelText: 'Password'),
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Password is required';
                        if (value.length < 6) return 'Password must be at least 6 characters';
                        return null;
                      },
                    ),
                    TextFormField(
                      controller: _confirmPasswordController,
                      decoration: InputDecoration(labelText: 'Confirm Password'),
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Please confirm your password';
                        if (value != _passwordController.text) return 'Passwords do not match';
                        return null;
                      },
                    ),
                    SizedBox(height: 16),
                    ElevatedButton.icon(
                      icon: Icon(Icons.login),
                      label: Text('Sign Up with Google'),
                      onPressed: _onGoogleSignIn,
                    ),
                  ],
                ),
              ),
              Step(
                title: Text('Personal Info'),
                isActive: _currentStep >= 1,
                state: StepState.indexed,
                content: Column(
                  children: [
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(labelText: 'District'),
                      value: _district,
                      items: _districts.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                      onChanged: (value) => setState(() => _district = value),
                      validator: (value) => (value == null || value.isEmpty) ? 'District is required' : null,
                    ),
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(labelText: 'Gender'),
                      value: _gender,
                      items: _genders.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                      onChanged: (value) => setState(() => _gender = value),
                      validator: (value) => (value == null || value.isEmpty) ? 'Gender is required' : null,
                    ),
                    TextFormField(
                      controller: _ageController,
                      decoration: InputDecoration(labelText: 'Age'),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Age is required';
                        final age = int.tryParse(value);
                        if (age == null || age < 1 || age > 120) return 'Enter a valid age';
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
