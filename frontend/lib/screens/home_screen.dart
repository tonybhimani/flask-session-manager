import 'package:flutter/material.dart';
import 'package:sessionmanager_app/services/auth_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthService _authService = AuthService();

  String? _errorMessage;
  bool _isLoading = false;
  Map<String, dynamic>? _currentUserData;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await _authService.fetchCurrentUser();

    if (mounted) {
      setState(() {
        _isLoading = false;
      });

      if (result['success']) {
        _currentUserData = result['user'];
      } else {
        _errorMessage =
            result['message'] ??
            result['msg'] ??
            'Failed to load profile data.';
        // If the session has expired on the backend, navigate to login
        if (result['message'] == 'Session expired. Please log in again.' ||
            result['message'] ==
                'Invalid access token' // Also handle general invalid token for user data
                ) {
          _navigateToLogin();
        }
      }
    }
  }

  void _navigateToLogin() {
    if (mounted) {
      // Navigate to Login Screen
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/login', // Use the named route
        (Route<dynamic> route) => false,
      );
    }
  }

  void _navigateToProfileEdit() {
    if (mounted) {
      // Navigte to Profile Screen (for Log Out All Devices)
      Navigator.of(context).pushNamed(
        '/profile', // Use the named route
      );
    }
  }

  void _logout(BuildContext context) async {
    // Show a snackbar to inform the user
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Logging out...')));

    // Call the logout method from AuthService, which hits the API
    final result = await _authService.logoutCurrentDevice();

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).hideCurrentSnackBar(); // Hide any ongoing snackbar

      if (result['success']) {
        // Only navigate if the logout was successful both locally and on the backend
        _navigateToLogin();
      } else {
        // If backend logout failed, clear local tokens anyway and show an error.
        // This ensures the user is logged out locally even if API call failed.
        await _authService.clearTokens();
        _navigateToLogin(); // Still navigate to login to ensure consistency

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result['message'] ?? 'Logout failed. Please try again.',
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Home"),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            tooltip: 'Edit Profile',
            onPressed: _navigateToProfileEdit,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                'Welcome ${_currentUserData?['username'] ?? 'Guest'}! You are logged in.',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 15),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500.0),
                child: Image.asset(
                  'assets/images/kitty.jpg',
                  fit: BoxFit.fitWidth,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
