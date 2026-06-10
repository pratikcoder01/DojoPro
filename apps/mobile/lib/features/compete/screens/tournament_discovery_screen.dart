import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/compete_provider.dart';
import 'tournament_detail_screen.dart';

class TournamentDiscoveryScreen extends ConsumerWidget {
  const TournamentDiscoveryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(competeProvider);

    // Apply client-side filter
    List<Tournament> filteredList = state.tournaments;
    if (state.selectedFilter == 'My Discipline') {
      filteredList = state.tournaments.where((t) => t.discipline.toLowerCase() == 'karate').toList(); // Mock Arjun's discipline Karate
    } else if (state.selectedFilter == 'My City') {
      filteredList = state.tournaments.where((t) => t.city.toLowerCase() == 'mumbai').toList(); // Launch City Mumbai
    } else if (state.selectedFilter == 'Open') {
      filteredList = state.tournaments.where((t) => t.status == 'open').toList();
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16, vertical: AppSpacing.s12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Screen Header (Bebas Neue 36px)
              Text(
                'UPCOMING TOURNAMENTS',
                style: GoogleFonts.bebasNeue(
                  fontSize: 36,
                  color: AppColors.textPrimary,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: AppSpacing.s16),

              // Filter tabs row
              _buildFilterTabs(ref, state.selectedFilter),
              const SizedBox(height: AppSpacing.s16),

              // List of Tournaments
              Expanded(
                child: filteredList.isEmpty
                    ? Center(
                        child: Text(
                          'No tournaments found.',
                          style: GoogleFonts.inter(color: AppColors.textSecondary),
                        ),
                      )
                    : ListView.builder(
                        itemCount: filteredList.length,
                        itemBuilder: (context, index) {
                          final tournament = filteredList[index];
                          return _buildTournamentCard(context, tournament);
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterTabs(WidgetRef ref, String activeFilter) {
    final filters = ['All', 'My Discipline', 'My City', 'Open'];

    return SizedBox(
      height: 36,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = activeFilter == filter;

          return GestureDetector(
            onTap: () => ref.read(competeProvider.notifier).selectFilter(filter),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.accentRed : AppColors.backgroundCard,
                borderRadius: BorderRadius.circular(AppRadius.badge),
                border: Border.all(
                  color: isSelected ? AppColors.accentRed : AppColors.divider,
                ),
              ),
              child: Text(
                filter.toUpperCase(),
                style: GoogleFonts.bebasNeue(
                  fontSize: 12,
                  letterSpacing: 0.5,
                  color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTournamentCard(BuildContext context, Tournament tournament) {
    final totalFee = tournament.feePaise / 100;
    
    // Cover Image selector based on discipline
    String coverUrl;
    if (tournament.discipline.toLowerCase() == 'karate') {
      coverUrl = 'https://images.unsplash.com/photo-1555597673-b21d5c935865?w=500';
    } else if (tournament.discipline.toLowerCase() == 'bjj') {
      coverUrl = 'https://images.unsplash.com/photo-1517649763962-0c623066013b?w=500';
    } else {
      coverUrl = 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=500';
    }

    // Progress percentage
    final double percent = tournament.currentParticipants / tournament.maxParticipants;

    return GestureDetector(
      key: ValueKey('tournament_card_${tournament.id}'),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => TournamentDetailScreen(tournamentId: tournament.id),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.s16),
        decoration: BoxDecoration(
          color: AppColors.backgroundCard,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: AppColors.divider),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Discipline cover banner image
            Stack(
              children: [
                SizedBox(
                  height: 140,
                  width: double.infinity,
                  child: Image.network(
                    coverUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(color: AppColors.backgroundElevated),
                  ),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(AppRadius.badge),
                    ),
                    child: Text(
                      tournament.discipline.toUpperCase(),
                      style: GoogleFonts.bebasNeue(
                        fontSize: 10,
                        color: AppColors.accentGold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Card content
            Padding(
              padding: const EdgeInsets.all(AppSpacing.s16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tournament Name
                  Text(
                    tournament.title.toUpperCase(),
                    style: GoogleFonts.bebasNeue(
                      fontSize: 20,
                      color: AppColors.textPrimary,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 6),

                  // City & Date
                  Row(
                    children: [
                      const Icon(LucideIcons.mapPin, color: AppColors.textSecondary, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        tournament.city,
                        style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 12),
                      ),
                      const SizedBox(width: 16),
                      const Icon(LucideIcons.calendar, color: AppColors.textSecondary, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        tournament.startDate,
                        style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.s12),

                  // Registration Capacity Progress Bar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'REGISTRATION CAPACITY',
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        '${tournament.currentParticipants} / ${tournament.maxParticipants}',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  LinearProgressIndicator(
                    value: percent,
                    backgroundColor: AppColors.backgroundElevated,
                    color: AppColors.accentRed,
                    minHeight: 6,
                    borderRadius: BorderRadius.circular(3),
                  ),
                  const SizedBox(height: AppSpacing.s16),

                  // Bottom info: Fee + Countdown Closes
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Entry Fee: ₹${totalFee.toStringAsFixed(0)}',
                        style: GoogleFonts.bebasNeue(
                          fontSize: 16,
                          color: AppColors.textPrimary,
                          letterSpacing: 0.5,
                        ),
                      ),
                      // Countdown closes in gold
                      Text(
                        tournament.status == 'open'
                            ? 'Closes in 3 days 14 hrs'
                            : 'Registration Closed',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.accentGold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
