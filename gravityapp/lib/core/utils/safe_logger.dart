import 'package:flutter/foundation.dart';

/// Safe logging helper that wraps debugPrint behind kDebugMode
/// Only logs in debug mode to avoid performance impact in production
class SafeLogger {
  /// Log a message (only in debug mode)
  static void log(String message) {
    if (kDebugMode) {
      debugPrint(message);
    }
  }

  /// Log an error message (only in debug mode)
  static void error(String message) {
    if (kDebugMode) {
      debugPrint('❌ $message');
    }
  }

  /// Log a warning message (only in debug mode)
  static void warning(String message) {
    if (kDebugMode) {
      debugPrint('⚠️ $message');
    }
  }

  /// Log an info message (only in debug mode)
  static void info(String message) {
    if (kDebugMode) {
      debugPrint('ℹ️ $message');
    }
  }

  /// Log a success message (only in debug mode)
  static void success(String message) {
    if (kDebugMode) {
      debugPrint('✅ $message');
    }
  }

  /// Log a debug message (only in debug mode)
  static void debug(String message) {
    if (kDebugMode) {
      debugPrint('🔍 $message');
    }
  }
}

