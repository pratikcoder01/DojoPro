import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';

class DiscoverGym {
  final String id;
  final String name;
  final List<String> styles;
  final double lat;
  final double lng;
  final double rating;
  final double distanceKm;
  final bool isOpen;
  final List<String> photos;
  final List<String> coaches;
  final List<String> schedule;

  DiscoverGym({
    required this.id,
    required this.name,
    required this.styles,
    required this.lat,
    required this.lng,
    required this.rating,
    required this.distanceKm,
    required this.isOpen,
    required this.photos,
    required this.coaches,
    required this.schedule,
  });

  factory DiscoverGym.fromJson(Map<String, dynamic> json) {
    return DiscoverGym(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Unknown Dojo',
      styles: List<String>.from(json['styles'] ?? []),
      lat: (json['lat'] as num?)?.toDouble() ?? 19.0760,
      lng: (json['lng'] as num?)?.toDouble() ?? 72.8777,
      rating: (json['rating'] as num?)?.toDouble() ?? 4.0,
      distanceKm: (json['distance_km'] as num?)?.toDouble() ?? 0.0,
      isOpen: json['isOpen'] == true,
      photos: List<String>.from(json['photos'] ?? []),
      coaches: List<String>.from(json['coaches'] ?? []),
      schedule: List<String>.from(json['schedule'] ?? []),
    );
  }
}

class DiscoverState {
  final List<DiscoverGym> gyms;
  final bool isLoading;
  final String selectedStyleFilter;
  final bool distanceFilter;
  final bool openNowFilter;
  final bool highRatingFilter;
  final bool hasPermission;
  final bool permissionRequested;
  final String? errorMessage;
  final double? userLat;
  final double? userLng;

  DiscoverState({
    this.gyms = const [],
    this.isLoading = false,
    this.selectedStyleFilter = "All Styles",
    this.distanceFilter = false,
    this.openNowFilter = false,
    this.highRatingFilter = false,
    this.hasPermission = false,
    this.permissionRequested = false,
    this.errorMessage,
    this.userLat,
    this.userLng,
  });

  DiscoverState copyWith({
    List<DiscoverGym>? gyms,
    bool? isLoading,
    String? selectedStyleFilter,
    bool? distanceFilter,
    bool? openNowFilter,
    bool? highRatingFilter,
    bool? hasPermission,
    bool? permissionRequested,
    String? errorMessage,
    double? userLat,
    double? userLng,
  }) {
    return DiscoverState(
      gyms: gyms ?? this.gyms,
      isLoading: isLoading ?? this.isLoading,
      selectedStyleFilter: selectedStyleFilter ?? this.selectedStyleFilter,
      distanceFilter: distanceFilter ?? this.distanceFilter,
      openNowFilter: openNowFilter ?? this.openNowFilter,
      highRatingFilter: highRatingFilter ?? this.highRatingFilter,
      hasPermission: hasPermission ?? this.hasPermission,
      permissionRequested: permissionRequested ?? this.permissionRequested,
      errorMessage: errorMessage ?? this.errorMessage,
      userLat: userLat ?? this.userLat,
      userLng: userLng ?? this.userLng,
    );
  }
}

class DiscoverNotifier extends StateNotifier<DiscoverState> {
  final Dio _dio;

  // Local fallback mock dataset
  static final List<DiscoverGym> _mockGyms = [
    DiscoverGym(
      id: 'gym_001',
      name: 'Dharavi MMA & BJJ Academy',
      styles: const ['BJJ', 'MMA'],
      lat: 19.0380,
      lng: 72.8538,
      rating: 4.8,
      distanceKm: 2.1,
      isOpen: true,
      photos: const [
        'https://images.unsplash.com/photo-1517649763962-0c623066013b?w=800',
        'https://images.unsplash.com/photo-1555597673-b21d5c935865?w=800',
        'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=800'
      ],
      coaches: const ['Sensei Priya Rao', 'Coach Vikram Singh'],
      schedule: const [
        'Mon - Fri: 7:00 AM - 9:00 PM',
        'Sat: 8:00 AM - 12:00 PM',
        'Sun: Closed'
      ],
    ),
    DiscoverGym(
      id: 'gym_002',
      name: 'Bandra Striking & Karate Dojo',
      styles: const ['Karate', 'Self-Defense'],
      lat: 19.0596,
      lng: 72.8295,
      rating: 4.6,
      distanceKm: 3.5,
      isOpen: true,
      photos: const [
        'https://images.unsplash.com/photo-1555597673-b21d5c935865?w=800',
        'https://images.unsplash.com/photo-1517649763962-0c623066013b?w=800'
      ],
      coaches: const ['Sensei Priya Rao'],
      schedule: const [
        'Mon - Wed - Fri: 6:00 AM - 8:00 PM',
        'Tue - Thu: 4:00 PM - 9:00 PM',
        'Sat: 9:00 AM - 1:00 PM'
      ],
    ),
    DiscoverGym(
      id: 'gym_003',
      name: 'Colaba Judo & Wrestling Center',
      styles: const ['Judo', 'Wrestling'],
      lat: 18.9067,
      lng: 72.8147,
      rating: 4.9,
      distanceKm: 12.0,
      isOpen: false,
      photos: const [
        'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=800',
        'https://images.unsplash.com/photo-1517649763962-0c623066013b?w=800'
      ],
      coaches: const ['Anita Desai'],
      schedule: const [
        'Tue - Thu - Sat: 8:00 AM - 10:00 PM',
        'Mon - Wed: Closed'
      ],
    ),
    DiscoverGym(
      id: 'gym_004',
      name: 'Andheri Fight Club (MMA)',
      styles: const ['MMA', 'Muay Thai'],
      lat: 19.1136,
      lng: 72.8697,
      rating: 4.7,
      distanceKm: 5.2,
      isOpen: true,
      photos: const [
        'https://images.unsplash.com/photo-1517649763962-0c623066013b?w=800',
        'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=800'
      ],
      coaches: const ['Coach Vikram Singh'],
      schedule: const [
        'Mon - Sat: 6:00 AM - 11:00 PM',
        'Sun: 9:00 AM - 5:00 PM'
      ],
    ),
    DiscoverGym(
      id: 'gym_005',
      name: 'Juhu Beach Karate Academy',
      styles: const ['Karate'],
      lat: 19.0988,
      lng: 72.8264,
      rating: 4.2,
      distanceKm: 4.8,
      isOpen: true,
      photos: const [
        'https://images.unsplash.com/photo-1555597673-b21d5c935865?w=800'
      ],
      coaches: const ['Arjun Mehta'],
      schedule: const [
        'Mon - Sun: 5:00 AM - 9:00 AM'
      ],
    ),
  ];

  DiscoverNotifier(this._dio) : super(DiscoverState());

  // Simulate Location Permission Request
  Future<void> requestLocationPermission() async {
    state = state.copyWith(isLoading: true);
    await Future.delayed(const Duration(seconds: 1)); // Mock location permission delay
    
    // Position user in center of Mumbai for discovery mapping
    state = state.copyWith(
      hasPermission: true,
      permissionRequested: true,
      userLat: 19.0760,
      userLng: 72.8777,
      isLoading: false,
    );
    
    await fetchGyms();
  }

  // Set selected style filter
  void setStyleFilter(String style) {
    state = state.copyWith(selectedStyleFilter: style);
    fetchGyms();
  }

  // Toggle distance limit filter (< 5km)
  void toggleDistanceFilter() {
    state = state.copyWith(distanceFilter: !state.distanceFilter);
    fetchGyms();
  }

  // Toggle open status filter (Open Now)
  void toggleOpenNowFilter() {
    state = state.copyWith(openNowFilter: !state.openNowFilter);
    fetchGyms();
  }

  // Toggle high rating filter (4★+)
  void toggleHighRatingFilter() {
    state = state.copyWith(highRatingFilter: !state.highRatingFilter);
    fetchGyms();
  }

  // Fetch gyms from API with fallback
  Future<void> fetchGyms() async {
    if (!state.hasPermission || state.userLat == null || state.userLng == null) {
      return;
    }

    try {
      state = state.copyWith(isLoading: true, errorMessage: null);

      // Build parameters
      final Map<String, dynamic> queryParams = {
        'lat': state.userLat,
        'lng': state.userLng,
        'radius': state.distanceFilter ? 5 : 10,
        if (state.selectedStyleFilter != 'All Styles') 'style': state.selectedStyleFilter,
        if (state.openNowFilter) 'openNow': true,
        if (state.highRatingFilter) 'minRating': 4.0,
      };

      final response = await _dio.get(
        'http://localhost:3001/api/v1/gyms/nearby',
        queryParameters: queryParams,
        options: Options(
          receiveTimeout: const Duration(seconds: 5),
          sendTimeout: const Duration(seconds: 5),
        ),
      );

      if (response.statusCode == 200) {
        final List<dynamic> gymsData = response.data['gyms'] ?? [];
        final List<DiscoverGym> fetchedGyms = gymsData.map((json) => DiscoverGym.fromJson(json)).toList();

        state = state.copyWith(
          gyms: fetchedGyms,
          isLoading: false,
        );
      } else {
        throw Exception('Server returned ${response.statusCode}');
      }
    } catch (e) {
      // Fallback: Perform local filtering in memory
      var filtered = List<DiscoverGym>.from(_mockGyms);

      // 1. Style filter
      if (state.selectedStyleFilter != 'All Styles') {
        filtered = filtered.where((g) => g.styles.contains(state.selectedStyleFilter)).toList();
      }

      // 2. Distance (< 5km)
      if (state.distanceFilter) {
        filtered = filtered.where((g) => g.distanceKm < 5.0).toList();
      }

      // 3. Open Now
      if (state.openNowFilter) {
        filtered = filtered.where((g) => g.isOpen).toList();
      }

      // 4. Rating (4★+)
      if (state.highRatingFilter) {
        filtered = filtered.where((g) => g.rating >= 4.0).toList();
      }

      state = state.copyWith(
        gyms: filtered,
        isLoading: false,
      );
    }
  }
}

final discoverProvider = StateNotifierProvider<DiscoverNotifier, DiscoverState>((ref) {
  final dio = Dio();
  return DiscoverNotifier(dio);
});
