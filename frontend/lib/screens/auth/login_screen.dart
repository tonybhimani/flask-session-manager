import 'package:flutter/material.dart';
import 'package:sessionmanager_app/services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  final String? initialErrorMessage;

  const LoginScreen({super.key, this.initialErrorMessage});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>(); // Global key for form validation
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  String? _errorMessage;
  bool _isLoading = false;

  final FocusNode _usernameFocus = FocusNode(); // Focus node for username field
  final FocusNode _passwordFocus = FocusNode(); // Focus node for password field

  @override
  void initState() {
    super.initState();
    // Display any initial error message passed from LoadingScreen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Retrieve the argument passed to this route
      final args = ModalRoute.of(context)?.settings.arguments;
      // Check if the argument is a non-empty String
      if (args is String && args.isNotEmpty) {
        _showSnackBar(args, isError: true);
      }
    });
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _usernameFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  void _showSnackBar(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade700,
        duration: const Duration(seconds: 4), // Adjust duration
        behavior: SnackBarBehavior.floating, // Often looks better
        margin: const EdgeInsets.all(10), // For floating behavior
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _login() async {
    if (!_formKey.currentState!.validate()) {
      // Validate form fields first
      return; // If validation fails, do not proceed
    }

    if (mounted) {
      setState(() {
        _errorMessage = null;
        _isLoading = true; // Show loading indicator
      });
    }

    final username = _usernameController.text;
    final password = _passwordController.text;

    final result = await _authService.login(
      username: username,
      password: password,
    );

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }

    if (result['success']) {
      if (mounted) {
        // Navigate to the Home Screen
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/home', // Use the named route
          (Route<dynamic> route) => false,
        );
      }
    } else {
      if (mounted) {
        setState(() {
          _errorMessage = result['message'];
        });
      }
    }
  }

  void _navigateToRegister() {
    // Navigate to the Register Screen
    Navigator.of(context).pushNamed(
      '/register', // Use the named route
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Welcome to Session Manager Demo!',
                  style: Theme.of(context).textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                TextFormField(
                  controller: _usernameController,
                  focusNode: _usernameFocus,
                  decoration: const InputDecoration(
                    labelText: 'Username or Email',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your username or email';
                    }
                    return null;
                  },
                  textInputAction: TextInputAction.next,
                  onFieldSubmitted: (value) {
                    _usernameFocus.unfocus();
                    FocusScope.of(context).requestFocus(
                      _passwordFocus,
                    ); // Move focus to password field.
                  },
                ),
                const SizedBox(height: 15),
                TextFormField(
                  controller: _passwordController,
                  focusNode: _passwordFocus,
                  obscureText: true, // Hide password input.
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    return null;
                  },
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (value) {
                    _login(); // Attempt login on pressing "done" key.
                  },
                ),
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 10.0),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ),
                const SizedBox(height: 20),
                _isLoading
                    ? const CircularProgressIndicator() // Show loading indicator
                    : ElevatedButton(
                        onPressed: _login,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 40,
                            vertical: 15,
                          ),
                          textStyle: const TextStyle(fontSize: 18),
                        ),
                        child: const Text('Login'),
                      ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: _navigateToRegister,
                  child: const Text('Don\'t have an account? Register here.'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
