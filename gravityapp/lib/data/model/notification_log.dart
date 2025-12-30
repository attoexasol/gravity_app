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
  