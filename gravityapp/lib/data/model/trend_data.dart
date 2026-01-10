/// Trend Data Model for 7-day charts
class TrendData {
  final String day; // 'Sun', 'Mon', 'Tue', etc.
  final int steps;
  final double sleep;
  final double water;

  TrendData({
    required this.day,
    required this.steps,
    required this.sleep,
    required this.water,
  });
}

