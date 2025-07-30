import 'dart:io' show Platform; // Import only the Platform class from dart:io
import 'package:flutter/foundation.dart'; // For kIsWeb and defaultTargetPlatform

// Base URL for the backend server
String get kBaseUrl {
  if (kIsWeb) {
    // Web applications need the actual hostname or domain
    // For development on web, you might use 'localhost' if your server is also running on localhost,
    // or your specific development server IP/domain.
    // If Flask is running on 127.0.0.1:5000 and you access the Flutter web app from localhost:XXXX,
    // then 'http://localhost:5000' is generally correct.
    return 'http://localhost:5000';
  } else if (Platform.isAndroid) {
    // Android emulator (10.0.2.2) and potentially some physical devices (adb reverse)
    // If you plan to test on physical Android devices WITHOUT adb reverse,
    // you'll need your actual local network IP (e.g., 'http://192.168.1.X:5000')
    // and might add another check or a configuration file for physical devices.
    return 'http://10.0.2.2:5000';
  } else if (Platform.isIOS) {
    // iOS simulator uses 'localhost' as it behaves similarly to a real machine
    // in network terms relative to your host.
    return 'http://localhost:5000';
  } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    // Desktop platforms can directly access your machine's localhost
    return 'http://127.0.0.1:5000';
  }
  // Fallback for unknown platforms (shouldn't happen for Flutter's supported platforms)
  return 'http://localhost:5000';
}

// API endpoint prefix
const String kApiPrefix = '/api';

// Full API URL combining base and prefix
String get kApiUrl =>
    '$kBaseUrl$kApiPrefix'; // Changed to getter since kBaseUrl is now a getter

// Firebase Vapid Key (Get from Firebase Console)
const String kVapidKey = 'REPLACE WITH YOUR VAPID KEY';
