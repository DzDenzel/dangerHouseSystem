import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final ProviderContainer appContainer = ProviderContainer();

void main() {
  runApp(
    UncontrolledProviderScope(
      container: appContainer,
      child: DangerHouseApp(),
    ),
  );
}
