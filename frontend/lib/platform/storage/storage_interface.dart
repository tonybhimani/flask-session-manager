// Abstract class for device/web storage
abstract class StorageInterface {
  Future<void> saveAccessToken(String token);
  Future<String?> getAccessToken();
  Future<void> saveRefreshToken(String token);
  Future<String?> getRefreshToken();
  Future<void> clearTokens();
  Future<void> saveDeviceId(String deviceId);
  Future<String?> getDeviceId();
  Future<void> saveNavigateToLogin(bool value);
  Future<bool> getNavigateToLogin();
  Future<void> clearNavigateToLoginFlag();
  void dispose();
}
