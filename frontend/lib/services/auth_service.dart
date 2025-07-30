import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import 'package:flutter/foundation.dart';
import 'package:sessionmanager_app/utils/constants.dart';

// Import storage interface (in this order)
import 'package:sessionmanager_app/platform/storage/storage_interface.dart'; // Interface for typing
import 'package:sessionmanager_app/platform/storage/storage_factory.dart'; // Factory implementation

// Firebase import
import 'package:firebase_messaging/firebase_messaging.dart';

class AuthService {
  final Uuid _uuid = const Uuid(); // Create a Uuid instance
  static const Duration timeoutDuration = Duration(
    seconds: 10,
  ); // Set a default HTTP timeout

  // --- Singleton Setup ---
  AuthService._internal(); // Private constructor
  static final AuthService _instance =
      AuthService._internal(); // Singleton instance
  factory AuthService() =>
      _instance; // Factory constructor to return the singleton

  // --- Authentication Status Stream ---
  // This stream will notify listeners when the authentication status changes (logged in/out)
  final _authStatusController = StreamController<bool>.broadcast();
  Stream<bool> get authStatusStream => _authStatusController.stream;

  // --- Storage Interface ---
  final StorageInterface _storage = StorageImpl();

  // Firebase Cloud Messaging Token
  String? _fcmToken;

  // --- Firebase ---

  Future<String?> getFCMToken() async {
    if (_fcmToken != null) {
      return _fcmToken;
    }

    try {
      // Request permission for notifications (important for web/iOS, good practice for desktop too)
      NotificationSettings settings = await FirebaseMessaging.instance
          .requestPermission(
            alert: true,
            announcement: false,
            badge: true,
            carPlay: false,
            criticalAlert: false,
            provisional: false,
            sound: true,
          );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        print('User granted permission for notifications');
        if (kIsWeb) {
          _fcmToken = await FirebaseMessaging.instance.getToken(
            vapidKey: kVapidKey,
          );
        } else {
          _fcmToken = await FirebaseMessaging.instance.getToken();
        }
      } else if (settings.authorizationStatus ==
          AuthorizationStatus.provisional) {
        print('User granted provisional permission');
        _fcmToken = await FirebaseMessaging.instance.getToken();
      } else {
        print('User declined or has not accepted permission');
        return null;
      }
      return _fcmToken;
    } catch (e) {
      print('Error getting FCM token: $e');
      return null;
    }
  }

  // --- Login to Navigate Flag ---

  // To combat Isolate Separation issue (non-textbook)
  Future<bool> getNavigateToLoginFlag() async {
    return await _storage.getNavigateToLogin();
  }

  Future<void> setNavigateToLoginFlag(bool value) async {
    await _storage.saveNavigateToLogin(value);
  }

  // --- Token Management ---

  Future<void> _saveAccessToken(String token) async {
    await _storage.saveAccessToken(token);
  }

  Future<String?> getAccessToken() async {
    return await _storage.getAccessToken();
  }

  Future<void> _saveRefreshToken(String token) async {
    await _storage.saveRefreshToken(token);
  }

  Future<String?> getRefreshToken() async {
    return await _storage.getRefreshToken();
  }

  Future<void> clearTokens() async {
    await _storage.clearTokens();
    await setNavigateToLoginFlag(true);
    // Also delete FCM token from Firebase client side to invalidate it
    await FirebaseMessaging.instance.deleteToken();
    _fcmToken = null; // Clear local reference
    _authStatusController.add(
      false,
    ); // Notify listeners that user is logged out
    print('Tokens cleared and auth status updated (false).');
  }

  // Check if refresh token exists locally
  Future<bool> hasValidRefreshTokenLocally() async {
    final refreshToken = await _storage.getRefreshToken();
    return refreshToken != null && refreshToken.isNotEmpty;
  }

  // --- Device ID Management ---

  // Fetches or generates a unique device ID
  Future<String> getDeviceId() async {
    String? deviceId = await _storage.getDeviceId();
    if (deviceId == null) {
      deviceId = _uuid.v4(); // Generate a new UUID
      await _storage.saveDeviceId(deviceId);
    }
    return deviceId;
  }

  // --- Helper for API Response Parsing ---

  Map<String, dynamic> _parseResponse(http.Response response) {
    try {
      if (response.body.isNotEmpty) {
        return jsonDecode(response.body);
      }
      return {'message': 'Empty response from server.'};
    } on FormatException {
      return {'message': 'Received an unexpected response from the server.'};
    } catch (e) {
      return {'message': 'An unexpected error occurred: ${e.toString()}'};
    }
  }

  // --- Authentication Endpoints ---

  Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
    String? firstName,
    String? lastName,
    String? phoneNumber,
  }) async {
    try {
      final deviceId = await getDeviceId(); // Get device ID
      final fcmToken = await getFCMToken(); // Get the FCM token

      final response = await http
          .post(
            Uri.parse('$kApiUrl/register'),
            headers: <String, String>{
              'Content-Type': 'application/json; charset=UTF-8',
            },
            body: jsonEncode(<String, String>{
              'username': username,
              'email': email,
              'password': password,
              'device_id': deviceId, // Send device ID
              if (fcmToken != null) 'fcm_token': fcmToken,
              if (firstName != null && firstName.isNotEmpty)
                'first_name': firstName,
              if (lastName != null && lastName.isNotEmpty)
                'last_name': lastName,
              if (phoneNumber != null && phoneNumber.isNotEmpty)
                'phone_number': phoneNumber,
            }),
          )
          .timeout(timeoutDuration);

      final responseBody = _parseResponse(response);

      // For testing - add a delay for to see the progress spinner
      // await Future.delayed(const Duration(seconds: 2));

      if (response.statusCode == 201) {
        final accessToken = responseBody['access_token'];
        final refreshToken = responseBody['refresh_token']; // Get refresh token
        if (accessToken != null && refreshToken != null) {
          await _saveAccessToken(accessToken);
          await _saveRefreshToken(refreshToken); // Save refresh token
          _authStatusController.add(
            true,
          ); // Notify listeners that user is logged in
          return {
            'success': true,
            'access_token': accessToken,
            'refresh_token': refreshToken,
            'user': responseBody['user'],
          };
        } else {
          return {
            'success': false,
            'message': 'Registration successful but missing token(s).',
          };
        }
      } else if (response.statusCode == 429) {
        return {
          'success': false,
          'message': 'Too many registration attempts. Please try again later.',
        };
      } else {
        return {
          'success': false,
          'message':
              responseBody['message'] ??
              responseBody['msg'] ??
              'Registration failed. Please check your details.',
        };
      }
    } on TimeoutException {
      // This specifically catches the timeout
      return {
        'success': false,
        'message': 'Request timed out. The server took too long to respond.',
      };
    } on SocketException {
      // This catches 'Connection refused', 'No internet connection', etc.
      return {
        'success': false,
        'message':
            'No internet connection or server is unreachable. Please check your network.',
      };
    } on FormatException {
      // Catches malformed JSON responses
      return {
        'success': false,
        'message': 'Invalid response format from server.',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'An unexpected error occurred: ${e.toString()}',
      };
    }
  }

  Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) async {
    try {
      final deviceId = await getDeviceId(); // Get device ID
      final fcmToken = await getFCMToken(); // Get the FCM token

      final response = await http
          .post(
            Uri.parse('$kApiUrl/login'),
            headers: <String, String>{
              'Content-Type': 'application/json; charset=UTF-8',
            },
            body: jsonEncode(<String, String>{
              'username': username,
              'password': password,
              'device_id': deviceId, // Send device ID
              if (fcmToken != null) 'fcm_token': fcmToken,
            }),
          )
          .timeout(timeoutDuration);

      final responseBody = _parseResponse(response);

      // For testing - add a delay for to see the progress spinner
      // await Future.delayed(const Duration(seconds: 2));

      if (response.statusCode == 200) {
        final accessToken = responseBody['access_token'];
        final refreshToken = responseBody['refresh_token']; // Get refresh token
        if (accessToken != null && refreshToken != null) {
          await _saveAccessToken(accessToken);
          await _saveRefreshToken(refreshToken); // Save refresh token
          _authStatusController.add(
            true,
          ); // Notify listeners that user is logged in
          return {
            'success': true,
            'access_token': accessToken,
            'refresh_token': refreshToken,
            'user': responseBody['user'],
          };
        } else {
          return {
            'success': false,
            'message': 'Login successful but missing token(s).',
          };
        }
      } else if (response.statusCode == 429) {
        return {
          'success': false,
          'message': 'Too many login attempts. Please wait a moment.',
        };
      } else {
        return {
          'success': false,
          'message':
              responseBody['message'] ?? responseBody['msg'] ?? 'Login failed',
        };
      }
    } on TimeoutException {
      // This specifically catches the timeout
      return {
        'success': false,
        'message': 'Request timed out. The server took too long to respond.',
      };
    } on SocketException {
      // This catches 'Connection refused', 'No internet connection', etc.
      return {
        'success': false,
        'message':
            'No internet connection or server is unreachable. Please check your network.',
      };
    } on FormatException {
      // Catches malformed JSON responses
      return {
        'success': false,
        'message': 'Invalid response format from server.',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'An unexpected error occurred: ${e.toString()}',
      };
    }
  }

  Future<Map<String, dynamic>> refreshToken() async {
    try {
      final refreshToken = await getRefreshToken();
      if (refreshToken == null) {
        // If refresh token is missing, the user is effectively logged out
        await clearTokens(); // Ensure all tokens are cleared
        return {
          'success': false,
          'message': 'No refresh token available. Please log in again.',
        };
      }

      final response = await http
          .post(
            Uri.parse('$kApiUrl/refresh'),
            headers: <String, String>{
              'Content-Type': 'application/json; charset=UTF-8',
              'Authorization': 'Bearer $refreshToken', // Send refresh token
            },
          )
          .timeout(timeoutDuration);

      final responseBody = _parseResponse(response);

      if (response.statusCode == 200) {
        final newAccessToken = responseBody['access_token'];
        if (newAccessToken != null) {
          await _saveAccessToken(newAccessToken); // Save new access token
          _authStatusController.add(true); // Confirm authenticated status
          return {'success': true, 'access_token': newAccessToken};
        } else {
          return {
            'success': false,
            'message': 'Refresh successful but no new access token.',
          };
        }
      } else {
        // Refresh failed (e.g., refresh token expired or revoked)
        await clearTokens(); // Clear all tokens and notify logout
        return {
          'success': false,
          'message':
              responseBody['message'] ??
              responseBody['msg'] ??
              'Failed to refresh token. Please log in again.',
        };
      }
    } on TimeoutException {
      // This specifically catches the timeout
      return {
        'success': false,
        'message': 'Request timed out. The server took too long to respond.',
      };
    } on SocketException {
      // This catches 'Connection refused', 'No internet connection', etc.
      return {
        'success': false,
        'message':
            'No internet connection or server is unreachable. Please check your network.',
      };
    } on FormatException {
      // Catches malformed JSON responses
      return {
        'success': false,
        'message': 'Invalid response format from server.',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'An unexpected error occurred: ${e.toString()}',
      };
    }
  }

  // --- Protected Resource (with Automatic Token Refresh) ---
  // This is a crucial wrapper to automatically handle expired access tokens
  Future<http.Response> getProtectedResource(String endpoint) async {
    String? token = await getAccessToken();
    if (token == null) {
      await clearTokens(); // Ensure state is consistent if token is unexpectedly missing
      throw Exception(
        'Not authenticated. No access token. Please log in again.',
      );
    }

    http.Response response = await http
        .get(
          Uri.parse('$kApiUrl/$endpoint'),
          headers: <String, String>{
            'Content-Type': 'application/json; charset=UTF-8',
            'Authorization': 'Bearer $token', // Include access token
          },
        )
        .timeout(timeoutDuration);

    // If access token is expired (401 Unauthorized), try to refresh it
    if (response.statusCode == 401) {
      final refreshResult = await refreshToken();
      if (refreshResult['success']) {
        // If refresh successful, retry the original request with the new access token
        token = refreshResult['access_token'];
        if (token == null) {
          await clearTokens(); // Clear tokens if new access token is null after successful refresh
          throw Exception(
            'Failed to get new access token after successful refresh. Please log in again.',
          );
        }
        response = await http
            .get(
              Uri.parse('$kApiUrl/$endpoint'),
              headers: <String, String>{
                'Content-Type': 'application/json; charset=UTF-8',
                'Authorization': 'Bearer $token',
              },
            )
            .timeout(timeoutDuration);
      } else {
        // Refresh failed, so the user needs to log in again
        // clearTokens() already called within refreshToken() on failure
        throw Exception(
          refreshResult['message'] ??
              refreshResult['msg'] ??
              'Session expired. Please log in again.',
        );
      }
    }
    return response;
  }

  // --- Logout Methods ---

  Future<Map<String, dynamic>> logoutCurrentDevice() async {
    try {
      final accessToken = await getAccessToken();
      final deviceId = await getDeviceId();

      if (accessToken == null) {
        await clearTokens(); // Ensure consistent state
        return {'success': false, 'message': 'Not logged in.'};
      }

      final response = await http
          .post(
            Uri.parse('$kApiUrl/logout'),
            headers: <String, String>{
              'Content-Type': 'application/json; charset=UTF-8',
              'Authorization': 'Bearer $accessToken',
            },
            body: jsonEncode(<String, String>{
              'device_id': deviceId, // Send current device_id to revoke
            }),
          )
          .timeout(timeoutDuration);

      final responseBody = _parseResponse(response);

      if (response.statusCode == 200) {
        await clearTokens(); // Clear local tokens and notify logout
        return {'success': true, 'message': responseBody['message']};
      } else {
        return {
          'success': false,
          'message':
              responseBody['message'] ??
              responseBody['msg'] ??
              'Failed to log out this device.',
        };
      }
    } on TimeoutException {
      // This specifically catches the timeout
      return {
        'success': false,
        'message': 'Request timed out. The server took too long to respond.',
      };
    } on SocketException {
      // This catches 'Connection refused', 'No internet connection', etc.
      return {
        'success': false,
        'message':
            'No internet connection or server is unreachable. Please check your network.',
      };
    } on FormatException {
      // Catches malformed JSON responses
      return {
        'success': false,
        'message': 'Invalid response format from server.',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'An unexpected error occurred: ${e.toString()}',
      };
    }
  }

  Future<Map<String, dynamic>> logoutAllDevices() async {
    try {
      final accessToken = await getAccessToken();
      final deviceId = await getDeviceId();

      if (accessToken == null) {
        await clearTokens(); // Ensure consistent state
        return {'success': false, 'message': 'Not logged in.'};
      }

      final response = await http
          .post(
            Uri.parse('$kApiUrl/logout_all_devices'),
            headers: <String, String>{
              'Content-Type': 'application/json; charset=UTF-8',
              'Authorization': 'Bearer $accessToken',
            },
            body: jsonEncode(<String, String>{
              'device_id': deviceId, // Send current device_id to revoke
            }),
          )
          .timeout(timeoutDuration);

      final responseBody = _parseResponse(response);

      if (response.statusCode == 200) {
        await clearTokens(); // Clear local tokens on the initiating device and notify logout
        // Note: Other devices will clear their tokens via FCM notification
        return {'success': true, 'message': responseBody['message']};
      } else {
        return {
          'success': false,
          'message':
              responseBody['message'] ??
              responseBody['msg'] ??
              'Failed to log out all devices.',
        };
      }
    } on TimeoutException {
      // This specifically catches the timeout
      return {
        'success': false,
        'message': 'Request timed out. The server took too long to respond.',
      };
    } on SocketException {
      // This catches 'Connection refused', 'No internet connection', etc.
      return {
        'success': false,
        'message':
            'No internet connection or server is unreachable. Please check your network.',
      };
    } on FormatException {
      // Catches malformed JSON responses
      return {
        'success': false,
        'message': 'Invalid response format from server.',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'An unexpected error occurred: ${e.toString()}',
      };
    }
  }

  // --- Fetch Current User ---

  Future<Map<String, dynamic>> fetchCurrentUser() async {
    try {
      final response = await getProtectedResource('user');
      final responseBody = _parseResponse(response);

      if (response.statusCode == 200) {
        return {'success': true, 'user': responseBody};
      } else {
        // If getProtectedResource threw an exception due to refresh failure, it's caught outside.
        // This is for other non-auth related errors from the /user endpoint.
        return {
          'success': false,
          'message':
              responseBody['message'] ??
              responseBody['msg'] ??
              'Failed to fetch user data.',
        };
      }
    } on TimeoutException {
      // This specifically catches the timeout
      return {
        'success': false,
        'message': 'Request timed out. The server took too long to respond.',
      };
    } on SocketException {
      // This catches 'Connection refused', 'No internet connection', etc.
      return {
        'success': false,
        'message':
            'No internet connection or server is unreachable. Please check your network.',
      };
    } on FormatException {
      // Catches malformed JSON responses
      return {
        'success': false,
        'message': 'Invalid response format from server.',
      };
    } catch (e) {
      // Catch exceptions from getProtectedResource (e.g., "Session expired. Please log in again.")
      // or other network errors.
      return {
        'success': false,
        'message': 'An unexpected error occurred: ${e.toString()}',
      };
    }
  }

  // Dispose method to close the stream when no longer needed
  void dispose() {
    _authStatusController.close();
    print('AuthService StreamController disposed.');
  }
}
