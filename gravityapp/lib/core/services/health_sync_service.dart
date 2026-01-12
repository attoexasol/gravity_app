import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:health/health.dart';
import 'package:permission_handler/permission_handler.dart';

enum SyncStatus { never, syncing, success, error }

enum HealthPlatform { none, apple, google }

/// Sync Activity Record
class SyncActivity {
  final String status; // 'success', 'error', 'syncing'
  final DateTime timestamp;
  final String? error;
  final Map<String, dynamic>? metrics;

  SyncActivity({
    required this.status,
    required this.timestamp,
    this.error,
    this.metrics,
  });

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'timestamp': timestamp.toIso8601String(),
      'error': error,
      'metrics': metrics,
    };
  }

  factory SyncActivity.fromJson(Map<String, dynamic> json) {
    return SyncActivity(
      status: json['status'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      error: json['error'] as String?,
      metrics: json['metrics'] as Map<String, dynamic>?,
    );
  }
}

class HealthMetrics {
  final int steps;
  final double sleepHours;
  final SyncStatus syncStatus;
  final DateTime? lastSyncTime;
  final HealthPlatform platform;
  final double? weight; // Add weight to metrics
  final double? waterIntake; // Add water intake to metrics

  HealthMetrics({
    required this.steps,
    required this.sleepHours,
    required this.syncStatus,
    this.lastSyncTime,
    required this.platform,
    this.weight,
    this.waterIntake,
  });
}

class HealthSyncService {
  static final HealthSyncService _instance = HealthSyncService._internal();
  factory HealthSyncService() => _instance;
  HealthSyncService._internal();

  Health? _health;
  bool _isInitialized = false;

  HealthMetrics _metrics = HealthMetrics(
    steps: 0,
    sleepHours: 0.0,
    syncStatus: SyncStatus.never,
    platform: HealthPlatform.none,
  );

  final _controller = StreamController<HealthMetrics>.broadcast();
  final _syncActivityController = StreamController<SyncActivity>.broadcast();

  HealthMetrics getMetrics() => _metrics;

  Stream<HealthMetrics> get stream => _controller.stream;
  Stream<SyncActivity> get syncActivityStream => _syncActivityController.stream;

  void subscribe(void Function(HealthMetrics) onData) {
    stream.listen(onData);
  }

  void subscribeToSyncActivity(void Function(SyncActivity) onData) {
    syncActivityStream.listen(onData);
  }

  /// Initialize HealthKit (iOS) or Google Fit (Android) connection
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    // Only initialize on iOS or Android, not on web
    if (kIsWeb) {
      print('⚠️ Health services are only available on iOS and Android devices, not on web');
      return false;
    }

    if (!Platform.isIOS && !Platform.isAndroid) {
      print('⚠️ Health services are only available on iOS and Android devices');
      return false;
    }

    try {
      final platformName = kIsWeb ? 'Web' : (Platform.isIOS ? 'HealthKit' : 'Google Fit');
      print('🔵 Initializing $platformName...');

      // On Android, request runtime permissions first
      if (!kIsWeb && Platform.isAndroid) {
        print('🔵 Requesting Android runtime permissions...');
        final activityRecognitionStatus = await Permission.activityRecognition
            .request();
        print('🔵 Activity Recognition permission: $activityRecognitionStatus');

        if (!activityRecognitionStatus.isGranted) {
          print('❌ Activity Recognition permission denied');
          _updateMetrics(SyncStatus.error, platform: HealthPlatform.none);
          return false;
        }
      }

      // Create Health instance
      _health = Health();

      // Request permissions - use platform-specific data types
      // For Android, request essential permissions first, then optionally sleep permissions
      // This prevents the entire authorization from failing if sleep types aren't supported
      final essentialTypes = (!kIsWeb && Platform.isAndroid)
          ? [
              // Health Connect/Google Fit essential types (known to work)
              HealthDataType.STEPS,
              HealthDataType.WEIGHT,
              HealthDataType.WATER,
            ]
          : [
              // HealthKit supported types (all at once for iOS)
              HealthDataType.STEPS,
              HealthDataType.SLEEP_IN_BED,
              HealthDataType.SLEEP_ASLEEP,
              HealthDataType.WEIGHT,
              HealthDataType.WATER,
            ];

      // Sleep types for Android (requested separately as optional)
      final sleepTypes = [
        HealthDataType.SLEEP_IN_BED,
        HealthDataType.SLEEP_ASLEEP,
      ];

      print('🔵 Requesting $platformName permissions...');

      bool granted = false;

      // On Android, check if we can actually request authorization
      if (!kIsWeb && Platform.isAndroid) {
        try {
          print(
            '🔵 Attempting to request Health Connect/Google Fit authorization...',
          );
          print('🔵 This should open the permission dialog...');
          print(
            '🔵 Requesting essential permissions: ${essentialTypes.map((t) => t.toString()).join(", ")}',
          );

          // First, request essential permissions (steps, weight, water)
          // This should trigger the permission dialog
          // Note: The health package will show the Health Connect permission dialog automatically
          // if Health Connect is installed and properly configured
          granted = await _health!.requestAuthorization(essentialTypes);
          print('🔵 Essential permissions granted: $granted');

          if (!granted) {
            print(
              '⚠️ Health Connect/Google Fit authorization was denied or not available',
            );
            print('💡 Troubleshooting steps:');
            print(
              '   1. Make sure Health Connect app is installed and up to date',
            );
            print('   2. Open Health Connect app and complete initial setup');
            print('   3. Restart your device');
            print(
              '   4. Try tapping "Connect" again - the permission dialog should appear',
            );
            print(
              '   5. If the dialog still doesn\'t appear, try clearing app cache and data',
            );
            print(
              '   6. Check if Health Connect appears in your device\'s app list',
            );
            _updateMetrics(SyncStatus.error, platform: HealthPlatform.google);
            return false;
          }

          // If essential permissions granted, try to request sleep permissions (optional)
          try {
            print('🔵 Requesting optional sleep permissions...');
            final sleepGranted = await _health!.requestAuthorization(sleepTypes);
            print('🔵 Sleep permissions granted: $sleepGranted');
            if (!sleepGranted) {
              print('⚠️ Sleep permissions not available - will continue without sleep data');
            }
          } catch (e) {
            print('⚠️ Could not request sleep permissions: $e - will continue without sleep data');
            // Don't fail the entire initialization if sleep permissions fail
          }
        } catch (e, stackTrace) {
          print(
            '❌ Error requesting Health Connect/Google Fit authorization: $e',
          );
          print('Stack trace: $stackTrace');
          print('💡 This might mean:');
          print(
            '   - Health Connect is not installed (install from Play Store)',
          );
          print(
            '   - Health Connect is not properly configured or needs to be updated',
          );
          print(
            '   - The device doesn\'t support Health Connect (requires Android 14+ or Health Connect app)',
          );
          print('   - There might be a permissions configuration issue');
          print('   - Try restarting the device and Health Connect app');
          _updateMetrics(SyncStatus.error, platform: HealthPlatform.none);
          return false;
        }
      } else {
        // For iOS, request all permissions at once
        granted = await _health!.requestAuthorization(essentialTypes);
        print('🔵 Permission granted: $granted');

        if (!granted) {
          _updateMetrics(SyncStatus.error, platform: HealthPlatform.none);
          return false;
        }
      }

      // If we get here, permissions were granted
      if (granted) {
        _isInitialized = true;
        final platform = kIsWeb
            ? HealthPlatform.none
            : (Platform.isIOS ? HealthPlatform.apple : HealthPlatform.google);
        print('✅ $platformName initialized successfully');

        _updateMetrics(SyncStatus.success, platform: platform);
        // Record successful initialization
        _recordSyncActivity(
          status: 'success',
          error: null,
          metrics: {'action': 'initialization', 'platform': platform.name},
        );
        // Fetch initial data
        await syncHealthData();
        return true;
      } else {
        print('❌ $platformName permission denied');
        _updateMetrics(SyncStatus.error, platform: HealthPlatform.none);
        // Record failed initialization
        _recordSyncActivity(
          status: 'error',
          error: 'Permission denied',
          metrics: {'action': 'initialization'},
        );
        return false;
      }
    } catch (e, stackTrace) {
      final platformName = kIsWeb ? 'Web' : (Platform.isIOS ? 'HealthKit' : 'Google Fit');
      print('❌ $platformName initialization error: $e');
      print('Stack trace: $stackTrace');
      _updateMetrics(SyncStatus.error, platform: HealthPlatform.none);
      // Record initialization error
      _recordSyncActivity(
        status: 'error',
        error: e.toString(),
        metrics: {'action': 'initialization'},
      );
      return false;
    }
  }

  /// Sync health data from HealthKit (iOS) or Google Fit (Android)
  Future<void> syncHealthData() async {
    if (kIsWeb) {
      print('⚠️ Health data syncing is not available on web');
      return;
    }

    if (!_isInitialized) {
      final platformName = Platform.isIOS ? 'HealthKit' : 'Google Fit';
      print('🔵 $platformName not initialized, initializing now...');
      final initialized = await initialize();
      if (!initialized) {
        print('❌ Failed to initialize $platformName, cannot sync data');
        return;
      }
    }

    final platformName = Platform.isIOS ? 'HealthKit' : 'Google Fit';
    print('🔄 Syncing health data from $platformName...');
    _updateMetrics(SyncStatus.syncing);
    // Record sync start
    _recordSyncActivity(
      status: 'syncing',
      error: null,
      metrics: {'action': 'sync_start'},
    );

    try {
      final now = DateTime.now();
      // Calculate today's start in local time (midnight today)
      final todayStart = DateTime(now.year, now.month, now.day);
      // For sleep, check from yesterday evening (6 PM yesterday) to now
      final yesterdayEvening = todayStart.subtract(const Duration(hours: 6));

      // Fetch Steps (today only)
      int steps = 0;
      try {
        final stepsData = await _health!.getHealthDataFromTypes(
          types: [HealthDataType.STEPS],
          startTime: todayStart,
          endTime: now,
        );
        if (stepsData.isNotEmpty) {
          steps = stepsData
              .map(
                (data) =>
                    (data.value as NumericHealthValue).numericValue.toInt(),
              )
              .reduce((a, b) => a + b);
        }
        if (steps > 0) {
          print('📊 Today\'s steps: $steps (from ${stepsData.length} data points)');
        } else if (stepsData.isEmpty) {
          print('⚠️ No steps data found in health platform for today');
          print('   Query range: ${todayStart.toString()} to ${now.toString()}');
        } else {
          print('📊 Today\'s steps: $steps (data points found but sum is 0)');
        }
      } catch (e) {
        print('⚠️ Error fetching steps: $e');
      }

      // Fetch Sleep Hours (from yesterday evening to now to catch overnight sleep)
      double sleepHours = 0.0;
      try {
        // Health Connect (Android) and HealthKit (iOS) both support sleep data
        final sleepTypes = [
          HealthDataType.SLEEP_IN_BED,
          HealthDataType.SLEEP_ASLEEP,
          HealthDataType.SLEEP_AWAKE,
        ];
        print('🔵 Querying sleep data from ${Platform.isIOS ? 'HealthKit' : 'Health Connect'}...');
        print('   Time range: ${yesterdayEvening.toString()} to ${now.toString()}');
        // Query sleep data (health package handles timezone conversion)
        final sleepData = await _health!.getHealthDataFromTypes(
          types: sleepTypes,
          startTime: yesterdayEvening,
          endTime: now,
        );
        print('🔵 Sleep data query returned ${sleepData.length} data points');
        
        if (sleepData.isNotEmpty) {
          // Calculate total sleep in hours for today
          // Group by sleep sessions and calculate total
          for (var data in sleepData) {
            final start = data.dateFrom;
            final end = data.dateTo;
            final duration = end.difference(start).inMinutes / 60.0;
            print('   - Sleep entry: ${data.type.toString()} from ${start.toString()} to ${end.toString()} (${duration.toStringAsFixed(2)}h)');
            
            // Only count sleep that ended today or is still ongoing
            if (end.isAfter(todayStart) || end.isAtSameMomentAs(todayStart)) {
              final sleepStart = start.isBefore(todayStart)
                  ? todayStart
                  : start;
              final sleepDuration = end.difference(sleepStart).inMinutes / 60.0;
              // Only count actual sleep (not awake time)
              if (data.type != HealthDataType.SLEEP_AWAKE) {
                sleepHours += sleepDuration;
                print('     ✓ Counted ${sleepDuration.toStringAsFixed(2)}h (total: ${sleepHours.toStringAsFixed(2)}h)');
              } else {
                print('     ✗ Skipped (awake time)');
              }
            } else {
              print('     ✗ Skipped (ended before today)');
            }
          }
          print('📊 Today\'s sleep: ${sleepHours.toStringAsFixed(1)}h');
        } else {
          final platformName = kIsWeb ? 'Web' : (Platform.isIOS ? 'HealthKit' : 'Health Connect');
          print('⚠️ No sleep data found in $platformName');
          print('   💡 Make sure sleep is tracked in Google Fit/Health Connect app');
        }
      } catch (e, stackTrace) {
        print('⚠️ Error fetching sleep: $e');
        print('   Stack trace: $stackTrace');
        // Don't fail the entire sync if sleep fetch fails
      }

      // Fetch Weight (most recent from last 30 days for better chance of finding data)
      double? weight;
      try {
        final monthAgo = now.subtract(const Duration(days: 30));
        final weightData = await _health!.getHealthDataFromTypes(
          types: [HealthDataType.WEIGHT],
          startTime: monthAgo,
          endTime: now,
        );
        if (weightData.isNotEmpty) {
          // Get the most recent weight
          weightData.sort((a, b) {
            return b.dateFrom.compareTo(a.dateFrom);
          });
          weight = (weightData.first.value as NumericHealthValue).numericValue
              .toDouble();
          print('📊 Most recent weight: $weight kg');
        } else {
          final platformName = kIsWeb ? 'Web' : (Platform.isIOS ? 'HealthKit' : 'Google Fit');
          print('⚠️ No weight data found in $platformName');
        }
      } catch (e) {
        print('⚠️ Error fetching weight: $e');
      }

      // Fetch Water Intake (today only)
      double? waterIntake;
      try {
        // Query water intake for today
        print('🔵 Querying water intake data from ${Platform.isIOS ? 'HealthKit' : 'Health Connect'}...');
        print('   Time range: ${todayStart.toString()} to ${now.toString()}');
        final waterData = await _health!.getHealthDataFromTypes(
          types: [HealthDataType.WATER],
          startTime: todayStart,
          endTime: now,
        );
        print('🔵 Water data query returned ${waterData.length} data points');
        
        if (waterData.isNotEmpty) {
          // Sum all water intake values
          // Note: Health Connect/Google Fit may return values in different units
          // The health package should handle unit conversion, but we'll log the raw values
          double totalWater = 0.0;
          for (var data in waterData) {
            final value = (data.value as NumericHealthValue).numericValue.toDouble();
            print('   - Water entry: $value (from ${data.dateFrom} to ${data.dateTo})');
            totalWater += value;
          }
          waterIntake = totalWater;
          print('📊 Today\'s water intake: $waterIntake L (from ${waterData.length} entries)');
        } else {
          // Set to 0.0 to indicate we checked but found no data (vs null which means not checked)
          waterIntake = 0.0;
          final platformName = kIsWeb ? 'Web' : (Platform.isIOS ? 'HealthKit' : 'Health Connect');
          print('⚠️ No water intake data found in $platformName for today (set to 0.0)');
          print('   💡 Make sure water intake is logged in Google Fit/Health Connect app');
        }
      } catch (e, stackTrace) {
        print('⚠️ Error fetching water: $e');
        print('   Stack trace: $stackTrace');
        // On error, set to null to indicate we couldn't fetch (vs 0.0 which means no data found)
        waterIntake = null;
      }

      // Update metrics with fetched data
      // If waterIntake is null (error fetching), set to 0.0 to indicate we checked but couldn't fetch
      final finalWaterIntake = waterIntake ?? 0.0;
      print(
        '✅ Health data synced: Steps=$steps, Sleep=${sleepHours.toStringAsFixed(1)}h, Weight=$weight kg, Water=$finalWaterIntake L',
      );
      _updateMetrics(
        SyncStatus.success,
        steps: steps,
        sleepHours: sleepHours,
        weight: weight,
        waterIntake: finalWaterIntake,
      );
      // Record successful sync
      _recordSyncActivity(
        status: 'success',
        error: null,
        metrics: {
          'steps': steps,
          'sleepHours': sleepHours,
          'weight': weight,
          'waterIntake': waterIntake,
        },
      );
    } catch (e, stackTrace) {
      print('❌ Error syncing health data: $e');
      print('Stack trace: $stackTrace');
      _updateMetrics(SyncStatus.error);
      // Record sync error
      _recordSyncActivity(status: 'error', error: e.toString(), metrics: null);
    }
  }

  void _updateMetrics(
    SyncStatus status, {
    int? steps,
    double? sleepHours,
    double? weight,
    double? waterIntake,
    HealthPlatform? platform,
  }) {
    _metrics = HealthMetrics(
      steps: steps ?? _metrics.steps,
      sleepHours: sleepHours ?? _metrics.sleepHours,
      syncStatus: status,
      lastSyncTime: status == SyncStatus.success
          ? DateTime.now()
          : _metrics.lastSyncTime,
      platform: platform ?? _metrics.platform,
      weight: weight ?? _metrics.weight,
      waterIntake: waterIntake ?? _metrics.waterIntake,
    );
    _controller.add(_metrics);
  }

  /// Record sync activity
  void _recordSyncActivity({
    required String status,
    String? error,
    Map<String, dynamic>? metrics,
  }) {
    final activity = SyncActivity(
      status: status,
      timestamp: DateTime.now(),
      error: error,
      metrics: metrics,
    );
    _syncActivityController.add(activity);
  }

  void dispose() {
    _controller.close();
    _syncActivityController.close();
  }
}
