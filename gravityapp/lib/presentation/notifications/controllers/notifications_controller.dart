import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/preferences_service.dart';
import '../../../data/model/notification_preferences.dart';
import '../../../data/remote/notifications_api.dart';

enum NotificationType {
  message,
  payment,
  streak,
  offer,
  social,
  reminder,
  update,
}

class NotificationItem {
  NotificationItem({
    required this.id,
    required this.title,
    required this.description,
    required this.timeText,
    required this.type,
    required this.isUnread,
    required this.isHighPriority,
    this.actionText,
    this.notificationId,
  });

  final String id;
  final String title;
  final String description;
  final String timeText;
  final NotificationType type;
  bool isUnread;
  final bool isHighPriority;
  final String? actionText;
  /// Backend notification id for mark-read API
  final int? notificationId;

  NotificationItem copyWith({
    String? id,
    String? title,
    String? description,
    String? timeText,
    NotificationType? type,
    bool? isUnread,
    bool? isHighPriority,
    String? actionText,
    int? notificationId,
  }) {
    return NotificationItem(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      timeText: timeText ?? this.timeText,
      type: type ?? this.type,
      isUnread: isUnread ?? this.isUnread,
      isHighPriority: isHighPriority ?? this.isHighPriority,
      actionText: actionText ?? this.actionText,
      notificationId: notificationId ?? this.notificationId,
    );
  }
}

class NotificationsController extends GetxController {
  final NotificationsApi _api = NotificationsApi();

  final RxList<NotificationItem> notifications = <NotificationItem>[].obs;
  final RxInt unreadCount = 0.obs;
  final RxBool loading = false.obs;
  final RxBool loadingMore = false.obs;
  final Rx<String?> error = Rx<String?>(null);
  final Rx<NotificationPreferences?> preferences = Rx<NotificationPreferences?>(null);

  static const int _perPage = 20;
  int _currentPage = 1;
  bool _hasMore = true;

  @override
  void onInit() {
    super.onInit();
    loadAll();
  }

  String? _getApiToken() {
    return PreferencesService.getAuthToken();
  }

  Future<void> loadAll() async {
    final token = _getApiToken();
    if (token == null || token.isEmpty) {
      if (kDebugMode) debugPrint('Notifications: no api token, skipping load');
      error.value = 'Please sign in to load notifications.';
      return;
    }
    error.value = null;
    loading.value = true;
    try {
      final count = await _api.unreadCount(apiToken: token);
      unreadCount.value = count;
      _currentPage = 1;
      _hasMore = true;
      final page = await _api.listNotifications(apiToken: token, page: 1, perPage: _perPage);
      notifications.assignAll(_mapApiItems(page.items));
      _hasMore = page.hasMore;
      _syncUnreadCountFromList();
    } on ApiException catch (e) {
      if (kDebugMode) debugPrint('Notifications API Error: ${e.message}');
      error.value = e.message;
      notifications.clear();
    } catch (e) {
      if (kDebugMode) debugPrint('Notifications load error: $e');
      error.value = 'Failed to load notifications.';
      notifications.clear();
    } finally {
      loading.value = false;
    }
  }

  /// Ensures unreadCount is at least the number of unread items in the loaded list.
  /// Fixes the case where the API returns 0 but the list contains unread notifications.
  void _syncUnreadCountFromList() {
    final fromList = notifications.where((n) => n.isUnread).length;
    if (fromList > unreadCount.value) {
      unreadCount.value = fromList;
    }
  }

  Future<void> refreshList() async {
    final token = _getApiToken();
    if (token == null || token.isEmpty) return;
    error.value = null;
    loading.value = true;
    try {
      final count = await _api.unreadCount(apiToken: token);
      unreadCount.value = count;
      _currentPage = 1;
      _hasMore = true;
      final page = await _api.listNotifications(apiToken: token, page: 1, perPage: _perPage);
      notifications.assignAll(_mapApiItems(page.items));
      _hasMore = page.hasMore;
      _syncUnreadCountFromList();
    } on ApiException catch (e) {
      error.value = e.message;
    } catch (e) {
      error.value = 'Failed to refresh.';
    } finally {
      loading.value = false;
    }
  }

  Future<void> loadMore() async {
    final token = _getApiToken();
    if (token == null || token.isEmpty || !_hasMore || loadingMore.value) return;
    loadingMore.value = true;
    try {
      _currentPage += 1;
      final page = await _api.listNotifications(apiToken: token, page: _currentPage, perPage: _perPage);
      notifications.addAll(_mapApiItems(page.items));
      _hasMore = page.hasMore;
      _syncUnreadCountFromList();
    } catch (e) {
      _currentPage -= 1;
      if (kDebugMode) debugPrint('Notifications loadMore error: $e');
    } finally {
      loadingMore.value = false;
    }
  }

  List<NotificationItem> _mapApiItems(List<NotificationApiItem> items) {
    return items.map((e) {
      return NotificationItem(
        id: e.id.toString(),
        title: e.title,
        description: e.body ?? '',
        timeText: _timeAgo(e.createdAt),
        type: _parseType(e.type),
        isUnread: e.isRead == 0,
        isHighPriority: false,
        notificationId: e.id,
      );
    }).toList();
  }

  static String _timeAgo(String? createdAt) {
    if (createdAt == null || createdAt.isEmpty) return '';
    try {
      final dt = DateTime.tryParse(createdAt);
      if (dt == null) return createdAt;
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      if (diff.inDays == 1) return 'Yesterday';
      if (diff.inDays < 7) return '${diff.inDays}d ago';
      return createdAt;
    } catch (_) {
      return createdAt;
    }
  }

  static NotificationType _parseType(String? type) {
    if (type == null) return NotificationType.message;
    final t = type.toLowerCase();
    if (t.contains('payment')) return NotificationType.payment;
    if (t.contains('streak')) return NotificationType.streak;
    if (t.contains('offer')) return NotificationType.offer;
    if (t.contains('social')) return NotificationType.social;
    if (t.contains('reminder')) return NotificationType.reminder;
    if (t.contains('update')) return NotificationType.update;
    return NotificationType.message;
  }

  Future<void> onMarkAllRead() async {
    final token = _getApiToken();
    if (token == null || token.isEmpty) return;
    try {
      await _api.markAllRead(apiToken: token);
      unreadCount.value = 0;
      for (int i = 0; i < notifications.length; i++) {
        if (notifications[i].isUnread) {
          notifications[i] = notifications[i].copyWith(isUnread: false);
        }
      }
      notifications.refresh();
    } catch (e) {
      if (kDebugMode) debugPrint('Mark all read error: $e');
    }
  }

  /// Clears all notifications from the list and resets unread count.
  /// Calls the backend clear endpoint if available; otherwise only clears locally.
  /// After clear, the list is empty until the user refreshes or reopens (if backend did not clear).
  Future<void> onClearAll() async {
    final token = _getApiToken();
    if (token == null || token.isEmpty) {
      notifications.clear();
      unreadCount.value = 0;
      return;
    }
    try {
      await _api.clearAll(apiToken: token);
    } catch (e) {
      if (kDebugMode) debugPrint('Clear notifications API error: $e');
      // Still clear locally so the inbox appears empty; next refresh will re-fetch from server.
    }
    notifications.clear();
    unreadCount.value = 0;
  }

  Future<void> onOpenNotification(NotificationItem item) async {
    final token = _getApiToken();
    final id = item.notificationId ?? int.tryParse(item.id);
    if (id != null && token != null && token.isNotEmpty) {
      try {
        await _api.markRead(apiToken: token, notificationId: id);
        if (unreadCount.value > 0) unreadCount.value -= 1;
        final index = notifications.indexWhere((n) => n.id == item.id);
        if (index >= 0 && notifications[index].isUnread) {
          notifications[index] = notifications[index].copyWith(isUnread: false);
          notifications.refresh();
        }
      } catch (e) {
        if (kDebugMode) debugPrint('Mark read error: $e');
      }
    }
    // Navigate to detail if needed; for now just mark read (existing design)
  }

  void markAsRead(String id) {
    try {
      final item = notifications.firstWhere((n) => n.id == id);
      onOpenNotification(item);
    } catch (_) {}
  }

  Future<void> updatePreferenceToggle(String key, bool value) async {
    final token = _getApiToken();
    if (token == null || token.isEmpty) return;
    try {
      final current = preferences.value ?? NotificationPreferences();
      NotificationPreferences updated;
      switch (key) {
        case 'enabled':
          updated = current.copyWith(enabled: value);
          break;
        case 'hydration':
          updated = current.copyWith(hydration: value);
          break;
        case 'meals':
          updated = current.copyWith(meals: value);
          break;
        case 'sleep':
          updated = current.copyWith(sleep: value);
          break;
        case 'exercise':
          updated = current.copyWith(exercise: value);
          break;
        case 'dailySummary':
          updated = current.copyWith(dailySummary: value);
          break;
        case 'weeklySummary':
          updated = current.copyWith(weeklySummary: value);
          break;
        case 'quietHoursEnabled':
          updated = current.copyWith(quietHoursEnabled: value);
          break;
        default:
          updated = current;
      }
      final prefs = await _api.updatePreferences(
        apiToken: token,
        prefs: updated,
      );
      preferences.value = prefs;
    } catch (e) {
      if (kDebugMode) debugPrint('Update preference error: $e');
    }
  }

  /// Debug: send FCM token to server and print result.
  Future<void> debugSyncFcmToken(String fcmToken) async {
    final token = _getApiToken();
    if (token == null || token.isEmpty) {
      if (kDebugMode) debugPrint('debugSyncFcmToken: no api token');
      return;
    }
    try {
      await _api.storeDeviceToken(apiToken: token, fcmToken: fcmToken);
      if (kDebugMode) debugPrint('debugSyncFcmToken: success');
    } catch (e) {
      if (kDebugMode) debugPrint('debugSyncFcmToken: failure $e');
    }
  }

  void markAllAsRead() => onMarkAllRead();

  void onBack() {
    Get.back();
  }
}
