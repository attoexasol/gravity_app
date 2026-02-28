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

  factory NotificationLog.fromJson(Map<String, dynamic> json) {
    DateTime ts = DateTime.now();
    try {
      final t = json['timestamp'] ?? json['created_at'];
      if (t != null) ts = DateTime.tryParse(t.toString()) ?? ts;
    } catch (_) {}
    return NotificationLog(
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? json['message'] as String? ?? '',
      status: json['status'] as String? ?? 'unknown',
      timestamp: ts,
      error: json['error'] as String?,
    );
  }
}
  