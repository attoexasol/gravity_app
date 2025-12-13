/// Generic API Response Model
class ApiResponse<T> {
  final bool status;
  final String message;
  final T? data;
  final dynamic error;

  ApiResponse({
    required this.status,
    required this.message,
    this.data,
    this.error,
  });

  factory ApiResponse.fromJson(
      Map<String, dynamic> json,
      T Function(dynamic)? fromJsonT,
      ) {
    return ApiResponse<T>(
      status: json['status'] ?? false,
      message: json['message'] ?? '',
      data: fromJsonT != null && json['data'] != null
          ? fromJsonT(json['data'])
          : null,
      error: json['error'],
    );
  }

  bool get isSuccess => status == true;
  bool get isError => status == false;
}