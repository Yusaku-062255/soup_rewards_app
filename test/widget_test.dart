import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:soup_rewards/main.dart';

void main() {
  testWidgets('SOUP Rewards app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(
        child: SoupRewardsApp(),
      ),
    );

    // Verify that the app starts without crashing
    expect(find.text('ホーム'), findsWidgets);
    expect(find.text('おかえりなさい！'), findsOneWidget);
    expect(find.text('現在のポイント'), findsOneWidget);
  });
}
