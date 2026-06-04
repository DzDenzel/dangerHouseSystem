import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dangerhouse_app/app.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('End-to-End Tests', () {
    testWidgets('Complete login flow', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: DangerHouseApp(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('欢迎回来'), findsOneWidget);

      final usernameField = find.widgetWithText(TextField, '用户名').first;
      final passwordField = find.widgetWithText(TextField, '密码').first;

      await tester.enterText(usernameField, 'testuser');
      await tester.enterText(passwordField, 'password123');

      final checkbox = find.byType(Checkbox);
      await tester.tap(checkbox);
      await tester.pump();

      final loginButton = find.text('登录');
      await tester.tap(loginButton);
      await tester.pumpAndSettle(const Duration(seconds: 3));

      final snackBar = find.byType(SnackBar);
      if (snackBar.evaluate().isNotEmpty) {
        final snackBarText = tester.widget<SnackBar>(snackBar).content;
        debugPrint('Login result: $snackBarText');
      }
    });

    testWidgets('Navigation from login to register', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: DangerHouseApp(),
        ),
      );

      await tester.pumpAndSettle();

      final registerLink = find.text('立即注册');
      await tester.tap(registerLink);
      await tester.pumpAndSettle();

      expect(find.text('创建账号'), findsOneWidget);
      expect(find.text('已有账号？'), findsOneWidget);
    });

    testWidgets('Register form validation', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: DangerHouseApp(),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.text('立即注册'));
      await tester.pumpAndSettle();

      final registerButton = find.text('注册');
      await tester.tap(registerButton);
      await tester.pump();

      expect(find.text('请输入用户名'), findsOneWidget);
      expect(find.text('请输入密码'), findsOneWidget);
      expect(find.text('请输入手机号'), findsOneWidget);
    });
  });
}
