import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../core/theme/app_theme.dart';
import '../providers/coach_dashboard_provider.dart';

class CoachDashboardScreen extends ConsumerStatefulWidget {
  final String coachId;
  const CoachDashboardScreen({super.key, this.coachId = 'coach_priya_rao'});

  @override
  ConsumerState<CoachDashboardScreen> createState() => _CoachDashboardScreenState();
}

class _CoachDashboardScreenState extends ConsumerState<CoachDashboardScreen> {
  int? _hoveredChartBarIndex;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(coachDashboardProvider(widget.coachId).notifier).loadDashboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(coachDashboardProvider(widget.coachId));
    final notifier = ref.read(coachDashboardProvider(widget.coachId).notifier);

    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: AppBar(
        title: const Text('SENSEI DASHBOARD'),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCw, size: 18),
            onPressed: () => notifier.loadDashboard(),
          ),
        ],
      ),
      body: state.isLoading && state.earnings == null
          ? const Center(child: CircularProgressIndicator(color: AppColors.accentRed))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.s16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Earnings Overview
                  if (state.earnings != null) ...[
                    _buildEarningsCard(state.earnings!),
                    const SizedBox(height: AppSpacing.s24),
                  ],

                  // 2. Upcoming Sessions
                  _buildUpcomingSessionsSection(context, state.upcomingSessions, notifier),
                  const SizedBox(height: AppSpacing.s24),

                  // 3. Student Roster
                  _buildStudentRosterSection(context, state.students, notifier),
                  const SizedBox(height: AppSpacing.s24),

                  // 4. Availability Manager
                  _buildAvailabilityManagerSection(context, state, notifier),
                  const SizedBox(height: AppSpacing.s24),

                  // 5. Course Builder preview
                  _buildCourseBuilderLockedCard(context),
                  const SizedBox(height: AppSpacing.s48),
                ],
              ),
            ),
    );
  }

  // Earnings Card with Custom Bar Chart
  Widget _buildEarningsCard(CoachEarnings earnings) {
    final currencyFormatter = NumberFormat.currency(
      locale: 'en_US',
      symbol: '₹',
      decimalDigits: 0,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.s16),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.accentGold.withOpacity(0.5), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'EARNINGS OVERVIEW',
                style: GoogleFonts.bebasNeue(
                  fontSize: 18,
                  color: AppColors.accentGold,
                  letterSpacing: 1.0,
                ),
              ),
              const Icon(LucideIcons.coins, color: AppColors.accentGold, size: 20),
            ],
          ),
          const SizedBox(height: AppSpacing.s16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildEarningsStat('This Week', currencyFormatter.format(earnings.thisWeek)),
              _buildEarningsStat('This Month', currencyFormatter.format(earnings.thisMonth)),
              _buildEarningsStat('Total Students', '${earnings.totalStudents}'),
            ],
          ),
          const Divider(color: AppColors.divider, height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Next Payout Scheduled:',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
              Text(
                '${earnings.nextPayoutDate} — ${currencyFormatter.format(earnings.nextPayoutAmount)}',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s24),
          Text(
            'WEEKLY EARNINGS (LAST 8 WEEKS)',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.s16),
          
          // Custom Interactive Bar Chart
          SizedBox(
            height: 150,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(earnings.chartData.length, (index) {
                final amount = earnings.chartData[index];
                // Max earnings value in mock is 5200. Max height 100px.
                final double barHeight = (amount / 5200.0) * 90.0;
                final bool isHovered = _hoveredChartBarIndex == index;

                return GestureDetector(
                  onTapDown: (_) {
                    setState(() {
                      _hoveredChartBarIndex = index;
                    });
                  },
                  onTapCancel: () {
                    setState(() {
                      _hoveredChartBarIndex = null;
                    });
                  },
                  onTap: () {
                    setState(() {
                      _hoveredChartBarIndex = index;
                    });
                  },
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // Tooltip overlay above the active bar
                      AnimatedOpacity(
                        duration: const Duration(milliseconds: 200),
                        opacity: isHovered ? 1.0 : 0.0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: AppColors.accentGold, width: 0.5),
                          ),
                          child: Text(
                            currencyFormatter.format(amount),
                            style: const TextStyle(color: AppColors.accentGold, fontSize: 9, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        width: 18,
                        height: barHeight.clamp(10.0, 100.0),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.accentGold,
                              AppColors.accentGold.withOpacity(0.5),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'W${index + 1}',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 9),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEarningsStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.bebasNeue(
            fontSize: 22,
            color: AppColors.textPrimary,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  // Upcoming Sessions Section
  Widget _buildUpcomingSessionsSection(
    BuildContext context,
    List<CoachSession> sessions,
    CoachDashboardNotifier notifier,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'UPCOMING BOOKED SESSIONS',
          style: GoogleFonts.bebasNeue(
            fontSize: 20,
            color: AppColors.textPrimary,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: AppSpacing.s12),
        if (sessions.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.s24),
            decoration: BoxDecoration(
              color: AppColors.backgroundCard,
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: Border.all(color: AppColors.divider),
            ),
            child: const Center(
              child: Text(
                'No upcoming booked sessions.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
          )
        else
          ...sessions.map((session) {
            final now = DateTime.now();
            final difference = session.time.difference(now);
            // Starts within 30 mins, or has started up to 1 hour ago
            final bool canStart = difference.inMinutes >= -60 && difference.inMinutes <= 30;
            final beltColor = AppColors.beltColors[session.beltLevel.toLowerCase()] ?? Colors.white;

            return Container(
              margin: const EdgeInsets.only(bottom: AppSpacing.s12),
              padding: const EdgeInsets.all(AppSpacing.s12),
              decoration: BoxDecoration(
                color: AppColors.backgroundCard,
                borderRadius: BorderRadius.circular(AppRadius.card),
                border: Border.all(color: AppColors.divider),
              ),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Athlete Belt ring
                      Container(
                        padding: const EdgeInsets.all(1.5),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: beltColor, width: 2),
                        ),
                        child: const CircleAvatar(
                          radius: 18,
                          backgroundColor: AppColors.backgroundElevated,
                          child: Icon(LucideIcons.user, size: 16, color: AppColors.textPrimary),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.s12),
                      // Details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  session.athleteName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(color: beltColor, shape: BoxShape.circle),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${session.sessionType == 'online' ? 'Online Video' : 'In-Person'} • ₹${session.amount}',
                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      // Time
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            DateFormat('jm').format(session.time),
                            style: GoogleFonts.bebasNeue(
                              fontSize: 16,
                              color: AppColors.accentGold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            DateFormat('MMM d').format(session.time),
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 10),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Divider(color: AppColors.divider, height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // Start button (conditional)
                      if (canStart) ...[
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.successGreen,
                            minimumSize: const Size(120, 36),
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                          ),
                          icon: const Icon(LucideIcons.video, size: 14),
                          label: const Text('START SESSION', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          onPressed: () => _startSessionCall(context, session),
                        ),
                        const SizedBox(width: AppSpacing.s8),
                      ],
                      // Cancel option
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.accentRed,
                          side: const BorderSide(color: AppColors.accentRed),
                          minimumSize: const Size(80, 36),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                        ),
                        child: const Text('CANCEL', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        onPressed: () => _showCancelWarning(context, session, notifier),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  void _startSessionCall(BuildContext context, CoachSession session) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.backgroundCard,
          title: const Row(
            children: [
              Icon(LucideIcons.video, color: AppColors.successGreen),
              SizedBox(width: AppSpacing.s8),
              Text('CONNECTING...'),
            ],
          ),
          content: Text(
            'Starting HD streaming portal for session with ${session.athleteName}. Establishing encrypted WebRTC connection to Mumbai Dojo Hub...',
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('DISMISS', style: TextStyle(color: AppColors.accentGold)),
            ),
          ],
        );
      },
    );
  }

  void _showCancelWarning(BuildContext context, CoachSession session, CoachDashboardNotifier notifier) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.backgroundCard,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.card)),
          title: const Row(
            children: [
              Icon(LucideIcons.shieldAlert, color: AppColors.accentRed),
              SizedBox(width: AppSpacing.s8),
              Text('CANCEL SESSION?'),
            ],
          ),
          content: const Text(
            'WARNING: Cancellations within 24 hours of session times are subject to Mumbai regional disputes. Fees may be refunded to the athlete automatically. Are you sure you want to cancel?',
            style: TextStyle(color: AppColors.textPrimary, fontSize: 13, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('GO BACK', style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentRed),
              onPressed: () {
                notifier.cancelSession(session.id);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).clearSnackBars();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Session with ${session.athleteName} cancelled successfully.')),
                );
              },
              child: const Text('CONFIRM CANCEL'),
            ),
          ],
        );
      },
    );
  }

  // Student Roster Section
  Widget _buildStudentRosterSection(
    BuildContext context,
    List<StudentDetail> students,
    CoachDashboardNotifier notifier,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'STUDENT ROSTER',
          style: GoogleFonts.bebasNeue(
            fontSize: 20,
            color: AppColors.textPrimary,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: AppSpacing.s12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: AppSpacing.s12,
            mainAxisSpacing: AppSpacing.s12,
            childAspectRatio: 1.25,
          ),
          itemCount: students.length,
          itemBuilder: (context, index) {
            final student = students[index];
            final beltColor = AppColors.beltColors[student.beltLevel.toLowerCase()] ?? Colors.white;

            Color statusColor = AppColors.successGreen;
            if (student.progressStatus == 'Needs Focus') {
              statusColor = AppColors.accentRed;
            } else if (student.progressStatus == 'On Track') {
              statusColor = AppColors.accentGold;
            }

            return GestureDetector(
              onTap: () => _showStudentDetailSheet(context, student, notifier),
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.s12),
                decoration: BoxDecoration(
                  color: AppColors.backgroundCard,
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundImage: CachedNetworkImageProvider(student.avatar),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            student.name,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.s12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: beltColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: beltColor, width: 0.5),
                          ),
                          child: Text(
                            student.beltLevel.toUpperCase(),
                            style: TextStyle(color: beltColor, fontSize: 8, fontWeight: FontWeight.bold),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            student.progressStatus.toUpperCase(),
                            style: TextStyle(color: statusColor, fontSize: 8, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      'Last: ${student.lastSessionDate}',
                      style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  void _showStudentDetailSheet(BuildContext context, StudentDetail student, CoachDashboardNotifier notifier) {
    final noteController = TextEditingController(text: student.coachNotes);

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.backgroundCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.card)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.85,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              builder: (context, scrollController) {
                return SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(AppSpacing.s24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundImage: CachedNetworkImageProvider(student.avatar),
                          ),
                          const SizedBox(width: AppSpacing.s12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                student.name.toUpperCase(),
                                style: GoogleFonts.bebasNeue(
                                  fontSize: 24,
                                  color: AppColors.textPrimary,
                                  letterSpacing: 1.0,
                                ),
                              ),
                              Text(
                                '${student.beltLevel.toUpperCase()} BELT • PROGRESS: ${student.progressStatus.toUpperCase()}',
                                style: const TextStyle(color: AppColors.accentGold, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const Divider(color: AppColors.divider, height: 32),

                      // Editable Coach Notes
                      const Text(
                        'COACH NOTES',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textSecondary, letterSpacing: 0.5),
                      ),
                      const SizedBox(height: AppSpacing.s8),
                      TextFormField(
                        controller: noteController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          hintText: 'Enter student training observations...',
                          hintStyle: TextStyle(color: AppColors.textSecondary),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.s12),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accentRed,
                          minimumSize: const Size(double.infinity, 40),
                        ),
                        child: const Text('SAVE NOTES', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                        onPressed: () async {
                          final success = await notifier.saveStudentNote(student.id, noteController.text);
                          if (success && context.mounted) {
                            ScaffoldMessenger.of(context).clearSnackBars();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Notes updated successfully.')),
                            );
                            Navigator.pop(context);
                          }
                        },
                      ),
                      const SizedBox(height: AppSpacing.s24),

                      // Attendance Log
                      const Text(
                        'ATTENDANCE LOG',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textSecondary, letterSpacing: 0.5),
                      ),
                      const SizedBox(height: AppSpacing.s12),
                      ...student.attendanceLog.map((log) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: Row(
                              children: [
                                const Icon(LucideIcons.calendar, size: 14, color: AppColors.accentGold),
                                const SizedBox(width: 8),
                                Text(log, style: const TextStyle(color: AppColors.textPrimary, fontSize: 12)),
                              ],
                            ),
                          )),
                      const SizedBox(height: AppSpacing.s24),

                      // Belt Progression
                      const Text(
                        'BELT PROGRESSION HISTORY',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textSecondary, letterSpacing: 0.5),
                      ),
                      const SizedBox(height: AppSpacing.s12),
                      ...student.beltProgression.map((b) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: Row(
                              children: [
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: AppColors.beltColors[b.level.toLowerCase()] ?? Colors.white,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: AppColors.divider),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${b.level.toUpperCase()} BELT — Earned on ${b.earnedDate}',
                                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 12),
                                ),
                              ],
                            ),
                          )),
                      const SizedBox(height: AppSpacing.s24),

                      // Next Milestones
                      const Text(
                        'UPCOMING MILESTONES',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textSecondary, letterSpacing: 0.5),
                      ),
                      const SizedBox(height: AppSpacing.s12),
                      ...student.nextMilestones.map((m) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: Row(
                              children: [
                                const Icon(LucideIcons.target, size: 14, color: AppColors.accentRed),
                                const SizedBox(width: 8),
                                Expanded(child: Text(m, style: const TextStyle(color: AppColors.textPrimary, fontSize: 12))),
                              ],
                            ),
                          )),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  // Availability Manager Section
  Widget _buildAvailabilityManagerSection(
    BuildContext context,
    CoachDashboardState state,
    CoachDashboardNotifier notifier,
  ) {
    // 7 days from today
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final days = List.generate(7, (i) => today.add(Duration(days: i)));
    
    // Slots per day: Morning (10 AM), Afternoon (2 PM), Evening (6 PM)
    final hours = [10, 14, 18];
    final hourNames = {10: '10:00 AM', 14: '2:00 PM', 18: '6:00 PM'};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'AVAILABILITY MANAGER',
          style: GoogleFonts.bebasNeue(
            fontSize: 20,
            color: AppColors.textPrimary,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: AppSpacing.s4),
        // Recurring Switch
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Expanded(
              child: Text(
                'Always available Mon/Wed/Fri 6pm–9pm (Recurring)',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
            ),
            Switch(
              value: state.isRecurringMonWedFri,
              activeColor: AppColors.accentRed,
              onChanged: (val) {
                notifier.setRecurringMonWedFriAvailability(val);
              },
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.s12),
        // Grid Table representation
        Container(
          padding: const EdgeInsets.all(AppSpacing.s8),
          decoration: BoxDecoration(
            color: AppColors.backgroundCard,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: AppColors.divider),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Table(
              defaultColumnWidth: const FixedColumnWidth(90.0),
              children: [
                // Headers (Days)
                TableRow(
                  children: days.map((day) => Padding(
                    padding: const EdgeInsets.all(6.0),
                    child: Center(
                      child: Column(
                        children: [
                          Text(
                            DateFormat('EEE').format(day).toUpperCase(),
                            style: GoogleFonts.bebasNeue(fontSize: 14, color: AppColors.accentGold),
                          ),
                          Text(
                            DateFormat('d').format(day),
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                  )).toList(),
                ),
                // Slots rows
                ...hours.map((hour) {
                  return TableRow(
                    children: days.map((day) {
                      final slotTime = DateTime(day.year, day.month, day.day, hour);
                      final isAvailable = state.availabilitySlots.any((t) => t.isAtSameMomentAs(slotTime));

                      return GestureDetector(
                        onTap: () => notifier.toggleSlotAvailability(slotTime),
                        child: Container(
                          margin: const EdgeInsets.all(4.0),
                          height: 36,
                          decoration: BoxDecoration(
                            color: isAvailable ? AppColors.successGreen : AppColors.backgroundElevated,
                            borderRadius: BorderRadius.circular(AppRadius.element),
                          ),
                          child: Center(
                            child: Text(
                              hourNames[hour]!,
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: isAvailable ? Colors.white : AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  );
                }),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Course Builder Locked Card
  Widget _buildCourseBuilderLockedCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.s16),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard.withOpacity(0.6),
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'COURSE BUILDER',
                style: GoogleFonts.bebasNeue(
                  fontSize: 18,
                  color: AppColors.textSecondary,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(LucideIcons.lock, color: AppColors.textSecondary, size: 14),
            ],
          ),
          const SizedBox(height: AppSpacing.s8),
          const Text(
            'Create online video courses, establish structured grading curriculums, and earn passive subscription income — coming in Phase 2.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.4),
          ),
          const SizedBox(height: AppSpacing.s16),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.backgroundElevated,
              foregroundColor: AppColors.accentGold,
              side: const BorderSide(color: AppColors.accentGold),
              minimumSize: const Size(double.infinity, 44),
            ),
            icon: const Icon(LucideIcons.bellRing, size: 16),
            label: const Text('GET NOTIFIED ON LAUNCH', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            onPressed: () {
              ScaffoldMessenger.of(context).clearSnackBars();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Launch notification registered! We will email you when Course Builder goes live.')),
              );
            },
          ),
        ],
      ),
    );
  }
}
