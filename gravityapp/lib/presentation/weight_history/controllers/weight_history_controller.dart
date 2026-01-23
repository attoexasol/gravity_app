import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../data/model/weight_history.dart';
import '../../../../data/repositories/user_gravity_repository.dart';
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

  // Weight data (reactive observables for dynamic updates)
  final RxDouble goalWeight = 71.5.obs;
  final RxDouble startingWeight = 85.0.obs;
  
  // Current weight (calculated from history)
  double get currentWeight {
    if (_weightHistory.isEmpty) {
      // Fallback: try to get from storage
      final savedStartingWeight = PreferencesService.getStartingWeight();
      if (savedStartingWeight != null && savedStartingWeight > 0) {
        return savedStartingWeight;
      }
      return 79.0; // Final fallback
    }
    return _weightHistory.first.weight; // Latest entry
  }
  
  // Weekly average (calculated dynamically from actual data)
  double get weeklyAverage {
    if (_weightHistory.length < 2) {
      return 0.0; // Need at least 2 entries
    }
    
    // Sort by date (oldest to newest) for calculation
    final sortedHistory = List<WeightEntry>.from(_weightHistory);
    sortedHistory.sort((a, b) {
      final dateA = DateTime.parse(a.date);
      final dateB = DateTime.parse(b.date);
      return dateA.compareTo(dateB);
    });
    
    final oldestEntry = sortedHistory.first;
    final newestEntry = sortedHistory.last;
    
    final oldestDate = DateTime.parse(oldestEntry.date);
    final newestDate = DateTime.parse(newestEntry.date);
    
    // Calculate days between oldest and newest entry
    final daysDiff = newestDate.difference(oldestDate).inDays;
    if (daysDiff <= 0) {
      return 0.0; // Same day or invalid
    }
    
    // Calculate total weight loss
    final totalLoss = oldestEntry.weight - newestEntry.weight;
    
    // Calculate weeks
    final weeks = daysDiff / 7.0;
    if (weeks <= 0) {
      return 0.0;
    }
    
    // Weekly average = total loss / weeks
    final average = totalLoss / weeks;
    return average > 0 ? average : 0.0; // Return positive value or 0
  }

  // Weight history entries (sorted by date descending - latest first)
  List<WeightEntry> get weightHistory => _weightHistory.toList();

  // Get recent entries (already sorted descending)
  List<WeightEntry> get recentEntries => _weightHistory.toList();

  // Calculated values (reactive - will update when observables change)
  double get totalLoss {
    final start = startingWeight.value;
    final current = currentWeight;
    final loss = start - current;
    return loss > 0 ? loss : 0.0; // Ensure non-negative
  }
  
  double get remaining {
    final current = currentWeight;
    final goal = goalWeight.value;
    final remaining = current - goal;
    return remaining > 0 ? remaining : 0.0; // Ensure non-negative
  }
  
  int get weeksTracking {
    if (_weightHistory.length < 2) {
      return 0; // Need at least 2 entries
    }
    
    // Sort by date (oldest to newest)
    final sortedHistory = List<WeightEntry>.from(_weightHistory);
    sortedHistory.sort((a, b) {
      final dateA = DateTime.parse(a.date);
      final dateB = DateTime.parse(b.date);
      return dateA.compareTo(dateB);
    });
    
    final oldestDate = DateTime.parse(sortedHistory.first.date);
    final newestDate = DateTime.parse(sortedHistory.last.date);
    
    // Calculate weeks between oldest and newest entry
    final daysDiff = newestDate.difference(oldestDate).inDays;
    final weeks = (daysDiff / 7.0).floor();
    
    return weeks > 0 ? weeks : 0;
  }

  // Calculate estimated target date
  String get estimatedTargetDate {
    final avg = weeklyAverage;
    if (avg <= 0 || remaining <= 0) {
      return 'N/A'; // Can't estimate if no progress or no data
    }
    final weeksRemaining = (remaining / avg).ceil();
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
    if (_weightHistory.isEmpty) return goalWeight.value - 2;
    final weights = _weightHistory.map((e) => e.weight).toList();
    final minWeight = weights.reduce((a, b) => a < b ? a : b);
    return minWeight - 2;
  }
  
  double get maxY {
    if (_weightHistory.isEmpty) return startingWeight.value + 2;
    final weights = _weightHistory.map((e) => e.weight).toList();
    final maxWeight = weights.reduce((a, b) => a > b ? a : b);
    return maxWeight + 2;
  }

  @override
  void onInit() {
    super.onInit();
    // Load goals from storage first
    _loadGoalsFromStorage();
    // Fetch weight history when controller initializes
    fetchWeightHistory();
  }
  
  /// Load goal weight and starting weight from storage
  void _loadGoalsFromStorage() {
    try {
      // Load goal weight (target weight) from storage
      final savedGoals = PreferencesService.getStorage().read('userGoals');
      if (savedGoals != null) {
        final goalsMap = jsonDecode(savedGoals) as Map<String, dynamic>;
        
        // Load target weight
        final targetWeightStr = goalsMap['targetWeight']?.toString() ?? '71.5';
        final targetWeight = double.tryParse(targetWeightStr);
        if (targetWeight != null && targetWeight > 0) {
          goalWeight.value = targetWeight;
        }
      }
      
      // Load starting weight from storage (set from Settings > Current Weight)
      final savedStartingWeight = PreferencesService.getStartingWeight();
      if (savedStartingWeight != null && savedStartingWeight > 0) {
        startingWeight.value = savedStartingWeight;
      } else {
        // Fallback: try to get from goals
        if (savedGoals != null) {
          final goalsMap = jsonDecode(savedGoals) as Map<String, dynamic>;
          final currentWeightStr = goalsMap['currentWeight']?.toString();
          if (currentWeightStr != null) {
            final weight = double.tryParse(currentWeightStr);
            if (weight != null && weight > 0) {
              startingWeight.value = weight;
            }
          }
        }
      }
    } catch (e) {
      debugPrint('⚠️ Error loading goals from storage: $e');
    }
  }
  
  /// Public method to be called when goals are updated in settings
  /// This ensures stats recalculate with new starting weight/goal weight
  void notifyGoalsChanged() {
    debugPrint('🔄 Weight History: Goals changed - reloading from storage');
    _loadGoalsFromStorage();
    // Trigger update to rebuild observers
    update();
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
      
      // Update starting weight if history has data and starting weight not set from storage
      if (entries.isNotEmpty && startingWeight.value == 85.0) {
        // Use oldest entry as starting weight if not set from storage
        final oldestEntry = entries.last; // Last in descending order = oldest
        startingWeight.value = oldestEntry.weight;
      }
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

