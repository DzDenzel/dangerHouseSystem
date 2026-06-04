import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class TestHelpers {
  static Future<void> pumpApp(
    WidgetTester tester, {
    required Widget child,
    List<Override> overrides = const [],
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: overrides,
        child: MaterialApp(
          home: child,
        ),
      ),
    );
  }

  static Future<void> pumpAndSettle(WidgetTester tester) async {
    await tester.pumpAndSettle();
  }

  static Future<void> enterText(
    WidgetTester tester,
    Finder finder,
    String text,
  ) async {
    await tester.enterText(finder, text);
    await tester.pump();
  }

  static Future<void> tap(WidgetTester tester, Finder finder) async {
    await tester.tap(finder);
    await tester.pump();
  }

  static Finder findByKey(String key) => find.byKey(Key(key));

  static Finder findByText(String text) => find.text(text);

  static Finder findByType<T extends Widget>() => find.byType(T);

  static Finder findByWidget(Widget widget) => find.byWidget(widget);

  static void expectOne(Finder finder) => expect(finder, findsOneWidget);

  static void expectNone(Finder finder) => expect(finder, findsNothing);

  static void expectN(Finder finder, int count) =>
      expect(finder, findsNWidgets(count));

  static void expectText(String text) => expectOne(findByText(text));
}
