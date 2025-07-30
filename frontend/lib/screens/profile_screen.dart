import 'package:flutter/material.dart';
import 'package:sessionmanager_app/services/auth_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();

  void _logOutAllDevices() async {
    // Show a snackbar to inform the user
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Logging out all devices...')));

    // Call the logoutAllDevices method from AuthService
    final result = await _authService.logoutAllDevices();

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).hideCurrentSnackBar(); // Hide any ongoing snackbar

      if (result['success']) {
        // If logout was successful on the backend and locally, navigate to login
        _navigateToLogin();
      } else {
        // If backend logout failed, still clear local tokens for safety
        await _authService.clearTokens();
        _navigateToLogin(); // Still navigate to login to ensure consistency

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result['message'] ??
                  result['msg'] ??
                  'Failed to log out all devices. Please try again.',
            ),
          ),
        );
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

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                "Profile editing is not available in this demo. The primary function " +
                    "of this screen is to allow you to remotely log out all active " +
                    "sessions across your devices.",
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: _logOutAllDevices,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 18,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 5,
                  textStyle: const TextStyle(fontSize: 22),
                ),
                child: const Text('Log Out All Devices'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
