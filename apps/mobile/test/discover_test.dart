import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/features/discover/screens/discover_screen.dart';

void main() {
  setUpAll(() {
    // Disable runtime HTTP fetching for Google Fonts in headless test mode
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('Gym Discover screen permission request and bottom sheet list test', (WidgetTester tester) async {
    // 1. Render DiscoverScreen within MaterialApp inside ProviderScope
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: DiscoverScreen(),
        ),
      ),
    );

    // 2. Verify that permission preview screen renders initially
    expect(find.text('DISCOVER YOUR DOJO'), findsOneWidget);
    expect(find.text('GRANT LOCATION PERMISSION'), findsOneWidget);

    // 3. Tap to grant permission and trigger location coordinates fetching
    await tester.tap(find.text('GRANT LOCATION PERMISSION'));
    
    // Pump frames to resolve future delay of mock location retrieval
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    // 4. Verify that bottom sheet renders and lists nearby gyms
    expect(find.text('DOJOS NEARBY'), findsOneWidget);
    expect(find.text('Dharavi MMA & BJJ Academy'), findsOneWidget);
  });
}
