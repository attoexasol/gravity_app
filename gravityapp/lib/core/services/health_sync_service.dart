import 'dart:async';
import 'dart:io' show Platform;
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
    if (!Platform.isIOS && !Platform.isAndroid) {
      print('⚠️ Health services are only available on iOS and Android devices');
      return false;
    }

    try {
      final platformName = Platform.isIOS ? 'HealthKit' : 'Google Fit';
      print('🔵 Initializing $platformName...');

      // On Android, request runtime permissions first
      if (Platform.isAndroid) {
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
      final types = Platform.isAndroid
          ? [
              // Google Fit supported types
              HealthDataType.STEPS,
              HealthDataType.WEIGHT,
              HealthDataType.WATER,
              // Note: Sleep types are not well supported in Google Fit
            ]
          : [
              // HealthKit supported types
              HealthDataType.STEPS,
              HealthDataType.SLEEP_IN_BED,
              HealthDataType.SLEEP_ASLEEP,
              HealthDataType.WEIGHT,
              HealthDataType.WATER,
            ];

      print('🔵 Requesting $platformName permissions...');

      bool granted = false;

      // On Android, check if we can actually request authorization
      if (Platform.isAndroid) {
        try {
          print(
            '🔵 Attempting to request Health Connect/Google Fit authorization...',
          );
          print('🔵 This should open the permission dialog...');
          print(
            '🔵 Requesting permissions for: ${types.map((t) => t.toString()).join(", ")}',
          );

          // Try to check if Google Fit/Health Connect is available by attempting authorization
          // This should trigger the permission dialog
          // Note: The health package will show the Health Connect permission dialog automatically
          // if Health Connect is installed and properly configured
          granted = await _health!.requestAuthorization(types);
          print('🔵 Permission granted: $granted');

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
        granted = await _health!.requestAuthorization(types);
        print('🔵 Permission granted: $granted');

        if (!granted) {
          _updateMetrics(SyncStatus.error, platform: HealthPlatform.none);
          return false;
        }
      }

      // If we get here, permissions were granted
      if (granted) {
        _isInitialized = true;
        final platform = Platform.isIOS
            ? HealthPlatform.apple
            : HealthPlatform.google;
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
      final platformName = Platform.isIOS ? 'HealthKit' : 'Google Fit';
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
        print('📊 Today\'s steps: $steps');
      } catch (e) {
        print('⚠️ Error fetching steps: $e');
      }

      // Fetch Sleep Hours (from yesterday evening to now to catch overnight sleep)
      double sleepHours = 0.0;
      try {
        if (Platform.isAndroid) {
          // Google Fit doesn't support sleep data types, skip for Android
          print('⚠️ Sleep tracking not available in Google Fit');
        } else {
          // HealthKit sleep tracking
          final sleepTypes = [
            HealthDataType.SLEEP_IN_BED,
            HealthDataType.SLEEP_ASLEEP,
            HealthDataType.SLEEP_AWAKE,
          ];
          final sleepData = await _health!.getHealthDataFromTypes(
            types: sleepTypes,
            startTime: yesterdayEvening,
            endTime: now,
          );
          if (sleepData.isNotEmpty) {
            // Calculate total sleep in hours for today
            // Group by sleep sessions and calculate total
            for (var data in sleepData) {
              final start = data.dateFrom;
              final end = data.dateTo;
              // Only count sleep that ended today or is still ongoing
              if (end.isAfter(todayStart) || end.isAtSameMomentAs(todayStart)) {
                final sleepStart = start.isBefore(todayStart)
                    ? todayStart
                    : start;
                final duration = end.difference(sleepStart).inMinutes / 60.0;
                // Only count actual sleep (not awake time)
                if (data.type != HealthDataType.SLEEP_AWAKE) {
                  sleepHours += duration;
                }
              }
            }
          } else {
            print('⚠️ No sleep data found in HealthKit');
          }
        }
        print('📊 Today\'s sleep: ${sleepHours.toStringAsFixed(1)}h');
      } catch (e) {
        print('⚠️ Error fetching sleep: $e');
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
          final platformName = Platform.isIOS ? 'HealthKit' : 'Google Fit';
          print('⚠️ No weight data found in $platformName');
        }
      } catch (e) {
        print('⚠️ Error fetching weight: $e');
      }

      // Fetch Water Intake (today only)
      double? waterIntake;
      try {
        final waterData = await _health!.getHealthDataFromTypes(
          types: [HealthDataType.WATER],
          startTime: todayStart,
          endTime: now,
        );
        if (waterData.isNotEmpty) {
          waterIntake = waterData
              .map(
                (data) =>
                    (data.value as NumericHealthValue).numericValue.toDouble(),
              )
              .reduce((a, b) => a + b);
          print('📊 Today\'s water intake: $waterIntake L');
        } else {
          final platformName = Platform.isIOS ? 'HealthKit' : 'Google Fit';
          print('⚠️ No water intake data found in $platformName for today');
        }
      } catch (e) {
        print('⚠️ Error fetching water: $e');
      }

      // Update metrics with fetched data
      print(
        '✅ Health data synced: Steps=$steps, Sleep=${sleepHours}h, Weight=$weight kg, Water=$waterIntake L',
      );
      _updateMetrics(
        SyncStatus.success,
        steps: steps,
        sleepHours: sleepHours,
        weight: weight,
        waterIntake: waterIntake,
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
