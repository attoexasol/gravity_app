/// Meal Analysis Model
class MealAnalysis {
  final List<String> foodItems;
  final int healthScore;
  final double confidence;
  final NutritionInfo nutritionInfo;
  final String feedback;
  final List<String> suggestions;
  final String aiProvider;
  final String? imageUrl;
  final bool cached;

  MealAnalysis({
    required this.foodItems,
    required this.healthScore,
    required this.confidence,
    required this.nutritionInfo,
    required this.feedback,
    required this.suggestions,
    required this.aiProvider,
    this.imageUrl,
    this.cached = false,
  });

  factory MealAnalysis.fromJson(Map<String, dynamic> json) {
    return MealAnalysis(
      foodItems: List<String>.from(json['foodItems'] ?? []),
      healthScore: json['healthScore'] ?? 0,
      confidence: (json['confidence'] ?? 0.0).toDouble(),
      nutritionInfo: NutritionInfo.fromJson(json['nutritionInfo'] ?? {}),
      feedback: json['feedback'] ?? '',
      suggestions: List<String>.from(json['suggestions'] ?? []),
      aiProvider: json['aiProvider'] ?? 'gemini',
      imageUrl: json['imageUrl'],
      cached: json['cached'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'foodItems': foodItems,
      'healthScore': healthScore,
      'confidence': confidence,
      'nutritionInfo': nutritionInfo.toJson(),
      'feedback': feedback,
      'suggestions': suggestions,
      'aiProvider': aiProvider,
      'imageUrl': imageUrl,
      'cached': cached,
    };
  }
}

/// Nutrition Information
class NutritionInfo {
  final int calories;
  final double protein;
  final double carbs;
  final double fat;
  final double fiber;
  final int sodium;

  NutritionInfo({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.fiber,
    required this.sodium,
  });

  factory NutritionInfo.fromJson(Map<String, dynamic> json) {
    return NutritionInfo(
      calories: json['calories'] ?? 0,
      protein: (json['protein'] ?? 0.0).toDouble(),
      carbs: (json['carbs'] ?? 0.0).toDouble(),
      fat: (json['fat'] ?? 0.0).toDouble(),
      fiber: (json['fiber'] ?? 0.0).toDouble(),
      sodium: json['sodium'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'fiber': fiber,
      'sodium': sodium,
    };
  }
}

/// Usage Statistics
class UsageStats {
  final int totalCalls;
  final double totalCost;
  final DateTime resetTime;

  UsageStats({
    required this.totalCalls,
    required this.totalCost,
    required this.resetTime,
  });
}
