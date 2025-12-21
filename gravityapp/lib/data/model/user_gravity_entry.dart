/// User Gravity Entry Model
/// Represents a single day's health metrics entry
class UserGravityEntry {
  final int? id;
  final double? weight; // in kg
  final int? steps;
  final double? sleepHours;
  final double? hydrationLiters; // parsed from "3L" format
  final String? nutration; // nutrition (note: backend uses "nutration")
  final String? dataSource; // "google_fit", "apple_health", "manual"
  final String date; // yyyy-MM-dd format
  final DateTime? createdAt;
  final DateTime? updatedAt;

  UserGravityEntry({
    this.id,
    this.weight,
    this.steps,
    this.sleepHours,
    this.hydrationLiters,
    this.nutration,
    this.dataSource,
    required this.date,
    this.createdAt,
    this.updatedAt,
  });

  /// Parse from JSON response
  factory UserGravityEntry.fromJson(Map<String, dynamic> json) {
    // Parse steps - might come as string or int
    int? parsedSteps;
    if (json['steps'] != null) {
      if (json['steps'] is String) {
        parsedSteps = int.tryParse(json['steps'] as String);
      } else if (json['steps'] is int) {
        parsedSteps = json['steps'] as int;
      } else if (json['steps'] is num) {
        parsedSteps = (json['steps'] as num).toInt();
      }
    }

    // Parse sleep_hours - might come as string or number
    double? parsedSleepHours;
    if (json['sleep_hours'] != null) {
      if (json['sleep_hours'] is String) {
        parsedSleepHours = double.tryParse(json['sleep_hours'] as String);
      } else if (json['sleep_hours'] is num) {
        parsedSleepHours = (json['sleep_hours'] as num).toDouble();
      }
    }

    // Parse hydration - might be "3L" or "3.5L" or just a number
    double? parsedHydration;
    if (json['hydration'] != null) {
      final hydrationStr = json['hydration'].toString();
      // Remove "L" suffix and parse
      final numericStr = hydrationStr.replaceAll(RegExp(r'[Ll]'), '').trim();
      parsedHydration = double.tryParse(numericStr);
    }

    // Parse weight
    double? parsedWeight;
    if (json['weight'] != null) {
      if (json['weight'] is num) {
        parsedWeight = (json['weight'] as num).toDouble();
      } else if (json['weight'] is String) {
        parsedWeight = double.tryParse(json['weight'] as String);
      }
    }

    // Parse dates
    DateTime? parsedCreatedAt;
    if (json['created_at'] != null) {
      try {
        parsedCreatedAt = DateTime.parse(json['created_at'].toString());
      } catch (e) {
        // Ignore parse errors
      }
    }

    DateTime? parsedUpdatedAt;
    if (json['updated_at'] != null) {
      try {
        parsedUpdatedAt = DateTime.parse(json['updated_at'].toString());
      } catch (e) {
        // Ignore parse errors
      }
    }

    return UserGravityEntry(
      id: json['id'] != null ? (json['id'] is int ? json['id'] : int.tryParse(json['id'].toString())) : null,
      weight: parsedWeight,
      steps: parsedSteps,
      sleepHours: parsedSleepHours,
      hydrationLiters: parsedHydration,
      nutration: json['nutration']?.toString(),
      dataSource: json['data_source']?.toString() ?? json['dataSource']?.toString(),
      date: json['date']?.toString() ?? '',
      createdAt: parsedCreatedAt,
      updatedAt: parsedUpdatedAt,
    );
  }

  /// Convert to JSON for API requests
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (weight != null) 'weight': weight,
      if (steps != null) 'steps': steps.toString(),
      if (sleepHours != null) 'sleep_hours': sleepHours.toString(),
      if (hydrationLiters != null) 'hydration': '${hydrationLiters!.toStringAsFixed(hydrationLiters! % 1 == 0 ? 0 : 1)}L',
      if (nutration != null) 'nutration': nutration,
      if (dataSource != null) 'data_source': dataSource,
      'date': date,
    };
  }

  /// Create a copy with updated fields
  UserGravityEntry copyWith({
    int? id,
    double? weight,
    int? steps,
    double? sleepHours,
    double? hydrationLiters,
    String? nutration,
    String? dataSource,
    String? date,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserGravityEntry(
      id: id ?? this.id,
      weight: weight ?? this.weight,
      steps: steps ?? this.steps,
      sleepHours: sleepHours ?? this.sleepHours,
      hydrationLiters: hydrationLiters ?? this.hydrationLiters,
      nutration: nutration ?? this.nutration,
      dataSource: dataSource ?? this.dataSource,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

