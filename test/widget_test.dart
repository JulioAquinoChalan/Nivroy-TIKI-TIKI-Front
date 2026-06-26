import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:nivroy_tiki_tiki/core/app_state.dart';
import 'package:nivroy_tiki_tiki/main.dart';

void main() {
  testWidgets('shows desktop dashboard after verified login state change', (
    tester,
  ) async {
    tester.view
      ..devicePixelRatio = 1
      ..physicalSize = const Size(1200, 900);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final appState = AppState();

    await tester.pumpWidget(
      ChangeNotifierProvider.value(value: appState, child: const NivroyApp()),
    );

    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    appState
      ..isInitialized = true
      ..isAuthenticated = true
      ..isEmailVerified = true
      ..notifyListeners();

    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(AppShell), findsOneWidget);
    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.text('Automation Hub'), findsOneWidget);
  });
}
