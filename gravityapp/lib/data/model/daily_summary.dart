/// Daily Summary Model
/// Represents AI-generated daily summary with trends, highlights, concerns, and recommendations
class DailySummary {
  final int overallScore; // 0-100
  final String summary; // Overall summary message
  final bool cached; // Whether the summary was cached
  final DailyTrends trends; // 7-day trends data
  final List<String> highlights; // Positive highlights
  final List<String> concerns; // Areas for improvement
  final List<String> recommendations; // AI recommendations
  final DateTime generatedAt; // When the summary was generated

  DailySummary({
    required this.overallScore,
    required this.summary,
    required this.cached,
    required this.trends,
    required this.highlights,
    required this.concerns,
    required this.recommendations,
    required this.generatedAt,
  });

  /// Parse from JSON response
  factory DailySummary.fromJson(Map<String, dynamic> json) {
    // Parse trends
    DailyTrends? parsedTrends;
    if (json['trends'] != null && json['trends'] is Map<String, dynamic>) {
      parsedTrends = DailyTrends.fromJson(json['trends'] as Map<String, dynamic>);
    }

    // Parse highlights
    List<String> parsedHighlights = [];
    if (json['highlights'] != null && json['highlights'] is List) {
      parsedHighlights = (json['highlights'] as List)
          .map((item) => item.toString())
          .toList();
    }

    // Parse concerns
    List<String> parsedConcerns = [];
    if (json['concerns'] != null && json['concerns'] is List) {
      parsedConcerns = (json['concerns'] as List)
          .map((item) => item.toString())
          .toList();
    }

    // Parse recommendations
    List<String> parsedRecommendations = [];
    if (json['recommendations'] != null && json['recommendations'] is List) {
      parsedRecommendations = (json['recommendations'] as List)
          .map((item) => item.toString())
          .toList();
    }

    // Parse generatedAt
    DateTime parsedGeneratedAt = DateTime.now();
    if (json['generated_at'] != null) {
      try {
        parsedGeneratedAt = DateTime.parse(json['generated_at'].toString());
      } catch (e) {
        // Use current time as fallback
      }
    }

    return DailySummary(
      overallScore: json['overallScore'] != null
          ? (json['overallScore'] is int
              ? json['overallScore']
              : int.tryParse(json['overallScore'].toString()) ?? 0)
          : 0,
      summary: json['summary']?.toString() ?? '',
      cached: json['cached'] == true || json['cached'] == 'true',
      trends: parsedTrends ?? DailyTrends(steps: 'neutral', sleep: 'neutral', water: 'neutral'),
      highlights: parsedHighlights,
      concerns: parsedConcerns,
      recommendations: parsedRecommendations,
      generatedAt: parsedGeneratedAt,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'overallScore': overallScore,
      'summary': summary,
      'cached': cached,
      'trends': trends.toJson(),
      'highlights': highlights,
      'concerns': concerns,
      'recommendations': recommendations,
      'generated_at': generatedAt.toIso8601String(),
    };
  }
}

/// Daily Trends Model
/// Represents trend indicators for different metrics
class DailyTrends {
  final String steps; // 'up', 'down', 'neutral'
  final String sleep; // 'up', 'down', 'neutral'
  final String water; // 'up', 'down', 'neutral'

  DailyTrends({
    required this.steps,
    required this.sleep,
    required this.water,
  });

  factory DailyTrends.fromJson(Map<String, dynamic> json) {
    return DailyTrends(
      steps: json['steps']?.toString() ?? 'neutral',
      sleep: json['sleep']?.toString() ?? 'neutral',
      water: json['water']?.toString() ?? 'neutral',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'steps': steps,
      'sleep': sleep,
      'water': water,
    };
  }
}


