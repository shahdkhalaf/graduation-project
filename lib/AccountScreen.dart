import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({Key? key}) : super(key: key);

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen>
    with TickerProviderStateMixin {
  String userId = "";
  String firstName = "";
  String lastName = "";
  String email = "";
  String age = "";
  String gender = "";
  String district = "";
  bool isLoading = true;
  String errorMessage = "";

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadUserData();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    setState(() {
      isLoading = true;
      errorMessage = "";
    });

    try {
      final prefs = await SharedPreferences.getInstance();

      // Load from SharedPreferences and ensure all are String
      final savedUserId = prefs.get('user_id')?.toString() ?? '';
      final savedFirstName = prefs.getString('first_name') ?? '';
      final savedLastName = prefs.getString('last_name') ?? '';
      final savedEmail = prefs.getString('email') ?? '';
      final savedAge = prefs.get('age')?.toString() ?? '';
      final savedGender = prefs.getString('gender') ?? '';
      final savedDistrict = prefs.getString('district') ?? '';

      setState(() {
        userId = savedUserId;
        firstName = savedFirstName;
        lastName = savedLastName;
        email = savedEmail;
        age = savedAge;
        gender = savedGender;
        district = savedDistrict;
        isLoading = false;
      });

      // Start animations after loading data
      _animationController.forward();

      // If we don't have essential data, show appropriate message
      if (firstName.isEmpty && lastName.isEmpty) {
        setState(() {
          errorMessage = "No user data found. Please sign in again.";
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = "Error loading user data: $e";
        isLoading = false;
      });
    }
  }

  Future<void> _refreshUserData() async {
    setState(() {
      isLoading = true;
      errorMessage = "";
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final savedEmail = prefs.getString('email') ??
          ''; // Changed from 'user_email' to 'email'

      if (savedEmail.isEmpty) {
        setState(() {
          errorMessage = "No email found. Please sign in again.";
          isLoading = false;
        });
        return;
      }

      final response = await http.post(
        Uri.parse(
            'https://graduation-project-production-39f0.up.railway.app/get_user'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": savedEmail}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['success'] == true) {
          final user = data['user'];

          // Update SharedPreferences with fresh data
          await prefs.setString('user_id', user['user_id']?.toString() ?? '');
          await prefs.setString('first_name', user['first_name'] ?? '');
          await prefs.setString('last_name', user['last_name'] ?? '');
          await prefs.setString('email', user['email'] ?? ''); // Save email too
          await prefs.setString('age', user['age']?.toString() ?? '');
          await prefs.setString(
              'gender', user['gendar'] ?? ''); // Note: API has typo 'gendar'
          await prefs.setString('district', user['district'] ?? '');

          setState(() {
            userId = user['user_id']?.toString() ?? '';
            firstName = user['first_name'] ?? '';
            lastName = user['last_name'] ?? '';
            email = user['email'] ?? '';
            age = user['age']?.toString() ?? '';
            gender = user['gendar'] ?? '';
            district = user['district'] ?? '';
            isLoading = false;
            errorMessage = "";
          });

          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text('Profile updated successfully!'),
                ],
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          );
        } else {
          setState(() {
            errorMessage =
                data['error'] ?? data['message'] ?? 'Failed to refresh data';
            isLoading = false;
          });
        }
      } else {
        setState(() {
          errorMessage = "Server error: ${response.statusCode}";
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = "Network error: $e";
        isLoading = false;
      });
    }
  }

  Future<void> _signOut() async {
    final shouldSignOut = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.logout, color: Colors.red),
            SizedBox(width: 8),
            Text('Sign Out'),
          ],
        ),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel',
                style: TextStyle(color: Color(0xFF175579))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child:
                const Text('Sign Out', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (shouldSignOut == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      Navigator.of(context)
          .pushNamedAndRemoveUntil('/signin', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: CustomScrollView(
        slivers: [
          // Modern App Bar
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
                      'assets/img_1.png', // ← حط هنا اللوجو اللي عندك
                      width: 22,
                      height: 22,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "My Account",
                    style: const TextStyle(
                      color: Color(0xFF175579),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh, color: Color(0xFF175579)),
                onPressed: _refreshUserData,
                tooltip: 'Refresh Profile',
              ),
            ],
          ),


          // Content
          SliverToBoxAdapter(
            child: isLoading
                ? _buildLoadingView()
                : errorMessage.isNotEmpty
                    ? _buildErrorView()
                    : _buildProfileView(),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingView() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF175579)),
              strokeWidth: 3,
            ),
            SizedBox(height: 24),
            Text(
              "Loading your profile...",
              style: TextStyle(
                color: Color(0xFF175579),
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red.shade400,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                "Oops! Something went wrong",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                errorMessage,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: _loadUserData,
                    icon: const Icon(Icons.refresh),
                    label: const Text("Try Again"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF175579),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  OutlinedButton.icon(
                    onPressed: _signOut,
                    icon: const Icon(Icons.logout),
                    label: const Text("Sign Out"),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileView() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Profile Header Card
              _buildProfileHeader(),
              const SizedBox(height: 24),

              // Personal Information Card
              _buildPersonalInfoCard(),
              const SizedBox(height: 24),

              // Quick Actions Card
              _buildQuickActionsCard(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(6.0),
      child: Column(
        children: [
          Hero(
            tag: 'profile_avatar',
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: const Color(0xFF175579).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.account_circle,
                size: 80,
                color: Color(0xFF175579),
              ),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            "$firstName $lastName",
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF175579),
              letterSpacing: 0.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            email,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfoCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF175579).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.person_outline,
                    color: Color(0xFF175579),
                    size: 18,
                  ),
                ),
                const SizedBox(width: 16),
                const Text(
                  "Personal Information",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF175579),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildInfoItem(Icons.badge_outlined, "User ID",
                userId.isEmpty ? "Not available" : userId),
            _buildInfoItem(Icons.cake_outlined, "Age",
                age.isEmpty ? "Not specified" : "$age years"),
            _buildInfoItem(
              gender.toLowerCase() == 'male' ? Icons.male : Icons.female,
              "Gender",
              gender.isEmpty ? "Not specified" : gender,
            ),
            _buildInfoItem(
              Icons.location_on_outlined,
              "District",
              district.isEmpty ? "Not specified" : district,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF175579).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.settings_outlined,
                    color: Color(0xFF175579),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                const Text(
                  "Quick Actions",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF175579),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildActionButton(
              Icons.refresh_outlined,
              "Refresh Profile",
              "Update your information from server",
              _refreshUserData,
              const Color(0xFF175579),
            ),
            const SizedBox(height: 12),
            _buildActionButton(
              Icons.logout_outlined,
              "Sign Out",
              "Sign out of your account",
              _signOut,
              Colors.red,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF175579).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF175579),
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String title, String subtitle,
      VoidCallback onTap, Color color) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade200),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }
}

