/// Date-Wise Gravity Response Model
/// Represents the response from POST /api/date_wise/gravity
class DateWiseGravityResponse {
  final double? weight;
  final int? steps;
  final double? sleepHours;
  final double? hydrationLiters;
  final int? nutritionCalories;
  final bool fastingCompleted;
  final double? startingWeight;
  final double? goalWeightLoss;
  final DateTime? createdAt;

  DateWiseGravityResponse({
    this.weight,
    this.steps,
    this.sleepHours,
    this.hydrationLiters,
    this.nutritionCalories,
    required this.fastingCompleted,
    this.startingWeight,
    this.goalWeightLoss,
    this.createdAt,
  });

  /// Parse from JSON response
  factory DateWiseGravityResponse.fromJson(Map<String, dynamic> json) {
    // Parse weight
    double? parsedWeight;
    if (json['weight'] != null) {
      if (json['weight'] is num) {
        parsedWeight = (json['weight'] as num).toDouble();
      } else if (json['weight'] is String) {
        parsedWeight = double.tryParse(json['weight'] as String);
      }
    }

    // Parse steps
    int? parsedSteps;
    if (json['steps'] != null) {
      if (json['steps'] is int) {
        parsedSteps = json['steps'] as int;
      } else if (json['steps'] is num) {
        parsedSteps = (json['steps'] as num).toInt();
      } else if (json['steps'] is String) {
        parsedSteps = int.tryParse(json['steps'] as String);
      }
    }

    // Parse sleep_hours
    double? parsedSleepHours;
    if (json['sleep_hours'] != null) {
      if (json['sleep_hours'] is num) {
        parsedSleepHours = (json['sleep_hours'] as num).toDouble();
      } else if (json['sleep_hours'] is String) {
        parsedSleepHours = double.tryParse(json['sleep_hours'] as String);
      }
    }

    // Parse hydration_liters (and fallback to "hydration" string e.g. "3L" from manual/API)
    double? parsedHydrationLiters;
    if (json['hydration_liters'] != null) {
      if (json['hydration_liters'] is num) {
        parsedHydrationLiters = (json['hydration_liters'] as num).toDouble();
      } else if (json['hydration_liters'] is String) {
        parsedHydrationLiters = double.tryParse(json['hydration_liters'] as String);
      }
    }
    if (parsedHydrationLiters == null && json['hydration'] != null) {
      final hydrationStr = json['hydration'].toString();
      final numericStr = hydrationStr.replaceAll(RegExp(r'[Ll]'), '').trim();
      parsedHydrationLiters = double.tryParse(numericStr);
    }

    // Parse nutrition_calories
    int? parsedNutritionCalories;
    if (json['nutrition_calories'] != null) {
      if (json['nutrition_calories'] is int) {
        parsedNutritionCalories = json['nutrition_calories'] as int;
      } else if (json['nutrition_calories'] is num) {
        parsedNutritionCalories = (json['nutrition_calories'] as num).toInt();
      } else if (json['nutrition_calories'] is String) {
        parsedNutritionCalories = int.tryParse(json['nutrition_calories'] as String);
      }
    }

    // Parse fasting_completed
    final fastingCompleted = json['fasting_completed'] == true ||
        json['fasting_completed'] == 1 ||
        (json['fasting_completed'] is String && json['fasting_completed'].toString().toLowerCase() == 'true');

    // Parse starting_weight
    double? parsedStartingWeight;
    if (json['starting_weight'] != null) {
      if (json['starting_weight'] is num) {
        parsedStartingWeight = (json['starting_weight'] as num).toDouble();
      } else if (json['starting_weight'] is String) {
        parsedStartingWeight = double.tryParse(json['starting_weight'] as String);
      }
    }

    // Parse goal_weight_loss
    double? parsedGoalWeightLoss;
    if (json['goal_weight_loss'] != null) {
      if (json['goal_weight_loss'] is num) {
        parsedGoalWeightLoss = (json['goal_weight_loss'] as num).toDouble();
      } else if (json['goal_weight_loss'] is String) {
        parsedGoalWeightLoss = double.tryParse(json['goal_weight_loss'] as String);
      }
    }

    // Parse created_at
    DateTime? parsedCreatedAt;
    if (json['created_at'] != null) {
      try {
        parsedCreatedAt = DateTime.parse(json['created_at'].toString());
      } catch (e) {
        // Ignore parse errors
      }
    }

    return DateWiseGravityResponse(
      weight: parsedWeight,
      steps: parsedSteps,
      sleepHours: parsedSleepHours,
      hydrationLiters: parsedHydrationLiters,
      nutritionCalories: parsedNutritionCalories,
      fastingCompleted: fastingCompleted,
      startingWeight: parsedStartingWeight,
      goalWeightLoss: parsedGoalWeightLoss,
      createdAt: parsedCreatedAt,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      if (weight != null) 'weight': weight,
      if (steps != null) 'steps': steps,
      if (sleepHours != null) 'sleep_hours': sleepHours,
      if (hydrationLiters != null) 'hydration_liters': hydrationLiters,
      if (nutritionCalories != null) 'nutrition_calories': nutritionCalories,
      'fasting_completed': fastingCompleted,
      if (startingWeight != null) 'starting_weight': startingWeight,
      if (goalWeightLoss != null) 'goal_weight_loss': goalWeightLoss,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    };
  }
}
