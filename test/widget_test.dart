import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:nivroy_tiki_tiki/core/app_state.dart';
import 'package:nivroy_tiki_tiki/main.dart';

void main() {
  testWidgets('shows dashboard shell', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AppState(),
        child: const NivroyApp(),
      ),
    );

    await tester.pump();

    expect(find.text('Dashboard'), findsWidgets);
    expect(find.text('Conectar TikTok'), findsOneWidget);
  });
}
