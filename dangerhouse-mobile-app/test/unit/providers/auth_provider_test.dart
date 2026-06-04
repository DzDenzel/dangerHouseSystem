import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dangerhouse_app/core/state/base_state.dart';
import 'package:dangerhouse_app/data/models/auth_models.dart';
import 'package:dangerhouse_app/data/repositories/auth_repository.dart';
import 'package:dangerhouse_app/providers/auth_provider.dart';
import 'package:dangerhouse_app/core/providers/network_providers.dart';
import 'package:dangerhouse_app/core/errors/error_handler.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class FakeRegisterRequest extends Fake implements RegisterRequest {}

class FakeUpdateUserRequest extends Fake implements UpdateUserRequest {}

void main() {
  late ProviderContainer container;
  late MockAuthRepository mockAuthRepository;

  setUpAll(() {
    registerFallbackValue(FakeRegisterRequest());
    registerFallbackValue(FakeUpdateUserRequest());
    ErrorHandler.setEnableToast(false);
  });

  tearDownAll(() {
    ErrorHandler.setEnableToast(true);
  });

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(mockAuthRepository),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('AuthNotifier', () {
    group('login', () {
      test('emits loading then data on successful login', () async {
        final loginResponse = LoginResponse(
          success: true,
          message: '登录成功',
          token: 'test_token',
          id: 1,
          username: 'testuser',
        );

        when(() => mockAuthRepository.login('testuser', 'password'))
            .thenAnswer((_) async => loginResponse);

        final notifier = container.read(authNotifierProvider.notifier);
        final states = <SimpleState<LoginResponse>>[];
        container.listen<SimpleState<LoginResponse>>(
          authNotifierProvider,
          (previous, next) => states.add(next),
        );

        final result = await notifier.login('testuser', 'password');

        expect(result, isTrue);
        expect(states.first.isLoading, isTrue);
        expect(states.last.hasData, isTrue);
        expect(states.last.data?.username, equals('testuser'));
      });

      test('emits loading then error on failed login', () async {
        final failedResponse = LoginResponse(
          success: false,
          message: '用户名或密码错误',
        );

        when(() => mockAuthRepository.login('testuser', 'wrong'))
            .thenAnswer((_) async => failedResponse);

        final notifier = container.read(authNotifierProvider.notifier);
        final result = await notifier.login('testuser', 'wrong');

        expect(result, isFalse);
        final state = container.read(authNotifierProvider);
        expect(state.hasError, isTrue);
        expect(state.error, contains('用户名或密码错误'));
      });

      test('emits error on exception', () async {
        when(() => mockAuthRepository.login('testuser', 'password'))
            .thenThrow(Exception('Network error'));

        final notifier = container.read(authNotifierProvider.notifier);
        final result = await notifier.login('testuser', 'password');

        expect(result, isFalse);
        final state = container.read(authNotifierProvider);
        expect(state.hasError, isTrue);
      });
    });

    group('register', () {
      test('emits data on successful registration', () async {
        final request = RegisterRequest(
          username: 'newuser',
          password: 'password123',
          phone: '13800138000',
          role: 'USER',
        );

        final registerResponse = RegisterResponse(
          id: 1,
          username: 'newuser',
          phone: '13800138000',
          role: 'USER',
          message: '注册成功',
          createTime: DateTime.now(),
        );

        when(() => mockAuthRepository.register(request))
            .thenAnswer((_) async => registerResponse);

        final notifier = container.read(authNotifierProvider.notifier);
        final result = await notifier.register(request);

        expect(result, isTrue);
        final state = container.read(authNotifierProvider);
        expect(state.hasData, isTrue);
        expect(state.data?.username, equals('newuser'));
      });

      test('emits error on failed registration', () async {
        final request = RegisterRequest(
          username: 'existinguser',
          password: 'password123',
          phone: '13800138000',
          role: 'USER',
        );

        when(() => mockAuthRepository.register(request))
            .thenThrow(Exception('用户名已存在'));

        final notifier = container.read(authNotifierProvider.notifier);
        final result = await notifier.register(request);

        expect(result, isFalse);
        final state = container.read(authNotifierProvider);
        expect(state.hasError, isTrue);
      });
    });

    group('updateProfile', () {
      test('emits updated data on successful update', () async {
        final request = UpdateUserRequest(
          nickname: 'New Nickname',
          email: 'new@example.com',
        );

        final updateResponse = LoginResponse(
          success: true,
          message: '更新成功',
        );

        final profileResponse = LoginResponse(
          success: true,
          id: 1,
          username: 'testuser',
          nickname: 'New Nickname',
          email: 'new@example.com',
        );

        when(() => mockAuthRepository.updateProfile(request))
            .thenAnswer((_) async => updateResponse);
        when(() => mockAuthRepository.getProfile())
            .thenAnswer((_) async => profileResponse);

        final notifier = container.read(authNotifierProvider.notifier);
        final result = await notifier.updateProfile(request);

        expect(result, isTrue);
        final state = container.read(authNotifierProvider);
        expect(state.hasData, isTrue);
        expect(state.data?.nickname, equals('New Nickname'));
      });

      test('emits error on failed update', () async {
        final request = UpdateUserRequest(nickname: 'New');

        final failedResponse = LoginResponse(
          success: false,
          message: '更新失败',
        );

        when(() => mockAuthRepository.updateProfile(request))
            .thenAnswer((_) async => failedResponse);

        final notifier = container.read(authNotifierProvider.notifier);
        final result = await notifier.updateProfile(request);

        expect(result, isFalse);
        final state = container.read(authNotifierProvider);
        expect(state.hasError, isTrue);
      });
    });

    group('logout', () {
      test('clears state on logout', () async {
        when(() => mockAuthRepository.logout()).thenAnswer((_) async {});

        final notifier = container.read(authNotifierProvider.notifier);
        await notifier.logout();

        final state = container.read(authNotifierProvider);
        expect(state.isLoading, isFalse);
        expect(state.hasData, isFalse);
        expect(state.hasError, isFalse);
        verify(() => mockAuthRepository.logout()).called(1);
      });
    });

    group('clearError', () {
      test('clears error state', () async {
        when(() => mockAuthRepository.login('testuser', 'wrong'))
            .thenAnswer((_) async => LoginResponse(
                  success: false,
                  message: '登录失败',
                ));

        final notifier = container.read(authNotifierProvider.notifier);
        await notifier.login('testuser', 'wrong');

        expect(container.read(authNotifierProvider).hasError, isTrue);

        notifier.clearError();

        final state = container.read(authNotifierProvider);
        expect(state.error, isNull);
      });
    });
  });

  group('Auth Providers', () {
    test('isLoggedInProvider returns true when user is logged in', () async {
      final loginResponse = LoginResponse(
        success: true,
        token: 'test_token',
        id: 1,
        username: 'testuser',
      );

      when(() => mockAuthRepository.login('testuser', 'password'))
          .thenAnswer((_) async => loginResponse);

      final notifier = container.read(authNotifierProvider.notifier);
      await notifier.login('testuser', 'password');

      expect(container.read(isLoggedInProvider), isTrue);
    });

    test('isLoggedInProvider returns false when user is not logged in', () {
      expect(container.read(isLoggedInProvider), isFalse);
    });

    test('currentUserProvider returns user data when logged in', () async {
      final loginResponse = LoginResponse(
        success: true,
        token: 'test_token',
        id: 1,
        username: 'testuser',
      );

      when(() => mockAuthRepository.login('testuser', 'password'))
          .thenAnswer((_) async => loginResponse);

      final notifier = container.read(authNotifierProvider.notifier);
      await notifier.login('testuser', 'password');

      final user = container.read(currentUserProvider);
      expect(user, isNotNull);
      expect(user?.username, equals('testuser'));
    });

    test('authLoadingProvider returns true during loading', () async {
      when(() => mockAuthRepository.login('testuser', 'password'))
          .thenAnswer((_) async {
        await Future.delayed(const Duration(milliseconds: 100));
        return LoginResponse(success: true, token: 'test_token');
      });

      final notifier = container.read(authNotifierProvider.notifier);
      final future = notifier.login('testuser', 'password');

      expect(container.read(authLoadingProvider), isTrue);

      await future;
    });

    test('authErrorProvider returns error message on error', () async {
      when(() => mockAuthRepository.login('testuser', 'wrong'))
          .thenAnswer((_) async => LoginResponse(
                success: false,
                message: '登录失败',
              ));

      final notifier = container.read(authNotifierProvider.notifier);
      await notifier.login('testuser', 'wrong');

      expect(container.read(authErrorProvider), contains('登录失败'));
    });
  });
}
