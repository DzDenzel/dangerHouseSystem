/// 异步数据加载状态封装
class SimpleState<T> {
  /// 数据
  final T? data;

  /// 是否正在加载
  final bool isLoading;

  /// 错误消息
  final String? error;

  const SimpleState({
    this.data,
    this.isLoading = false,
    this.error,
  });

  /// 创建初始状态
  const SimpleState.initial()
      : data = null,
        isLoading = false,
        error = null;

  /// 创建加载中状态
  const SimpleState.loading()
      : data = null,
        isLoading = true,
        error = null;

  /// 创建成功状态
  SimpleState.data(T data)
      : data = data,
        isLoading = false,
        error = null;

  /// 创建错误状态
  SimpleState.error(String error)
      : data = null,
        isLoading = false,
        error = error;

  /// 是否有数据
  bool get hasData => data != null;

  /// 是否有错误
  bool get hasError => error != null;

  /// 复制状态
  ///
  /// [clearError] / [clearData] 用于把字段显式置空（传 null 表示保持原值）。
  SimpleState<T> copyWith({
    T? data,
    bool? isLoading,
    String? error,
    bool clearError = false,
    bool clearData = false,
  }) {
    return SimpleState<T>(
      data: clearData ? null : (data ?? this.data),
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  String toString() {
    return 'SimpleState(data: $data, isLoading: $isLoading, error: $error)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SimpleState<T> &&
        other.data == data &&
        other.isLoading == isLoading &&
        other.error == error;
  }

  @override
  int get hashCode => Object.hash(data, isLoading, error);
}
