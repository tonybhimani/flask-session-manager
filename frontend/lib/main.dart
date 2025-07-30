import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sessionmanager_app/screens/auth/register_screen.dart';
import 'package:sessionmanager_app/screens/home_screen.dart';
import 'package:sessionmanager_app/screens/profile_screen.dart';
import 'package:sessionmanager_app/services/auth_service.dart';
import 'package:sessionmanager_app/screens/auth/loading_screen.dart';
import 'package:sessionmanager_app/screens/auth/login_screen.dart';

// Firebase imports
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';

// Import Service Worker Listener (in this order)
import 'package:sessionmanager_app/platform/service_worker/service_worker_listener_interface.dart';
import 'package:sessionmanager_app/platform/service_worker/service_worker_listener_factory.dart';

// Define a GlobalKey for the Navigator
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// Declare a global variable using the common implementation class name
late ServiceWorkerListenerInterface _serviceWorkerListener;

// Store the AuthService singleton instance globally in the main Isolate
late AuthService _mainAuthServiceInstance;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize the single instance here
  _mainAuthServiceInstance = AuthService();

  // Instantiate the concrete implementation. The `export` in the factory file
  // ensures the correct `ServiceWorkerListenerImpl` class (web or mobile) is used here.
  _serviceWorkerListener = ServiceWorkerListenerImpl();
  _serviceWorkerListener.initialize(_mainAuthServiceInstance);

  // For handling messages when the app is in the foreground
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print('Got a message while in the foreground');
    print('Message data: ${message.data}');

    // This handles direct FCM foreground messages
    if (message.data['logout_command'] == 'true') {
      print('FCM onMessage: Logout command received. Clearing tokens.');
      _mainAuthServiceInstance.clearTokens(); // Clear tokens via the singleton
    }
  });

  // For handling messages when the app is in the background/terminated (FCM specific)
  // This is the Dart entry point for background FCM messages on mobile
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Pass the singleton instance
  runApp(MyApp(authService: _mainAuthServiceInstance));
}

// Dart VM entry point for handling Firebase messages received in the background
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print('Handling a background message: ${message.messageId}');

  AuthService().clearTokens();
}

class MyApp extends StatefulWidget {
  final AuthService authService; // Receive AuthService instance

  const MyApp({super.key, required this.authService});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  // Add a listener for the auth status stream
  late StreamSubscription<bool> _authStatusSubscription;

  @override
  void initState() {
    super.initState();
    // Add this instance as an observer for app lifecycle changes
    WidgetsBinding.instance.addObserver(this);
    _authStatusSubscription = widget.authService.authStatusStream.listen((
      isAuthenticated,
    ) async {
      if (!isAuthenticated) {
        // Not authenticated
        await _navigateToLoginIfLoggedOut();
      }
    });
  }

  // --- App Lifecycle Listener ---
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Check if the app is coming back to the foreground
    if (state == AppLifecycleState.resumed) {
      print(
        'App has resumed from background. Checking authentication status...',
      );
      // Re-check authentication status when the app comes to foreground
      _checkAuthAndNavigateOnResume();
    }
  }

  // Helper method for foreground FCM logout or general stream changes
  Future<void> _navigateToLoginIfLoggedOut() async {
    if (mounted) {
      // Not an ideal solution. I use storage to combat Isolate Separation.
      // Remembering this flag when the app is in the background is rough.
      // I use device/web storage as a workaround.
      if (await widget.authService.getNavigateToLoginFlag()) {
        navigatorKey.currentState!.pushNamedAndRemoveUntil(
          '/login', // Use the named route
          (Route<dynamic> route) => false,
        );
        // Reset the flag to avoid Login Screen reloads
        await widget.authService.setNavigateToLoginFlag(false);
      }
    }
  }

  // Helper method for app resume from background
  Future<void> _checkAuthAndNavigateOnResume() async {
    final bool isAuthenticated = await widget.authService
        .hasValidRefreshTokenLocally();
    if (!isAuthenticated) {
      print(
        'AuthService detected invalid tokens on app resume. Forcing logout navigation.',
      );
      await _navigateToLoginIfLoggedOut();
    } else {
      print(
        'AuthService detected valid tokens on app resume. Remaining on current screen.',
      );
    }
  }

  @override
  void dispose() {
    // Remove the observer when the state is disposed
    WidgetsBinding.instance.removeObserver(this);
    // Cancel subscription to avoid memory leaks
    _authStatusSubscription.cancel();
    _serviceWorkerListener.dispose(); // Dispose the service worker listener
    widget.authService.dispose(); // Dispose the StreamController
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Session Manager Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      navigatorKey: navigatorKey,
      initialRoute: '/',
      routes: {
        '/': (context) => const LoadingScreen(),
        '/register': (context) => const RegisterScreen(),
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const HomeScreen(),
        '/profile': (context) => const ProfileScreen(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}
