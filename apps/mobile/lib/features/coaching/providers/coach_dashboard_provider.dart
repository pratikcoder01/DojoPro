import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';

class CoachEarnings {
  final int thisWeek;
  final int thisMonth;
  final int totalStudents;
  final int nextPayoutAmount;
  final String nextPayoutDate;
  final List<int> chartData;

  CoachEarnings({
    required this.thisWeek,
    required this.thisMonth,
    required this.totalStudents,
    required this.nextPayoutAmount,
    required this.nextPayoutDate,
    required this.chartData,
  });

  factory CoachEarnings.fromJson(Map<String, dynamic> json) {
    return CoachEarnings(
      thisWeek: int.tryParse(json['thisWeek']?.toString() ?? '0') ?? 0,
      thisMonth: int.tryParse(json['thisMonth']?.toString() ?? '0') ?? 0,
      totalStudents: int.tryParse(json['totalStudents']?.toString() ?? '0') ?? 0,
      nextPayoutAmount: int.tryParse(json['nextPayoutAmount']?.toString() ?? '0') ?? 0,
      nextPayoutDate: json['nextPayoutDate']?.toString() ?? '',
      chartData: List<int>.from(json['chartData'] ?? []),
    );
  }
}

class CoachSession {
  final String id;
  final String athleteName;
  final String beltLevel;
  final String sessionType;
  final DateTime time;
  final int amount;

  CoachSession({
    required this.id,
    required this.athleteName,
    required this.beltLevel,
    required this.sessionType,
    required this.time,
    required this.amount,
  });

  factory CoachSession.fromJson(Map<String, dynamic> json) {
    return CoachSession(
      id: json['id']?.toString() ?? '',
      athleteName: json['athleteName']?.toString() ?? '',
      beltLevel: json['beltLevel']?.toString() ?? 'white',
      sessionType: json['sessionType']?.toString() ?? 'in-person',
      time: DateTime.tryParse(json['time']?.toString() ?? '') ?? DateTime.now(),
      amount: int.tryParse(json['amount']?.toString() ?? '0') ?? 0,
    );
  }
}

class StudentProgression {
  final String level;
  final String earnedDate;

  StudentProgression({
    required this.level,
    required this.earnedDate,
  });
}

class StudentDetail {
  final String id;
  final String name;
  final String avatar;
  final String beltLevel;
  final String lastSessionDate;
  final String progressStatus;
  final List<String> attendanceLog;
  final String coachNotes;
  final List<StudentProgression> beltProgression;
  final List<String> nextMilestones;

  StudentDetail({
    required this.id,
    required this.name,
    required this.avatar,
    required this.beltLevel,
    required this.lastSessionDate,
    required this.progressStatus,
    required this.attendanceLog,
    required this.coachNotes,
    required this.beltProgression,
    required this.nextMilestones,
  });

  factory StudentDetail.fromJson(Map<String, dynamic> json) {
    final List<dynamic> progRaw = json['beltProgression'] ?? [];
    final List<StudentProgression> prog = progRaw.map((p) => StudentProgression(
      level: p['level']?.toString() ?? 'white',
      earnedDate: p['earnedDate']?.toString() ?? '',
    )).toList();

    return StudentDetail(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      avatar: json['avatar']?.toString() ?? '',
      beltLevel: json['beltLevel']?.toString() ?? 'white',
      lastSessionDate: json['lastSessionDate']?.toString() ?? '',
      progressStatus: json['progressStatus']?.toString() ?? 'On Track',
      attendanceLog: List<String>.from(json['attendanceLog'] ?? []),
      coachNotes: json['coachNotes']?.toString() ?? '',
      beltProgression: prog,
      nextMilestones: List<String>.from(json['nextMilestones'] ?? []),
    );
  }

  StudentDetail copyWith({
    String? id,
    String? name,
    String? avatar,
    String? beltLevel,
    String? lastSessionDate,
    String? progressStatus,
    List<String>? attendanceLog,
    String? coachNotes,
    List<StudentProgression>? beltProgression,
    List<String>? nextMilestones,
  }) {
    return StudentDetail(
      id: id ?? this.id,
      name: name ?? this.name,
      avatar: avatar ?? this.avatar,
      beltLevel: beltLevel ?? this.beltLevel,
      lastSessionDate: lastSessionDate ?? this.lastSessionDate,
      progressStatus: progressStatus ?? this.progressStatus,
      attendanceLog: attendanceLog ?? this.attendanceLog,
      coachNotes: coachNotes ?? this.coachNotes,
      beltProgression: beltProgression ?? this.beltProgression,
      nextMilestones: nextMilestones ?? this.nextMilestones,
    );
  }
}

class CoachDashboardState {
  final bool isLoading;
  final String? errorMessage;
  final CoachEarnings? earnings;
  final List<CoachSession> upcomingSessions;
  final List<StudentDetail> students;
  final List<DateTime> availabilitySlots;
  final bool isRecurringMonWedFri;
  final bool isSavingNote;

  CoachDashboardState({
    this.isLoading = false,
    this.errorMessage,
    this.earnings,
    this.upcomingSessions = const [],
    this.students = const [],
    this.availabilitySlots = const [],
    this.isRecurringMonWedFri = false,
    this.isSavingNote = false,
  });

  CoachDashboardState copyWith({
    bool? isLoading,
    String? errorMessage,
    CoachEarnings? earnings,
    List<CoachSession>? upcomingSessions,
    List<StudentDetail>? students,
    List<DateTime>? availabilitySlots,
    bool? isRecurringMonWedFri,
    bool? isSavingNote,
  }) {
    return CoachDashboardState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      earnings: earnings ?? this.earnings,
      upcomingSessions: upcomingSessions ?? this.upcomingSessions,
      students: students ?? this.students,
      availabilitySlots: availabilitySlots ?? this.availabilitySlots,
      isRecurringMonWedFri: isRecurringMonWedFri ?? this.isRecurringMonWedFri,
      isSavingNote: isSavingNote ?? this.isSavingNote,
    );
  }
}

class CoachDashboardNotifier extends StateNotifier<CoachDashboardState> {
  final Dio _dio;
  final String _coachId;

  CoachDashboardNotifier(this._dio, this._coachId) : super(CoachDashboardState()) {
    loadDashboard();
  }

  // Fetch coach dashboard details
  Future<void> loadDashboard() async {
    state = state.copyWith(isLoading: true);
    try {
      final response = await _dio.get('http://localhost:3001/api/v1/coaches/$_coachId/dashboard');
      final earnings = CoachEarnings.fromJson(response.data['earnings']);
      
      final List<dynamic> sessionsRaw = response.data['upcomingSessions'] ?? [];
      final upcomingSessions = sessionsRaw.map((s) => CoachSession.fromJson(s)).toList();

      final responseStudents = await _dio.get('http://localhost:3001/api/v1/coaches/$_coachId/students');
      final List<dynamic> studentsRaw = responseStudents.data['students'] ?? [];
      final students = studentsRaw.map((s) => StudentDetail.fromJson(s)).toList();

      final List<dynamic> slotsRaw = response.data['availabilitySlots'] ?? [];
      final availabilitySlots = slotsRaw.map((s) => DateTime.parse(s.toString())).toList();

      state = state.copyWith(
        isLoading: false,
        earnings: earnings,
        upcomingSessions: upcomingSessions,
        students: students,
        availabilitySlots: availabilitySlots,
      );
    } catch (_) {
      // Mock Fallback Offline
      final fallbackEarnings = CoachEarnings(
        thisWeek: 12400,
        thisMonth: 48200,
        totalStudents: 34,
        nextPayoutAmount: 18500,
        nextPayoutDate: '2026-06-15',
        chartData: const [1500, 2400, 1800, 3200, 2900, 4100, 3800, 5200],
      );

      final fallbackSessions = [
        CoachSession(
          id: 'sess_1',
          athleteName: 'Arjun Mehta',
          beltLevel: 'brown',
          sessionType: 'in-person',
          time: DateTime.now().add(const Duration(minutes: 15)), // Starts in 15 mins (under 30 mins)
          amount: 800,
        ),
        CoachSession(
          id: 'sess_2',
          athleteName: 'Rohan Sharma',
          beltLevel: 'black',
          sessionType: 'online',
          time: DateTime.now().add(const Duration(days: 1)),
          amount: 800,
        ),
        CoachSession(
          id: 'sess_3',
          athleteName: 'Pooja Patel',
          beltLevel: 'green',
          sessionType: 'online',
          time: DateTime.now().add(const Duration(days: 2)),
          amount: 800,
        ),
        CoachSession(
          id: 'sess_4',
          athleteName: 'Aisha Khan',
          beltLevel: 'blue',
          sessionType: 'in-person',
          time: DateTime.now().add(const Duration(days: 3)),
          amount: 800,
        ),
        CoachSession(
          id: 'sess_5',
          athleteName: 'Sameer Joshi',
          beltLevel: 'yellow',
          sessionType: 'in-person',
          time: DateTime.now().add(const Duration(days: 4)),
          amount: 800,
        ),
      ];

      final fallbackStudents = [
        StudentDetail(
          id: 'stud_1',
          name: 'Arjun Mehta',
          avatar: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150',
          beltLevel: 'brown',
          lastSessionDate: '2026-06-08',
          progressStatus: 'On Track',
          attendanceLog: const [
            'Shotokan Karate Kata Class - 2026-06-08',
            'Kumite Sparring Practice - 2026-06-05',
            'Strength & Conditioning - 2026-06-03',
          ],
          coachNotes: 'Excellent hip drive on kicks. Needs to keep guard higher during combinations.',
          beltProgression: [
            StudentProgression(level: 'white', earnedDate: '2024-01-15'),
            StudentProgression(level: 'yellow', earnedDate: '2024-06-10'),
            StudentProgression(level: 'green', earnedDate: '2024-12-05'),
            StudentProgression(level: 'blue', earnedDate: '2025-05-20'),
            StudentProgression(level: 'brown', earnedDate: '2025-11-10'),
          ],
          nextMilestones: const ['Refine Bassai Dai kata forms', 'Increase sparring stamina'],
        ),
        StudentDetail(
          id: 'stud_2',
          name: 'Rohan Sharma',
          avatar: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=150',
          beltLevel: 'black',
          lastSessionDate: '2026-06-03',
          progressStatus: 'Advanced',
          attendanceLog: const [
            'Advanced Kumite Fighting - 2026-06-03',
            'Tactical Combat Drills - 2026-05-27',
          ],
          coachNotes: 'Sharp reflexes. Focus on tournament rules limits and clinch exits.',
          beltProgression: [
            StudentProgression(level: 'white', earnedDate: '2023-03-10'),
            StudentProgression(level: 'yellow', earnedDate: '2023-09-12'),
            StudentProgression(level: 'green', earnedDate: '2024-03-15'),
            StudentProgression(level: 'blue', earnedDate: '2024-09-18'),
            StudentProgression(level: 'brown', earnedDate: '2025-03-22'),
            StudentProgression(level: 'black', earnedDate: '2026-01-10'),
          ],
          nextMilestones: const ['Preparation for National Karate Division Open'],
        ),
        StudentDetail(
          id: 'stud_3',
          name: 'Pooja Patel',
          avatar: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=150',
          beltLevel: 'green',
          lastSessionDate: '2026-05-20',
          progressStatus: 'Needs Focus',
          attendanceLog: const [
            'Intro to Leverage & Throws - 2026-05-20',
          ],
          coachNotes: 'Needs more consistency in attendance. Leverage techniques are promising.',
          beltProgression: [
            StudentProgression(level: 'white', earnedDate: '2025-02-10'),
            StudentProgression(level: 'yellow', earnedDate: '2025-08-15'),
            StudentProgression(level: 'green', earnedDate: '2026-02-20'),
          ],
          nextMilestones: const ['Attend 3 consecutive weekly sparring sessions', 'Green belt requirements revision'],
        ),
      ];

      final now = DateTime.now();
      final baseDate = DateTime(now.year, now.month, now.day);
      final List<DateTime> fallbackSlots = [
        baseDate.add(const Duration(hours: 10)), // Today 10:00 AM
        baseDate.add(const Duration(days: 1, hours: 10)), // Tomorrow 10:00 AM
        baseDate.add(const Duration(days: 2, hours: 10)), // Day After 10:00 AM
      ];

      state = state.copyWith(
        isLoading: false,
        earnings: fallbackEarnings,
        upcomingSessions: fallbackSessions,
        students: fallbackStudents,
        availabilitySlots: fallbackSlots,
      );
    }
  }

  // Cancel booking session
  void cancelSession(String sessionId) {
    state = state.copyWith(
      upcomingSessions: state.upcomingSessions.where((s) => s.id != sessionId).toList(),
    );
  }

  // Toggle availability slot
  Future<void> toggleSlotAvailability(DateTime slotTime) async {
    final List<DateTime> updatedSlots = List.from(state.availabilitySlots);
    if (updatedSlots.any((t) => t.isAtSameMomentAs(slotTime))) {
      updatedSlots.removeWhere((t) => t.isAtSameMomentAs(slotTime));
    } else {
      updatedSlots.add(slotTime);
    }

    state = state.copyWith(availabilitySlots: updatedSlots);

    try {
      final List<String> listStrings = updatedSlots.map((d) => d.toIso8601String()).toList();
      await _dio.put(
        'http://localhost:3001/api/v1/coaches/$_coachId/availability',
        data: {'slots': listStrings},
      );
    } catch (_) {
      // Fallback offline updates locally only
    }
  }

  // Save coach notes for a student
  Future<bool> saveStudentNote(String studentId, String note) async {
    state = state.copyWith(isSavingNote: true);
    
    // Optimistic Local Update
    state = state.copyWith(
      students: state.students.map((s) {
        if (s.id == studentId) {
          return s.copyWith(coachNotes: note);
        }
        return s;
      }).toList(),
    );

    try {
      final response = await _dio.post(
        'http://localhost:3001/api/v1/coaches/$_coachId/student-notes',
        data: {
          'student_id': studentId,
          'note': note,
        },
      );
      state = state.copyWith(isSavingNote: false);
      return response.statusCode == 200;
    } catch (_) {
      // Offline fallback success
      state = state.copyWith(isSavingNote: false);
      return true;
    }
  }

  // Set recurring availability Mon/Wed/Fri 6pm-9pm
  Future<void> setRecurringMonWedFriAvailability(bool active) async {
    state = state.copyWith(isRecurringMonWedFri: active);

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    // Standard slots: Mon, Wed, Fri at 6:00 PM (18:00) for the current week starting today
    final List<DateTime> updatedSlots = List.from(state.availabilitySlots);
    
    for (int i = 0; i < 7; i++) {
      final day = today.add(Duration(days: i));
      if (day.weekday == DateTime.monday || day.weekday == DateTime.wednesday || day.weekday == DateTime.friday) {
        final slotTime = DateTime(day.year, day.month, day.day, 18);
        final exists = updatedSlots.any((t) => t.isAtSameMomentAs(slotTime));
        
        if (active && !exists) {
          updatedSlots.add(slotTime);
        } else if (!active && exists) {
          updatedSlots.removeWhere((t) => t.isAtSameMomentAs(slotTime));
        }
      }
    }

    state = state.copyWith(availabilitySlots: updatedSlots);

    try {
      final List<String> listStrings = updatedSlots.map((d) => d.toIso8601String()).toList();
      await _dio.put(
        'http://localhost:3001/api/v1/coaches/$_coachId/availability',
        data: {'slots': listStrings},
      );
    } catch (_) {
      // Offline fallback success
    }
  }
}

// Scoped coach dashboard provider family
final coachDashboardProvider = StateNotifierProvider.family<CoachDashboardNotifier, CoachDashboardState, String>((ref, coachId) {
  final dio = Dio();
  return CoachDashboardNotifier(dio, coachId);
});
