/// Day Activity API response model
/// API: POST /user/day-activity
/// Response data: weight, steps, sleep, hydration, nutration (per-pillar goal/actual/status)
class DayActivityData {
  final String date;
  final DayActivityPillar? weight;
  final DayActivityPillar? steps;
  final DayActivityPillar? sleep;
  final DayActivityPillar? hydration;
  final DayActivityNutration? nutration;

  DayActivityData({
    required this.date,
    this.weight,
    this.steps,
    this.sleep,
    this.hydration,
    this.nutration,
  });

  factory DayActivityData.fromJson(Map<String, dynamic> json) {
    return DayActivityData(
      date: json['date'] is String ? json['date'] as String : '',
      weight: json['weight'] is Map<String, dynamic>
          ? DayActivityPillar.fromJson(json['weight'] as Map<String, dynamic>)
          : null,
      steps: json['steps'] is Map<String, dynamic>
          ? DayActivityPillar.fromJson(json['steps'] as Map<String, dynamic>)
          : null,
      sleep: json['sleep'] is Map<String, dynamic>
          ? DayActivityPillar.fromJson(json['sleep'] as Map<String, dynamic>)
          : null,
      hydration: json['hydration'] is Map<String, dynamic>
          ? DayActivityPillar.fromJson(json['hydration'] as Map<String, dynamic>)
          : null,
      nutration: json['nutration'] is Map<String, dynamic>
          ? DayActivityNutration.fromJson(
              json['nutration'] as Map<String, dynamic>)
          : null,
    );
  }
}

class DayActivityPillar {
  final String? goal;
  final dynamic actual; // number or string
  final String status; // "completed" | "partial" | "missed" etc.

  DayActivityPillar({
    this.goal,
    this.actual,
    this.status = 'none',
  });

  factory DayActivityPillar.fromJson(Map<String, dynamic> json) {
    return DayActivityPillar(
      goal: json['goal']?.toString(),
      actual: json['actual'],
      status: json['status'] is String ? json['status'] as String : 'none',
    );
  }

  String get actualString =>
      actual == null ? '' : actual is num ? actual.toString() : actual.toString();
}

class DayActivityNutration {
  final dynamic actual; // e.g. 550 (calories)
  final String status;

  DayActivityNutration({
    this.actual,
    this.status = 'none',
  });

  factory DayActivityNutration.fromJson(Map<String, dynamic> json) {
    return DayActivityNutration(
      actual: json['actual'],
      status: json['status'] is String ? json['status'] as String : 'none',
    );
  }

  String get actualString =>
      actual == null ? '' : actual is num ? actual.toString() : actual.toString();
}
