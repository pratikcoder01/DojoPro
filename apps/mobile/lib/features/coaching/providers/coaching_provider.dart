import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';

class AvailabilitySlot {
  final DateTime time;
  final bool isBooked;

  AvailabilitySlot({
    required this.time,
    required this.isBooked,
  });
}

class CoachDetail {
  final String id;
  final String name;
  final String avatarUrl;
  final String coverUrl;
  final bool isVerified;
  final List<String> disciplines;
  final double rating;
  final int reviewCount;
  final int sessionsCompleted;
  final int activeStudents;
  final int yearsExperience;
  final String bio;
  final int hourlyRate;
  final List<String> specialties;
  final List<CoachReview> recentReviews;
  final List<AvailabilitySlot> availableSlots;

  CoachDetail({
    required this.id,
    required this.name,
    required this.avatarUrl,
    required this.coverUrl,
    required this.isVerified,
    required this.disciplines,
    required this.rating,
    required this.reviewCount,
    required this.sessionsCompleted,
    required this.activeStudents,
    required this.yearsExperience,
    required this.bio,
    required this.hourlyRate,
    required this.specialties,
    required this.recentReviews,
    required this.availableSlots,
  });

  factory CoachDetail.fromJson(Map<String, dynamic> json) {
    final List<dynamic> reviewsData = json['recentReviews'] ?? [];
    final List<CoachReview> reviews = reviewsData.map((r) => CoachReview.fromJson(r)).toList();

    return CoachDetail(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Sensei',
      avatarUrl: json['avatarUrl']?.toString() ?? '',
      coverUrl: json['coverUrl']?.toString() ?? '',
      isVerified: json['isVerified'] == true,
      disciplines: List<String>.from(json['disciplines'] ?? []),
      rating: (json['rating'] as num?)?.toDouble() ?? 5.0,
      reviewCount: (json['reviewCount'] as num?)?.toInt() ?? 0,
      sessionsCompleted: (json['sessionsCompleted'] as num?)?.toInt() ?? 0,
      activeStudents: (json['activeStudents'] as num?)?.toInt() ?? 0,
      yearsExperience: (json['yearsExperience'] as num?)?.toInt() ?? 0,
      bio: json['bio']?.toString() ?? '',
      hourlyRate: (json['hourlyRate'] as num?)?.toInt() ?? 800,
      specialties: List<String>.from(json['specialties'] ?? []),
      recentReviews: reviews,
      availableSlots: const [], // Populated dynamically
    );
  }
}

class CoachReview {
  final String id;
  final String userName;
  final String userAvatar;
  final double rating;
  final String comment;
  final String date;

  CoachReview({
    required this.id,
    required this.userName,
    required this.userAvatar,
    required this.rating,
    required this.comment,
    required this.date,
  });

  factory CoachReview.fromJson(Map<String, dynamic> json) {
    return CoachReview(
      id: json['id']?.toString() ?? '',
      userName: json['userName']?.toString() ?? 'Anonymous',
      userAvatar: json['userAvatar']?.toString() ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 5.0,
      comment: json['comment']?.toString() ?? '',
      date: json['date']?.toString() ?? '',
    );
  }
}

enum BookingSessionType { inPerson, online }

enum BookingStatus { idle, loading, success, error }

class BookingState {
  final CoachDetail? coach;
  final DateTime? selectedSlot;
  final BookingSessionType sessionType;
  final int durationHours;
  final BookingStatus status;
  final String? errorMessage;
  final String? paymentIntentId;
  final String? razorpayOrderId;
  final String selectedPaymentMethod; // 'stripe' or 'razorpay'

  BookingState({
    this.coach,
    this.selectedSlot,
    this.sessionType = BookingSessionType.inPerson,
    this.durationHours = 1,
    this.status = BookingStatus.idle,
    this.errorMessage,
    this.paymentIntentId,
    this.razorpayOrderId,
    this.selectedPaymentMethod = 'stripe',
  });

  BookingState copyWith({
    CoachDetail? coach,
    DateTime? selectedSlot,
    BookingSessionType? sessionType,
    int? durationHours,
    BookingStatus? status,
    String? errorMessage,
    String? paymentIntentId,
    String? razorpayOrderId,
    String? selectedPaymentMethod,
  }) {
    return BookingState(
      coach: coach ?? this.coach,
      selectedSlot: selectedSlot ?? this.selectedSlot,
      sessionType: sessionType ?? this.sessionType,
      durationHours: durationHours ?? this.durationHours,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      paymentIntentId: paymentIntentId ?? this.paymentIntentId,
      razorpayOrderId: razorpayOrderId ?? this.razorpayOrderId,
      selectedPaymentMethod: selectedPaymentMethod ?? this.selectedPaymentMethod,
    );
  }
}

class CoachingNotifier extends StateNotifier<BookingState> {
  final Dio _dio;

  CoachingNotifier(this._dio) : super(BookingState()) {
    loadCoachDetails();
  }

  // Fallback mock details matching Dark Premium guidelines
  static final CoachDetail _mockCoachDetails = CoachDetail(
    id: 'coach_priya_rao',
    name: 'Sensei Priya Rao',
    avatarUrl: 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=150',
    coverUrl: 'https://images.unsplash.com/photo-1517649763962-0c623066013b?w=800',
    isVerified: true,
    disciplines: const ['Karate', 'Self-Defense', 'Competition Prep'],
    rating: 4.8,
    reviewCount: 127,
    sessionsCompleted: 1420,
    activeStudents: 85,
    yearsExperience: 12,
    bio: 'Black belt in Shotokan Karate and Brazilian Jiu-Jitsu. Over 12 years of coaching professional athletes in Mumbai. Specialized in explosive striking mechanics and active competition prep.',
    hourlyRate: 800,
    specialties: const ['Explosive Striking', 'Youth Mentorship', 'Tournament Strategy', 'Advanced Kumite'],
    recentReviews: [
      CoachReview(
        id: 'rev_1',
        userName: 'Arjun Mehta',
        userAvatar: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=80',
        rating: 5.0,
        comment: 'Sensei Priya is incredible. Her attention to detail on hip rotation during kicks completely changed my sparring game.',
        date: '2 days ago',
      ),
      CoachReview(
        id: 'rev_2',
        userName: 'Rohan Sharma',
        userAvatar: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=80',
        rating: 5.0,
        comment: 'Highly structured class. Ideal for anyone preparing for state tournaments in Maharashtra.',
        date: '1 week ago',
      ),
      CoachReview(
        id: 'rev_3',
        userName: 'Pooja Patel',
        userAvatar: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=80',
        rating: 4.8,
        comment: 'Excellent self-defense drills. She explains the physics of leverage so well!',
        date: '3 weeks ago',
      ),
    ],
    availableSlots: const [], // Populated dynamically
  );

  // Fetch coach details (Mumbai Sensei Priya Rao)
  Future<void> loadCoachDetails() async {
    try {
      state = state.copyWith(status: BookingStatus.loading);

      final now = DateTime.now();
      final baseDate = DateTime(now.year, now.month, now.day);
      final List<DateTime> mockTimes = [
        baseDate.add(const Duration(days: 0, hours: 10)), // Today 10:00 AM
        baseDate.add(const Duration(days: 0, hours: 15)), // Today 3:00 PM (Booked)
        baseDate.add(const Duration(days: 1, hours: 11)), // Tomorrow 11:00 AM
        baseDate.add(const Duration(days: 1, hours: 16)), // Tomorrow 4:00 PM
        baseDate.add(const Duration(days: 2, hours: 9)),  // Day after 9:00 AM (Booked)
        baseDate.add(const Duration(days: 2, hours: 14)), // Day after 2:00 PM
        baseDate.add(const Duration(days: 3, hours: 10)), // Next day 10:00 AM
        baseDate.add(const Duration(days: 3, hours: 17)), // Next day 5:00 PM
      ];

      // Query from API
      final response = await _dio.get(
        'http://localhost:3001/api/v1/coaching/coaches/coach_priya_rao',
        options: Options(
          receiveTimeout: const Duration(seconds: 5),
          sendTimeout: const Duration(seconds: 5),
        ),
      );

      if (response.statusCode == 200) {
        final coachRaw = response.data['coach'];
        final coachParsed = CoachDetail.fromJson(coachRaw);

        // Fetch availability weekly slots
        final availabilityResponse = await _dio.get(
          'http://localhost:3001/api/v1/coaching/coaches/coach_priya_rao/availability',
          queryParameters: {'week': '2024-W12'},
        );

        List<AvailabilitySlot> finalSlots = [];
        if (availabilityResponse.statusCode == 200) {
          final List<dynamic> slotsRaw = availabilityResponse.data['slots'] ?? [];
          if (slotsRaw.isNotEmpty) {
            finalSlots = slotsRaw
                .map((s) => AvailabilitySlot(
                      time: DateTime.parse(s['time'].toString()),
                      isBooked: s['isBooked'] == true,
                    ))
                .toList();
          }
        }

        if (finalSlots.isEmpty) {
          finalSlots = mockTimes
              .map((time) => AvailabilitySlot(
                    time: time,
                    isBooked: time.hour == 15 || time.hour == 9,
                  ))
              .toList();
        }

        final coach = CoachDetail(
          id: coachParsed.id,
          name: coachParsed.name,
          avatarUrl: coachParsed.avatarUrl,
          coverUrl: coachParsed.coverUrl,
          isVerified: coachParsed.isVerified,
          disciplines: coachParsed.disciplines,
          rating: coachParsed.rating,
          reviewCount: coachParsed.reviewCount,
          sessionsCompleted: coachParsed.sessionsCompleted,
          activeStudents: coachParsed.activeStudents,
          yearsExperience: coachParsed.yearsExperience,
          bio: coachParsed.bio,
          hourlyRate: coachParsed.hourlyRate,
          specialties: coachParsed.specialties,
          recentReviews: coachParsed.recentReviews,
          availableSlots: finalSlots,
        );

        state = state.copyWith(
          coach: coach,
          status: BookingStatus.idle,
        );
      } else {
        throw Exception('Server returned ${response.statusCode}');
      }
    } catch (e) {
      // Fallback local loading in offline mode
      final now = DateTime.now();
      final baseDate = DateTime(now.year, now.month, now.day);
      final List<DateTime> mockTimes = [
        baseDate.add(const Duration(days: 0, hours: 10)), // Today 10:00 AM
        baseDate.add(const Duration(days: 0, hours: 15)), // Today 3:00 PM (Booked)
        baseDate.add(const Duration(days: 1, hours: 11)), // Tomorrow 11:00 AM
        baseDate.add(const Duration(days: 1, hours: 16)), // Tomorrow 4:00 PM
        baseDate.add(const Duration(days: 2, hours: 9)),  // Day after 9:00 AM (Booked)
        baseDate.add(const Duration(days: 2, hours: 14)), // Day after 2:00 PM
        baseDate.add(const Duration(days: 3, hours: 10)), // Next day 10:00 AM
      ];

      final List<AvailabilitySlot> finalSlots = mockTimes
          .map((time) => AvailabilitySlot(
                time: time,
                isBooked: time.hour == 15 || time.hour == 9,
              ))
          .toList();

      final coach = CoachDetail(
        id: _mockCoachDetails.id,
        name: _mockCoachDetails.name,
        avatarUrl: _mockCoachDetails.avatarUrl,
        coverUrl: _mockCoachDetails.coverUrl,
        isVerified: _mockCoachDetails.isVerified,
        disciplines: _mockCoachDetails.disciplines,
        rating: _mockCoachDetails.rating,
        reviewCount: _mockCoachDetails.reviewCount,
        sessionsCompleted: _mockCoachDetails.sessionsCompleted,
        activeStudents: _mockCoachDetails.activeStudents,
        yearsExperience: _mockCoachDetails.yearsExperience,
        bio: _mockCoachDetails.bio,
        hourlyRate: _mockCoachDetails.hourlyRate,
        specialties: _mockCoachDetails.specialties,
        recentReviews: _mockCoachDetails.recentReviews,
        availableSlots: finalSlots,
      );

      state = state.copyWith(
        coach: coach,
        status: BookingStatus.idle,
      );
    }
  }

  void selectSlot(DateTime slot) {
    state = state.copyWith(selectedSlot: slot);
  }

  void selectSessionType(BookingSessionType type) {
    state = state.copyWith(sessionType: type);
  }

  void selectDuration(int hours) {
    state = state.copyWith(durationHours: hours);
  }

  void selectPaymentMethod(String method) {
    state = state.copyWith(selectedPaymentMethod: method);
  }

  // Create booking & checkout payments flow
  Future<bool> processBookingPayment() async {
    if (state.coach == null || state.selectedSlot == null) {
      state = state.copyWith(
        status: BookingStatus.error,
        errorMessage: 'Please select an availability slot first.',
      );
      return false;
    }

    try {
      state = state.copyWith(status: BookingStatus.loading);

      final totalAmount = state.coach!.hourlyRate * state.durationHours;
      final athleteId = '00000000-0000-0000-0000-000000000000'; // Default mock athlete user id

      // 1. Create booking transaction
      final bookingResponse = await _dio.post(
        'http://localhost:3001/api/v1/coaching/bookings',
        data: {
          'coach_id': state.coach!.id,
          'athlete_id': athleteId,
          'scheduled_at': state.selectedSlot!.toIso8601String(),
          'duration_mins': state.durationHours * 60,
          'type': state.sessionType == BookingSessionType.online ? 'online' : 'in-person',
          'amount_paise': totalAmount * 100
        },
        options: Options(
          receiveTimeout: const Duration(seconds: 5),
          sendTimeout: const Duration(seconds: 5),
        ),
      );

      if (bookingResponse.statusCode == 200 || bookingResponse.statusCode == 201) {
        final bookingData = bookingResponse.data['booking'];
        final bookingId = bookingData['id'];

        // 2. Initialize Payment Intent/Order Checkout
        final checkoutResponse = await _dio.post(
          'http://localhost:3001/api/v1/coaching/payments/checkout',
          data: {
            'booking_id': bookingId,
            'amount_paise': totalAmount * 100,
            'currency': 'INR'
          },
        );

        if (checkoutResponse.statusCode == 200) {
          final checkoutData = checkoutResponse.data;
          final intentId = checkoutData['paymentIntentId'] as String?;
          final orderId = checkoutData['razorpayOrderId'] as String?;

          // Simulate payment network wait
          await Future.delayed(const Duration(milliseconds: 1500));

          state = state.copyWith(
            status: BookingStatus.success,
            paymentIntentId: intentId ?? 'pi_live_success_123',
            razorpayOrderId: orderId ?? 'order_live_success_123',
          );
          return true;
        }
      }
      throw Exception('Payment backend initialization failed.');
    } catch (_) {
      // Fallback offline payment success
      await Future.delayed(const Duration(milliseconds: 1500));
      state = state.copyWith(
        status: BookingStatus.success,
        paymentIntentId: 'pi_mock_offline_success',
        razorpayOrderId: 'order_mock_offline_success',
      );
      return true;
    }
  }

  void resetBookingState() {
    state = BookingState(
      coach: state.coach,
      selectedSlot: null,
      sessionType: BookingSessionType.inPerson,
      durationHours: 1,
      status: BookingStatus.idle,
      selectedPaymentMethod: 'stripe',
    );
  }
}

final coachingProvider = StateNotifierProvider<CoachingNotifier, BookingState>((ref) {
  final dio = Dio();
  return CoachingNotifier(dio);
});
