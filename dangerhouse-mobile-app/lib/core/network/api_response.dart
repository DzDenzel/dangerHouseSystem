class ApiResponse<T> {
  final int code;
  final String? message;
  final T? data;

  const ApiResponse({
    required this.code,
    this.message,
    this.data,
  });

  bool get isSuccess => code == 0 || code == 200;

  String get errorMessage => message ?? '请求失败';

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object? json)? fromJsonT,
  ) {
    return ApiResponse<T>(
      code: json['code'] as int? ?? -1,
      message: json['message'] as String?,
      data: json['data'] != null && fromJsonT != null
          ? fromJsonT(json['data'])
          : null,
    );
  }

  Map<String, dynamic> toJson(Object? Function(T value)? toJsonT) {
    return {
      'code': code,
      'message': message,
      'data': data != null && toJsonT != null ? toJsonT(data as T) : data,
    };
  }

  static ApiResponse<T> success<T>(T data, {String? message}) {
    return ApiResponse<T>(code: 200, message: message, data: data);
  }

  static ApiResponse<T> failure<T>(String message, {int code = -1}) {
    return ApiResponse<T>(code: code, message: message);
  }
}

class PaginatedResponse<T> {
  final List<T> records;
  final int total;
  final int page;
  final int size;
  final int pages;

  const PaginatedResponse({
    required this.records,
    required this.total,
    required this.page,
    required this.size,
    required this.pages,
  });

  bool get isEmpty => records.isEmpty;
  bool get isNotEmpty => records.isNotEmpty;
  bool get hasNextPage => page < pages;

  factory PaginatedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object? json) fromJsonT,
  ) {
    final recordsList = json['records'] as List<dynamic>? ?? [];
    return PaginatedResponse<T>(
      records: recordsList.map((e) => fromJsonT(e)).toList(),
      total: json['total'] as int? ?? 0,
      page: json['page'] as int? ?? 1,
      size: json['size'] as int? ?? 10,
      pages: json['pages'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson(Object? Function(T value) toJsonT) {
    return {
      'records': records.map((e) => toJsonT(e)).toList(),
      'total': total,
      'page': page,
      'size': size,
      'pages': pages,
    };
  }

  static PaginatedResponse<T> empty<T>() {
    return PaginatedResponse<T>(
      records: [],
      total: 0,
      page: 1,
      size: 10,
      pages: 0,
    );
  }
}

class ApiResult<T> {
  final T? data;
  final String? errorMessage;
  final bool isSuccess;
  final int? statusCode;

  const ApiResult._({
    this.data,
    this.errorMessage,
    required this.isSuccess,
    this.statusCode,
  });

  const ApiResult.success(T data, {int? statusCode})
      : data = data,
        errorMessage = null,
        isSuccess = true,
        statusCode = statusCode;

  const ApiResult.failure(String message, {int? statusCode})
      : data = null,
        errorMessage = message,
        isSuccess = false,
        statusCode = statusCode;

  R when<R>({
    required R Function(T data) success,
    required R Function(String message, int? statusCode) failure,
  }) {
    if (isSuccess && data != null) {
      return success(data as T);
    }
    return failure(errorMessage ?? '未知错误', statusCode);
  }

  T getOrElse(T defaultValue) {
    return isSuccess ? (data ?? defaultValue) : defaultValue;
  }

  T? getOrNull() => isSuccess ? data : null;
}
