import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/features/auth/screens/onboarding_flow.dart';

class MockLocalStorage extends LocalStorage {
  const MockLocalStorage();

  @override
  Future<void> initialize() async {}

  @override
  Future<String?> accessToken() async => null;

  @override
  Future<bool> hasAccessToken() async => false;

  @override
  Future<void> removePersistedSession() async {}

  @override
  Future<void> persistSession(String session) async {}
}

class MockGotrueAsyncStorage extends GotrueAsyncStorage {
  const MockGotrueAsyncStorage();

  @override
  Future<String?> getItem({required String key}) async => null;

  @override
  Future<void> removeItem({required String key}) async {}

  @override
  Future<void> setItem({required String key, required String value}) async {}
}

void main() {
  setUpAll(() async {
    // Disable GoogleFonts runtime HTTP fetching to prevent test failures
    GoogleFonts.config.allowRuntimeFetching = false;
    
    try {
      await Supabase.initialize(
        url: 'https://mock.supabase.co',
        anonKey: 'mock-anon-key',
        authOptions: const FlutterAuthClientOptions(
          localStorage: MockLocalStorage(),
          pkceAsyncStorage: MockGotrueAsyncStorage(),
        ),
      );
    } catch (_) {
      // Ignore if already initialized
    }
  });

  testWidgets('Onboarding Flow complete navigation and validation test', (WidgetTester tester) async {
    // Build Onboarding Flow within a ProviderScope
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: OnboardingFlow(),
        ),
      ),
    );

    // 1. Verify Step 1 is active (Splash Screen)
    expect(find.text('DOJOPRO'), findsOneWidget);
    expect(find.text('BEGIN ONBOARDING'), findsOneWidget);

    // Tap BEGIN ONBOARDING to go to Step 2 (Signup)
    await tester.tap(find.text('BEGIN ONBOARDING'));
    await tester.pumpAndSettle();

    // 2. Verify Step 2 is active (Signup Screen)
    expect(find.text('CREATE YOUR PROFILE'), findsOneWidget);
    expect(find.text('CONTINUE'), findsOneWidget);

    // Tap CONTINUE to go to Step 3 (Disciplines Selector)
    await tester.tap(find.text('CONTINUE'));
    await tester.pumpAndSettle();

    // 3. Verify Step 3 is active (Disciplines Selector)
    expect(find.text('CHOOSE YOUR DISCIPLINES'), findsOneWidget);

    // Tap CONTINUE. Validation should block navigation since no discipline is selected.
    await tester.tap(find.text('CONTINUE'));
    await tester.pumpAndSettle();

    // We should still be on Step 3
    expect(find.text('CHOOSE YOUR DISCIPLINES'), findsOneWidget);

    // Select a discipline card (Shotokan Karate)
    expect(find.text('Shotokan Karate'), findsOneWidget);
    await tester.tap(find.text('Shotokan Karate'));
    await tester.pumpAndSettle();

    // Now CONTINUE should be enabled. Tap it to go to Step 4 (Rank/Belt Selector)
    await tester.tap(find.text('CONTINUE'));
    await tester.pumpAndSettle();

    // 4. Verify Step 4 is active (Belt Selector)
    expect(find.text('SELECT CURRENT RANK'), findsOneWidget);

    // Tap CONTINUE to go to Step 5 (Location Permission)
    await tester.tap(find.text('CONTINUE'));
    await tester.pumpAndSettle();

    // 5. Verify Step 5 is active (Location Permission)
    expect(find.text('DISCOVER NEARBY DOJOS'), findsOneWidget);

    // Tap CONTINUE to go to Step 6 (Profile Photo)
    await tester.tap(find.text('CONTINUE'));
    await tester.pumpAndSettle();

    // 6. Verify Step 6 is active (Profile Photo)
    expect(find.text('UPLOAD PROFILE PHOTO'), findsOneWidget);
    expect(find.text('GET STARTED'), findsOneWidget);
  });
}
