import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dangerhouse_app/data/repositories/auth_repository.dart';
import 'package:dangerhouse_app/core/providers/network_providers.dart';
import 'package:dangerhouse_app/presentation/login/login_activity.dart';
import 'package:flutter/material.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository mockAuthRepository;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
  });

  testWidgets('Login page smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(mockAuthRepository),
        ],
        child: const MaterialApp(
          home: LoginActivity(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('登 录'), findsOneWidget);
    expect(find.text('还没有账号？'), findsOneWidget);
    expect(find.text('点击创建'), findsOneWidget);
  });
}
