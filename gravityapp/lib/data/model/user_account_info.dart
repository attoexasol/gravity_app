class UserAccountInfo {
  final String name;
  final String email;
  final String initials;
  final String? profileImagePath;

  UserAccountInfo({
    required this.name,
    required this.email,
    required this.initials,
    this.profileImagePath,
  });

  static String generateInitials(String name) {
    if (name.isEmpty) return 'U';
    final parts = name.trim().split(' ');
    if (parts.length == 1) {
      return parts[0][0].toUpperCase();
    } else {
      return (parts[0][0] + parts[parts.length - 1][0]).toUpperCase();
    }
  }
  UserAccountInfo copyWith({
    String? name,
    String? email,
    String? initials,
    String? profileImagePath,
  }) {
    return UserAccountInfo(
      name: name ?? this.name,
      email: email ?? this.email,
      initials: initials ?? this.initials,
      profileImagePath: profileImagePath ?? this.profileImagePath,
    );
  }
}
