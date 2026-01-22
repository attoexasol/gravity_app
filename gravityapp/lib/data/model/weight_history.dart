import 'package:intl/intl.dart';

class WeightEntry {
  final String date; // YYYY-MM-DD format
  final double weight;
  final String displayDate; // Formatted date for display

  WeightEntry({
    required this.date,
    required this.weight,
    required this.displayDate,
  });

  /// Create from API response format
  factory WeightEntry.fromApiData(String dateStr, dynamic weightValue) {
    // Parse date
    final date = DateTime.parse(dateStr);
    final displayDate = _formatDisplayDate(date);
    
    // Parse weight
    double weight;
    if (weightValue is num) {
      weight = weightValue.toDouble();
    } else if (weightValue is String) {
      weight = double.tryParse(weightValue) ?? 0.0;
    } else {
      weight = 0.0;
    }

    return WeightEntry(
      date: dateStr,
      weight: weight,
      displayDate: displayDate,
    );
  }

  /// Format date for display (e.g., "Wednesday, Jan 22")
  static String _formatDisplayDate(DateTime date) {
    final formatter = DateFormat('EEEE, MMM d', 'en_US');
    return formatter.format(date);
  }
}
