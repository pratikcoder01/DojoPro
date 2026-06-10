import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/features/profile/screens/belt_verification_screen.dart';

void main() {
  setUpAll(() {
    // Disable runtime HTTP fetching for Google Fonts in headless test mode
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('Belt Verification 4-Step Wizard Navigation and Selections Test', (WidgetTester tester) async {
    // 1. Render BeltVerificationScreen
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: BeltVerificationScreen(),
        ),
      ),
    );

    // 2. Verify Step 1 is active (Discipline & Belt Level Picker)
    expect(find.text('CHOOSE DISCIPLINE'), findsOneWidget);
    expect(find.text('SELECT BELT LEVEL'), findsOneWidget);
    expect(find.text('WHITE'), findsOneWidget); // Default selected belt display name in Bebas Neue

    // Tap Taekwondo card in discipline grid
    expect(find.text('Taekwondo'), findsOneWidget);
    await tester.tap(find.text('Taekwondo'));
    await tester.pump(const Duration(milliseconds: 100));

    // Tap Continue button to navigate to Step 2 (Upload Evidence)
    expect(find.text('CONTINUE TO UPLOAD'), findsOneWidget);
    await tester.tap(find.text('CONTINUE TO UPLOAD'));
    await tester.pump(const Duration(milliseconds: 100));

    // 3. Verify Step 2 is active (Upload Evidence Screen)
    expect(find.text('UPLOAD EVIDENCE'), findsOneWidget);
    expect(find.text('REQUIREMENT INSTRUCTIONS'), findsOneWidget);
    expect(find.text('UPLOAD KATA VIDEO DEMO'), findsOneWidget);

    // Tap to select mock video & certificate evidence files
    await tester.tap(find.text('UPLOAD KATA VIDEO DEMO'));
    await tester.pump(const Duration(milliseconds: 100));

    final certFinder = find.text('UPLOAD CERTIFICATE / CREDENTIAL PHOTO');
    await tester.ensureVisible(certFinder);
    await tester.tap(certFinder);
    await tester.pump(const Duration(milliseconds: 100));

    // Verify files attached successfully and button text changed
    expect(find.text('KATA_DEMO.MP4 ATTACHED'), findsOneWidget);
    expect(find.text('CERTIFICATE_PHOTO.JPG ATTACHED'), findsOneWidget);
    expect(find.text('CONTINUE TO GYM VERIFICATION'), findsOneWidget);
  });
}
