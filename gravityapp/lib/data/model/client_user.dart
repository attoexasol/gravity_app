class ClientUser {
  final int id;
  final String name;
  final String avatar;
  final int compliance;
  final String status; // 'high', 'medium', 'low'
  final int todayScore;
  final List<String> alerts;

  ClientUser({
    required this.id,
    required this.name,
    required this.avatar,
    required this.compliance,
    required this.status,
    required this.todayScore,
    required this.alerts,
  });

  /// Optional: factory for API usage later
  factory ClientUser.fromJson(Map<String, dynamic> json) {
    return ClientUser(
      id: json['id'],
      name: json['name'],
      avatar: json['avatar'],
      compliance: json['compliance'],
      status: json['status'],
      todayScore: json['todayScore'],
      alerts: List<String>.from(json['alerts'] ?? []),
    );
  }
}
