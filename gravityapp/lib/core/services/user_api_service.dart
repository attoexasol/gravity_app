import 'package:flutter/foundation.dart';
import 'package:gravityapp/core/services/api_service.dart';
import 'package:gravityapp/data/model/message_user_model.dart';

/// Paginated result from users API.
class UsersPageResult {
  final List<MessageUserModel> users;
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;

  const UsersPageResult({
    required this.users,
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
  });

  bool get hasMore => currentPage < lastPage;
}

/// Fetches users from Laravel API for messaging inbox.
/// GET https://gravity.attoexasolutions.com/api/users with JSON body: search, role, page, per_page
class UserApiService {
  final ApiService _api = ApiService();

  /// Fetch users with pagination and optional search.
  /// GET with body: role, search, page, per_page (Laravel expects GET + body).
  Future<UsersPageResult> fetchUsers({
    required String role,
    String search = '',
    int page = 1,
    int perPage = 10,
  }) async {
    final body = <String, dynamic>{
      'role': _capitalizeRole(role),
      'page': page,
      'per_page': perPage,
    };
    if (search.trim().isNotEmpty) {
      body['search'] = search.trim();
    }

    try {
      final response = await _api.get('/users', body: body);
      return _parseResponse(response, page, perPage);
    } on ApiException catch (e) {
      if (kDebugMode) {
        debugPrint('❌ UserApiService fetchUsers: ${e.message}');
      }
      rethrow;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ UserApiService fetchUsers: $e');
      }
      rethrow;
    }
  }

  static String _capitalizeRole(String role) {
    final r = role.trim().toLowerCase();
    if (r == 'coach') return 'Coach';
    if (r == 'customer') return 'Customer';
    return role;
  }

  UsersPageResult _parseResponse(Map<String, dynamic> response, int page, int perPage) {
    List<dynamic> rawList = [];
    if (response['data'] is List) {
      rawList = response['data'] as List<dynamic>;
    } else if (response['users'] is List) {
      rawList = response['users'] as List<dynamic>;
    }

    final users = rawList.map((e) {
      final map = e is Map<String, dynamic> ? e : <String, dynamic>{};
      final id = map['id'] ?? map['user_id'];
      final idInt = id is int ? id : int.tryParse(id?.toString() ?? '0') ?? 0;
      String? profileImage = map['profile_image']?.toString();
      if (profileImage != null && profileImage.isNotEmpty && !profileImage.startsWith('http')) {
        profileImage = 'https://gravity.attoexasolutions.com/storage/$profileImage';
      }
      return MessageUserModel(
        id: idInt,
        name: (map['name'] ?? map['user_name'] ?? '').toString(),
        profileImage: profileImage,
        firebaseUid: map['firebase_uid']?.toString(),
      );
    }).toList();

    final pagination = response['pagination'] is Map ? response['pagination'] as Map<String, dynamic> : null;
    int lastPageVal = page;
    final lp = pagination?['last_page'] ?? response['last_page'] ?? response['meta']?['last_page'];
    if (lp != null) lastPageVal = (lp is int) ? lp : (lp is num) ? lp.toInt() : page;

    int totalVal = users.length;
    final tot = pagination?['total'] ?? response['total'] ?? response['meta']?['total'];
    if (tot != null) totalVal = (tot is int) ? tot : (tot is num) ? tot.toInt() : users.length;

    return UsersPageResult(
      users: users,
      currentPage: page,
      lastPage: lastPageVal,
      perPage: perPage,
      total: totalVal,
    );
  }
}
