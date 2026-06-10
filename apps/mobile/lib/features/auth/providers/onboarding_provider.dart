import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OnboardingState {
  final String role;
  final List<String> selectedDisciplines;
  final String beltLevel;
  final bool locationGranted;
  final String? profileImagePath;
  final bool isLoading;
  final String? errorMessage;

  OnboardingState({
    this.role = 'athlete',
    this.selectedDisciplines = const [],
    this.beltLevel = 'white',
    this.locationGranted = false,
    this.profileImagePath,
    this.isLoading = false,
    this.errorMessage,
  });

  OnboardingState copyWith({
    String? role,
    List<String>? selectedDisciplines,
    String? beltLevel,
    bool? locationGranted,
    String? profileImagePath,
    bool? isLoading,
    String? errorMessage,
  }) {
    return OnboardingState(
      role: role ?? this.role,
      selectedDisciplines: selectedDisciplines ?? this.selectedDisciplines,
      beltLevel: beltLevel ?? this.beltLevel,
      locationGranted: locationGranted ?? this.locationGranted,
      profileImagePath: profileImagePath ?? this.profileImagePath,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class OnboardingNotifier extends StateNotifier<OnboardingState> {
  final SupabaseClient _supabaseClient;

  OnboardingNotifier(this._supabaseClient) : super(OnboardingState());

  void setRole(String role) {
    state = state.copyWith(role: role);
  }

  void toggleDiscipline(String discipline) {
    final updated = List<String>.from(state.selectedDisciplines);
    if (updated.contains(discipline)) {
      updated.remove(discipline);
    } else {
      updated.add(discipline);
    }
    state = state.copyWith(selectedDisciplines: updated);
  }

  void setBeltLevel(String beltLevel) {
    state = state.copyWith(beltLevel: beltLevel);
  }

  void setLocationGranted(bool granted) {
    state = state.copyWith(locationGranted: granted);
  }

  void setProfileImagePath(String? path) {
    state = state.copyWith(profileImagePath: path);
  }

  // Supabase integration for OAuth registration
  Future<bool> signInWithOAuth(OAuthProvider provider) async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);
      
      // Perform Supabase OAuth sign-in
      final response = await _supabaseClient.auth.signInWithOAuth(
        provider,
        redirectTo: 'dojopro://onboarding-callback',
      );

      state = state.copyWith(isLoading: false);
      return response;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  // Save profile to Supabase users table on completion
  Future<bool> completeOnboarding() async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);

      final currentUser = _supabaseClient.auth.currentUser;
      if (currentUser == null) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'User session not found. Please log in first.',
        );
        return false;
      }

      // Convert disciplines to a comma-separated or first discipline string for DB
      final disciplineString = state.selectedDisciplines.isNotEmpty 
          ? state.selectedDisciplines.join(', ') 
          : 'None';

      // Update public.users table (which maps auth.users by ID)
      await _supabaseClient.from('users').update({
        'role': state.role,
        'belt_level': state.beltLevel,
        'discipline': disciplineString,
        'verified': false,
        'avatar_url': state.profileImagePath, // Store local path as fallback or upload URL
      }).eq('id', currentUser.id);

      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }
}

// Provider definition
final onboardingProvider = StateNotifierProvider<OnboardingNotifier, OnboardingState>((ref) {
  final client = Supabase.instance.client;
  return OnboardingNotifier(client);
});
