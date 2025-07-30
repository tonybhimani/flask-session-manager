import 'package:shared_preferences/shared_preferences.dart';
import 'storage_interface.dart';

class StorageImpl implements StorageInterface {
  @override
  Future<void> saveAccessToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', token);
  }

  @override
  Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  @override
  Future<void> saveRefreshToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('refresh_token', token);
  }

  @override
  Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    // **CRITICAL:** Reload preferences *before* checking their values
    // This ensures you get the most up-to-date data from disk,
    // especially after a background write from another isolate.
    await prefs.reload();
    return prefs.getString('refresh_token');
  }

  @override
  Future<void> clearTokens() async {
    final prefs = await SharedPreferences.getInstance();
    // Defensive reload here to ensure we're clearing the latest state,
    // especially important if this is called in a background isolate
    // that might not have the most recent cache.
    await prefs.reload();
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');
    await prefs.remove('device_id'); // Clear device_id on full logout
  }

  @override
  Future<void> saveDeviceId(String deviceId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('device_id', deviceId);
  }

  @override
  Future<String?> getDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('device_id');
  }

  @override
  Future<void> saveNavigateToLogin(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('navigate_to_login', value);
  }

  @override
  Future<bool> getNavigateToLogin() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    return prefs.getBool('navigate_to_login') ?? false;
  }

  @override
  Future<void> clearNavigateToLoginFlag() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    await prefs.remove('navigate_to_login');
  }

  @override
  dispose() {
    // No-op
  }
}
