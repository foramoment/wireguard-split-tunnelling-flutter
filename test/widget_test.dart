import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:wg_client/app.dart';

void main() {
  testWidgets('App renders home screen', (WidgetTester tester) async {
    // Build our app and trigger a frame
    await tester.pumpWidget(
      const ProviderScope(
        child: WgClientApp(),
      ),
    );

    // Wait for async operations
    await tester.pumpAndSettle();

    // Verify the home screen is rendered with "No Tunnels Yet" text
    expect(find.text('No Tunnels Yet'), findsOneWidget);
    expect(find.text('WireGuard'), findsOneWidget);
  });
}
