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
    this.quietHoursStart = '22:00',
    this.quietHoursEnd = '08:00',
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

  factory NotificationPreferences.fromJson(Map<String, dynamic> json) {
    return NotificationPreferences(
      enabled: _readBool(json, 'all_enabled') ?? false,
      hydration: _readBool(json, 'hydration_enabled') ?? true,
      meals: _readBool(json, 'meal_enabled') ?? true,
      sleep: _readBool(json, 'sleep_enabled') ?? true,
      exercise: _readBool(json, 'exercise_enabled') ?? true,
      dailySummary: _readBool(json, 'daily_summary_enabled') ?? true,
      weeklySummary: _readBool(json, 'weekly_summary_enabled') ?? true,
      quietHoursEnabled: _readBool(json, 'quiet_hours_enabled') ?? false,
      quietHoursStart: json['quiet_start'] as String? ?? '22:00',
      quietHoursEnd: json['quiet_end'] as String? ?? '08:00',
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

  Map<String, dynamic> toJson() {
    return {
      'all_enabled': enabled ? 1 : 0,
      'hydration_enabled': hydration ? 1 : 0,
      'meal_enabled': meals ? 1 : 0,
      'sleep_enabled': sleep ? 1 : 0,
      'exercise_enabled': exercise ? 1 : 0,
      'daily_summary_enabled': dailySummary ? 1 : 0,
      'weekly_summary_enabled': weeklySummary ? 1 : 0,
      'quiet_hours_enabled': quietHoursEnabled ? 1 : 0,
      if (_isValidHi(quietHoursStart)) 'quiet_start': quietHoursStart,
      if (_isValidHi(quietHoursEnd)) 'quiet_end': quietHoursEnd,
    };
  }

  /// Checks whether [time] matches the H:i format expected by the backend (e.g. "22:00", "8:00").
  static bool _isValidHi(String time) {
    return RegExp(r'^\d{1,2}:\d{2}$').hasMatch(time);
  }
}
