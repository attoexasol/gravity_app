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
}
