import 'dart:io';
import '../../data/model/meal_analysis.dart';

class MealAnalysisService {
  static final MealAnalysisService _instance = MealAnalysisService._internal();
  factory MealAnalysisService() => _instance;
  MealAnalysisService._internal();

  int _dailyAnalyses = 0;
  final DateTime _resetTime = DateTime.now().add(const Duration(days: 1));
  int _totalCalls = 0;
  double _totalCost = 0.0;

  /// Get remaining analyses for today
  int getRemainingAnalyses() {
    // Reset if past reset time
    if (DateTime.now().isAfter(_resetTime)) {
      _dailyAnalyses = 0;
    }
    return 5 - _dailyAnalyses;
  }

  /// Get usage statistics
  UsageStats getUsageStats() {
    return UsageStats(
      totalCalls: _totalCalls,
      totalCost: _totalCost,
      resetTime: _resetTime,
    );
  }

  /// Analyze meal from image file
  Future<MealAnalysis> analyzeMeal(File imageFile, String provider) async {
    if (getRemainingAnalyses() <= 0) {
      throw Exception('Daily limit reached');
    }

    _dailyAnalyses++;
    _totalCalls++;
    _totalCost += 0.002; // $0.002 per analysis

    // Simulate API call delay
    await Future.delayed(const Duration(seconds: 2));

    // Mock analysis result
    return MealAnalysis(
      foodItems: [
        'Grilled Chicken',
        'Brown Rice',
        'Steamed Broccoli',
        'Mixed Salad',
      ],
      healthScore: 85,
      confidence: 0.92,
      nutritionInfo: NutritionInfo(
        calories: 450,
        protein: 35.0,
        carbs: 45.0,
        fat: 12.0,
        fiber: 8.0,
        sodium: 580,
      ),
      feedback:
          'This is a well-balanced meal with lean protein, complex carbs, and plenty of vegetables. Great choice for maintaining energy levels and supporting muscle recovery.',
      suggestions: [
        'Consider adding a source of healthy fats like avocado or nuts',
        'The portion size looks appropriate for a main meal',
        'Excellent variety of vegetables for micronutrients',
      ],
      aiProvider: provider,
      cached: false,
    );
  }
}
