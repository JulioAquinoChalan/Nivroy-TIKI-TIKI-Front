import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:nivroy_tiki_tiki/core/app_state.dart';
import 'package:nivroy_tiki_tiki/main.dart';

void main() {
  testWidgets('shows login form before session is initialized', (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AppState(),
        child: const NivroyApp(),
      ),
    );

    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
