import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soup_rewards_app/features/faq/presentation/pages/faq_page.dart';

void main() {
  testWidgets('FAQ Page should load and display items', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: FaqPage(),
        ),
      ),
    );

    // 1. Verify loading state
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // 2. Wait for the simulated delay in initState and rebuild
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();


    // 3. Verify content is displayed
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.byType(ExpansionTile), findsWidgets);
    expect(find.text('予約はどのように行えばよいですか？'), findsOneWidget);
  });

  testWidgets('Tapping on a FAQ item should expand it', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: FaqPage(),
        ),
      ),
    );

    // Wait for data to load
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();

    // Tap the first FAQ item to expand it
    await tester.tap(find.text('予約はどのように行えばよいですか？'));
    await tester.pump(); // Rebuild with the expanded state

    // Verify the answer is now visible
    expect(find.textContaining('お電話またはWebサイトからご予約いただけます'), findsOneWidget);
  });
}

