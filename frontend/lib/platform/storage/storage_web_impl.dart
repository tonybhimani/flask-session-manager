import 'package:web/web.dart' as web; // Web-specific import
import 'storage_interface.dart';

class StorageImpl implements StorageInterface {
  @override
  Future<void> saveAccessToken(String token) async {
    web.window.localStorage.setItem('access_token', token);
  }

  @override
  Future<String?> getAccessToken() async {
    return web.window.localStorage.getItem('access_token');
  }

  @override
  Future<void> saveRefreshToken(String token) async {
    web.window.localStorage.setItem('refresh_token', token);
  }

  @override
  Future<String?> getRefreshToken() async {
    return web.window.localStorage.getItem('refresh_token');
  }

  @override
  Future<void> clearTokens() async {
    web.window.localStorage.removeItem('access_token');
    web.window.localStorage.removeItem('refresh_token');
    web.window.localStorage.removeItem('device_id');
  }

  @override
  Future<void> saveDeviceId(String deviceId) async {
    web.window.localStorage.setItem('device_id', deviceId);
  }

  @override
  Future<String?> getDeviceId() async {
    return web.window.localStorage.getItem('device_id');
  }

  @override
  Future<void> saveNavigateToLogin(bool value) async {
    web.window.localStorage.setItem('navigate_to_login', value.toString());
  }

  @override
  Future<bool> getNavigateToLogin() async {
    final String? storedValue = web.window.localStorage.getItem(
      'navigate_to_login',
    );
    return storedValue == 'true';
  }

  @override
  Future<void> clearNavigateToLoginFlag() async {
    web.window.localStorage.removeItem('navigate_to_login');
  }

  @override
  void dispose() {
    // No-op
  }
}
