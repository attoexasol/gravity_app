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
  /// Single-flight: prevent overlapping syncHealthData() runs (avoids duplicate success emissions).
  bool _syncInProgress = false;

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
      // READ for STEPS; READ_WRITE for WEIGHT, WATER, sleep (so manual entry can write to health store)
      final essentialTypes = (!kIsWeb && Platform.isAndroid)
          ? [
              HealthDataType.STEPS,
              HealthDataType.WEIGHT,
              HealthDataType.WATER,
            ]
          : [
              HealthDataType.STEPS,
              HealthDataType.SLEEP_ASLEEP,
              HealthDataType.WEIGHT,
              HealthDataType.WATER,
            ];
      final essentialPermissions = (!kIsWeb && Platform.isAndroid)
          ? [
              HealthDataAccess.READ,       // STEPS
              HealthDataAccess.READ_WRITE, // WEIGHT
              HealthDataAccess.READ_WRITE, // WATER
            ]
          : [
              HealthDataAccess.READ,       // STEPS
              HealthDataAccess.READ_WRITE, // SLEEP_ASLEEP
              HealthDataAccess.READ_WRITE, // WEIGHT
              HealthDataAccess.READ_WRITE, // WATER
            ];

      // Sleep types for Android (requested separately as optional)
      final sleepTypes = (!kIsWeb && Platform.isAndroid)
          ? [HealthDataType.SLEEP_SESSION]
          : [HealthDataType.SLEEP_ASLEEP];
      final sleepPermissions = [HealthDataAccess.READ_WRITE];

      print('🔵 Requesting $platformName permissions...');

      bool granted = false;

      // On Android, check if we can actually request authorization
      if (!kIsWeb && Platform.isAndroid) {
        try {
          print(
            '🔵 Attempting to request Health Connect authorization...',
          );
          print(
            '🔵 Requesting essential permissions (READ_WRITE for weight/water): ${essentialTypes.map((t) => t.toString()).join(", ")}',
          );

          granted = await _health!.requestAuthorization(essentialTypes, permissions: essentialPermissions);
          print('🔵 Essential permissions granted: $granted');

          if (!granted) {
            print(
              '⚠️ Health Connect authorization was denied or not available',
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
            print('🔵 Requesting optional sleep permissions (READ_WRITE)...');
            final sleepGranted = await _health!.requestAuthorization(sleepTypes, permissions: sleepPermissions);
            print('🔵 Sleep permissions granted: $sleepGranted');
            if (!sleepGranted) {
              print('⚠️ Sleep permissions not available - will continue without sleep data');
            }
          } catch (e) {
            print('⚠️ Could not request sleep permissions: $e - will continue without sleep data');
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
        // For iOS, request all permissions at once (READ_WRITE for weight, water, sleep)
        granted = await _health!.requestAuthorization(essentialTypes, permissions: essentialPermissions);
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

        // Set platform and "syncing" so UI has platform; do NOT emit success here (would trigger
        // upsertTodayGravity before real data is fetched). Only syncHealthData() emits success.
        _updateMetrics(SyncStatus.syncing, platform: platform);
        _recordSyncActivity(
          status: 'syncing',
          error: null,
          metrics: {'action': 'initialization', 'platform': platform.name},
        );
        // Fetch initial data; syncHealthData() will emit success when done
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

  /// Sleep uses REPLACE strategy, not merge or sum.
  /// Deletes all sleep records in the overnight window for the given date (Health Connect / Apple Health)
  /// so that writeSleepHours can insert the only session for that day.
  Future<bool> _deleteSleepForDate(DateTime date) async {
    if (kIsWeb || _health == null || !_isInitialized) return false;
    try {
      // Same window as sync query: yesterday 18:00 to date 12:00 (overnight sleep for this date)
      final rangeStart = DateTime(date.year, date.month, date.day - 1, 18);
      final rangeEnd = DateTime(date.year, date.month, date.day, 12);
      final type = (!kIsWeb && Platform.isAndroid)
          ? HealthDataType.SLEEP_SESSION
          : HealthDataType.SLEEP_ASLEEP;
      final deleted = await _health!.delete(
        type: type,
        startTime: rangeStart,
        endTime: rangeEnd,
      );
      if (deleted) {
        print('🔄 Sleep REPLACE: deleted existing sleep in range $rangeStart → $rangeEnd');
      }
      return deleted;
    } catch (e) {
      print('⚠️ Error deleting sleep for date: $e');
      return false;
    }
  }

  /// Sync health data from HealthKit (iOS) or Google Fit (Android)
  /// Single-flight: if a sync is already in progress, this call is skipped to avoid duplicate success emissions.
  Future<void> syncHealthData() async {
    if (kIsWeb) {
      print('⚠️ Health data syncing is not available on web');
      return;
    }

    if (_syncInProgress) {
      print('⏳ Sync already in progress, skipping duplicate call');
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

    _syncInProgress = true;
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

      // Sleep uses REPLACE strategy: single session only. Never sum, merge, or accumulate.
      // Query window must include: overnight (yesterday 18:00 → today) and any session logged today.
      // Use end = now so afternoon/evening sessions and late-logged overnight sleep are included.
      double sleepHours = 0.0;
      try {
        final sleepQueryStart = DateTime(now.year, now.month, now.day - 1, 18);
        final sleepQueryEnd = now;
        final sleepTypes = (!kIsWeb && Platform.isAndroid)
            ? [HealthDataType.SLEEP_SESSION]
            : [HealthDataType.SLEEP_ASLEEP];
        final platformName = Platform.isIOS ? 'HealthKit' : 'Health Connect';
        print('🔵 Sleep query: $platformName from $sleepQueryStart to $sleepQueryEnd (sessions spanning midnight included)');
        final sleepData = await _health!.getHealthDataFromTypes(
          types: sleepTypes,
          startTime: sleepQueryStart,
          endTime: sleepQueryEnd,
        );
        print('🔵 Sleep data query returned ${sleepData.length} data points');
        if (sleepData.isNotEmpty) {
          sleepData.sort((a, b) => b.dateTo.compareTo(a.dateTo));
          final session = sleepData.first;
          sleepHours = session.dateTo.difference(session.dateFrom).inMinutes / 60.0;
          print('📊 Sleep for dashboard: duration = ${sleepHours.toStringAsFixed(1)}h (${session.dateFrom} → ${session.dateTo})');
        } else {
          print('⚠️ No sleep data found in $platformName for query window');
        }
      } catch (e, stackTrace) {
        print('⚠️ Error fetching sleep: $e');
        print('   Stack trace: $stackTrace');
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
    } finally {
      _syncInProgress = false;
    }
  }

  /// Write weight (kg) to device health store. Returns false on web/unsupported or on error.
  Future<bool> writeWeightKg(double kg, {DateTime? at}) async {
    if (kIsWeb || (!Platform.isIOS && !Platform.isAndroid)) return false;
    if (_health == null || !_isInitialized) {
      final ok = await initialize();
      if (!ok || _health == null) return false;
    }
    try {
      final when = at ?? DateTime.now();
      final success = await _health!.writeHealthData(
        value: kg,
        type: HealthDataType.WEIGHT,
        startTime: when,
        endTime: when,
        unit: HealthDataUnit.KILOGRAM,
        recordingMethod: RecordingMethod.manual,
      );
      if (success) print('✅ Wrote weight to health store: $kg kg');
      return success;
    } catch (e) {
      print('⚠️ Error writing weight to health store: $e');
      return false;
    }
  }

  /// Best-effort, experimental: attempt to write hydration to Google Fit / Health Connect.
  /// Google Fit / Health Connect hydration write is unreliable by platform design; it may not
  /// appear in Google Fit UI. Failure must NOT break the app. Gravity local data is the
  /// source of truth; dashboard must use local data only.
  /// Uses short time range (event-based record). No retry. Silent failure on error.
  Future<bool> writeWaterLiters(double liters, {DateTime? at}) async {
    if (kIsWeb || (!Platform.isIOS && !Platform.isAndroid)) return false;
    if (liters <= 0) return true;
    try {
      if (_health == null || !_isInitialized) {
        final ok = await initialize();
        if (!ok || _health == null) return false;
      }
    } catch (e) {
      print('⚠️ Hydration write (best-effort): init failed, skipping — $e');
      return false;
    }
    final end = at ?? DateTime.now();
    final start = end.subtract(const Duration(minutes: 2));
    final ml = (liters * 1000).round();
    try {
      final successMl = await _health!.writeHealthData(
        value: ml.toDouble(),
        type: HealthDataType.WATER,
        startTime: start,
        endTime: end,
        unit: HealthDataUnit.MILLILITER,
        recordingMethod: RecordingMethod.manual,
      );
      if (successMl) {
        print('✅ Hydration (best-effort): wrote $liters L ($ml ml) to health store');
        return true;
      }
    } catch (e) {
      print('⚠️ Hydration write (best-effort): MILLILITER failed, trying LITER — $e');
    }
    try {
      final successL = await _health!.writeHealthData(
        value: liters,
        type: HealthDataType.WATER,
        startTime: start,
        endTime: end,
        unit: HealthDataUnit.LITER,
        recordingMethod: RecordingMethod.manual,
      );
      if (successL) {
        print('✅ Hydration (best-effort): wrote $liters L to health store');
        return true;
      }
    } catch (e) {
      print('⚠️ Hydration write (best-effort): LITER failed — $e');
    }
    return false;
  }

  /// Sleep uses REPLACE strategy, not merge or sum.
  /// 1) DELETE existing sleep for the same date (Health Connect / Apple Health).
  /// 2) INSERT only the new session. New sleep is the ONLY record for that day.
  Future<bool> writeSleepHours(double hours, {DateTime? endAt}) async {
    if (kIsWeb || (!Platform.isIOS && !Platform.isAndroid)) return false;
    if (_health == null || !_isInitialized) {
      final ok = await initialize();
      if (!ok || _health == null) return false;
    }
    if (hours <= 0) return true;
    try {
      final end = endAt ?? DateTime.now();
      final start = end.subtract(Duration(seconds: (hours * 3600).round().clamp(0, 86400 * 365)));
      // Step 1: Delete existing sleep for this date (confirm deletion before insert)
      await _deleteSleepForDate(end);
      // Step 2: Insert only the new session (single record for that day)
      final type = (!kIsWeb && Platform.isAndroid)
          ? HealthDataType.SLEEP_SESSION
          : HealthDataType.SLEEP_ASLEEP;
      final success = await _health!.writeHealthData(
        value: 0,
        type: type,
        startTime: start,
        endTime: end,
        recordingMethod: RecordingMethod.manual,
      );
      if (success) {
        print('✅ Sleep REPLACE: inserted only session $hours h ($start → $end)');
      }
      return success;
    } catch (e) {
      print('⚠️ Error writing sleep to health store: $e');
      return false;
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
