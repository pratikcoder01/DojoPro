import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/features/coaching/screens/coach_dashboard_screen.dart';

void main() {
  setUpAll(() {
    // Disable runtime HTTP fetching for Google Fonts in headless test mode
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('Coach Dashboard renders earnings overview, sessions, student detail bottom sheets, availability grid, and handles locked course builder', (WidgetTester tester) async {
    // Set a modern screen size for testing to prevent layout/overflow/tap constraints
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    // 1. Render the CoachDashboardScreen
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: CoachDashboardScreen(coachId: 'test_coach_priya'),
        ),
      ),
    );

    // 2. Wait for provider mock data initialization
    await tester.pumpAndSettle();

    // 3. Verify Earnings Overview Card
    expect(find.text('EARNINGS OVERVIEW'), findsOneWidget);
    expect(find.text('₹12,400'), findsOneWidget);
    expect(find.text('₹48,200'), findsOneWidget);
    expect(find.text('34'), findsOneWidget);
    expect(find.text('W1'), findsOneWidget); // Part of chart axis

    // 4. Verify Upcoming Sessions Section
    expect(find.text('UPCOMING BOOKED SESSIONS'), findsOneWidget);
    expect(find.text('Arjun Mehta'), findsNWidgets(2));
    expect(find.text('START SESSION'), findsOneWidget); // Visible for Arjun's session (starts in 15m)

    // Tap Start Session and verify connecting dialog
    await tester.ensureVisible(find.text('START SESSION'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('START SESSION'));
    await tester.pumpAndSettle();

    expect(find.text('CONNECTING...'), findsOneWidget);
    await tester.tap(find.text('DISMISS'));
    await tester.pumpAndSettle();

    // Tap Cancel on Rohan's session and verify warning dialog
    final cancelFinders = find.text('CANCEL');
    expect(cancelFinders, findsWidgets);
    await tester.ensureVisible(cancelFinders.first);
    await tester.pumpAndSettle();
    await tester.tap(cancelFinders.first);
    await tester.pumpAndSettle();

    expect(find.text('CANCEL SESSION?'), findsOneWidget);
    await tester.tap(find.text('CONFIRM CANCEL'));
    await tester.pumpAndSettle();

    // 5. Verify Student Roster Grid is rendered
    expect(find.text('STUDENT ROSTER'), findsOneWidget);

    // Scroll down to make student roster fully interactive in 800x600 test frame
    final scrollable = find.byType(SingleChildScrollView).first;
    await tester.drag(scrollable, const Offset(0, -350));
    await tester.pumpAndSettle();

    // Find and tap Arjun Mehta card in Roster to open Student Details bottom sheet
    final arjunRosterCard = find.descendant(
      of: find.byType(GridView),
      matching: find.text('Arjun Mehta'),
    );
    expect(arjunRosterCard, findsOneWidget);
    await tester.ensureVisible(arjunRosterCard);
    await tester.pumpAndSettle();
    await tester.tap(arjunRosterCard);
    await tester.pumpAndSettle();

    // Verify Student Details contents
    expect(find.text('ATTENDANCE LOG'), findsOneWidget);
    expect(find.text('BELT PROGRESSION HISTORY'), findsOneWidget);
    expect(find.text('UPCOMING MILESTONES'), findsOneWidget);
    expect(find.text('SAVE NOTES'), findsOneWidget);

    // Tap Save Notes to dismiss sheet
    await tester.tap(find.text('SAVE NOTES'));
    await tester.pumpAndSettle();

    // Scroll down further to show Availability Manager and Course Builder
    await tester.drag(scrollable, const Offset(0, -450));
    await tester.pumpAndSettle();

    // 6. Verify Availability Manager
    expect(find.text('AVAILABILITY MANAGER'), findsOneWidget);
    expect(find.text('Always available Mon/Wed/Fri 6pm–9pm (Recurring)'), findsOneWidget);

    // Tap an availability time slot (e.g. 10:00 AM)
    final slotFinder = find.text('10:00 AM');
    expect(slotFinder, findsWidgets);
    await tester.ensureVisible(slotFinder.first);
    await tester.pumpAndSettle();
    await tester.tap(slotFinder.first);
    await tester.pumpAndSettle();

    // 7. Verify Course Builderlocked preview
    expect(find.text('COURSE BUILDER'), findsOneWidget);
    expect(find.text('GET NOTIFIED ON LAUNCH'), findsOneWidget);

    await tester.ensureVisible(find.text('GET NOTIFIED ON LAUNCH'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('GET NOTIFIED ON LAUNCH'));
    await tester.pumpAndSettle();

    // Verify success snackbar is shown
    final snackBarFinder = find.byType(SnackBar);
    expect(snackBarFinder, findsOneWidget);
    final snackBarWidget = tester.widget<SnackBar>(snackBarFinder);
    expect(snackBarWidget.content, isA<Text>());
    final textWidget = snackBarWidget.content as Text;
    expect(textWidget.data, contains('Launch notification registered'));
  });
}
