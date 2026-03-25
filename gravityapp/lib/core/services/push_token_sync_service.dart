import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../../app/routes/app_routes.dart';
import '../../data/repositories/notifications_repository.dart';
import '../../presentation/main_layout/controllers/main_layout_controller.dart';
import 'device_manager.dart';
import 'preferences_service.dart';

const String _kFocusPostId = 'focus_post_id';

/// Handles FCM token upload to Laravel, foreground local notifications, and tap → Notifications screen.
class PushTokenSyncService {
  static final PushTokenSyncService _instance = PushTokenSyncService._internal();
  factory PushTokenSyncService() => _instance;
  PushTokenSyncService._internal();

  final NotificationsRepository _api = NotificationsRepository();
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  static const String _channelId = 'gravity_push';
  static const String _channelName = 'Gravity Notifications';

  bool _initialized = false;

  /// Call once at app startup (e.g. from main.dart after runApp).
  Future<void> init() async {
    if (_initialized) return;
    try {
      final androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      final initSettings = InitializationSettings(android: androidSettings);
      await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );
      if (Platform.isAndroid) {
        await _localNotifications
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
            ?.createNotificationChannel(AndroidNotificationChannel(
          _channelId,
          _channelName,
          importance: Importance.high,
          playSound: true,
        ));
      }

      FirebaseMessaging.instance.onTokenRefresh.listen(_uploadFcmToken);
      FirebaseMessaging.onMessage.listen(_onForegroundMessage);
      FirebaseMessaging.onMessageOpenedApp.listen(_onMessageOpenedApp);
      final initial = await FirebaseMessaging.instance.getInitialMessage();
      if (initial != null) _handlePushTap(initial.data);
      _initialized = true;
      if (kDebugMode) debugPrint('PushTokenSyncService: init done');
    } catch (e) {
      if (kDebugMode) debugPrint('PushTokenSyncService init error: $e');
    }
  }

  void _onNotificationTapped(NotificationResponse response) {
    if (response.payload != null && response.payload!.isNotEmpty) {
      Get.toNamed(AppRoutes.notifications);
    } else {
      Get.toNamed(AppRoutes.notifications);
    }
  }

  Future<void> _onForegroundMessage(RemoteMessage message) async {
    final title = message.notification?.title ?? message.data['title'] as String? ?? 'Notification';
    final body = message.notification?.body ?? message.data['body'] as String? ?? '';
    final androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      importance: Importance.high,
      priority: Priority.high,
    );
    final details = NotificationDetails(android: androidDetails);
    await _localNotifications.show(
      message.hashCode % 0x7FFFFFFF,
      title,
      body,
      details,
      payload: message.data['notification_id']?.toString(),
    );
  }

  void _onMessageOpenedApp(RemoteMessage message) {
    _handlePushTap(message.data);
  }

  /// Routes push tap: post_reaction -> Community + focus post; else -> Notifications.
  void _handlePushTap(Map<String, dynamic> data) {
    final type = (data['type'] ?? '').toString();
    if (type == 'post_reaction') {
      final postId = (data['post_id'] ?? '').toString();
      if (postId.isNotEmpty) _openCommunityAndFocusPost(postId);
      final notificationId = (data['notification_id'] ?? '').toString();
      if (notificationId.isNotEmpty) _markNotificationRead(notificationId);
      return;
    }
    try {
      Get.toNamed(AppRoutes.notifications);
    } catch (_) {}
  }

  void _openCommunityAndFocusPost(String postId) {
    try {
      final storage = GetStorage();
      storage.write(_kFocusPostId, postId);
      Get.offAllNamed(AppRoutes.home);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        try {
          if (Get.isRegistered<MainLayoutController>()) {
            Get.find<MainLayoutController>().navigateToTab(1);
          }
        } catch (_) {}
      });
    } catch (_) {}
  }

  Future<void> _markNotificationRead(String notificationIdStr) async {
    final id = int.tryParse(notificationIdStr);
    if (id == null) return;
    final apiToken = PreferencesService.getAuthToken();
    if (apiToken == null || apiToken.isEmpty) return;
    try {
      await _api.markRead(apiToken: apiToken, notificationId: id);
    } catch (_) {}
  }

  Future<void> _uploadFcmToken(String fcmToken) async {
    final apiToken = PreferencesService.getAuthToken();
    if (apiToken == null || apiToken.isEmpty) return;
    try {
      String? deviceId;
      try {
        deviceId = await DeviceManager().getDeviceId();
      } catch (_) {}
      await _api.storeDeviceToken(
        apiToken: apiToken,
        fcmToken: fcmToken,
        platform: Platform.isAndroid ? 'android' : (Platform.isIOS ? 'ios' : 'unknown'),
        deviceId: deviceId,
      );
      if (kDebugMode) debugPrint('FCM token uploaded (onRefresh)');
    } catch (e) {
      if (kDebugMode) debugPrint('FCM token upload error: $e');
    }
  }

  /// Call after successful login. Requests permission, gets FCM token, uploads to backend.
  Future<void> syncTokenAfterLogin() async {
    try {
      final settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        if (kDebugMode) debugPrint('PushTokenSyncService: notification permission denied');
        return;
      }
      final fcmToken = await FirebaseMessaging.instance.getToken();
      if (fcmToken == null || fcmToken.isEmpty) return;
      await _uploadFcmToken(fcmToken);
      if (kDebugMode) debugPrint('PushTokenSyncService: token synced after login');
    } catch (e) {
      if (kDebugMode) debugPrint('PushTokenSyncService syncTokenAfterLogin error: $e');
    }
  }
}
