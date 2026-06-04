/// 基础状态类
///
/// 用于管理异步数据加载状态的通用状态类。
/// 包含数据、加载状态、错误信息等。
///
/// 类型参数:
/// - [T] 数据类型
///
/// 状态类型:
/// - 初始状态: [BaseState.initial]
/// - 加载中: [BaseState.loading]
/// - 成功: [BaseState.data]
/// - 失败: [BaseState.error]
///
/// 示例:
/// ```dart
/// final state = BaseState<User>.loading();
/// state.when(
///   initial: () => Text('初始状态'),
///   loading: () => CircularProgressIndicator(),
///   data: (user) => Text(user.name),
///   error: (msg, _, __) => Text(msg),
///   orElse: () => SizedBox(),
/// );
/// ```
class BaseState<T> {
  /// 数据
  final T? data;

  /// 是否正在加载
  final bool isLoading;

  /// 错误消息
  final String? error;

  /// 原始错误对象
  final Object? originalError;

  /// 堆栈跟踪
  final StackTrace? stackTrace;

  /// 创建状态
  const BaseState({
    this.data,
    this.isLoading = false,
    this.error,
    this.originalError,
    this.stackTrace,
  });

  /// 创建初始状态
  const BaseState.initial()
      : data = null,
        isLoading = false,
        error = null,
        originalError = null,
        stackTrace = null;

  /// 创建加载中状态
  const BaseState.loading()
      : data = null,
        isLoading = true,
        error = null,
        originalError = null,
        stackTrace = null;

  /// 创建成功状态
  ///
  /// [data] 成功数据
  BaseState.data(T data)
      : data = data,
        isLoading = false,
        error = null,
        originalError = null,
        stackTrace = null;

  /// 创建错误状态
  ///
  /// [message] 错误消息
  /// [error] 原始错误对象（可选）
  /// [stackTrace] 堆栈跟踪（可选）
  BaseState.error(
    String message, {
    Object? error,
    StackTrace? stackTrace,
  })  : data = null,
        isLoading = false,
        error = message,
        originalError = error,
        stackTrace = stackTrace;

  /// 是否有数据
  bool get hasData => data != null;

  /// 是否有错误
  bool get hasError => error != null;

  /// 是否为初始状态
  bool get isInitial => !isLoading && !hasData && !hasError;

  /// 复制状态
  ///
  /// [data] 新数据
  /// [isLoading] 加载状态
  /// [error] 错误消息
  /// [originalError] 原始错误
  /// [stackTrace] 堆栈跟踪
  /// [clearError] 是否清除错误
  /// [clearData] 是否清除数据
  BaseState<T> copyWith({
    T? data,
    bool? isLoading,
    String? error,
    Object? originalError,
    StackTrace? stackTrace,
    bool clearError = false,
    bool clearData = false,
  }) {
    return BaseState<T>(
      data: clearData ? null : (data ?? this.data),
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      originalError: clearError ? null : (originalError ?? this.originalError),
      stackTrace: clearError ? null : (stackTrace ?? this.stackTrace),
    );
  }

  /// 模式匹配处理状态
  ///
  /// 根据当前状态调用对应的处理函数。
  ///
  /// [initial] 初始状态处理
  /// [loading] 加载中处理
  /// [data] 成功状态处理
  /// [error] 错误状态处理
  /// [orElse] 默认处理
  R when<R>({
    R Function()? initial,
    R Function()? loading,
    R Function(T data)? data,
    R Function(String message, Object? error, StackTrace? stackTrace)? error,
    required R Function() orElse,
  }) {
    if (isLoading) return loading?.call() ?? orElse();
    if (hasError) {
      return error?.call(this.error!, originalError, stackTrace) ?? orElse();
    }
    if (hasData) return data?.call(this.data as T) ?? orElse();
    return initial?.call() ?? orElse();
  }

  @override
  String toString() {
    return 'BaseState(data: $data, isLoading: $isLoading, error: $error)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BaseState<T> &&
        other.data == data &&
        other.isLoading == isLoading &&
        other.error == error;
  }

  @override
  int get hashCode => Object.hash(data, isLoading, error);
}

/// 简单状态类
///
/// 简化版的状态类，不包含原始错误和堆栈跟踪。
/// 适用于不需要详细错误信息的场景。
///
/// 类型参数:
/// - [T] 数据类型
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

/// 分页状态类
///
/// 用于管理分页数据加载状态。
/// 支持下拉刷新和上拉加载更多。
///
/// 类型参数:
/// - [T] 列表项数据类型
///
/// 示例:
/// ```dart
/// final state = PaginatedState<User>.data(
///   users,
///   currentPage: 1,
///   hasMore: true,
/// );
/// if (state.hasMore) {
///   await loadMore();
/// }
/// ```
class PaginatedState<T> {
  /// 数据列表
  final List<T> items;

  /// 是否正在加载（首次加载）
  final bool isLoading;

  /// 是否正在加载更多
  final bool isLoadingMore;

  /// 错误消息
  final String? error;

  /// 当前页码
  final int currentPage;

  /// 是否有更多数据
  final bool hasMore;

  /// 总数据量
  final int totalItems;

  const PaginatedState({
    this.items = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.currentPage = 1,
    this.hasMore = true,
    this.totalItems = 0,
  });

  /// 创建初始状态
  const PaginatedState.initial()
      : items = const [],
        isLoading = false,
        isLoadingMore = false,
        error = null,
        currentPage = 1,
        hasMore = true,
        totalItems = 0;

  /// 创建加载中状态
  const PaginatedState.loading()
      : items = const [],
        isLoading = true,
        isLoadingMore = false,
        error = null,
        currentPage = 1,
        hasMore = true,
        totalItems = 0;

  /// 创建错误状态
  PaginatedState.error(String error)
      : items = const [],
        isLoading = false,
        isLoadingMore = false,
        error = error,
        currentPage = 1,
        hasMore = true,
        totalItems = 0;

  /// 创建成功状态
  ///
  /// [items] 数据列表
  /// [currentPage] 当前页码
  /// [hasMore] 是否有更多数据
  /// [totalItems] 总数据量
  PaginatedState.data(
    List<T> items, {
    int currentPage = 1,
    bool hasMore = true,
    int totalItems = 0,
  })  : items = items,
        isLoading = false,
        isLoadingMore = false,
        error = null,
        currentPage = currentPage,
        hasMore = hasMore,
        totalItems = totalItems;

  /// 是否有数据
  bool get hasData => items.isNotEmpty;

  /// 是否有错误
  bool get hasError => error != null;

  /// 是否为空
  bool get isEmpty => items.isEmpty && !isLoading && !hasError;

  /// 复制状态
  ///
  /// [items] 数据列表
  /// [isLoading] 加载状态
  /// [isLoadingMore] 加载更多状态
  /// [error] 错误消息
  /// [currentPage] 当前页码
  /// [hasMore] 是否有更多
  /// [totalItems] 总数据量
  /// [clearError] 是否清除错误
  /// [appendItems] 是否追加数据
  PaginatedState<T> copyWith({
    List<T>? items,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    int? currentPage,
    bool? hasMore,
    int? totalItems,
    bool clearError = false,
    bool appendItems = false,
  }) {
    List<T> newItems = items ?? this.items;
    if (appendItems && items != null) {
      newItems = [...this.items, ...items];
    }

    return PaginatedState<T>(
      items: newItems,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: clearError ? null : (error ?? this.error),
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
      totalItems: totalItems ?? this.totalItems,
    );
  }

  @override
  String toString() {
    return 'PaginatedState(items: ${items.length}, isLoading: $isLoading, isLoadingMore: $isLoadingMore, error: $error, currentPage: $currentPage, hasMore: $hasMore)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PaginatedState<T> &&
        _listEquals(other.items, items) &&
        other.isLoading == isLoading &&
        other.isLoadingMore == isLoadingMore &&
        other.error == error &&
        other.currentPage == currentPage &&
        other.hasMore == hasMore;
  }

  @override
  int get hashCode => Object.hash(items.length, isLoading, isLoadingMore, error, currentPage, hasMore);

  static bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
