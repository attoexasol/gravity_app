import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import '../../../core/services/preferences_service.dart';
import '../../../core/services/health_sync_service.dart'
    show HealthSyncService, HealthPlatform, SyncActivity;
import '../../../data/model/health_permissions.dart';
import '../../../data/model/notification_preferences.dart';
import '../../../data/repositories/goals_repository.dart';
import '../../../data/repositories/auth_repository.dart';

/// Sync Log Entry
class SyncLog {
  final String status;
  final DateTime timestamp;
  final String? error;
  final Map<String, dynamic>? metrics;

  SyncLog({
    required this.status,
    required this.timestamp,
    this.error,
    this.metrics,
  });
}

/// Notification Log Entry
class NotificationLog {
  final String title;
  final String body;
  final String status;
  final DateTime timestamp;
  final String? error;

  NotificationLog({
    required this.title,
    required this.body,
    required this.status,
    required this.timestamp,
    this.error,
  });
}

/// User Account Info
class UserAccountInfo {
  final String name;
  final String email;
  final String initials;

  UserAccountInfo({
    required this.name,
    required this.email,
    required this.initials,
  });

  /// Generate initials from name
  static String generateInitials(String name) {
    if (name.isEmpty) return 'U';
    final parts = name.trim().split(' ');
    if (parts.length == 1) {
      return parts[0][0].toUpperCase();
    } else {
      return (parts[0][0] + parts[parts.length - 1][0]).toUpperCase();
    }
  }
}

class SettingsController extends GetxController {
  // Services
  final HealthSyncService _healthService = HealthSyncService();
  final GoalsRepository _goalsRepository = GoalsRepository();
  final AuthRepository _authRepository = AuthRepository();

  // Notification preferences
  final Rx<NotificationPreferences> notificationPrefs =
      NotificationPreferences().obs;

  // Health permissions
  final Rx<HealthPermissions> healthPermissions =
      HealthPermissions.defaultPermissions().obs;

  // UI State
  final RxBool showGoalsEditor = false.obs;
  final RxBool showSyncLogs = false.obs;
  final RxBool showNotificationLogs = false.obs;
  final RxBool isCheckingPermissions = false.obs;
  final RxBool aiFeatures = true.obs;
  final RxBool isLoadingGoals = false.obs;

  // Goals
  final RxMap<String, String> goals = <String, String>{
    'currentWeight': '75',
    'targetWeight': '70',
    'stepGoal': '12000',
    'waterIntake': '3',
    'sleepHours': '7-8',
  }.obs;

  // Sync logs
  final RxList<SyncLog> syncLogs = <SyncLog>[].obs;

  // Notification logs
  final RxList<NotificationLog> notificationLogs = <NotificationLog>[].obs;

  // User account info
  final Rx<UserAccountInfo> user = UserAccountInfo(
    name: 'User',
    email: 'user@example.com',
    initials: 'U',
  ).obs;

  @override
  void onInit() {
    super.onInit();
    _loadUserData();
    _loadSettings();
    _loadGoals();
    _fetchGoalsFromAPI();
    _initializeHealthPermissions();
    _loadSyncLogs();
    _subscribeToSyncActivity();
  }

  /// Load user data from storage
  void _loadUserData() {
    final userName = PreferencesService.getUserName() ?? 'User';
    final userEmail = PreferencesService.getUserEmail() ?? 'user@example.com';
    final userInitials = UserAccountInfo.generateInitials(userName);

    user.value = UserAccountInfo(
      name: userName,
      email: userEmail,
      initials: userInitials,
    );
  }

  /// Load settings from storage
  void _loadSettings() {
    // Load notification preferences from storage
    final savedNotifPrefs = PreferencesService.getStorage().read(
      'notification_preferences',
    );
    if (savedNotifPrefs != null) {
      try {
        final prefsMap = jsonDecode(savedNotifPrefs) as Map<String, dynamic>;
        notificationPrefs.value = NotificationPreferences(
          enabled: prefsMap['enabled'] ?? false,
          hydration: prefsMap['hydration'] ?? true,
          meals: prefsMap['meals'] ?? true,
          sleep: prefsMap['sleep'] ?? true,
          exercise: prefsMap['exercise'] ?? true,
          dailySummary: prefsMap['dailySummary'] ?? true,
          weeklySummary: prefsMap['weeklySummary'] ?? true,
          quietHoursEnabled: prefsMap['quietHoursEnabled'] ?? false,
          quietHoursStart: prefsMap['quietHoursStart'] ?? '10:00 PM',
          quietHoursEnd: prefsMap['quietHoursEnd'] ?? '8:00 AM',
        );
      } catch (e) {
        debugPrint('Error loading notification preferences: $e');
      }
    }

    // Load AI features setting
    final aiFeaturesValue = PreferencesService.getStorage().read('ai_features');
    if (aiFeaturesValue != null) {
      aiFeatures.value = aiFeaturesValue as bool;
    }
  }

  /// Load goals from storage
  void _loadGoals() {
    final savedGoals = PreferencesService.getStorage().read('userGoals');
    if (savedGoals != null) {
      try {
        final goalsMap = jsonDecode(savedGoals) as Map<String, dynamic>;
        goals.value = {
          'currentWeight': goalsMap['currentWeight']?.toString() ?? '75',
          'targetWeight': goalsMap['targetWeight']?.toString() ?? '70',
          'stepGoal': goalsMap['stepGoal']?.toString() ?? '12000',
          'waterIntake': goalsMap['waterIntake']?.toString() ?? '3',
          'sleepHours': goalsMap['sleepHours']?.toString() ?? '7-8',
        };
      } catch (e) {
        debugPrint('Error loading goals: $e');
      }
    }
  }

  /// Fetch goals from API
  Future<void> _fetchGoalsFromAPI() async {
    try {
      isLoadingGoals.value = true;

      // Get token from storage
      final token = PreferencesService.getAuthToken();
      if (token == null || token.isEmpty) {
        debugPrint('⚠️ Token not found, skipping API fetch');
        // Keep existing goals from storage if token is missing
        return;
      }

      final response = await _goalsRepository.getSingleGoal(token: token);

      if (response.isSuccess && response.data != null) {
        final goalData = response.data!;

        // Map API response to goals format
        // Remove "L" from water intake if present for display
        final waterIntake = goalData['daily_water_intake']?.toString() ?? '3';
        final waterIntakeValue = waterIntake
            .replaceAll('L', '')
            .replaceAll('l', '')
            .trim();

        goals.value = {
          'currentWeight': goalData['current_weight']?.toString() ?? '75',
          'targetWeight': goalData['target_weight']?.toString() ?? '70',
          'stepGoal': goalData['step_goal']?.toString() ?? '12000',
          'waterIntake': waterIntakeValue,
          'sleepHours': goalData['sleep_hours']?.toString() ?? '7-8',
        };

        // Also save to local storage
        final goalsMap = Map<String, String>.from(goals);
        PreferencesService.getStorage().write(
          'userGoals',
          jsonEncode(goalsMap),
        );

        debugPrint('✅ Goals loaded from API: $goalsMap');
      } else {
        debugPrint('⚠️ Failed to load goals from API: ${response.message}');
        // Keep existing goals from storage if API fails
      }
    } catch (e) {
      debugPrint('❌ Error fetching goals from API: $e');
      // Keep existing goals from storage if API fails
    } finally {
      isLoadingGoals.value = false;
    }
  }

  /// Initialize health permissions
  void _initializeHealthPermissions() {
    // Check current permissions
    healthPermissions.value = HealthPermissions(
      steps: PermissionStatus.granted, // Default for now
      sleep: PermissionStatus.granted,
      heartRate: PermissionStatus.granted,
      lastChecked: DateTime.now(),
    );
  }

  /// Recheck health permissions
  Future<void> recheckPermissions() async {
    isCheckingPermissions.value = true;
    try {
      // Simulate permission check
      await Future.delayed(const Duration(seconds: 1));

      healthPermissions.value = HealthPermissions(
        steps: PermissionStatus.granted,
        sleep: PermissionStatus.granted,
        heartRate: PermissionStatus.granted,
        lastChecked: DateTime.now(),
      );
    } catch (e) {
      debugPrint('Error checking permissions: $e');
    } finally {
      isCheckingPermissions.value = false;
    }
  }

  /// Toggle notification preference
  void toggleNotificationPreference(String key, bool value) {
    final current = notificationPrefs.value;
    NotificationPreferences updated;

    switch (key) {
      case 'enabled':
        updated = current.copyWith(enabled: value);
        break;
      case 'hydration':
        updated = current.copyWith(hydration: value);
        break;
      case 'meals':
        updated = current.copyWith(meals: value);
        break;
      case 'sleep':
        updated = current.copyWith(sleep: value);
        break;
      case 'exercise':
        updated = current.copyWith(exercise: value);
        break;
      case 'dailySummary':
        updated = current.copyWith(dailySummary: value);
        break;
      case 'weeklySummary':
        updated = current.copyWith(weeklySummary: value);
        break;
      case 'quietHoursEnabled':
        updated = current.copyWith(quietHoursEnabled: value);
        break;
      default:
        updated = current;
    }

    notificationPrefs.value = updated;
    _saveNotificationPreferences();
  }

  /// Save notification preferences
  void _saveNotificationPreferences() {
    final prefs = notificationPrefs.value;
    final prefsMap = {
      'enabled': prefs.enabled,
      'hydration': prefs.hydration,
      'meals': prefs.meals,
      'sleep': prefs.sleep,
      'exercise': prefs.exercise,
      'dailySummary': prefs.dailySummary,
      'weeklySummary': prefs.weeklySummary,
      'quietHoursEnabled': prefs.quietHoursEnabled,
      'quietHoursStart': prefs.quietHoursStart,
      'quietHoursEnd': prefs.quietHoursEnd,
    };
    PreferencesService.getStorage().write(
      'notification_preferences',
      jsonEncode(prefsMap),
    );
  }

  /// Enable notifications
  Future<void> enableNotifications() async {
    // Request notification permission
    // TODO: Implement actual notification permission request
    toggleNotificationPreference('enabled', true);
  }

  /// Save goals
  Future<void> saveGoals() async {
    try {
      isLoadingGoals.value = true;

      // Save to local storage first
      final goalsMap = Map<String, String>.from(goals);
      PreferencesService.getStorage().write('userGoals', jsonEncode(goalsMap));

      // Get token from storage
      final token = PreferencesService.getAuthToken();
      if (token == null || token.isEmpty) {
        Get.snackbar(
          'Error',
          'Authentication token not found. Please login again.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Get.theme.colorScheme.error,
          colorText: Get.theme.colorScheme.onError,
          duration: const Duration(seconds: 4),
        );
        return;
      }

      // Prepare water intake with "L" suffix for API
      final waterIntake = goals['waterIntake'] ?? '3';
      final waterIntakeWithUnit =
          waterIntake.endsWith('L') || waterIntake.endsWith('l')
          ? waterIntake
          : '$waterIntake L';

      // Save to API
      final response = await _goalsRepository.createGoals(
        token: token,
        currentWeight: goals['currentWeight'] ?? '75',
        targetWeight: goals['targetWeight'] ?? '70',
        stepGoal: goals['stepGoal'] ?? '12000',
        dailyWaterIntake: waterIntakeWithUnit,
        sleepHours: goals['sleepHours'] ?? '7-8',
      );

      if (response.isSuccess) {
        showGoalsEditor.value = false;
        Get.snackbar(
          'Success',
          'Goals saved successfully',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFF00B8A9),
          colorText: Colors.white,
        );
      } else {
        Get.snackbar(
          'Warning',
          'Goals saved locally but failed to sync with server',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      debugPrint('❌ Error saving goals: $e');
      Get.snackbar(
        'Error',
        'Failed to save goals. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
      );
    } finally {
      isLoadingGoals.value = false;
    }
  }

  /// Toggle AI features
  void toggleAiFeatures(bool value) {
    aiFeatures.value = value;
    PreferencesService.getStorage().write('ai_features', value);
  }

  /// Get platform name
  String getPlatformName() {
    final platform = _healthService.getMetrics().platform;
    switch (platform) {
      case HealthPlatform.apple:
        return 'Apple Health';
      case HealthPlatform.google:
        return 'Google Fit';
      case HealthPlatform.none:
        return 'Health App';
    }
  }

  /// Load sync logs from storage
  void _loadSyncLogs() {
    try {
      final savedLogs = PreferencesService.getStorage().read('sync_logs');
      if (savedLogs != null) {
        final logsList = jsonDecode(savedLogs) as List<dynamic>;
        syncLogs.value = logsList
            .map((log) => SyncLog(
                  status: log['status'] as String,
                  timestamp: DateTime.parse(log['timestamp'] as String),
                  error: log['error'] as String?,
                  metrics: log['metrics'] as Map<String, dynamic>?,
                ))
            .toList();
        // Sort by timestamp (newest first)
        syncLogs.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      }
    } catch (e) {
      debugPrint('Error loading sync logs: $e');
    }
  }

  /// Save sync logs to storage
  void _saveSyncLogs() {
    try {
      final logsJson = syncLogs
          .map((log) => {
                'status': log.status,
                'timestamp': log.timestamp.toIso8601String(),
                'error': log.error,
                'metrics': log.metrics,
              })
          .toList();
      PreferencesService.getStorage().write('sync_logs', jsonEncode(logsJson));
    } catch (e) {
      debugPrint('Error saving sync logs: $e');
    }
  }

  /// Subscribe to sync activity from HealthSyncService
  void _subscribeToSyncActivity() {
    _healthService.subscribeToSyncActivity((SyncActivity activity) {
      // Convert SyncActivity to SyncLog
      final log = SyncLog(
        status: activity.status,
        timestamp: activity.timestamp,
        error: activity.error,
        metrics: activity.metrics,
      );
      // Add to beginning of list
      syncLogs.insert(0, log);
      // Keep only last 50 logs
      if (syncLogs.length > 50) {
        syncLogs.removeRange(50, syncLogs.length);
      }
      // Save to storage
      _saveSyncLogs();
    });
  }

  /// Get sync logs
  List<SyncLog> getSyncLogs() {
    return syncLogs.toList();
  }

  /// Get notification logs
  List<NotificationLog> getNotificationLogs() {
    // Return mock logs for now
    return notificationLogs.toList();
  }

  /// Navigate back
  void navigateBack() {
    Get.back();
  }

  /// Handle logout - calls API, clears all storage data and navigates to login
  Future<void> handleLogout() async {
    final confirmed = await Get.dialog<bool>(
      _buildLogoutDialog(),
      barrierDismissible: true,
    );

    if (confirmed == true) {
      try {
        // Get token from storage
        final token = PreferencesService.getAuthToken();

        // Call logout API if token exists
        if (token != null && token.isNotEmpty) {
          final response = await _authRepository.logout(token: token);

          if (!response.isSuccess) {
            debugPrint('⚠️ Logout API call failed: ${response.message}');
            // Continue with logout even if API call fails
          }
        }

        // Clear all storage data (token, user data, preferences, etc.)
        await PreferencesService.clearAll();

        // Navigate to login screen and clear navigation stack
        Get.offAllNamed('/login');
      } catch (e) {
        debugPrint('❌ Logout Error: $e');

        // Even if API call fails, clear local data and logout
        try {
          await PreferencesService.clearAll();
          Get.offAllNamed('/login');
        } catch (clearError) {
          debugPrint('❌ Error clearing storage: $clearError');
          Get.snackbar(
            'Error',
            'Failed to logout. Please try again.',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Get.theme.colorScheme.error,
            colorText: Get.theme.colorScheme.onError,
          );
        }
      }
    }
  }

  /// Build logout confirmation dialog
  Widget _buildLogoutDialog() {
    return AlertDialog(
      title: const Text('Logout'),
      content: const Text(
        'Are you sure you want to logout? All your data will be cleared.',
      ),
      actions: [
        TextButton(
          onPressed: () => Get.back(result: false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Get.back(result: true),
          style: TextButton.styleFrom(foregroundColor: const Color(0xFF00B8A9)),
          child: const Text('Logout'),
        ),
      ],
    );
  }
}
