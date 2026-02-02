import 'dart:async';
import 'package:flutter/widgets.dart';

/// Lightweight app foreground flag for guarding backend writes.
/// Updated only via [updateState] (called from app lifecycle).
/// True only when [AppLifecycleState.resumed] and past a short delay to avoid DNS/network instability.
class AppLifecycleService {
  static final AppLifecycleService _instance = AppLifecycleService._internal();
  factory AppLifecycleService() => _instance;
  AppLifecycleService._internal();

  bool _isAppInForeground = true;
  Timer? _resumeDelayTimer;

  /// True only when app is in [AppLifecycleState.resumed] and at least
  /// [resumeDelayMs] has passed since resume (to avoid host lookup errors).
  bool get isAppInForeground => _isAppInForeground;

  /// Call only from [WidgetsBindingObserver.didChangeAppLifecycleState].
  void updateState(AppLifecycleState state) {
    _resumeDelayTimer?.cancel();
    _resumeDelayTimer = null;

    switch (state) {
      case AppLifecycleState.resumed:
        _resumeDelayTimer = Timer(const Duration(milliseconds: 750), () {
          _resumeDelayTimer = null;
          _isAppInForeground = true;
        });
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        _isAppInForeground = false;
        break;
    }
  }
}
