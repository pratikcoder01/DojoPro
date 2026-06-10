import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:mobile/features/compete/screens/tournament_discovery_screen.dart';
import 'package:mobile/features/compete/screens/tournament_detail_screen.dart';
import 'package:mobile/features/compete/screens/bracket_view_screen.dart';

void main() {
  setUpAll(() {
    // Disable runtime HTTP fetching for Google Fonts in headless test mode
    GoogleFonts.config.allowRuntimeFetching = false;
    // Redirect all network image calls to a mock client returning 1x1 transparent PNG
    HttpOverrides.global = MockHttpOverrides();
  });

  testWidgets('Tournaments Feature Flow Test: Discovery, Filter, Detail, Registration & Bracket View', (WidgetTester tester) async {
    // Set a modern screen size for testing to prevent layout/overflow/tap constraints
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    // 1. Build MaterialApp with TournamentDiscoveryScreen
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: TournamentDiscoveryScreen(),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();

    // 2. Verify Discovery Page Renders Correctly
    expect(find.text('UPCOMING TOURNAMENTS'), findsOneWidget);
    expect(find.text('MUMBAI OPEN KARATE CHAMPIONSHIP'), findsOneWidget);
    expect(find.text('NATIONAL BJJ GRAPPLING CHALLENGE'), findsOneWidget);

    // Filter by "My Discipline"
    expect(find.text('MY DISCIPLINE'), findsOneWidget);
    await tester.tap(find.text('MY DISCIPLINE'));
    await tester.pumpAndSettle();

    // Only Karate should be shown (Arjun's discipline)
    expect(find.text('MUMBAI OPEN KARATE CHAMPIONSHIP'), findsOneWidget);
    expect(find.text('NATIONAL BJJ GRAPPLING CHALLENGE'), findsNothing);

    // Reset filter to All
    await tester.tap(find.text('ALL'));
    await tester.pumpAndSettle();
    expect(find.text('NATIONAL BJJ GRAPPLING CHALLENGE'), findsOneWidget);

    // 3. Navigate to Tournament Details (Karate Open Tournament)
    final karateCardFinder = find.byKey(const ValueKey('tournament_card_tourn_mumbai_open_123'));
    expect(karateCardFinder, findsOneWidget);

    // Let's tap on the card and navigate
    // Note: We need a Navigator stack. Let's rebuild the widget inside a navigation context to allow pushes.
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: TournamentDiscoveryScreen(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('tournament_card_tourn_mumbai_open_123')));
    await tester.pumpAndSettle();

    // Verify detail page is pushed
    expect(find.byType(TournamentDetailScreen), findsOneWidget);
    expect(find.text('MUMBAI OPEN KARATE CHAMPIONSHIP'), findsOneWidget);
    expect(find.text('Dharavi Sports Complex, Mumbai'), findsOneWidget);

    // Verify Info Grid & Capacity Meter
    expect(find.text('VENUE LOCATION'), findsOneWidget);
    expect(find.text('REGISTRATION FEE'), findsOneWidget);
    expect(find.text('₹500'), findsOneWidget);
    expect(find.text('47 / 100 Registered'), findsOneWidget);

    // Verify Bracket Preview shows Locked status (status is 'open')
    expect(find.text('BRACKET LOCKED'), findsOneWidget);

    // 4. Click the Register CTA and complete simulated payment
    final registerCtaFinder = find.byKey(const ValueKey('register_now_cta_button'));
    expect(registerCtaFinder, findsOneWidget);

    await tester.tap(registerCtaFinder);
    // Let the progress indicators run and async payment mock complete (1000ms delay)
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    // Verify Success card and graphics pass show up
    expect(find.text('REGISTRATION SECURED!'), findsOneWidget);
    expect(find.text('YOUR ATHLETE ENTRY CARD'), findsOneWidget);
    expect(find.byKey(const ValueKey('shareable_graphics_pass')), findsOneWidget);

    // Click share athlete pass button
    final sharePassBtn = find.byKey(const ValueKey('share_athlete_pass_button'));
    expect(sharePassBtn, findsOneWidget);
    await tester.ensureVisible(sharePassBtn);
    await tester.pumpAndSettle();
    await tester.tap(sharePassBtn);
    await tester.pumpAndSettle();
    expect(find.text('Athlete pass graphic shared successfully!'), findsOneWidget);

    // Go back to Discovery
    await tester.tap(find.byIcon(LucideIcons.arrowLeft));
    await tester.pumpAndSettle();
    expect(find.byType(TournamentDiscoveryScreen), findsOneWidget);

    // 5. Navigate to Completed Tournament details (TKD League) to test Bracket View Navigation
    await tester.tap(find.byKey(const ValueKey('tournament_card_tourn_tkd_league_789')));
    await tester.pumpAndSettle();

    expect(find.byType(TournamentDetailScreen), findsOneWidget);
    expect(find.text('MAHARASHTRA TAEKWONDO LEAGUE'), findsOneWidget);

    // Verify bracket is unlocked (since status is completed)
    final viewBracketBtn = find.byKey(const ValueKey('view_bracket_button'));
    expect(viewBracketBtn, findsOneWidget);

    // Tap View Tournament Bracket
    await tester.tap(viewBracketBtn);
    await tester.pumpAndSettle();

    // Verify Bracket View Screen is rendered
    expect(find.byType(BracketViewScreen), findsOneWidget);
    expect(find.text('COMPLETED'), findsOneWidget);
    expect(find.text('MAHARASHTRA TAEKWONDO LEAGUE'), findsOneWidget);

    // Verify rounds exist
    expect(find.text('QUARTERFINALS'), findsOneWidget);
    expect(find.text('SEMIFINALS'), findsOneWidget);
    expect(find.text('FINALS'), findsOneWidget);

    // Verify Completed Results Published Banner & Share Card exists
    expect(find.text('RESULTS PUBLISHED'), findsOneWidget);
    final resultsShareBtn = find.byKey(const ValueKey('completed_bracket_generate_share_button'));
    expect(resultsShareBtn, findsOneWidget);

    // Tap completed banner Share Card button to open share card dialog
    await tester.tap(resultsShareBtn);
    await tester.pumpAndSettle();

    // Verify modal share card is shown
    expect(find.byKey(const ValueKey('shareable_graphics_results_pass')), findsOneWidget);
    expect(find.text('Rohan Sharma (Black Belt)'), findsOneWidget);
    expect(find.text('Vikram Malhotra (Brown Belt)'), findsOneWidget);

    // Tap Share Results to close it
    final modalShareTriggerBtn = find.byKey(const ValueKey('results_share_card_trigger_button'));
    expect(modalShareTriggerBtn, findsOneWidget);
    await tester.tap(modalShareTriggerBtn);
    await tester.pumpAndSettle();
    expect(find.text('Championship results card shared successfully!'), findsOneWidget);

    // 6. Test Match Node details popup expansion
    // Tap on Match 1 Rohan vs Arjun (which is completed)
    final matchCardFinder = find.text('Arjun Mehta');
    expect(matchCardFinder, findsAtLeastNWidgets(1));
    await tester.tap(matchCardFinder.first);
    await tester.pumpAndSettle();

    // Verify modal detail displays match result
    expect(find.text('OFFICIAL MATCH RESULT'), findsOneWidget);
    expect(find.text('Rohan Sharma won by Decision (3-2) after close striking exchange.'), findsOneWidget);

    // Tap Close Details in modal
    final closeDetailsBtn = find.text('CLOSE DETAILS');
    expect(closeDetailsBtn, findsOneWidget);
    await tester.tap(closeDetailsBtn);
    await tester.pumpAndSettle();

    // Verify we are back on bracket screen
    expect(find.byType(BracketViewScreen), findsOneWidget);
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
