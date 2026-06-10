import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/main.dart';

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

  testWidgets('App launch smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(
        child: DojoProApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify that our brand name is found on the splash screen.
    expect(find.text('DOJOPRO'), findsOneWidget);
  });
}
