/// User Model - Matches API response structure
class UserModel {
  final int id;
  final String name;
  final String email;
  final String phone;
  final String? profileImage;
  final String role;
  final String registrationDate;
  final String lastActive;
  final String updatedAt;
  final String createdAt;
  /// Firebase custom token for signInWithCustomToken (from Laravel login).
  /// Prefer API field name firebase_custom_token; fallback fcm_token for backward compat.
  final String? firebaseCustomToken;
  /// Firebase UID for other users (e.g. from all_users). Used to build conversationId.
  final String? firebaseUid;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.profileImage,
    required this.role,
    required this.registrationDate,
    required this.lastActive,
    required this.updatedAt,
    required this.createdAt,
    this.firebaseCustomToken,
    this.firebaseUid,
  });

  /// Create UserModel from JSON
  factory UserModel.fromJson(Map<String, dynamic> json) {
    final token = json['firebase_custom_token'] as String? ?? json['fcm_token'] as String?;
    return UserModel(
      id: json['id'] ?? json['user_id'] ?? 0, // Support both 'id' and 'user_id'
      name: json['name'] ?? json['user_name'] ?? '', // Support both 'name' and 'user_name'
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      profileImage: json['profile_image'],
      role: json['role'] ?? '',
      registrationDate: json['registration_date'] ?? '',
      lastActive: json['last_active'] ?? '',
      updatedAt: json['updated_at'] ?? '',
      createdAt: json['created_at'] ?? '',
      firebaseCustomToken: token,
      firebaseUid: json['firebase_uid'] as String?,
    );
  }

  /// Convert UserModel to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'profile_image': profileImage,
      'role': role,
      'registration_date': registrationDate,
      'last_active': lastActive,
      'updated_at': updatedAt,
      'created_at': createdAt,
      if (firebaseCustomToken != null) 'firebase_custom_token': firebaseCustomToken,
      if (firebaseUid != null) 'firebase_uid': firebaseUid,
    };
  }

  /// Create a copy with updated fields
  UserModel copyWith({
    int? id,
    String? name,
    String? email,
    String? phone,
    String? profileImage,
    String? role,
    String? registrationDate,
    String? lastActive,
    String? updatedAt,
    String? createdAt,
    String? firebaseCustomToken,
    String? firebaseUid,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      profileImage: profileImage ?? this.profileImage,
      role: role ?? this.role,
      registrationDate: registrationDate ?? this.registrationDate,
      lastActive: lastActive ?? this.lastActive,
      updatedAt: updatedAt ?? this.updatedAt,
      createdAt: createdAt ?? this.createdAt,
      firebaseCustomToken: firebaseCustomToken ?? this.firebaseCustomToken,
      firebaseUid: firebaseUid ?? this.firebaseUid,
    );
  }
}