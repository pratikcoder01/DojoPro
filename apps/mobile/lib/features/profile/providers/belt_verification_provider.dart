import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'dart:async';

class BeltVerificationState {
  final String selectedDiscipline;
  final String selectedBelt;
  final String? videoPath;
  final String? certificatePath;
  final double uploadProgress;
  final bool isUploading;
  final String searchedGymQuery;
  final String? selectedGymId;
  final String? selectedGymName;
  final String verificationStatus; // 'none', 'submitting', 'pending', 'approved'
  final bool isBurstActive;
  final int wizardStep;
  final List<Map<String, dynamic>> gymsList;
  final bool isLoadingGyms;
  final String? errorMessage;

  BeltVerificationState({
    this.selectedDiscipline = 'Karate',
    this.selectedBelt = 'white',
    this.videoPath,
    this.certificatePath,
    this.uploadProgress = 0.0,
    this.isUploading = false,
    this.searchedGymQuery = '',
    this.selectedGymId,
    this.selectedGymName,
    this.verificationStatus = 'none',
    this.isBurstActive = false,
    this.wizardStep = 1,
    this.gymsList = const [],
    this.isLoadingGyms = false,
    this.errorMessage,
  });

  BeltVerificationState copyWith({
    String? selectedDiscipline,
    String? selectedBelt,
    String? videoPath,
    String? certificatePath,
    double? uploadProgress,
    bool? isUploading,
    String? searchedGymQuery,
    String? selectedGymId,
    String? selectedGymName,
    String? verificationStatus,
    bool? isBurstActive,
    int? wizardStep,
    List<Map<String, dynamic>>? gymsList,
    bool? isLoadingGyms,
    String? errorMessage,
  }) {
    return BeltVerificationState(
      selectedDiscipline: selectedDiscipline ?? this.selectedDiscipline,
      selectedBelt: selectedBelt ?? this.selectedBelt,
      videoPath: videoPath ?? this.videoPath,
      certificatePath: certificatePath ?? this.certificatePath,
      uploadProgress: uploadProgress ?? this.uploadProgress,
      isUploading: isUploading ?? this.isUploading,
      searchedGymQuery: searchedGymQuery ?? this.searchedGymQuery,
      selectedGymId: selectedGymId ?? this.selectedGymId,
      selectedGymName: selectedGymName ?? this.selectedGymName,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      isBurstActive: isBurstActive ?? this.isBurstActive,
      wizardStep: wizardStep ?? this.wizardStep,
      gymsList: gymsList ?? this.gymsList,
      isLoadingGyms: isLoadingGyms ?? this.isLoadingGyms,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class BeltVerificationNotifier extends StateNotifier<BeltVerificationState> {
  final Dio _dio;
  Timer? _uploadTimer;

  // Mock list of gyms matching our discovery features
  static final List<Map<String, dynamic>> _mockGyms = [
    {'id': 'gym_001', 'name': 'Dharavi MMA & BJJ Academy'},
    {'id': 'gym_002', 'name': 'Bandra Striking & Karate Dojo'},
    {'id': 'gym_003', 'name': 'Colaba Judo & Wrestling Center'},
    {'id': 'gym_004', 'name': 'Andheri Fight Club (MMA)'},
    {'id': 'gym_005', 'name': 'Juhu Beach Karate Academy'},
  ];

  BeltVerificationNotifier(this._dio) : super(BeltVerificationState()) {
    searchGyms('');
  }

  void setDiscipline(String disc) {
    state = state.copyWith(selectedDiscipline: disc);
  }

  void setBelt(String belt) {
    state = state.copyWith(selectedBelt: belt);
  }

  void setVideoPath(String path) {
    state = state.copyWith(videoPath: path);
  }

  void setCertificatePath(String path) {
    state = state.copyWith(certificatePath: path);
  }

  void setWizardStep(int step) {
    state = state.copyWith(wizardStep: step);
  }

  // Search and filter verifying gyms list
  Future<void> searchGyms(String query) async {
    state = state.copyWith(isLoadingGyms: true, searchedGymQuery: query);

    try {
      final response = await _dio.get(
        'http://localhost:3001/api/v1/gyms/nearby',
        queryParameters: {
          'lat': 19.0760,
          'lng': 72.8777,
          'radius': 15,
          if (query.isNotEmpty) 'style': query,
        },
        options: Options(
          receiveTimeout: const Duration(seconds: 5),
          sendTimeout: const Duration(seconds: 5),
        ),
      );

      if (response.statusCode == 200) {
        final List<dynamic> gymsData = response.data['gyms'] ?? [];
        final List<Map<String, dynamic>> parsedGyms = gymsData
            .map((json) => {
                  'id': json['id']?.toString() ?? '',
                  'name': json['name']?.toString() ?? '',
                })
            .toList();
        state = state.copyWith(gymsList: parsedGyms, isLoadingGyms: false);
      } else {
        throw Exception('Server returned ${response.statusCode}');
      }
    } catch (_) {
      // Fallback local search filtering in offline mode
      final List<Map<String, dynamic>> filtered = _mockGyms
          .where((g) =>
              query.isEmpty ||
              g['name'].toString().toLowerCase().contains(query.toLowerCase()))
          .toList();

      state = state.copyWith(gymsList: filtered, isLoadingGyms: false);
    }
  }

  void selectGym(String id, String name) {
    state = state.copyWith(selectedGymId: id, selectedGymName: name);
  }

  // Simulated Evidence File Uploads (Video via Mux, Certificate to S3)
  void startUploadSimulation() {
    if (state.isUploading) return;

    state = state.copyWith(isUploading: true, uploadProgress: 0.0);
    _uploadTimer = Timer.periodic(const Duration(milliseconds: 150), (timer) {
      final currentProgress = state.uploadProgress + 0.1;
      if (currentProgress >= 1.0) {
        timer.cancel();
        state = state.copyWith(
          isUploading: false,
          uploadProgress: 1.0,
          wizardStep: 3, // Auto transition to gym select step
        );
      } else {
        state = state.copyWith(uploadProgress: currentProgress);
      }
    });
  }

  // Submit Belt verification request to API
  Future<bool> submitVerificationRequest() async {
    if (state.selectedGymId == null) {
      state = state.copyWith(errorMessage: 'Please select a verifying gym.');
      return false;
    }

    try {
      state = state.copyWith(verificationStatus: 'submitting', errorMessage: null);

      final response = await _dio.post(
        'http://localhost:3001/api/v1/belts/verify',
        data: {
          'discipline': state.selectedDiscipline,
          'level': state.selectedBelt,
          'video_url': 'https://assets.mixkit.co/videos/preview/mixkit-martial-arts-trainer-practicing-karate-kicks-40334-large.mp4',
          'certificate_url': 'https://images.unsplash.com/photo-1555597673-b21d5c935865?w=800',
          'gym_id': state.selectedGymId
        },
        options: Options(
          receiveTimeout: const Duration(seconds: 5),
          sendTimeout: const Duration(seconds: 5),
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        state = state.copyWith(verificationStatus: 'pending');
        
        // Auto-approve in local demo for step 4 presentation flow
        _triggerAutoApproveMock();
        return true;
      } else {
        throw Exception('Server returned ${response.statusCode}');
      }
    } catch (_) {
      // Fallback offline submission success
      state = state.copyWith(verificationStatus: 'pending');
      _triggerAutoApproveMock();
      return true;
    }
  }

  // Auto-approves verification request after 3 seconds in demo to show Step 4 verified badge
  void _triggerAutoApproveMock() {
    Future.delayed(const Duration(seconds: 3), () {
      state = state.copyWith(
        verificationStatus: 'approved',
        isBurstActive: true,
        wizardStep: 4, // Transition to Step 4: Verified badge page
      );
      
      // Turn off shimmer burst after animation finishes (1500ms)
      Future.delayed(const Duration(milliseconds: 1500), () {
        state = state.copyWith(isBurstActive: false);
      });
    });
  }

  // Manual reset of validation flow
  void resetFlow() {
    state = BeltVerificationState();
    searchGyms('');
  }

  @override
  void dispose() {
    _uploadTimer?.cancel();
    super.dispose();
  }
}

final beltVerificationProvider =
    StateNotifierProvider<BeltVerificationNotifier, BeltVerificationState>((ref) {
  final dio = Dio();
  return BeltVerificationNotifier(dio);
});
