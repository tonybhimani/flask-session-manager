import 'package:flutter/material.dart';
import 'package:sessionmanager_app/services/auth_service.dart';

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  void _navigateToLogin([String? errorMessage]) {
    if (mounted) {
      // Navigate to the Login Screen (pass an optional initial error)
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/login', // Use the named route
        (Route<dynamic> route) => false,
        arguments: errorMessage,
      );
    }
  }

  void _navigateToHome() {
    if (mounted) {
      // Navigate to the Home Screen
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/home', // Use the named route
        (Route<dynamic> route) => false,
      );
    }
  }

  Future<void> _checkAuthStatus() async {
    // 1. Check if a refresh token exists
    final refreshToken = await _authService.getRefreshToken();

    if (refreshToken != null) {
      // 2. If refresh token exists, try to refresh the access token
      final result = await _authService.refreshToken();
      if (result['success']) {
        // 3a. If refresh successful, navigate to HomeScreen
        _navigateToHome();
      } else {
        // 3b. If refresh failed (e.g., refresh token expired/revoked), clear tokens
        // AuthService.refreshToken already calls clearTokens on failure.
        // Navigate to Login Screen
        _navigateToLogin(result['message']);
      }
    } else {
      // 4. No refresh token found, navigate directly to Login Screen
      _navigateToLogin();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Display a simple progress indicator
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text('Checking authentication status...'),
          ],
        ),
      ),
    );
  }
}
