import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/coaching_provider.dart';
import 'booking_confirmation_screen.dart';

class CoachProfileScreen extends ConsumerWidget {
  const CoachProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(coachingProvider);

    if (state.status == BookingStatus.loading && state.coach == null) {
      return const Scaffold(
        backgroundColor: AppColors.backgroundPrimary,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.accentRed),
        ),
      );
    }

    if (state.coach == null) {
      return Scaffold(
        backgroundColor: AppColors.backgroundPrimary,
        appBar: AppBar(title: const Text('COACH PROFILE')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(LucideIcons.userX, size: 48, color: AppColors.textSecondary),
              const SizedBox(height: AppSpacing.s16),
              Text(
                'Coach profile not found.',
                style: GoogleFonts.inter(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.s16),
              ElevatedButton(
                onPressed: () => ref.read(coachingProvider.notifier).loadCoachDetails(),
                child: const Text('RELOAD PROFILE'),
              ),
            ],
          ),
        ),
      );
    }

    final coach = state.coach!;

    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      body: Stack(
        children: [
          // Main Scrollable Content
          CustomScrollView(
            slivers: [
              // Hero AppBar (full-bleed cover image)
              _buildHeroAppBar(context, coach),

              // Profile Details List
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16, vertical: AppSpacing.s24),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Title/Name & Verification Badge (Inter Bold 28px)
                    _buildNameHeader(coach),
                    const SizedBox(height: AppSpacing.s12),

                    // Specialties as pill tags
                    _buildSpecialtiesPills(coach),
                    const SizedBox(height: AppSpacing.s16),

                    // Rating & Reviews Row (numeric + count)
                    _buildRatingRow(coach),
                    const SizedBox(height: AppSpacing.s24),

                    // Stats Grid (Sessions, Students, Experience)
                    _buildStatsRow(coach),
                    const SizedBox(height: AppSpacing.s32),

                    // Session type toggle: "In-Person" | "Online" — segmented control
                    _buildSessionTypeToggle(context, ref, state),
                    const SizedBox(height: AppSpacing.s32),

                    // Availability Calendar (weekly view, green = available, grey = booked)
                    _buildAvailabilitySection(context, ref, state, coach),
                    const SizedBox(height: AppSpacing.s32),

                    // Biography
                    _buildBioSection(coach),
                    const SizedBox(height: AppSpacing.s32),

                    // Pinned Recent Reviews (Top 3, card style, dark background #1A1A2E)
                    _buildReviewsSection(coach),
                    const SizedBox(height: 120), // Extra space for the fixed bottom bar
                  ]),
                ),
              ),
            ],
          ),

          // Back Button top left (floating over hero)
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16,
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(LucideIcons.arrowLeft, color: AppColors.textPrimary, size: 20),
              ),
            ),
          ),

          // Fixed Bottom Booking Bar
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildBottomBookingBar(context, ref, state, coach),
          ),
        ],
      ),
    );
  }

  // Hero Image and cover view
  Widget _buildHeroAppBar(BuildContext context, CoachDetail coach) {
    return SliverAppBar(
      expandedHeight: 280,
      backgroundColor: AppColors.backgroundPrimary,
      elevation: 0,
      automaticallyImplyLeading: false,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Full-bleed Cover Photo
            Image.network(
              coach.coverUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: AppColors.backgroundCard,
                child: const Icon(LucideIcons.image, size: 48, color: AppColors.textSecondary),
              ),
            ),
            // Bottom gradient overlay for readability
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.transparent, AppColors.backgroundPrimary],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0.6, 1.0],
                ),
              ),
            ),
            // Avatar profile overlay (bottom left of cover image)
            Positioned(
              bottom: 16,
              left: 16,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.accentGold, width: 2.0),
                ),
                child: CircleAvatar(
                  radius: 36,
                  backgroundImage: NetworkImage(coach.avatarUrl),
                  backgroundColor: AppColors.backgroundCard,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Name Header (Inter Bold 28px) with Verified Gold Checkmark Badge
  Widget _buildNameHeader(CoachDetail coach) {
    return Row(
      children: [
        Expanded(
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                coach.name,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  fontSize: 28,
                  color: AppColors.textPrimary,
                ),
              ),
              if (coach.isVerified) ...[
                const SizedBox(width: AppSpacing.s8),
                const Icon(
                  LucideIcons.check,
                  color: AppColors.accentGold,
                  size: 28,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // Specialties as pill tags
  Widget _buildSpecialtiesPills(CoachDetail coach) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: coach.specialties.map((specialty) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.backgroundCard,
            border: Border.all(color: AppColors.divider),
            borderRadius: BorderRadius.circular(AppRadius.badge),
          ),
          child: Text(
            specialty,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.accentGold,
            ),
          ),
        );
      }).toList(),
    );
  }

  // Rating and review overview
  Widget _buildRatingRow(CoachDetail coach) {
    return Row(
      children: [
        const Icon(LucideIcons.star, color: AppColors.accentGold, size: 18),
        const SizedBox(width: 6),
        Text(
          coach.rating.toString(),
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
            fontSize: 14,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          '(${coach.reviewCount} reviews)',
          style: GoogleFonts.inter(
            color: AppColors.textSecondary,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  // Stats Row
  Widget _buildStatsRow(CoachDetail coach) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.s16),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatItem(coach.sessionsCompleted.toString(), 'SESSIONS'),
          _buildDivider(),
          _buildStatItem(coach.activeStudents.toString(), 'STUDENTS'),
          _buildDivider(),
          _buildStatItem('${coach.yearsExperience} yrs', 'EXPERIENCE'),
        ],
      ),
    );
  }

  Widget _buildStatItem(String val, String label) {
    return Column(
      children: [
        Text(
          val,
          style: GoogleFonts.bebasNeue(
            fontSize: 22,
            color: AppColors.accentGold,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 9,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 32,
      width: 1,
      color: AppColors.divider,
    );
  }

  // Session Type Toggle segmented control
  Widget _buildSessionTypeToggle(BuildContext context, WidgetRef ref, BookingState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'SESSION TYPE',
          style: GoogleFonts.bebasNeue(fontSize: 22, color: AppColors.textPrimary),
        ),
        const SizedBox(height: AppSpacing.s12),
        Row(
          children: [
            Expanded(
              child: _buildSessionTypeOption(
                label: 'IN-PERSON',
                icon: LucideIcons.users,
                isSelected: state.sessionType == BookingSessionType.inPerson,
                onTap: () => ref.read(coachingProvider.notifier).selectSessionType(BookingSessionType.inPerson),
              ),
            ),
            const SizedBox(width: AppSpacing.s12),
            Expanded(
              child: _buildSessionTypeOption(
                label: 'ONLINE (HD STREAM)',
                icon: LucideIcons.video,
                isSelected: state.sessionType == BookingSessionType.online,
                onTap: () => ref.read(coachingProvider.notifier).selectSessionType(BookingSessionType.online),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSessionTypeOption({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accentRed.withOpacity(0.2) : AppColors.backgroundCard,
          border: Border.all(
            color: isSelected ? AppColors.accentRed : AppColors.divider,
            width: isSelected ? 1.5 : 1.0,
          ),
          borderRadius: BorderRadius.circular(AppRadius.element),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.accentRedLight : AppColors.textSecondary,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.bebasNeue(
                fontSize: 13,
                color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Availability section with weekly calendar view (green = available, grey = booked)
  Widget _buildAvailabilitySection(BuildContext context, WidgetRef ref, BookingState state, CoachDetail coach) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'WEEKLY AVAILABILITY',
          style: GoogleFonts.bebasNeue(fontSize: 22, color: AppColors.textPrimary),
        ),
        const SizedBox(height: AppSpacing.s12),
        const Text(
          'Tap an open slot below to select it for your private training session.',
          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.s16),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: coach.availableSlots.length,
            itemBuilder: (context, index) {
              final slot = coach.availableSlots[index];
              final isBooked = slot.isBooked;
              final isSelected = state.selectedSlot == slot.time;
              final dayFormat = DateFormat('EEE');
              final dateFormat = DateFormat('d MMM');
              final timeFormat = DateFormat('h:mm a');

              Color bgColor;
              Color borderColor;
              Color dayTextColor;
              Color dateTextColor;
              Color timeTextColor;

              if (isBooked) {
                // Booked: grey, disabled style
                bgColor = AppColors.backgroundCard.withOpacity(0.3);
                borderColor = AppColors.divider.withOpacity(0.5);
                dayTextColor = AppColors.textSecondary.withOpacity(0.4);
                dateTextColor = AppColors.textPrimary.withOpacity(0.3);
                timeTextColor = AppColors.textSecondary.withOpacity(0.3);
              } else {
                // Available: green base
                if (isSelected) {
                  bgColor = AppColors.successGreen.withOpacity(0.2);
                  borderColor = AppColors.successGreen;
                  dayTextColor = AppColors.successGreen;
                  dateTextColor = AppColors.textPrimary;
                  timeTextColor = AppColors.accentGold;
                } else {
                  bgColor = AppColors.backgroundCard;
                  borderColor = AppColors.successGreen.withOpacity(0.5);
                  dayTextColor = AppColors.textSecondary;
                  dateTextColor = AppColors.textPrimary;
                  timeTextColor = AppColors.accentGold;
                }
              }

              return GestureDetector(
                onTap: isBooked
                    ? null
                    : () {
                        ref.read(coachingProvider.notifier).selectSlot(slot.time);
                      },
                child: Container(
                  width: 110,
                  margin: const EdgeInsets.only(right: AppSpacing.s12),
                  decoration: BoxDecoration(
                    color: bgColor,
                    border: Border.all(
                      color: borderColor,
                      width: isSelected ? 2.0 : 1.0,
                    ),
                    borderRadius: BorderRadius.circular(AppRadius.card),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        dayFormat.format(slot.time).toUpperCase(),
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: dayTextColor,
                        ),
                      ),
                      Text(
                        dateFormat.format(slot.time),
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: dateTextColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isBooked ? 'BOOKED' : timeFormat.format(slot.time),
                        style: GoogleFonts.bebasNeue(
                          fontSize: 13,
                          color: timeTextColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // Biography Section
  Widget _buildBioSection(CoachDetail coach) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'BIOGRAPHY',
          style: GoogleFonts.bebasNeue(fontSize: 22, color: AppColors.textPrimary),
        ),
        const SizedBox(height: AppSpacing.s12),
        Text(
          coach.bio,
          style: GoogleFonts.inter(
            fontSize: 13,
            height: 1.5,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  // Reviews Section (pinned card style reviews, dark background #1A1A2E)
  Widget _buildReviewsSection(CoachDetail coach) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'RECENT REVIEWS',
          style: GoogleFonts.bebasNeue(fontSize: 22, color: AppColors.textPrimary),
        ),
        const SizedBox(height: AppSpacing.s16),
        ...coach.recentReviews.map((review) {
          return Container(
            margin: const EdgeInsets.only(bottom: AppSpacing.s12),
            padding: const EdgeInsets.all(AppSpacing.s16),
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
                      backgroundImage: NetworkImage(review.userAvatar),
                      backgroundColor: AppColors.backgroundElevated,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        review.userName,
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    Row(
                      children: List.generate(5, (index) {
                        return Icon(
                          LucideIcons.star,
                          size: 12,
                          color: index < review.rating.floor()
                              ? AppColors.accentGold
                              : AppColors.divider,
                        );
                      }),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.s8),
                Text(
                  review.comment,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  review.date,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: AppColors.textSecondary.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  // Fixed Bottom Booking Bar with full-width red button
  Widget _buildBottomBookingBar(BuildContext context, WidgetRef ref, BookingState state, CoachDetail coach) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16, vertical: AppSpacing.s16),
      decoration: const BoxDecoration(
        color: AppColors.backgroundCard,
        border: BorderValues.topOnly,
        boxShadow: [
          BoxShadow(
            color: Colors.black54,
            blurRadius: 8,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            key: const ValueKey('book_session_bar_button'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentRed,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.element),
              ),
            ),
            onPressed: () {
              if (state.selectedSlot == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please select an availability slot from the calendar first.'),
                    backgroundColor: AppColors.accentRed,
                  ),
                );
                return;
              }
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const BookingConfirmationScreen(),
                ),
              );
            },
            child: Text(
              'Book Session — ₹${coach.hourlyRate}/hr'.toUpperCase(),
              style: GoogleFonts.bebasNeue(
                fontSize: 18,
                color: AppColors.textPrimary,
                letterSpacing: 1.0,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Border values utility
class BorderValues {
  static const Border topOnly = Border(
    top: BorderSide(color: AppColors.divider, width: 1.0),
  );
}
