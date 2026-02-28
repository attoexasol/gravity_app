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

  /// Get preferences – tries /notification-settings/get then /get_notification_preferences
  Future<NotificationPreferences> getPreferences({required String apiToken}) async {
    var body = <String, dynamic>{'token': apiToken};
    try {
      var res = await _api.post('/notification-settings/get', body: body, requireAuth: false);
      var data = res['data'];
      if (data is Map<String, dynamic>) {
        return _prefsFromData(data);
      }
    } catch (_) {}
    try {
      var res = await _api.post('/get_notification_preferences', body: body, requireAuth: false);
      var data = res['data'];
      if (data is Map<String, dynamic>) return _prefsFromData(data);
    } catch (_) {}
    return NotificationPreferences();
  }

  static NotificationPreferences _prefsFromData(Map<String, dynamic> data) {
    return NotificationPreferences.fromJson(Map<String, dynamic>.from(data));
  }

  /// Update preferences using (B) keys for /update_notification
  Future<NotificationPreferences> updatePreferences({
    required String apiToken,
    bool? is_notification_allowed,
    bool? is_hydration_notify,
    bool? is_meal_notify,
    bool? is_sleep_notify,
    bool? is_excercise_notify,
    bool? is_ai_daily_sumery_notify,
    bool? is_ai_weekly_sumery_notify,
    bool? is_quite_hours_notify,
    String? quiet_start,
    String? quiet_end,
  }) async {
    final body = <String, dynamic>{'token': apiToken};
    if (is_notification_allowed != null) body['is_notification_allowed'] = is_notification_allowed;
    if (is_hydration_notify != null) body['is_hydration_notify'] = is_hydration_notify;
    if (is_meal_notify != null) body['is_meal_notify'] = is_meal_notify;
    if (is_sleep_notify != null) body['is_sleep_notify'] = is_sleep_notify;
    if (is_excercise_notify != null) body['is_excercise_notify'] = is_excercise_notify;
    if (is_ai_daily_sumery_notify != null) body['is_ai_daily_sumery_notify'] = is_ai_daily_sumery_notify;
    if (is_ai_weekly_sumery_notify != null) body['is_ai_weekly_sumery_notify'] = is_ai_weekly_sumery_notify;
    if (is_quite_hours_notify != null) body['is_quite_hours_notify'] = is_quite_hours_notify;
    if (quiet_start != null) body['quiet_start'] = quiet_start;
    if (quiet_end != null) body['quiet_end'] = quiet_end;
    final res = await _api.post('/update_notification', body: body, requireAuth: false);
    final data = res['data'];
    if (data is Map<String, dynamic>) return _prefsFromData(data);
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
    if (data is Map && data['count'] != null) return (data['count'] as num).toInt();
    if (res['count'] != null) return (res['count'] as num).toInt();
    return 0;
  }

  Future<void> markRead({required String apiToken, required int notificationId}) async {
    await _api.post('/notifications/read', body: {'token': apiToken, 'notification_id': notificationId}, requireAuth: false);
  }

  Future<void> markAllRead({required String apiToken}) async {
    await _api.post('/notifications/read-all', body: {'token': apiToken}, requireAuth: false);
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
