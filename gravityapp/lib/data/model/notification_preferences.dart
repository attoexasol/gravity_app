/// Notification Preferences Model
class NotificationPreferences {
  final bool enabled;
  final bool hydration;
  final bool meals;
  final bool sleep;
  final bool exercise;
  final bool dailySummary;
  final bool weeklySummary;
  final bool quietHoursEnabled;
  final String quietHoursStart;
  final String quietHoursEnd;

  NotificationPreferences({
    this.enabled = false,
    this.hydration = true,
    this.meals = true,
    this.sleep = true,
    this.exercise = true,
    this.dailySummary = true,
    this.weeklySummary = true,
    this.quietHoursEnabled = false,
    this.quietHoursStart = '10:00 PM',
    this.quietHoursEnd = '8:00 AM',
  });

  NotificationPreferences copyWith({
    bool? enabled,
    bool? hydration,
    bool? meals,
    bool? sleep,
    bool? exercise,
    bool? dailySummary,
    bool? weeklySummary,
    bool? quietHoursEnabled,
    String? quietHoursStart,
    String? quietHoursEnd,
  }) {
    return NotificationPreferences(
      enabled: enabled ?? this.enabled,
      hydration: hydration ?? this.hydration,
      meals: meals ?? this.meals,
      sleep: sleep ?? this.sleep,
      exercise: exercise ?? this.exercise,
      dailySummary: dailySummary ?? this.dailySummary,
      weeklySummary: weeklySummary ?? this.weeklySummary,
      quietHoursEnabled: quietHoursEnabled ?? this.quietHoursEnabled,
      quietHoursStart: quietHoursStart ?? this.quietHoursStart,
      quietHoursEnd: quietHoursEnd ?? this.quietHoursEnd,
    );
  }

  /// From backend (B) keys: is_notification_allowed, is_hydration_notify, etc.
  factory NotificationPreferences.fromJson(Map<String, dynamic> json) {
    return NotificationPreferences(
      enabled: _readBool(json, 'is_notification_allowed') ?? false,
      hydration: _readBool(json, 'is_hydration_notify') ?? true,
      meals: _readBool(json, 'is_meal_notify') ?? true,
      sleep: _readBool(json, 'is_sleep_notify') ?? true,
      exercise: _readBool(json, 'is_excercise_notify') ?? true,
      dailySummary: _readBool(json, 'is_ai_daily_sumery_notify') ?? true,
      weeklySummary: _readBool(json, 'is_ai_weekly_sumery_notify') ?? true,
      quietHoursEnabled: _readBool(json, 'is_quite_hours_notify') ?? false,
      quietHoursStart: json['quiet_start'] as String? ?? '10:00 PM',
      quietHoursEnd: json['quiet_end'] as String? ?? '8:00 AM',
    );
  }

  static bool? _readBool(Map<String, dynamic> json, String key) {
    final v = json[key];
    if (v == null) return null;
    if (v is bool) return v;
    if (v is int) return v == 1;
    if (v is String) return v.toLowerCase() == 'true' || v == '1';
    return null;
  }

  /// To backend (B) keys for /update_notification
  Map<String, dynamic> toJson() {
    return {
      'is_notification_allowed': enabled,
      'is_hydration_notify': hydration,
      'is_meal_notify': meals,
      'is_sleep_notify': sleep,
      'is_excercise_notify': exercise,
      'is_ai_daily_sumery_notify': dailySummary,
      'is_ai_weekly_sumery_notify': weeklySummary,
      'is_quite_hours_notify': quietHoursEnabled,
      if (quietHoursStart.isNotEmpty) 'quiet_start': quietHoursStart,
      if (quietHoursEnd.isNotEmpty) 'quiet_end': quietHoursEnd,
    };
  }
}
