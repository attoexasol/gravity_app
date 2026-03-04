import '../../core/services/api_service.dart';
import '../model/notification_preferences.dart';
import '../model/notification_log.dart';

/// API response item for a single notification (inbox)
class NotificationApiItem {
  final int id;
  final String title;
  final String? body;
  final String? type;
  final int isRead;
  final String? createdAt;

  NotificationApiItem({
    required this.id,
    required this.title,
    this.body,
    this.type,
    this.isRead = 0,
    this.createdAt,
  });

  factory NotificationApiItem.fromJson(Map<String, dynamic> json) {
    return NotificationApiItem(
      id: (json['id'] is int) ? json['id'] as int : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      title: json['title'] as String? ?? json['message'] as String? ?? '',
      body: json['body'] as String? ?? json['description'] as String? ?? json['data'] as String?,
      type: json['type'] as String?,
      isRead: _readInt(json, 'is_read') ?? _readInt(json, 'read') ?? 0,
      createdAt: json['created_at'] as String? ?? json['createdAt'] as String?,
    );
  }
}

int? _readInt(Map<String, dynamic> json, String key) {
  final v = json[key];
  if (v == null) return null;
  if (v is int) return v;
  if (v is bool) return v ? 1 : 0;
  if (v is String) return int.tryParse(v);
  return null;
}

class PaginatedNotifications {
  final List<NotificationApiItem> items;
  final int currentPage;
  final int? total;
  final bool hasMore;

  PaginatedNotifications({
    required this.items,
    this.currentPage = 1,
    this.total,
    this.hasMore = false,
  });
}

class PaginatedNotificationLogs {
  final List<NotificationLog> items;
  final int currentPage;
  final bool hasMore;

  PaginatedNotificationLogs({
    required this.items,
    this.currentPage = 1,
    this.hasMore = false,
  });
}

/// Notifications API – all requests send [token] in body (custom auth).
class NotificationsApi {
  final ApiService _api = ApiService();

  Future<void> storeDeviceToken({
    required String apiToken,
    required String fcmToken,
    String platform = 'android',
    String? deviceId,
    String? appVersion,
  }) async {
    final body = <String, dynamic>{
      'token': apiToken,
      'fcm_token': fcmToken,
      'platform': platform,
    };
    if (deviceId != null && deviceId.isNotEmpty) body['device_id'] = deviceId;
    if (appVersion != null && appVersion.isNotEmpty) body['app_version'] = appVersion;
    await _api.post('/device-token/store', body: body, requireAuth: false);
  }

  /// Get notification preferences from /notification-settings/get
  Future<NotificationPreferences> getPreferences({required String apiToken}) async {
    final body = <String, dynamic>{'token': apiToken};
    try {
      final res = await _api.post('/notification-settings/get', body: body, requireAuth: false);
      final data = res['data'];
      if (data is Map<String, dynamic>) {
        return NotificationPreferences.fromJson(Map<String, dynamic>.from(data));
      }
    } catch (_) {}
    return NotificationPreferences();
  }

  /// Update all notification preferences via /notification-settings/update.
  /// Sends the full current state so the backend stays in sync.
  Future<NotificationPreferences> updatePreferences({
    required String apiToken,
    required NotificationPreferences prefs,
  }) async {
    final body = <String, dynamic>{
      'token': apiToken,
      ...prefs.toJson(),
    };
    final res = await _api.post('/notification-settings/update', body: body, requireAuth: false);
    final data = res['data'];
    if (data is Map<String, dynamic>) {
      return NotificationPreferences.fromJson(Map<String, dynamic>.from(data));
    }
    return NotificationPreferences();
  }

  Future<PaginatedNotifications> listNotifications({
    required String apiToken,
    int page = 1,
    int perPage = 20,
  }) async {
    final res = await _api.post('/notifications/list', body: {
      'token': apiToken,
      'page': page,
      'per_page': perPage,
    }, requireAuth: false);
    final list = _extractList(res);
    final items = list.map((e) => NotificationApiItem.fromJson(e)).toList();
    final currentPage = res['data'] is Map ? (res['data'] as Map)['current_page'] as int? ?? page : page;
    final total = res['data'] is Map ? (res['data'] as Map)['total'] as int? : null;
    final hasMore = total != null ? (currentPage * perPage < total) : (items.length >= perPage);
    return PaginatedNotifications(items: items, currentPage: currentPage, total: total, hasMore: hasMore);
  }

  Future<int> unreadCount({required String apiToken}) async {
    final res = await _api.post('/notifications/unread-count', body: {'token': apiToken}, requireAuth: false);
    final data = res['data'];
    if (data is int) return data;
    if (data is Map<String, dynamic>) {
      final map = data;
      if (map['count'] != null) return (map['count'] as num).toInt();
      if (map['unread_count'] != null) return (map['unread_count'] as num).toInt();
      if (map['unreadCount'] != null) return (map['unreadCount'] as num).toInt();
      if (map['total'] != null) return (map['total'] as num).toInt();
    }
    if (res['count'] != null) return (res['count'] as num).toInt();
    if (res['unread_count'] != null) return (res['unread_count'] as num).toInt();
    if (res['unreadCount'] != null) return (res['unreadCount'] as num).toInt();
    return 0;
  }

  Future<void> markRead({required String apiToken, required int notificationId}) async {
    await _api.post('/notifications/read', body: {'token': apiToken, 'notification_id': notificationId}, requireAuth: false);
  }

  Future<void> markAllRead({required String apiToken}) async {
    await _api.post('/notifications/read-all', body: {'token': apiToken}, requireAuth: false);
  }

  /// Clear/delete all notifications for the user. Backend may expose
  /// POST /notifications/clear or similar. If the endpoint does not exist,
  /// the app still clears the list locally when the user taps Clear.
  Future<void> clearAll({required String apiToken}) async {
    await _api.post('/notifications/clear', body: {'token': apiToken}, requireAuth: false);
  }

  Future<PaginatedNotificationLogs> listLogs({
    required String apiToken,
    int page = 1,
    int perPage = 20,
  }) async {
    final res = await _api.post('/notification-logs/list', body: {
      'token': apiToken,
      'page': page,
      'per_page': perPage,
    }, requireAuth: false);
    final list = _extractList(res);
    final items = list.map((e) => NotificationLog.fromJson(Map<String, dynamic>.from(e))).toList();
    final currentPage = res['data'] is Map ? (res['data'] as Map)['current_page'] as int? ?? page : page;
    final total = (res['data'] is Map ? (res['data'] as Map)['total'] as int? : null) ?? 0;
    final hasMore = total > 0 ? (currentPage * perPage < total) : (items.length >= perPage);
    return PaginatedNotificationLogs(items: items, currentPage: currentPage, hasMore: hasMore);
  }

  static List<Map<String, dynamic>> _extractList(Map<String, dynamic> res) {
    final data = res['data'];
    if (data is List) return data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    if (data is Map) {
      final notifs = data['notifications'];
      if (notifs is List) return notifs.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      final list = data['data'];
      if (list is List) return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }
    return [];
  }
}
