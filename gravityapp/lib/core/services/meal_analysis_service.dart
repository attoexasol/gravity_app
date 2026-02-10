import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../../data/model/meal_analysis.dart';
import 'preferences_service.dart';

class MealAnalysisService {
  static final MealAnalysisService _instance = MealAnalysisService._internal();
  factory MealAnalysisService() => _instance;
  MealAnalysisService._internal();

  int _dailyAnalyses = 0;
  final DateTime _resetTime = DateTime.now().add(const Duration(days: 1));
  int _totalCalls = 0;
  double _totalCost = 0.0;

  /// Gravity AI endpoint for food analysis (replaces n8n webhook)
  static const String _apiUrl = 'https://gravity.attoexasolutions.com/api/ai/analyze-post';

  /// Get remaining analyses for today
  int getRemainingAnalyses() {
    // Reset if past reset time
    if (DateTime.now().isAfter(_resetTime)) {
      _dailyAnalyses = 0;
    }
    return 5000 - _dailyAnalyses;
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
  /// Uses Gravity AI endpoint: POST /api/ai/analyze-post with base64 JSON body
  /// [mealDetails] optional user-provided context (e.g. "Grilled chicken, medium portion")
  Future<MealAnalysis> analyzeMeal(File imageFile, String provider,
      {String? mealDetails}) async {
    if (getRemainingAnalyses() <= 0) {
      throw Exception('Daily limit reached');
    }

    // Get api_token from existing auth storage (same as other Gravity API calls)
    final apiToken = PreferencesService.getAuthToken();
    if (apiToken == null || apiToken.isEmpty) {
      throw Exception('Authentication token not found. Please login again.');
    }

    _dailyAnalyses++;
    _totalCalls++;
    _totalCost += 0.002; // $0.002 per analysis

    try {
      debugPrint('🌐 Uploading image to Gravity AI food analysis API...');
      debugPrint('📁 Image path: ${imageFile.path}');
      debugPrint('📁 Image size: ${await imageFile.length()} bytes');

      // Convert image to base64 with data URI prefix (required by Gravity API)
      final imageBytes = await imageFile.readAsBytes();
      final fileName = imageFile.path.split(RegExp(r'[/\\]')).last;
      final base64Image = base64Encode(imageBytes);

      // Determine MIME type from file extension for data URI
      String mimeType = 'image/jpeg';
      if (fileName.toLowerCase().endsWith('.png')) {
        mimeType = 'image/png';
      } else if (fileName.toLowerCase().endsWith('.jpg') ||
          fileName.toLowerCase().endsWith('.jpeg')) {
        mimeType = 'image/jpeg';
      } else if (fileName.toLowerCase().endsWith('.webp')) {
        mimeType = 'image/webp';
      }
      final imageBase64 = 'data:$mimeType;base64,$base64Image';

      // Build JSON request body (replaces multipart upload)
      final message = (mealDetails?.trim().isNotEmpty == true)
          ? mealDetails!.trim()
          : '';
      final requestBody = {
        'api_token': apiToken,
        'message': message, // Optional user meal context
        'community_id': 2,
        'image_base64': imageBase64,
      };

      debugPrint('📤 Sending request to: $_apiUrl');
      debugPrint('📤 Content-Type: application/json');
      debugPrint('📤 Payload keys: ${requestBody.keys}');

      // POST JSON (replaces multipart)
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      debugPrint('📡 Response Status: ${response.statusCode}');
      debugPrint('📄 Response Body: ${response.body}');

      if (response.statusCode != 200) {
        throw Exception(
            'API request failed with status ${response.statusCode}: ${response.body}');
      }

      // Parse JSON response
      final Map<String, dynamic> jsonResponse;
      try {
        jsonResponse = jsonDecode(response.body) as Map<String, dynamic>;
        debugPrint('✅ Successfully parsed JSON response');
      } catch (e) {
        debugPrint('❌ JSON Decode Error: $e');
        debugPrint('❌ Response body that failed to parse: ${response.body}');
        throw Exception('Invalid response format from server: $e');
      }

      // Validate success before parsing ai_result
      if (jsonResponse['success'] != true) {
        final message = jsonResponse['message']?.toString() ?? 'Unknown error';
        throw Exception('Gravity AI analysis failed: $message');
      }

      // Extract ai_result - response wraps data in ai_result object
      final aiResult = jsonResponse['ai_result'];
      if (aiResult == null || aiResult is! Map<String, dynamic>) {
        throw Exception('API response missing ai_result object');
      }

      // Map Gravity API ai_result to MealAnalysis model (same fields as before)
      final result = _mapApiResponseToMealAnalysis(aiResult);
      debugPrint('✅ Successfully created MealAnalysis from API response');
      return result;
    } catch (e) {
      debugPrint('❌ Food Analysis API Error: $e');
      rethrow;
    }
  }

  /// Map API response to MealAnalysis model
  MealAnalysis _mapApiResponseToMealAnalysis(Map<String, dynamic> json) {
    debugPrint('📋 Mapping API response: ${json.toString()}');

    // Validate required fields exist
    if (!json.containsKey('identified_items')) {
      throw Exception('API response missing required field: identified_items');
    }
    if (!json.containsKey('health_score')) {
      throw Exception('API response missing required field: health_score');
    }
    if (!json.containsKey('nutrition_breakdown')) {
      throw Exception('API response missing required field: nutrition_breakdown');
    }
    if (!json.containsKey('gravity_reflection')) {
      throw Exception('API response missing required field: gravity_reflection');
    }

    // Extract identified items - use actual API data only
    final identifiedItemsRaw = json['identified_items'];
    if (identifiedItemsRaw == null) {
      throw Exception('API response has null identified_items');
    }
    if (identifiedItemsRaw is! List) {
      throw Exception('API response identified_items is not a list');
    }
    final identifiedItems = identifiedItemsRaw
        .map((item) => item.toString())
        .toList();

    // Extract health score - use actual API data only
    final healthScoreRaw = json['health_score'];
    if (healthScoreRaw == null) {
      throw Exception('API response has null health_score');
    }
    final healthScore = healthScoreRaw is int
        ? healthScoreRaw
        : (healthScoreRaw is num ? healthScoreRaw.toInt() : throw Exception('API response health_score is not a number'));

    // Extract nutrition breakdown - use actual API data only
    final nutritionBreakdownRaw = json['nutrition_breakdown'];
    if (nutritionBreakdownRaw == null) {
      throw Exception('API response has null nutrition_breakdown');
    }
    if (nutritionBreakdownRaw is! Map<String, dynamic>) {
      throw Exception('API response nutrition_breakdown is not an object');
    }
    final nutritionBreakdown = nutritionBreakdownRaw;

    // Validate and extract nutrition values - use actual API data only
    if (!nutritionBreakdown.containsKey('calories')) {
      throw Exception('API response nutrition_breakdown missing calories');
    }
    if (!nutritionBreakdown.containsKey('protein_g')) {
      throw Exception('API response nutrition_breakdown missing protein_g');
    }
    if (!nutritionBreakdown.containsKey('carbs_g')) {
      throw Exception('API response nutrition_breakdown missing carbs_g');
    }
    if (!nutritionBreakdown.containsKey('fat_g')) {
      throw Exception('API response nutrition_breakdown missing fat_g');
    }
    if (!nutritionBreakdown.containsKey('fiber_g')) {
      throw Exception('API response nutrition_breakdown missing fiber_g');
    }
    if (!nutritionBreakdown.containsKey('sodium_mg')) {
      throw Exception('API response nutrition_breakdown missing sodium_mg');
    }

    final nutritionInfo = NutritionInfo(
      calories: nutritionBreakdown['calories'] is int
          ? nutritionBreakdown['calories'] as int
          : (nutritionBreakdown['calories'] as num).toInt(),
      protein: (nutritionBreakdown['protein_g'] as num).toDouble(),
      carbs: (nutritionBreakdown['carbs_g'] as num).toDouble(),
      fat: (nutritionBreakdown['fat_g'] as num).toDouble(),
      fiber: (nutritionBreakdown['fiber_g'] as num).toDouble(),
      sodium: nutritionBreakdown['sodium_mg'] is int
          ? nutritionBreakdown['sodium_mg'] as int
          : (nutritionBreakdown['sodium_mg'] as num).toInt(),
    );

    // Extract gravity reflection (feedback) - use actual API data only
    final feedbackRaw = json['gravity_reflection'];
    if (feedbackRaw == null) {
      throw Exception('API response has null gravity_reflection');
    }
    final feedback = feedbackRaw.toString();

    debugPrint('✅ Successfully mapped API response to MealAnalysis');

    // Create MealAnalysis object with ONLY API response data
    return MealAnalysis(
      foodItems: identifiedItems,
      healthScore: healthScore,
      confidence: 1.0, // Set to 1.0 since API doesn't provide this, but we trust the API response
      nutritionInfo: nutritionInfo,
      feedback: feedback,
      suggestions: [], // API doesn't provide suggestions, so empty list
      aiProvider: 'gravity', // Gravity AI endpoint (replaced n8n webhook)
      cached: false,
    );
  }
}
