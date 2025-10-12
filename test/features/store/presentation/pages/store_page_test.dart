import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:network_image_mock/network_image_mock.dart';
import 'package:soup_rewards_app/features/store/presentation/pages/store_page.dart';

void main() {
  testWidgets('Store Page should load and display content correctly', (WidgetTester tester) async {
    await mockNetworkImagesFor(() async {
      // Set a larger screen size to avoid overflow errors
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: StorePage(),
          ),
        ),
      );

      // 1. Verify loading state is present
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // 2. Wait for the simulated network delay in initState
      await tester.pump(const Duration(seconds: 1));
      // Pump again to rebuild the widget with the new state
      await tester.pump();

      // 3. Verify loading is finished and content is displayed
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('SOUP カーケアサービス'), findsOneWidget);
      expect(find.text('徳島県徳島市○○町○○番地'), findsOneWidget);

      // 4. Verify interaction is possible
      expect(find.text('電話をかける'), findsOneWidget);
      await tester.tap(find.text('電話をかける'));
      await tester.pump();
    });
  });
}

