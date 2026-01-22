import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';
import '../../../../data/model/weight_history.dart';
import '../../../../data/repositories/user_gravity_repository.dart';
import '../../../../data/model/api_response.dart';
import '../../../../core/services/preferences_service.dart';
import '../../../../app/routes/app_routes.dart';

class WeightHistoryController extends GetxController {
  // Repository
  final UserGravityRepository _gravityRepository = UserGravityRepository();

  // State management
  final RxList<WeightEntry> _weightHistory = <WeightEntry>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool hasError = false.obs;
  final RxString errorMessage = ''.obs;
  
  // Cache management
  Map<String, dynamic>? _cachedData;
  DateTime? _lastFetchTime;
  static const Duration _cacheDuration = Duration(minutes: 5); // Cache for 5 minutes

  // Weight data (calculated from history)
  double get goalWeight => 71.5; // Can be loaded from goals/settings
  double get currentWeight {
    if (_weightHistory.isEmpty) return 79.0; // Fallback
    return _weightHistory.first.weight; // Latest entry
  }
  double get startingWeight {
    if (_weightHistory.isEmpty) return 85.0; // Fallback
    return _weightHistory.last.weight; // Oldest entry
  }
  final double weeklyAverage = 1.6; // kg per week

  // Weight history entries (sorted by date descending - latest first)
  List<WeightEntry> get weightHistory => _weightHistory.toList();

  // Get recent entries (already sorted descending)
  List<WeightEntry> get recentEntries => _weightHistory.toList();

  // Calculated values
  double get totalLoss => startingWeight - currentWeight;
  double get remaining => currentWeight - goalWeight;
  int get weeksTracking => weightHistory.length - 1;

  // Calculate estimated target date
  String get estimatedTargetDate {
    final weeksRemaining = (remaining / weeklyAverage).ceil();
    final estimatedDate = DateTime.now().add(Duration(days: weeksRemaining * 7));
    return DateFormat('MMMM yyyy', 'en_US').format(estimatedDate);
  }

  // Chart data points
  List<FlSpot> get chartSpots {
    if (_weightHistory.isEmpty) return [];
    // Sort by date ascending for chart (oldest to newest)
    final sortedHistory = List<WeightEntry>.from(_weightHistory);
    sortedHistory.sort((a, b) {
      final dateA = DateTime.parse(a.date);
      final dateB = DateTime.parse(b.date);
      return dateA.compareTo(dateB); // Ascending order for chart
    });
    return sortedHistory.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.weight);
    }).toList();
  }

  // Chart Y-axis domain
  double get minY {
    if (_weightHistory.isEmpty) return goalWeight - 2;
    final weights = _weightHistory.map((e) => e.weight).toList();
    final minWeight = weights.reduce((a, b) => a < b ? a : b);
    return minWeight - 2;
  }
  
  double get maxY {
    if (_weightHistory.isEmpty) return startingWeight + 2;
    final weights = _weightHistory.map((e) => e.weight).toList();
    final maxWeight = weights.reduce((a, b) => a > b ? a : b);
    return maxWeight + 2;
  }

  @override
  void onInit() {
    super.onInit();
    // Fetch weight history when controller initializes
    fetchWeightHistory();
  }

  /// Fetch monthly weight data from API
  Future<void> fetchWeightHistory({bool forceRefresh = false}) async {
    // Check cache first
    if (!forceRefresh && _cachedData != null && _lastFetchTime != null) {
      final timeSinceFetch = DateTime.now().difference(_lastFetchTime!);
      if (timeSinceFetch < _cacheDuration) {
        debugPrint('📦 Using cached weight history data');
        _parseAndSetData(_cachedData!);
        return;
      }
    }

    try {
      isLoading.value = true;
      hasError.value = false;
      errorMessage.value = '';

      final apiToken = PreferencesService.getAuthToken();
      if (apiToken == null || apiToken.isEmpty) {
        hasError.value = true;
        errorMessage.value = 'No authentication token';
        isLoading.value = false;
        return;
      }

      debugPrint('📤 Fetching monthly weight history...');

      final response = await _gravityRepository.getMonthlyGravityWeight(
        apiToken: apiToken,
      );

      if (response.isSuccess && response.data != null) {
        // Cache the response
        _cachedData = response.data;
        _lastFetchTime = DateTime.now();
        
        // Parse and set data
        _parseAndSetData(response.data!);
        
        hasError.value = false;
        errorMessage.value = '';
        debugPrint('✅ Weight history loaded successfully: ${_weightHistory.length} entries');
      } else {
        hasError.value = true;
        errorMessage.value = response.message.isNotEmpty 
            ? response.message 
            : 'Failed to load weight history';
        debugPrint('⚠️ Failed to load weight history: ${response.message}');
      }
    } catch (e) {
      hasError.value = true;
      errorMessage.value = 'An unexpected error occurred. Please try again.';
      debugPrint('❌ Error fetching weight history: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Parse API response data and convert to WeightEntry list
  void _parseAndSetData(Map<String, dynamic> data) {
    try {
      final List<WeightEntry> entries = [];
      
      // API returns: { "YYYY-MM-DD": weightValue, ... }
      data.forEach((dateStr, weightValue) {
        try {
          // Validate date format
          final date = DateTime.parse(dateStr);
          final entry = WeightEntry.fromApiData(dateStr, weightValue);
          entries.add(entry);
        } catch (e) {
          debugPrint('⚠️ Skipping invalid entry: $dateStr = $weightValue (Error: $e)');
        }
      });

      // Sort by date descending (latest first)
      entries.sort((a, b) {
        final dateA = DateTime.parse(a.date);
        final dateB = DateTime.parse(b.date);
        return dateB.compareTo(dateA); // Descending order
      });

      _weightHistory.value = entries;
    } catch (e) {
      debugPrint('❌ Error parsing weight history data: $e');
      hasError.value = true;
      errorMessage.value = 'Failed to parse weight history data';
    }
  }

  /// Retry fetching data
  Future<void> retry() async {
    await fetchWeightHistory(forceRefresh: true);
  }

  void onBack() {
    try {
      // Use Navigator directly to avoid GetX snackbar controller issues
      final context = Get.context;
      if (context != null) {
        final navigator = Navigator.of(context);
        if (navigator.canPop()) {
          // Use Navigator.pop() instead of Get.back() to avoid snackbar issues
          navigator.pop();
        } else {
          // If no route to go back to, navigate to home
          Get.offAllNamed(AppRoutes.home);
        }
      } else {
        // If no context, navigate to home as fallback
        Get.offAllNamed(AppRoutes.home);
      }
    } catch (e) {
      // If navigation fails, navigate to home as fallback
      print('Navigation error: $e');
      try {
        Get.offAllNamed(AppRoutes.home);
      } catch (e2) {
        print('Fallback navigation also failed: $e2');
      }
    }
  }

  void onEditEntry(WeightEntry entry) {
    // TODO: Implement edit entry functionality
    print('Edit entry: ${entry.weight} kg on ${entry.date}');
  }
}

