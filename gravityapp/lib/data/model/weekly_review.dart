/// Weekly Review Model
/// Represents weekly review data including consistency and patterns
class WeeklyReview {
  final String phase; // e.g., "Weight Loss"
  final int daysLogged; // e.g., 7
  final String summary; // e.g., "This week shows steady effort with a few gaps"
  final WeekConsistencyData consistency;
  final List<WeekPattern> patterns;
  final WeekStatusInsights statusInsights;

  WeeklyReview({
    required this.phase,
    required this.daysLogged,
    required this.summary,
    required this.consistency,
    required this.patterns,
    required this.statusInsights,
  });
}

/// Week Consistency Data Model
class WeekConsistencyData {
  final List<PillarStatus> nutrition;
  final List<PillarStatus> hydration;
  final List<PillarStatus> sleep;
  final List<PillarStatus> steps;
  final List<PillarStatus> fasting;
  final List<PillarStatus> weighin;

  WeekConsistencyData({
    required this.nutrition,
    required this.hydration,
    required this.sleep,
    required this.steps,
    required this.fasting,
    required this.weighin,
  });
}

/// Pillar Status Enum
enum PillarStatus {
  complete,
  partial,
  missed,
}

/// Week Pattern Model
class WeekPattern {
  final String category; // e.g., "Nutrition", "Movement"
  final String insight; // e.g., "Dinners were least consistent mid-week"

  WeekPattern({
    required this.category,
    required this.insight,
  });
}

/// Week Status Insights Model
class WeekStatusInsights {
  final String weightTrend; // e.g., "Trending Down"
  final String consistency; // e.g., "Moderate"
  final String momentum; // e.g., "Building"

  WeekStatusInsights({
    required this.weightTrend,
    required this.consistency,
    required this.momentum,
  });
}

/// Week Option Model for Week Picker
class WeekOption {
  final int id;
  final String label; // e.g., "This Week", "Last Week"
  final String dateRange; // e.g., "Jan 5 – Jan 11"
  final DateTime startDate;
  final DateTime endDate;

  WeekOption({
    required this.id,
    required this.label,
    required this.dateRange,
    required this.startDate,
    required this.endDate,
  });
}

