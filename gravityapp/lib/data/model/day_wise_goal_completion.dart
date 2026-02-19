/// Day-wise Goal Completion Model
/// Represents goal completion status for a single day
class DayWiseGoalCompletion {
  final String date;
  final GoalStatus nutration;
  final GoalStatus hydration;
  final GoalStatus sleep;
  final GoalStatus steps;
  final GoalStatus weight;
  final GoalStatus fasting;

  DayWiseGoalCompletion({
    required this.date,
    required this.nutration,
    required this.hydration,
    required this.sleep,
    required this.steps,
    required this.weight,
    required this.fasting,
  });

  factory DayWiseGoalCompletion.fromJson(Map<String, dynamic> json) {
    return DayWiseGoalCompletion(
      date: json['date'] as String? ?? '',
      nutration: GoalStatus.fromJson(json['nutration']),
      hydration: GoalStatus.fromJson(json['hydration']),
      sleep: GoalStatus.fromJson(json['sleep']),
      steps: GoalStatus.fromJson(json['steps']),
      weight: GoalStatus.fromJson(json['weight']),
      fasting: GoalStatus.fromJson(json['fasting']),
    );
  }
}

/// Goal Status Model
/// Represents the status of a specific goal for a day
class GoalStatus {
  final String status; // "completed", "partial", "missed"
  /// Optional numeric value (e.g. weight in kg when goal is weight)
  final double? value;

  GoalStatus({
    required this.status,
    this.value,
  });

  factory GoalStatus.fromJson(dynamic json) {
    if (json == null) {
      return GoalStatus(status: 'missed');
    }
    
    if (json is Map<String, dynamic>) {
      double? v;
      final valueDynamic = json['value'];
      if (valueDynamic != null) {
        if (valueDynamic is num) v = valueDynamic.toDouble();
        else if (valueDynamic is String) v = double.tryParse(valueDynamic);
      }
      return GoalStatus(
        status: json['status'] as String? ?? 'missed',
        value: v,
      );
    }
    
    if (json is String) {
      return GoalStatus(status: json);
    }
    
    return GoalStatus(status: 'missed');
  }
}
