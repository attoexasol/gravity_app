import 'package:flutter/material.dart';

/// Health Permission Status
enum PermissionStatus { granted, denied, restricted, notDetermined }

/// Health Permissions Model
class HealthPermissions {
  final PermissionStatus steps;
  final PermissionStatus sleep;
  final PermissionStatus heartRate;
  final DateTime? lastChecked;

  HealthPermissions({
    required this.steps,
    required this.sleep,
    required this.heartRate,
    this.lastChecked,
  });

  factory HealthPermissions.defaultPermissions() {
    return HealthPermissions(
      steps: PermissionStatus.notDetermined,
      sleep: PermissionStatus.notDetermined,
      heartRate: PermissionStatus.notDetermined,
    );
  }

  String getStatusText(PermissionStatus status) {
    switch (status) {
      case PermissionStatus.granted:
        return 'Granted';
      case PermissionStatus.denied:
        return 'Denied';
      case PermissionStatus.restricted:
        return 'Restricted';
      case PermissionStatus.notDetermined:
        return 'Not Set';
    }
  }

  Color getStatusColor(PermissionStatus status) {
    switch (status) {
      case PermissionStatus.granted:
        return const Color(0xFF00B8A9);
      case PermissionStatus.denied:
        return Colors.red;
      case PermissionStatus.restricted:
        return Colors.orange;
      case PermissionStatus.notDetermined:
        return Colors.grey;
    }
  }
}
