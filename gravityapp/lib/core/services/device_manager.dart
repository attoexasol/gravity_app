import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:get_storage/get_storage.dart';
import 'dart:convert';

/// Device Manager - Handles device identification and tracking
class DeviceManager {
  static final DeviceManager _instance = DeviceManager._internal();
  factory DeviceManager() => _instance;
  DeviceManager._internal();

  static final _storage = GetStorage();
  static const String _deviceIdKey = 'device_id';
  static const String _deviceInfoKey = 'device_info';

  /// Get or generate a unique device ID
  /// This ID persists across app sessions and is used to identify the device
  Future<String> getDeviceId() async {
    String? storedDeviceId = _storage.read(_deviceIdKey);
    
    if (storedDeviceId != null && storedDeviceId.isNotEmpty) {
      return storedDeviceId;
    }

    // Generate a new device ID
    final deviceId = await _generateDeviceId();
    await _storage.write(_deviceIdKey, deviceId);
    
    if (kDebugMode) {
      debugPrint('✅ Generated new device ID: $deviceId');
    }
    
    return deviceId;
  }

  /// Generate a unique device ID based on device characteristics
  Future<String> _generateDeviceId() async {
    try {
      // Create a unique identifier based on platform and other factors
      String identifier = '';
      
      if (kIsWeb) {
        // For web, use a combination of user agent and other browser info
        identifier = 'web_${DateTime.now().millisecondsSinceEpoch}';
      } else if (Platform.isAndroid) {
        // For Android, we'll use a combination of system info
        // In production, you might want to use device_info_plus package
        identifier = 'android_${DateTime.now().millisecondsSinceEpoch}_${_generateRandomString(8)}';
      } else if (Platform.isIOS) {
        // For iOS, similar approach
        identifier = 'ios_${DateTime.now().millisecondsSinceEpoch}_${_generateRandomString(8)}';
      } else {
        identifier = 'unknown_${DateTime.now().millisecondsSinceEpoch}_${_generateRandomString(8)}';
      }
      
      // Create a hash of the identifier for consistency
      // Use a simple hash function that works on all platforms (including web)
      final bytes = utf8.encode(identifier);
      final hash = _simpleHash(bytes);
      return hash;
    } catch (e) {
      debugPrint('❌ Error generating device ID: $e');
      // Fallback to timestamp-based ID
      return 'device_${DateTime.now().millisecondsSinceEpoch}';
    }
  }

  /// Generate a random string
  String _generateRandomString(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = DateTime.now().millisecondsSinceEpoch;
    final buffer = StringBuffer();
    for (int i = 0; i < length; i++) {
      buffer.write(chars[(random + i) % chars.length]);
    }
    return buffer.toString();
  }

  /// Simple hash function that works on all platforms (including web)
  /// Returns a 32-character hex string
  String _simpleHash(List<int> bytes) {
    // Use a combination of multiple hash values to create a longer hash
    int hash1 = 0;
    int hash2 = 5381; // DJB hash initial value
    int hash3 = 0;
    
    for (int i = 0; i < bytes.length; i++) {
      final byte = bytes[i];
      // First hash (simple shift-add)
      hash1 = ((hash1 << 5) - hash1) + byte;
      hash1 = hash1 & hash1; // Convert to 32-bit integer
      
      // Second hash (DJB)
      hash2 = ((hash2 << 5) + hash2) + byte;
      
      // Third hash (FNV-like)
      hash3 ^= byte;
      hash3 = (hash3 * 16777619) & 0xFFFFFFFF;
    }
    
    // Combine hashes and convert to hex
    final combined = '${hash1.toRadixString(16).padLeft(8, '0')}'
                    '${hash2.toRadixString(16).padLeft(8, '0')}'
                    '${hash3.toRadixString(16).padLeft(8, '0')}'
                    '${(hash1 ^ hash2 ^ hash3).toRadixString(16).padLeft(8, '0')}';
    
    return combined.substring(0, 32);
  }

  /// Get device information for API requests
  Future<Map<String, String>> getDeviceInfo() async {
    final deviceId = await getDeviceId();
    
    return {
      'device_id': deviceId,
      'platform': _getPlatform(),
      'app_version': '1.0.0', // You can get this from package_info_plus if needed
    };
  }

  /// Get platform name
  String _getPlatform() {
    if (kIsWeb) {
      return 'web';
    } else if (Platform.isAndroid) {
      return 'android';
    } else if (Platform.isIOS) {
      return 'ios';
    } else if (Platform.isWindows) {
      return 'windows';
    } else if (Platform.isMacOS) {
      return 'macos';
    } else if (Platform.isLinux) {
      return 'linux';
    } else {
      return 'unknown';
    }
  }

  /// Clear device ID (useful for testing or account deletion)
  Future<void> clearDeviceId() async {
    await _storage.remove(_deviceIdKey);
    await _storage.remove(_deviceInfoKey);
    
    if (kDebugMode) {
      debugPrint('✅ Device ID cleared');
    }
  }

  /// Get stored device ID without generating a new one
  String? getStoredDeviceId() {
    return _storage.read(_deviceIdKey);
  }
}