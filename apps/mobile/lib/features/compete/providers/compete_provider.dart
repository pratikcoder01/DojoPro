import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';

class Tournament {
  final String id;
  final String title;
  final String discipline;
  final String city;
  final String locationName;
  final String startDate;
  final String registrationDeadline;
  final int feePaise;
  final int maxParticipants;
  final int currentParticipants;
  final String status; // 'open' | 'closed' | 'completed'
  final String format; // 'kata' | 'kumite' | 'both'
  final String weightClass;
  final bool isRegistered;
  final dynamic bracket;

  Tournament({
    required this.id,
    required this.title,
    required this.discipline,
    required this.city,
    required this.locationName,
    required this.startDate,
    required this.registrationDeadline,
    required this.feePaise,
    required this.maxParticipants,
    required this.currentParticipants,
    required this.status,
    required this.format,
    required this.weightClass,
    required this.isRegistered,
    required this.bracket,
  });

  Tournament copyWith({
    bool? isRegistered,
    int? currentParticipants,
  }) {
    return Tournament(
      id: id,
      title: title,
      discipline: discipline,
      city: city,
      locationName: locationName,
      startDate: startDate,
      registrationDeadline: registrationDeadline,
      feePaise: feePaise,
      maxParticipants: maxParticipants,
      currentParticipants: currentParticipants ?? this.currentParticipants,
      status: status,
      format: format,
      weightClass: weightClass,
      isRegistered: isRegistered ?? this.isRegistered,
      bracket: bracket,
    );
  }

  factory Tournament.fromJson(Map<String, dynamic> json) {
    return Tournament(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      discipline: json['discipline']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      locationName: json['location_name']?.toString() ?? '',
      startDate: json['start_date']?.toString() ?? '',
      registrationDeadline: json['registration_deadline']?.toString() ?? '',
      feePaise: (json['fee_paise'] as num?)?.toInt() ?? 0,
      maxParticipants: (json['max_participants'] as num?)?.toInt() ?? 100,
      currentParticipants: (json['current_participants'] as num?)?.toInt() ?? 0,
      status: json['status']?.toString() ?? 'open',
      format: json['format']?.toString() ?? 'both',
      weightClass: json['weight_class']?.toString() ?? 'Open Weight',
      isRegistered: json['isRegistered'] == true,
      bracket: json['bracket'],
    );
  }
}

enum CompeteStatus { idle, loading, success, error }

class CompeteState {
  final List<Tournament> tournaments;
  final String selectedFilter; // 'All' | 'My Discipline' | 'My City' | 'Open'
  final CompeteStatus status;
  final String? errorMessage;

  CompeteState({
    this.tournaments = const [],
    this.selectedFilter = 'All',
    this.status = CompeteStatus.idle,
    this.errorMessage,
  });

  CompeteState copyWith({
    List<Tournament>? tournaments,
    String? selectedFilter,
    CompeteStatus? status,
    String? errorMessage,
  }) {
    return CompeteState(
      tournaments: tournaments ?? this.tournaments,
      selectedFilter: selectedFilter ?? this.selectedFilter,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class CompeteNotifier extends StateNotifier<CompeteState> {
  final Dio _dio;

  CompeteNotifier(this._dio) : super(CompeteState()) {
    loadTournaments();
  }

  static final List<Tournament> mockTournaments = [
    Tournament(
      id: 'tourn_mumbai_open_123',
      title: 'Mumbai Open Karate Championship',
      discipline: 'Karate',
      city: 'Mumbai',
      locationName: 'Dharavi Sports Complex, Mumbai',
      startDate: DateFormat('yyyy-MM-dd').format(DateTime.now().add(const Duration(days: 15))),
      registrationDeadline: DateFormat('yyyy-MM-dd').format(DateTime.now().add(const Duration(days: 3, hours: 14))),
      feePaise: 50000,
      maxParticipants: 100,
      currentParticipants: 47,
      status: 'open',
      format: 'both',
      weightClass: 'Under 75kg',
      isRegistered: false,
      bracket: null, // Populated via routes
    ),
    Tournament(
      id: 'tourn_bjj_challenge_456',
      title: 'National BJJ Grappling Challenge',
      discipline: 'BJJ',
      city: 'Pune',
      locationName: 'Balewadi Stadium, Pune',
      startDate: DateFormat('yyyy-MM-dd').format(DateTime.now().add(const Duration(days: 30))),
      registrationDeadline: DateFormat('yyyy-MM-dd').format(DateTime.now().add(const Duration(days: 25))),
      feePaise: 75000,
      maxParticipants: 64,
      currentParticipants: 12,
      status: 'open',
      format: 'kumite',
      weightClass: 'Absolute division',
      isRegistered: false,
      bracket: null,
    ),
    Tournament(
      id: 'tourn_tkd_league_789',
      title: 'Maharashtra Taekwondo League',
      discipline: 'Taekwondo',
      city: 'Mumbai',
      locationName: 'BKC Sports Center, Mumbai',
      startDate: DateFormat('yyyy-MM-dd').format(DateTime.now().subtract(const Duration(days: 2))),
      registrationDeadline: DateFormat('yyyy-MM-dd').format(DateTime.now().subtract(const Duration(days: 5))),
      feePaise: 60000,
      maxParticipants: 80,
      currentParticipants: 80,
      status: 'completed',
      format: 'kata',
      weightClass: 'Open Weight',
      isRegistered: false,
      bracket: null,
    ),
  ];

  Future<void> loadTournaments() async {
    try {
      state = state.copyWith(status: CompeteStatus.loading);

      final response = await _dio.get(
        'http://localhost:3001/api/v1/tournaments',
        options: Options(
          receiveTimeout: const Duration(seconds: 5),
          sendTimeout: const Duration(seconds: 5),
        ),
      );

      if (response.statusCode == 200) {
        final List<dynamic> listRaw = response.data['tournaments'] ?? [];
        final list = listRaw.map((t) => Tournament.fromJson(t)).toList();
        state = state.copyWith(tournaments: list, status: CompeteStatus.success);
      } else {
        throw Exception('Server returned ${response.statusCode}');
      }
    } catch (_) {
      state = state.copyWith(
        tournaments: mockTournaments,
        status: CompeteStatus.success,
      );
    }
  }

  void selectFilter(String filter) {
    state = state.copyWith(selectedFilter: filter);
  }

  Future<bool> registerForTournament(String id) async {
    try {
      state = state.copyWith(status: CompeteStatus.loading);

      final athleteId = '00000000-0000-0000-0000-000000000000';
      final paymentIntentId = 'pi_mock_razorpay_${DateTime.now().millisecondsSinceEpoch}';

      final response = await _dio.post(
        'http://localhost:3001/api/v1/tournaments/$id/register',
        data: {
          'athlete_id': athleteId,
          'payment_intent_id': paymentIntentId,
        },
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final updatedTournaments = state.tournaments.map((t) {
          if (t.id == id) {
            return t.copyWith(
              isRegistered: true,
              currentParticipants: t.currentParticipants + 1,
            );
          }
          return t;
        }).toList();

        state = state.copyWith(
          tournaments: updatedTournaments,
          status: CompeteStatus.success,
        );
        return true;
      }
      throw Exception('Registration failed.');
    } catch (_) {
      await Future.delayed(const Duration(milliseconds: 1000));
      final updatedTournaments = state.tournaments.map((t) {
        if (t.id == id) {
          return t.copyWith(
            isRegistered: true,
            currentParticipants: t.currentParticipants + 1,
          );
        }
        return t;
      }).toList();

      state = state.copyWith(
        tournaments: updatedTournaments,
        status: CompeteStatus.success,
      );
      return true;
    }
  }
}

final competeProvider = StateNotifierProvider<CompeteNotifier, CompeteState>((ref) {
  final dio = Dio();
  return CompeteNotifier(dio);
});
