import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'home.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:webview_flutter/webview_flutter.dart';
class SignUpPage extends StatefulWidget {
  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  int _currentStep = 0;
  final _formKeys = [GlobalKey<FormState>(), GlobalKey<FormState>()];

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  String? _district;
  String? _gender;
  final Completer<WebViewController> controller = Completer<WebViewController>();
  String token = '';
  final List<String> _districts = ['الكيلو 21', 'الهانوفيل', 'البيطاش'];
  final List<String> _genders = ['Male', 'Female', 'Other'];

  final RegExp _emailRegex = RegExp(r"^[a-zA-Z0-9.!#\$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*");

  Future<void> _signUp() async {
    if (_formKeys[1].currentState?.validate() ?? false) {
      String firstName = _firstNameController.text.trim();
      String lastName = _lastNameController.text.trim();
      String email = _emailController.text.trim();
      String password = _passwordController.text.trim();
      String age = _ageController.text.trim();
      String gender = _gender ?? '';
      String district = _district ?? '';

      // --- Get reCAPTCHA token ---
      String recaptchaToken = await getRecaptchaToken(); // Implement this method in your app

      final url = Uri.parse('https://graduation-project-production-39f0.up.railway.app/signup');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $recaptchaToken', // Send reCAPTCHA token here
        },
        body: jsonEncode({
          'first_name': firstName,
          'last_name': lastName,
          'email': email,
          'password': password,
          'age': age,
          'gendar': gender,
          'district': district,
        }),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final userId = data['user']['user_id'].toString();

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_id', userId);
        await prefs.setString('first_name', firstName);
        await prefs.setString('last_name', lastName);
        await prefs.setString('email', email);
        await prefs.setString('age', age);
        await prefs.setString('gender', gender);
        await prefs.setString('district', district);

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      } else {
        final error = jsonDecode(response.body)['error'] ?? 'Signup failed';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      }
    }
  }

  void _onGoogleSignIn() async {
    final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
    if (googleUser != null) {
      _emailController.text = googleUser.email;
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('google_email', googleUser.email);
      setState(() => _currentStep = 1);
    }
  }

  InputDecoration _inputDecoration(String label) => InputDecoration(
    labelText: label,
    labelStyle: const TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w500,
      color: Color(0xFF175579),
    ),
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.grey.shade300),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.grey.shade300),
    ),
    focusedBorder: const OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
      borderSide: BorderSide(color: Color(0xFF175579), width: 2),
    ),
  );


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 62,
            floating: false,
            pinned: true,
            backgroundColor: Colors.white,
            elevation: 1,
            iconTheme: const IconThemeData(color: Colors.black),
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsetsDirectional.only(start: 56, bottom: 16),
              title: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: const Color(0xFF175579),
                    child: Image.asset(
                      'assets/img_1.png', // ← غيّره لاسم اللوجو لو مختلف
                      width: 22,
                      height: 22,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    "Sign Up",
                    style: TextStyle(
                      color: Color(0xFF175579),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _buildStepper(),
            ),
          ),
        ],
      ),
    );

  }
  Widget _buildStepper() {
    return Stepper(
      type: StepperType.vertical,
      currentStep: _currentStep,
      onStepContinue: () {
        if (_currentStep == 0) {
          if (_formKeys[0].currentState?.validate() ?? false) {
            setState(() => _currentStep = 1);
          }
        } else {
          _signUp();
        }
      },
      onStepCancel: () {
        if (_currentStep > 0) setState(() => _currentStep--);
      },
      controlsBuilder: (context, details) => Padding(
        padding: const EdgeInsets.only(top: 16),
        child: Row(
          children: [
            ElevatedButton(
              onPressed: details.onStepContinue,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFFFFF),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text("Continue"),
            ),
            const SizedBox(width: 12),
            TextButton(
              onPressed: details.onStepCancel,
              child: const Text("Cancel"),
            ),
          ],
        ),
      ),
      steps: [
        Step(
          title: const Text('Account Info'),
          isActive: _currentStep >= 0,
          state: _currentStep > 0 ? StepState.complete : StepState.indexed,
          content: Form(
            key: _formKeys[0],
            child: Column(
              children: [
                TextFormField(
                  controller: _firstNameController,
                  decoration: _inputDecoration('First Name'),
                  validator: (value) => value == null || value.isEmpty ? 'First name is required' : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _lastNameController,
                  decoration: _inputDecoration('Last Name'),
                  validator: (value) => value == null || value.isEmpty ? 'Last name is required' : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _emailController,
                  decoration: _inputDecoration('Email'),
                  validator: (value) => value == null || !_emailRegex.hasMatch(value) ? 'Enter a valid email' : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: _inputDecoration('Password'),
                  validator: (value) => value == null || value.length < 6 ? 'Minimum 6 characters' : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: true,
                  decoration: _inputDecoration('Confirm Password'),
                  validator: (value) => value != _passwordController.text ? 'Passwords do not match' : null,
                ),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: _onGoogleSignIn,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset('assets/android_dark_rd_SI@1x.png', height: 48),
                  ),
                ),
              ],
            ),
          ),
        ),
        Step(
          title: const Text('Personal Info'),
          isActive: _currentStep >= 1,
          content: Form(
            key: _formKeys[1],
            child: Column(
              children: [
                DropdownButtonFormField<String>(
                  value: _district,
                  decoration: _inputDecoration("District"),
                  items: _districts.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                  onChanged: (val) => setState(() => _district = val),
                  validator: (value) => value == null || value.isEmpty ? 'District is required' : null,
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: _gender,
                  decoration: _inputDecoration("Gender"),
                  items: _genders.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                  onChanged: (val) => setState(() => _gender = val),
                  validator: (value) => value == null || value.isEmpty ? 'Gender is required' : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _ageController,
                  keyboardType: TextInputType.number,
                  decoration: _inputDecoration("Age"),
                  validator: (value) {
                    final age = int.tryParse(value ?? '');
                    return (age == null || age < 1 || age > 120) ? 'Enter valid age' : null;
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<String> getRecaptchaToken() async {
    // This HTML page loads reCAPTCHA v2 and posts the token back to Flutter

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("Security Check"),
        content: SizedBox(
          height: 150,
          child: Column(
            children: [
              const Text("Please confirm you're not a bot."),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  // Simulate a token fetch (replace with real token logic later)
                  token = "dummy_token_12345";
                  Navigator.of(context).pop();
                },
                child: const Text("I'm not a robot"),
              ),
            ],
          ),
        ),
      ),
    );



    if (token == null) {
      throw Exception('reCAPTCHA verification cancelled or failed.');
    }
    return token!;
  }

}