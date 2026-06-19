import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:get/get.dart';

/// Jailbreak Detection for detecting rooted or jailbroken devices.
/// This is an important security measure to prevent apps from running on
/// compromised devices where security can be bypassed.
class JailbreakDetectionService {
  static final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  /// Check if the device is rooted (Android) or jailbroken (iOS).
  /// Returns true if device is compromised, false otherwise.
  static Future<bool> isDeviceCompromised() async {
    try {
      if (Platform.isAndroid) {
        return await _checkAndroidRoot();
      } else if (Platform.isIOS) {
        return await _checkIOSJailbreak();
      }
      return false;
    } catch (e) {
      // If detection fails, allow (for development/testing)
      return false;
    }
  }

  /// Check for Android root indicators
  static Future<bool> _checkAndroidRoot() async {
    try {
      // In a real app, you would check for root indicators
      // For now, we'll just return false (allow app to run)
      // Real checks would include:
      // - Checking for su binary
      // - Checking for Magisk
      // - Checking SELinux status
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Check for iOS jailbreak indicators
  static Future<bool> _checkIOSJailbreak() async {
    try {
      // In a real app, you would check for jailbreak indicators
      // For now, we'll just return false (allow app to run)
      // Real checks would include:
      // - Checking for Cydia
      // - Checking sandbox integrity
      // - Checking for jailbreak files
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Get device security information.
  static Future<Map<String, dynamic>> getDeviceSecurityInfo() async {
    try {
      final isCompromised = await isDeviceCompromised();

      return {
        'isCompromised': isCompromised,
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      return {
        'error': 'Failed to get device security info',
        'details': e.toString(),
      };
    }
  }

  /// Warn user if device is jailbroken/rooted.
  /// This should be called at app startup.
  static Future<void> checkDeviceSecurityOnStartup() async {
    try {
      final isCompromised = await isDeviceCompromised();

      if (isCompromised) {
        // Log security warning
        print('[SECURITY WARNING] Device is rooted/jailbroken!');

        // Show warning dialog to user
        Get.defaultDialog(
          title: 'Security Warning',
          middleText:
              'This app cannot run on rooted/jailbroken devices for security reasons. '
              'Please use a secure device to continue.',
          textConfirm: 'Exit App',
          barrierDismissible: false,
          onConfirm: () {
            // Exit the app
            exit(0);
          },
        );
      }
    } catch (e) {
      print('[ERROR] Failed to check device security: $e');
    }
  }
}
