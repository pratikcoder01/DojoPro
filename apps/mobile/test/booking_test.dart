import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/features/coaching/providers/coaching_provider.dart';
import 'package:mobile/features/coaching/screens/coach_profile_screen.dart';
import 'package:mobile/features/coaching/screens/booking_confirmation_screen.dart';

void main() {
  setUpAll(() {
    // Disable runtime HTTP fetching for Google Fonts in headless test mode
    GoogleFonts.config.allowRuntimeFetching = false;
    // Redirect all network image calls to a mock client returning 1x1 transparent PNG
    HttpOverrides.global = MockHttpOverrides();
  });

  testWidgets('Coach Booking Flow: Profile Selection, Payment Processor and Confirmation Test', (WidgetTester tester) async {
    // Set a modern screen size for testing to prevent layout/overflow/tap constraints
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    // 1. Build MaterialApp with CoachProfileScreen inside a Navigator stack
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: CoachProfileScreen(),
        ),
      ),
    );

    // Let the auto loadCoachDetails complete (it runs on constructor initialization)
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();

    // 2. Verify Coach Details are correctly displayed
    expect(find.text('Sensei Priya Rao'), findsOneWidget);
    expect(find.text('Explosive Striking'), findsOneWidget);
    expect(find.text('4.8'), findsOneWidget);
    expect(find.text('(127 reviews)'), findsOneWidget);

    // 3. Verify Session Type toggle options exist
    expect(find.text('IN-PERSON'), findsOneWidget);
    expect(find.text('ONLINE (HD STREAM)'), findsOneWidget);

    // Tap ONLINE session type and verify toggle
    await tester.tap(find.text('ONLINE (HD STREAM)'));
    await tester.pumpAndSettle();

    // 4. Verify availability calendar is rendered
    expect(find.text('WEEKLY AVAILABILITY'), findsOneWidget);
    
    // Tap the first slot (available by default)
    final timeFormat = DateFormat('h:mm a');
    final now = DateTime.now();
    final today10 = DateTime(now.year, now.month, now.day, 10);
    final firstSlotTimeStr = timeFormat.format(today10);

    expect(find.text(firstSlotTimeStr), findsAtLeastNWidgets(1));
    await tester.tap(find.text(firstSlotTimeStr).first);
    await tester.pumpAndSettle();

    // Scroll down to verify the pinned reviews exist
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -600));
    await tester.pumpAndSettle();

    expect(find.text('Arjun Mehta'), findsOneWidget);
    expect(find.text('Rohan Sharma'), findsOneWidget);
    expect(find.text('Pooja Patel'), findsOneWidget);

    // 5. Click the Bottom Booking Bar to proceed
    final bookingButtonFinder = find.byKey(const ValueKey('book_session_bar_button'));
    expect(bookingButtonFinder, findsOneWidget);
    
    await tester.tap(bookingButtonFinder);
    await tester.pumpAndSettle();

    // 6. Verify we have transitioned/navigated to the BookingConfirmationScreen
    expect(find.byType(BookingConfirmationScreen), findsOneWidget);
    expect(find.text('REVIEW YOUR SESSION'), findsOneWidget);
    expect(find.text('SELECT PAYMENT PROCESSOR'), findsOneWidget);

    // Verify Stripe is selected by default, tap RAZORPAY option
    expect(find.text('STRIPE'), findsOneWidget);
    expect(find.text('RAZORPAY'), findsOneWidget);
    
    await tester.tap(find.text('RAZORPAY'));
    await tester.pumpAndSettle();

    // Tap Pay button (triggers processBookingPayment and mock checkout flow)
    final confirmPayButton = find.byKey(const ValueKey('confirm_payment_button'));
    expect(confirmPayButton, findsOneWidget);
    
    await tester.tap(confirmPayButton);
    // Let the progress indicators run and async payment mock complete (1500ms delay)
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    // 7. Verify Success View is shown with scale/fade animations
    expect(find.text('SESSION BOOKED!'), findsOneWidget);
    expect(find.text('Reminder push notification scheduled for 1 hour before session.'), findsOneWidget);

    // Verify Auto-add to calendar prompt
    final addToCalendarButton = find.byKey(const ValueKey('add_to_calendar_button'));
    expect(addToCalendarButton, findsOneWidget);
    
    await tester.tap(addToCalendarButton);
    await tester.pumpAndSettle();

    // Confirm YES in local calendar sync popup dialog
    final calendarConfirmYes = find.byKey(const ValueKey('calendar_confirm_yes'));
    expect(calendarConfirmYes, findsOneWidget);
    
    await tester.tap(calendarConfirmYes);
    await tester.pumpAndSettle();

    // Verify SnackBar success
    expect(find.text('Session successfully synced to your local calendar!'), findsOneWidget);

    // Tap BACK TO COACH PROFILE button to return
    final backToProfileButton = find.byKey(const ValueKey('back_to_profile_button'));
    expect(backToProfileButton, findsOneWidget);
    
    await tester.tap(backToProfileButton);
    await tester.pumpAndSettle();

    // Verify we are back to the main profile page
    expect(find.byType(CoachProfileScreen), findsOneWidget);
  });
}

// Mocking HttpOverrides to resolve network image load requests
class MockHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return MockHttpClient();
  }
}

class MockHttpClient implements HttpClient {
  @override
  Future<HttpClientRequest> getUrl(Uri url) async => MockHttpClientRequest();

  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) async => MockHttpClientRequest();

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class MockHttpClientRequest implements HttpClientRequest {
  @override
  HttpHeaders get headers => MockHttpHeaders();

  @override
  Future<HttpClientResponse> close() async => MockHttpClientResponse();

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class MockHttpHeaders implements HttpHeaders {
  @override
  List<String>? operator [](String name) => null;

  @override
  String? value(String name) => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class MockHttpClientResponse implements HttpClientResponse {
  static const List<int> _transparentImage = [
    137, 80, 78, 71, 13, 10, 26, 10, 0, 0, 0, 13, 73, 72, 68, 82, 0, 0, 0, 1, 0, 0, 0, 1, 8, 6, 0, 0, 0, 31, 21, 196, 137, 0, 0, 0, 13, 73, 68, 65, 84, 120, 156, 99, 96, 0, 0, 0, 2, 0, 1, 73, 175, 168, 116, 0, 0, 0, 0, 73, 69, 78, 68, 174, 66, 96, 130
  ];

  @override
  int get statusCode => 200;

  @override
  int get contentLength => _transparentImage.length;

  @override
  HttpClientResponseCompressionState get compressionState => HttpClientResponseCompressionState.notCompressed;

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return Stream<List<int>>.fromIterable([_transparentImage]).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}
