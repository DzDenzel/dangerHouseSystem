import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'base_state.dart';

/// 基础通知器
///
/// 用于管理异步数据加载的 StateNotifier 基类。
/// 自动处理加载状态和错误状态。
///
/// 类型参数:
/// - [T] 数据类型
///
/// 示例:
/// ```dart
/// class UserNotifier extends BaseNotifier<User> {
///   final UserRepository _repository;
///
///   Future<void> loadUser(int id) async {
///     await execute(() => _repository.getUser(id));
///   }
/// }
///
/// // 在UI中使用
/// final state = ref.watch(userProvider);
/// state.when(
///   initial: () => Text('请加载数据'),
///   loading: () => CircularProgressIndicator(),
///   data: (user) => Text(user.name),
///   error: (msg, _, __) => Text('错误: $msg'),
///   orElse: () => SizedBox(),
/// );
/// ```
abstract class BaseNotifier<T> extends StateNotifier<BaseState<T>> {
  BaseNotifier() : super(const BaseState.initial());

  /// 执行异步操作
  ///
  /// 自动管理加载状态和错误状态。
  ///
  /// [action] 要执行的异步操作
  /// [errorMessage] 自定义错误消息（可选）
  ///
  /// 返回操作结果，失败时重新抛出异常。
  Future<T> execute(Future<T> Function() action, {String? errorMessage}) async {
    state = const BaseState.loading();
    try {
      final result = await action();
      state = BaseState.data(result);
      return result;
    } catch (e, st) {
      final message = errorMessage ?? e.toString();
      state = BaseState.error(message, error: e, stackTrace: st);
      rethrow;
    }
  }

  /// 设置成功数据
  ///
  /// [data] 要设置的数据
  void setData(T data) {
    state = BaseState.data(data);
  }

  /// 设置错误状态
  ///
  /// [message] 错误消息
  /// [error] 原始错误对象
  /// [stackTrace] 堆栈跟踪
  void setError(String message, {Object? error, StackTrace? stackTrace}) {
    state = BaseState.error(message, error: error, stackTrace: stackTrace);
  }

  /// 重置状态
  void reset() {
    state = const BaseState.initial();
  }
}

/// 简单通知器
///
/// 简化版的通知器，不抛出异常，返回null表示失败。
/// 适用于不需要异常处理的场景。
///
/// 类型参数:
/// - [T] 数据类型
///
/// 示例:
/// ```dart
/// class LoginNotifier extends SimpleNotifier<LoginResponse> {
///   Future<LoginResponse?> login(String username, String password) async {
///     return execute(() => _authService.login(username, password));
///   }
/// }
/// ```
abstract class SimpleNotifier<T> extends StateNotifier<SimpleState<T>> {
  SimpleNotifier() : super(SimpleState.initial());

  /// 执行异步操作
  ///
  /// 自动管理加载状态和错误状态。
  /// 失败时不抛出异常，返回null。
  ///
  /// [action] 要执行的异步操作
  /// [errorMessage] 自定义错误消息（可选）
  ///
  /// 返回操作结果，失败时返回null。
  Future<T?> execute(Future<T> Function() action, {String? errorMessage}) async {
    state = SimpleState.loading();
    try {
      final result = await action();
      state = SimpleState.data(result);
      return result;
    } catch (e) {
      final message = errorMessage ?? e.toString();
      state = SimpleState.error(message);
      return null;
    }
  }

  /// 设置成功数据
  void setData(T data) {
    state = SimpleState.data(data);
  }

  /// 设置错误状态
  void setError(String message) {
    state = SimpleState.error(message);
  }

  /// 重置状态
  void reset() {
    state = SimpleState.initial();
  }

  /// 清除错误
  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

/// 分页通知器
///
/// 用于管理分页数据加载的 StateNotifier 基类。
/// 支持下拉刷新和上拉加载更多。
///
/// 类型参数:
/// - [T] 列表项数据类型
///
/// 示例:
/// ```dart
/// class BuildingListNotifier extends PaginatedNotifier<Building> {
///   final BuildingRepository _repository;
///
///   BuildingListNotifier(this._repository) : super(pageSize: 20);
///
///   @override
///   Future<List<Building>> fetchPage(int page, int size) {
///     return _repository.getBuildings(page: page, size: size);
///   }
/// }
///
/// // 使用
/// ref.read(buildingListProvider.notifier).load();
/// ref.read(buildingListProvider.notifier).loadMore();
/// ref.read(buildingListProvider.notifier).refresh();
/// ```
abstract class PaginatedNotifier<T> extends StateNotifier<PaginatedState<T>> {
  /// 每页数据量
  final int pageSize;

  PaginatedNotifier({this.pageSize = 10}) : super(PaginatedState.initial());

  /// 加载首页数据
  ///
  /// [loader] 数据加载函数，接收页码和每页数量
  Future<void> load(Future<List<T>> Function(int page, int size) loader) async {
    state = PaginatedState.loading();
    try {
      final items = await loader(1, pageSize);
      state = PaginatedState.data(
        items,
        currentPage: 1,
        hasMore: items.length >= pageSize,
        totalItems: items.length,
      );
    } catch (e) {
      state = PaginatedState.error(e.toString());
    }
  }

  /// 加载更多数据
  ///
  /// [loader] 数据加载函数
  Future<void> loadMore(Future<List<T>> Function(int page, int size) loader) async {
    if (state.isLoadingMore || !state.hasMore) return;

    state = state.copyWith(isLoadingMore: true);
    try {
      final nextPage = state.currentPage + 1;
      final items = await loader(nextPage, pageSize);
      state = state.copyWith(
        items: [...state.items, ...items],
        currentPage: nextPage,
        isLoadingMore: false,
        hasMore: items.length >= pageSize,
        appendItems: true,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingMore: false,
        error: e.toString(),
      );
    }
  }

  /// 刷新数据
  ///
  /// 重新加载首页数据。
  ///
  /// [loader] 数据加载函数
  Future<void> refresh(Future<List<T>> Function(int page, int size) loader) async {
    state = PaginatedState.loading();
    await load(loader);
  }

  /// 重置状态
  void reset() {
    state = PaginatedState.initial();
  }
}
