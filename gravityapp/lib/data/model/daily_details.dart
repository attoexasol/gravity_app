/// Daily Details Data Model
/// Represents a single day's detailed data

enum PillarStatus {
  complete,
  partial,
  missed,
  none,
}

enum DayMood {
  great,
  good,
  okay,
  tough,
}

/// Pillar Data Model
class Pillar {
  final PillarStatus status;
  final String detail;

  Pillar({
    required this.status,
    required this.detail,
  });
}

/// Day Data Model
class DayData {
  final String date; // e.g., "Jan 5"
  final String dayName; // e.g., "Monday"
  final String fullDate; // e.g., "Monday, January 5"
  final DayMood mood;
  final String moodEmoji;
  final String moodLabel;
  final int pillarsCompleted;
  final int totalPillars;
  final String morningTag;
  final String eveningTag;
  final DayPillars pillars;
  final String? reflection;

  DayData({
    required this.date,
    required this.dayName,
    required this.fullDate,
    required this.mood,
    required this.moodEmoji,
    required this.moodLabel,
    required this.pillarsCompleted,
    required this.totalPillars,
    required this.morningTag,
    required this.eveningTag,
    required this.pillars,
    this.reflection,
  });
}

/// Day Pillars Model
class DayPillars {
  final Pillar nutrition;
  final Pillar hydration;
  final Pillar sleep;
  final Pillar step;
  final Pillar fasting;
  final Pillar weighin;

  DayPillars({
    required this.nutrition,
    required this.hydration,
    required this.sleep,
    required this.step,
    required this.fasting,
    required this.weighin,
  });
}

