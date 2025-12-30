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

  factory SyncLog.fromJson(Map<String, dynamic> json) {
    return SyncLog(
      status: json['status'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      error: json['error'] as String?,
      metrics: json['metrics'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'timestamp': timestamp.toIso8601String(),
      'error': error,
      'metrics': metrics,
    };
  }
}
