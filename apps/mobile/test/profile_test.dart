import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/features/profile/screens/profile_screen.dart';

void main() {
  setUpAll(() {
    // Disable runtime HTTP fetching for Google Fonts in headless test mode
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('Athlete Profile Screen renders details, stats, timeline, trophies, and handles challenge actions', (WidgetTester tester) async {
    // 1. Render the ProfileScreen inside a ProviderScope and MaterialApp
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: ProfileScreen(userId: 'test_user_arjun'),
        ),
      ),
    );

    // 2. Wait for profile mock data initialization
    await tester.pumpAndSettle();

    // 3. Verify Hero Area details
    expect(find.text('ARJUN MEHTA'), findsOneWidget);
    expect(find.text('BROWN BELT'), findsOneWidget);
    expect(find.text('Karate • Mumbai, India'), findsOneWidget);

    // 4. Verify Stats Bar items
    expect(find.text('142 SESSIONS'), findsOneWidget);
    expect(find.text('3 WINS'), findsOneWidget);
    expect(find.text('2 CERTS'), findsOneWidget);

    // 5. Tap a stat item and verify that bottom sheet expands and shows detail
    await tester.tap(find.text('142 SESSIONS'));
    await tester.pumpAndSettle();

    expect(find.text('SESSIONS HISTORY'), findsOneWidget);
    expect(find.text('Shotokan Karate Kata Class - 2026-06-08'), findsOneWidget);

    // Close the bottom sheet
    await tester.tapAt(const Offset(10, 10)); // Tap outside bottom sheet to close
    await tester.pumpAndSettle();

    // 6. Verify Belt Progression Timeline is visible
    expect(find.text('BELT PROGRESSION'), findsOneWidget);
    expect(find.text('Brown Belt'), findsOneWidget);
    expect(find.text('Blue Belt'), findsOneWidget);

    // Scroll down the SingleChildScrollView to reveal lower elements
    final scrollable = find.byType(SingleChildScrollView);
    await tester.drag(scrollable, const Offset(0, -400));
    await tester.pumpAndSettle();

    // 7. Verify Trophy Shelf shows trophies and handles description click
    expect(find.text('TROPHY SHELF'), findsOneWidget);
    expect(find.text('Founding Member'), findsOneWidget);

    await tester.tap(find.text('Founding Member'));
    await tester.pumpAndSettle();

    expect(find.text('FOUNDING MEMBER'), findsOneWidget);
    expect(find.text('Founding Member of DojoPro community'), findsOneWidget);

    // Tap close on badge detail dialog
    await tester.tap(find.text('CLOSE'));
    await tester.pumpAndSettle();

    // 8. Verify technique videos are present
    expect(find.text('TECHNIQUE VIDEOS'), findsOneWidget);

    // Scroll down further to reveal the sparring challenge button
    await tester.drag(scrollable, const Offset(0, -300));
    await tester.pumpAndSettle();

    // 9. Verify Sparring Challenge flow
    expect(find.text('ISSUE SPARRING CHALLENGE'), findsOneWidget);

    await tester.tap(find.text('ISSUE SPARRING CHALLENGE'));
    await tester.pumpAndSettle();

    // Verify Success Dialog renders
    expect(find.text('CHALLENGE SENT'), findsOneWidget);
    expect(find.text('Your sparring request was sent! You will receive a notification once the target athlete responds.'), findsOneWidget);

    // Click awesome to dismiss
    await tester.tap(find.text('AWESOME'));
    await tester.pumpAndSettle();

    expect(find.text('CHALLENGE SENT'), findsNothing);
  });
}
