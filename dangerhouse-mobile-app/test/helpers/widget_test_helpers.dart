import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class WidgetTestHelpers {
  static Future<void> pumpWidget(
    WidgetTester tester, {
    required Widget widget,
    List<Override> overrides = const [],
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: overrides,
        child: MaterialApp(
          home: widget,
        ),
      ),
    );
  }

  static Future<void> pumpApp(
    WidgetTester tester, {
    required Widget child,
    List<Override> overrides = const [],
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: overrides,
        child: MaterialApp(
          home: Scaffold(body: child),
        ),
      ),
    );
  }

  static Future<void> enterTextAndPump(
    WidgetTester tester,
    Finder finder,
    String text,
  ) async {
    await tester.enterText(finder, text);
    await tester.pump();
  }

  static Future<void> tapAndPump(
    WidgetTester tester,
    Finder finder, {
    int pumps = 1,
  }) async {
    await tester.tap(finder);
    for (var i = 0; i < pumps; i++) {
      await tester.pump();
    }
  }

  static Future<void> tapAndSettle(
    WidgetTester tester,
    Finder finder,
  ) async {
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  static Finder findByKey(String key) => find.byKey(Key(key));

  static Finder findByText(String text) => find.text(text);

  static Finder findByType<T extends Widget>() => find.byType(T);

  static Finder findByWidgetPredicate(bool Function(Widget widget) predicate) =>
      find.byWidgetPredicate(predicate);

  static void expectFound(Finder finder) => expect(finder, findsOneWidget);

  static void expectNotFound(Finder finder) => expect(finder, findsNothing);

  static void expectCount(Finder finder, int count) =>
      expect(finder, findsNWidgets(count));

  static void expectTextFound(String text) => expectFound(findByText(text));

  static void expectWidgetType<T extends Widget>() =>
      expectFound(findByType<T>());

  static Future<void> scrollToFind(
    WidgetTester tester,
    Finder finder, {
    Finder? scrollable,
  }) async {
    scrollable ??= find.byType(ScrollView);
    await tester.scrollUntilVisible(
      finder,
      100.0,
      scrollable: scrollable,
    );
  }

  static Future<void> dragUntilVisible(
    WidgetTester tester, {
    required Finder finder,
    required Finder scrollable,
    Offset delta = const Offset(0, -100),
  }) async {
    await tester.dragUntilVisible(
      finder,
      scrollable,
      delta,
    );
  }

  static Future<void> verifyTextInWidget<T extends Widget>(
    WidgetTester tester,
    String expectedText,
  ) async {
    final widget = find.byType(T);
    expect(widget, findsOneWidget);
    expect(find.descendant(of: widget, matching: find.text(expectedText)),
        findsOneWidget);
  }

  static Future<void> verifyWidgetExists<T extends Widget>(
    WidgetTester tester,
  ) async {
    expect(find.byType(T), findsOneWidget);
  }

  static Future<void> verifyWidgetCount<T extends Widget>(
    WidgetTester tester,
    int expectedCount,
  ) async {
    expect(find.byType(T), findsNWidgets(expectedCount));
  }
}
