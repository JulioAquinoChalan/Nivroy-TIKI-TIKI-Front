class ApiResponse<T> {
  const ApiResponse({
    required this.success,
    required this.message,
    required this.data,
    required this.error,
    required this.meta,
    required this.timestamp,
  });

  final bool success;
  final String message;
  final T? data;
  final ApiError? error;
  final ApiMeta? meta;
  final String timestamp;

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T? Function(Object? value) parseData,
  ) {
    final error = json['error'];
    final meta = json['meta'];

    return ApiResponse<T>(
      success: json['success'] == true,
      message: json['message']?.toString() ?? '',
      data: parseData(json['data']),
      error: error is Map<String, dynamic> ? ApiError.fromJson(error) : null,
      meta: meta is Map<String, dynamic> ? ApiMeta.fromJson(meta) : null,
      timestamp: json['timestamp']?.toString() ?? '',
    );
  }

  String fallbackErrorMessage(int statusCode) {
    final detail = error?.detail.trim() ?? '';
    if (detail.isNotEmpty) {
      return detail;
    }

    final responseMessage = message.trim();
    if (responseMessage.isNotEmpty) {
      return responseMessage;
    }

    return 'Backend returned $statusCode';
  }
}

class ApiError {
  const ApiError({required this.code, required this.detail});

  final int code;
  final String detail;

  factory ApiError.fromJson(Map<String, dynamic> json) {
    return ApiError(
      code: int.tryParse(json['code']?.toString() ?? '') ?? 0,
      detail: json['detail']?.toString() ?? '',
    );
  }
}

class ApiMeta {
  const ApiMeta({
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });

  final int? page;
  final int? limit;
  final int? total;
  final int? totalPages;

  factory ApiMeta.fromJson(Map<String, dynamic> json) {
    return ApiMeta(
      page: int.tryParse(json['page']?.toString() ?? ''),
      limit: int.tryParse(json['limit']?.toString() ?? ''),
      total: int.tryParse(json['total']?.toString() ?? ''),
      totalPages: int.tryParse(json['totalPages']?.toString() ?? ''),
    );
  }
}
