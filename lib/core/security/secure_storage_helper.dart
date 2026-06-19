import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';

/// Secure Storage Helper for managing sensitive data like JWT tokens.
/// Uses flutter_secure_storage for encrypted storage on the device.
class SecureStorageHelper {
  static const String _jwtTokenKey = 'jwt_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _tokenExpiryKey = 'token_expiry';

  static final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      keyCipherAlgorithm: KeyCipherAlgorithm.RSA_ECB_OAEPwithSHA_256andMGF1Padding,
      storageCipherAlgorithm: StorageCipherAlgorithm.AES_GCM_NoPadding,
    ),
  );

  /// Save JWT access token to secure storage.
  /// Never store plain employee IDs - only store the JWT token.
  static Future<void> saveJwtToken(String token) async {
    try {
      await _storage.write(key: _jwtTokenKey, value: token);
    } catch (e) {
      throw Exception('Failed to save JWT token: $e');
    }
  }

  /// Retrieve JWT access token from secure storage.
  static Future<String?> getJwtToken() async {
    try {
      return await _storage.read(key: _jwtTokenKey);
    } catch (e) {
      throw Exception('Failed to retrieve JWT token: $e');
    }
  }

  /// Save refresh token to secure storage.
  static Future<void> saveRefreshToken(String token) async {
    try {
      await _storage.write(key: _refreshTokenKey, value: token);
    } catch (e) {
      throw Exception('Failed to save refresh token: $e');
    }
  }

  /// Retrieve refresh token from secure storage.
  static Future<String?> getRefreshToken() async {
    try {
      return await _storage.read(key: _refreshTokenKey);
    } catch (e) {
      throw Exception('Failed to retrieve refresh token: $e');
    }
  }

  /// Save token expiration time.
  static Future<void> saveTokenExpiry(DateTime expiry) async {
    try {
      await _storage.write(
        key: _tokenExpiryKey,
        value: expiry.toIso8601String(),
      );
    } catch (e) {
      throw Exception('Failed to save token expiry: $e');
    }
  }

  /// Get token expiration time.
  static Future<DateTime?> getTokenExpiry() async {
    try {
      final expiryString = await _storage.read(key: _tokenExpiryKey);
      if (expiryString == null) return null;
      return DateTime.parse(expiryString);
    } catch (e) {
      throw Exception('Failed to retrieve token expiry: $e');
    }
  }

  /// Check if token is expired.
  static Future<bool> isTokenExpired() async {
    try {
      final expiry = await getTokenExpiry();
      if (expiry == null) return true;
      return DateTime.now().isAfter(expiry);
    } catch (e) {
      return true;
    }
  }

  /// Clear all authentication tokens on logout.
  /// This is critical for security - never leave tokens in storage.
  static Future<void> clearAllTokens() async {
    try {
      await _storage.delete(key: _jwtTokenKey);
      await _storage.delete(key: _refreshTokenKey);
      await _storage.delete(key: _tokenExpiryKey);
    } catch (e) {
      throw Exception('Failed to clear tokens: $e');
    }
  }

  /// Check if user is authenticated (has valid token).
  static Future<bool> isAuthenticated() async {
    try {
      final token = await getJwtToken();
      if (token == null) return false;
      return !(await isTokenExpired());
    } catch (e) {
      return false;
    }
  }
}
