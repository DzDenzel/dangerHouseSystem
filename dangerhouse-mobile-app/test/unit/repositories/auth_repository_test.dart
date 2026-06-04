import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dangerhouse_app/data/models/auth_models.dart';
import 'package:dangerhouse_app/data/repositories/auth_repository.dart';
import 'package:dangerhouse_app/data/sources/auth_remote_data_source.dart';
import 'package:dangerhouse_app/core/auth/token_manager.dart';
import 'package:dangerhouse_app/core/errors/exceptions.dart';
import 'package:dangerhouse_app/core/errors/error_handler.dart';

class MockAuthRemoteDataSource extends Mock implements AuthRemoteDataSource {}

class MockTokenManager extends Mock implements TokenManager {}

class FakeRegisterRequest extends Fake implements RegisterRequest {}

class FakeUpdateUserRequest extends Fake implements UpdateUserRequest {}

void main() {
  late AuthRepositoryImpl repository;
  late MockAuthRemoteDataSource mockRemoteDataSource;
  late MockTokenManager mockTokenManager;

  setUpAll(() {
    registerFallbackValue(FakeRegisterRequest());
    registerFallbackValue(FakeUpdateUserRequest());
    ErrorHandler.setEnableToast(false);
  });

  tearDownAll(() {
    ErrorHandler.setEnableToast(true);
  });

  setUp(() {
    mockRemoteDataSource = MockAuthRemoteDataSource();
    mockTokenManager = MockTokenManager();
    repository = AuthRepositoryImpl(
      remoteDataSource: mockRemoteDataSource,
      tokenManager: mockTokenManager,
    );
  });

  group('AuthRepository', () {
    group('login', () {
      test('returns successful LoginResponse on successful login', () async {
        final loginResponse = LoginResponse(
          success: true,
          message: '登录成功',
          token: 'test_token',
          id: 1,
          username: 'testuser',
        );

        when(() => mockRemoteDataSource.login('testuser', 'password'))
            .thenAnswer((_) async => loginResponse);

        final result = await repository.login('testuser', 'password');

        expect(result.success, isTrue);
        expect(result.token, equals('test_token'));
        expect(result.username, equals('testuser'));
        verify(() => mockRemoteDataSource.login('testuser', 'password')).called(1);
      });

      test('returns failed LoginResponse on ValidationException', () async {
        when(() => mockRemoteDataSource.login('testuser', 'wrong'))
            .thenThrow(const ValidationException('用户名或密码错误'));

        final result = await repository.login('testuser', 'wrong');

        expect(result.success, isFalse);
        expect(result.message, contains('用户名或密码错误'));
      });

      test('returns failed LoginResponse on unknown exception', () async {
        when(() => mockRemoteDataSource.login('testuser', 'password'))
            .thenThrow(Exception('Network error'));

        final result = await repository.login('testuser', 'password');

        expect(result.success, isFalse);
        expect(result.message, isNotEmpty);
      });
    });

    group('register', () {
      test('returns RegisterResponse on successful registration', () async {
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

        when(() => mockRemoteDataSource.register(request))
            .thenAnswer((_) async => registerResponse);

        final result = await repository.register(request);

        expect(result.id, equals(1));
        expect(result.username, equals('newuser'));
        verify(() => mockRemoteDataSource.register(request)).called(1);
      });
    });

    group('checkUsername', () {
      test('returns available status when username is available', () async {
        when(() => mockRemoteDataSource.checkUsername('newuser'))
            .thenAnswer((_) async => {'available': true});

        final result = await repository.checkUsername('newuser');

        expect(result['available'], isTrue);
        verify(() => mockRemoteDataSource.checkUsername('newuser')).called(1);
      });

      test('returns unavailable status when username is taken', () async {
        when(() => mockRemoteDataSource.checkUsername('existinguser'))
            .thenAnswer((_) async => {'available': false});

        final result = await repository.checkUsername('existinguser');

        expect(result['available'], isFalse);
      });
    });

    group('isLoggedIn', () {
      test('returns true when token exists', () async {
        when(() => mockTokenManager.hasToken()).thenAnswer((_) async => true);

        final result = await repository.isLoggedIn();

        expect(result, isTrue);
        verify(() => mockTokenManager.hasToken()).called(1);
      });

      test('returns false when no token exists', () async {
        when(() => mockTokenManager.hasToken()).thenAnswer((_) async => false);

        final result = await repository.isLoggedIn();

        expect(result, isFalse);
      });
    });

    group('logout', () {
      test('calls logout on remote data source', () async {
        when(() => mockRemoteDataSource.logout())
            .thenAnswer((_) async {});

        await repository.logout();

        verify(() => mockRemoteDataSource.logout()).called(1);
      });
    });

    group('getProfile', () {
      test('returns LoginResponse with user data on success', () async {
        when(() => mockRemoteDataSource.getCurrentUser())
            .thenAnswer((_) async => {
                  'id': 1,
                  'username': 'testuser',
                  'email': 'test@example.com',
                  'nickname': 'Test User',
                });

        final result = await repository.getProfile();

        expect(result.success, isTrue);
        expect(result.id, equals(1));
        expect(result.username, equals('testuser'));
      });

      test('returns failed LoginResponse on error', () async {
        when(() => mockRemoteDataSource.getCurrentUser())
            .thenThrow(const UnauthorizedException('未授权'));

        final result = await repository.getProfile();

        expect(result.success, isFalse);
        expect(result.message, contains('未授权'));
      });
    });

    group('updateProfile', () {
      test('returns successful LoginResponse on update success', () async {
        final request = UpdateUserRequest(
          nickname: 'New Nickname',
          email: 'new@example.com',
        );

        when(() => mockRemoteDataSource.updateUser(request))
            .thenAnswer((_) async => {
                  'id': 1,
                  'username': 'testuser',
                  'nickname': 'New Nickname',
                  'email': 'new@example.com',
                });

        final result = await repository.updateProfile(request);

        expect(result.success, isTrue);
        expect(result.nickname, equals('New Nickname'));
      });

      test('returns failed LoginResponse on update error', () async {
        final request = UpdateUserRequest(nickname: 'New');

        when(() => mockRemoteDataSource.updateUser(request))
            .thenThrow(const ValidationException('更新失败'));

        final result = await repository.updateProfile(request);

        expect(result.success, isFalse);
        expect(result.message, contains('更新失败'));
      });
    });

    group('uploadAvatar', () {
      test('returns avatar URL on successful upload', () async {
        final bytes = [1, 2, 3, 4, 5];

        when(() => mockRemoteDataSource.uploadAvatar(bytes, 'avatar.jpg'))
            .thenAnswer((_) async => 'https://example.com/avatar.jpg');

        final result = await repository.uploadAvatar(bytes, 'avatar.jpg');

        expect(result, equals('https://example.com/avatar.jpg'));
      });

      test('returns null on upload error', () async {
        final bytes = [1, 2, 3, 4, 5];

        when(() => mockRemoteDataSource.uploadAvatar(bytes, 'avatar.jpg'))
            .thenThrow(Exception('Upload failed'));

        final result = await repository.uploadAvatar(bytes, 'avatar.jpg');

        expect(result, isNull);
      });
    });
  });
}
