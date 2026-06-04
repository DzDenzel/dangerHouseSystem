import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dangerhouse_app/data/models/auth_models.dart';
import 'package:dangerhouse_app/data/repositories/auth_repository.dart';
import 'package:dangerhouse_app/presentation/login/login_activity.dart';
import 'package:dangerhouse_app/core/providers/network_providers.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository mockAuthRepository;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
  });

  Widget createLoginScreen({
    List<Override> overrides = const [],
  }) {
    return ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(mockAuthRepository),
        ...overrides,
      ],
      child: const MaterialApp(
        home: LoginActivity(),
      ),
    );
  }

  group('LoginActivity Widget Tests', () {
    testWidgets('displays login form elements', (WidgetTester tester) async {
      await tester.pumpWidget(createLoginScreen());

      expect(find.text('登 录'), findsOneWidget);
      expect(find.text('忘记密码？'), findsOneWidget);
    });

    testWidgets('shows validation error for empty account',
        (WidgetTester tester) async {
      await tester.pumpWidget(createLoginScreen());

      final loginButton = find.text('登 录');
      await tester.tap(loginButton);
      await tester.pump();

      expect(find.text('账号不能为空'), findsOneWidget);
    });

    testWidgets('shows validation error for empty password',
        (WidgetTester tester) async {
      await tester.pumpWidget(createLoginScreen());

      final accountField = find.widgetWithText(TextFormField, '用户名/手机号/邮箱');
      await tester.enterText(accountField, 'testuser');

      await tester.tap(find.text('登 录'));
      await tester.pump();

      expect(find.text('密码不能为空'), findsOneWidget);
    });

    testWidgets('toggles password visibility', (WidgetTester tester) async {
      await tester.pumpWidget(createLoginScreen());

      final passwordField = find.widgetWithText(TextFormField, '请输入密码');
      expect(passwordField, findsOneWidget);

      final visibilityToggle = find.byIcon(Icons.visibility_off);
      await tester.tap(visibilityToggle);
      await tester.pump();

      final visibleIcon = find.byIcon(Icons.visibility);
      expect(visibleIcon, findsOneWidget);
    });

    testWidgets('shows error message on login failure',
        (WidgetTester tester) async {
      when(() => mockAuthRepository.login('testuser', 'wrong'))
          .thenAnswer((_) async => LoginResponse(
                success: false,
                message: '用户名或密码错误',
              ));

      await tester.pumpWidget(createLoginScreen());

      final accountField = find.widgetWithText(TextFormField, '用户名/手机号/邮箱');
      await tester.enterText(accountField, 'testuser');

      final passwordField = find.widgetWithText(TextFormField, '请输入密码');
      await tester.enterText(passwordField, 'wrong');

      final checkbox = find.byType(Checkbox);
      await tester.tap(checkbox);
      await tester.pump();

      await tester.tap(find.text('登 录'));
      await tester.pumpAndSettle();

      expect(find.text('用户名或密码错误'), findsOneWidget);
    });

    testWidgets('requires agreement checkbox to be checked',
        (WidgetTester tester) async {
      await tester.pumpWidget(createLoginScreen());

      final accountField = find.widgetWithText(TextFormField, '用户名/手机号/邮箱');
      await tester.enterText(accountField, 'testuser');

      final passwordField = find.widgetWithText(TextFormField, '请输入密码');
      await tester.enterText(passwordField, 'password');

      await tester.tap(find.text('登 录'));
      await tester.pumpAndSettle();

      expect(find.text('请先阅读并同意《用户协议》和《隐私政策》'), findsOneWidget);
    });

    testWidgets('navigates to register screen on tap',
        (WidgetTester tester) async {
      await tester.pumpWidget(createLoginScreen());

      await tester.ensureVisible(find.text('点击创建'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('点击创建'));
      await tester.pumpAndSettle();

      expect(find.text('创建新账号'), findsOneWidget);
    });
  });
}
