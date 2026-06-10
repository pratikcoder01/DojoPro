import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/compete_provider.dart';
import 'bracket_view_screen.dart';

class TournamentDetailScreen extends ConsumerStatefulWidget {
  final String tournamentId;
  const TournamentDetailScreen({super.key, required this.tournamentId});

  @override
  ConsumerState<TournamentDetailScreen> createState() => _TournamentDetailScreenState();
}

class _TournamentDetailScreenState extends ConsumerState<TournamentDetailScreen> {
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(competeProvider);
    final tournament = state.tournaments.firstWhere(
      (t) => t.id == widget.tournamentId,
      orElse: () => state.tournaments.isNotEmpty ? state.tournaments.first : CompeteNotifier.mockTournaments.first,
    );

    final totalFee = tournament.feePaise / 100;
    final double percent = tournament.currentParticipants / tournament.maxParticipants;

    // Cover Image selector based on discipline
    String coverUrl;
    if (tournament.discipline.toLowerCase() == 'karate') {
      coverUrl = 'https://images.unsplash.com/photo-1555597673-b21d5c935865?w=800';
    } else if (tournament.discipline.toLowerCase() == 'bjj') {
      coverUrl = 'https://images.unsplash.com/photo-1517649763962-0c623066013b?w=800';
    } else {
      coverUrl = 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=800';
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      body: Stack(
        children: [
          // Scrollable Content
          SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Hero Image Banner Header
                Stack(
                  children: [
                    SizedBox(
                      height: 250,
                      width: double.infinity,
                      child: Image.network(
                        coverUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(color: AppColors.backgroundCard),
                      ),
                    ),
                    // Bottom shadow gradient overlay
                    Positioned.fill(
                      child: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.transparent, AppColors.backgroundPrimary],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            stops: [0.6, 1.0],
                          ),
                        ),
                      ),
                    ),
                    // Date overlay bottom left
                    Positioned(
                      bottom: 16,
                      left: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.accentRed,
                          borderRadius: BorderRadius.circular(AppRadius.element),
                        ),
                        child: Row(
                          children: [
                            const Icon(LucideIcons.calendar, color: AppColors.textPrimary, size: 16),
                            const SizedBox(width: 8),
                            Text(
                              tournament.startDate.toUpperCase(),
                              style: GoogleFonts.bebasNeue(
                                fontSize: 14,
                                color: AppColors.textPrimary,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                // Title & Location
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tournament.title.toUpperCase(),
                        style: GoogleFonts.bebasNeue(
                          fontSize: 32,
                          color: AppColors.textPrimary,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(LucideIcons.mapPin, color: AppColors.accentGold, size: 16),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              tournament.locationName,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.s24),

                      // 2. Info Grid (Location, Fee, Weight Class, Format)
                      _buildInfoGrid(tournament, totalFee),
                      const SizedBox(height: AppSpacing.s24),

                      // Capacity Progress Bar
                      _buildCapacityProgressBar(tournament, percent),
                      const SizedBox(height: AppSpacing.s24),

                      // 3. Bracket Preview Card
                      _buildBracketPreviewCard(context, tournament),
                      const SizedBox(height: AppSpacing.s24),

                      // 4. Post-Registration Confirm + Card generator
                      if (tournament.isRegistered) ...[
                        _buildRegistrationSuccessCard(tournament),
                        const SizedBox(height: AppSpacing.s24),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Floating Back Button top left
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

          // Fixed bottom Register button (if NOT registered)
          if (!tournament.isRegistered)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _buildBottomRegisterBar(context, ref, tournament, totalFee),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoGrid(Tournament tournament, double totalFee) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildGridItem(
                label: 'VENUE LOCATION',
                value: tournament.city,
                icon: LucideIcons.building,
              ),
            ),
            const SizedBox(width: AppSpacing.s12),
            Expanded(
              child: _buildGridItem(
                label: 'REGISTRATION FEE',
                value: '₹${totalFee.toStringAsFixed(0)}',
                icon: LucideIcons.indianRupee,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.s12),
        Row(
          children: [
            Expanded(
              child: _buildGridItem(
                label: 'WEIGHT / SKILL CLASS',
                value: tournament.weightClass,
                icon: LucideIcons.shieldAlert,
              ),
            ),
            const SizedBox(width: AppSpacing.s12),
            Expanded(
              child: _buildGridItem(
                label: 'BRACKET FORMAT',
                value: tournament.format == 'both'
                    ? 'Kata + Kumite'
                    : tournament.format.toUpperCase(),
                icon: LucideIcons.swords,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGridItem({required String label, required String value, required IconData icon}) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.s16),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.accentGold, size: 20),
          const SizedBox(height: 12),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.bebasNeue(
              fontSize: 18,
              color: AppColors.textPrimary,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCapacityProgressBar(Tournament tournament, double percent) {
    return Container(
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'REGISTRATION CAPACITY',
                style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
              ),
              Text(
                '${tournament.currentParticipants} / ${tournament.maxParticipants} Registered',
                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: percent,
            backgroundColor: AppColors.backgroundElevated,
            color: AppColors.accentRed,
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }

  Widget _buildBracketPreviewCard(BuildContext context, Tournament tournament) {
    final isLocked = tournament.status == 'open';

    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                isLocked ? LucideIcons.lock : LucideIcons.unlock,
                color: AppColors.accentGold,
                size: 22,
              ),
              const SizedBox(width: 12),
              Text(
                'TOURNAMENT BRACKET',
                style: GoogleFonts.bebasNeue(fontSize: 20, color: AppColors.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s12),
          Text(
            isLocked
                ? 'The tournament tree bracket will be compiled and unlocked once the registration deadline closes.'
                : 'The tournament registration has closed, and the bracket tree is fully generated. View live matchups and winners.',
            style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
          ),
          const SizedBox(height: AppSpacing.s16),
          if (isLocked)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.backgroundPrimary,
                borderRadius: BorderRadius.circular(AppRadius.element),
                border: Border.all(color: AppColors.divider),
              ),
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(LucideIcons.lockKeyhole, color: AppColors.textSecondary, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'BRACKET LOCKED',
                      style: GoogleFonts.bebasNeue(fontSize: 14, color: AppColors.textSecondary, letterSpacing: 0.5),
                    ),
                  ],
                ),
              ),
            )
          else
            ElevatedButton.icon(
              key: const ValueKey('view_bracket_button'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentRed,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              icon: const Icon(LucideIcons.gitFork, color: AppColors.textPrimary, size: 16),
              label: Text(
                'VIEW TOURNAMENT BRACKET',
                style: GoogleFonts.bebasNeue(fontSize: 14, letterSpacing: 0.5),
              ),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => BracketViewScreen(tournamentId: tournament.id),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildRegistrationSuccessCard(Tournament tournament) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Confirmation Card
        Container(
          padding: const EdgeInsets.all(AppSpacing.s16),
          decoration: BoxDecoration(
            color: AppColors.successGreen.withOpacity(0.15),
            border: Border.all(color: AppColors.successGreen),
            borderRadius: BorderRadius.circular(AppRadius.card),
          ),
          child: Row(
            children: [
              const Icon(LucideIcons.checkCircle, color: AppColors.successGreen, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'REGISTRATION SECURED!',
                      style: GoogleFonts.bebasNeue(fontSize: 16, color: AppColors.textPrimary, letterSpacing: 0.5),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Payment processed successfully via Razorpay.',
                      style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.s24),

        // Shareable graphics card generator
        Text(
          'YOUR ATHLETE ENTRY CARD',
          style: GoogleFonts.bebasNeue(fontSize: 18, color: AppColors.textPrimary, letterSpacing: 0.8),
        ),
        const SizedBox(height: AppSpacing.s12),
        Container(
          key: const ValueKey('shareable_graphics_pass'),
          padding: const EdgeInsets.all(AppSpacing.s24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.backgroundCard, AppColors.backgroundElevated],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: AppColors.accentGold, width: 1.5),
            boxShadow: const [
              BoxShadow(
                color: Colors.black45,
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'DOJOPRO COMPETE ENTRY',
                    style: GoogleFonts.bebasNeue(
                      fontSize: 14,
                      color: AppColors.accentGold,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const Icon(LucideIcons.award, color: AppColors.accentGold, size: 20),
                ],
              ),
              const SizedBox(height: AppSpacing.s16),
              Text(
                tournament.title.toUpperCase(),
                style: GoogleFonts.bebasNeue(
                  fontSize: 24,
                  color: AppColors.textPrimary,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              _buildSharePassDetail('ATHLETE', 'Arjun Mehta (You)'),
              _buildSharePassDetail('DISCIPLINE', '${tournament.discipline} (${tournament.weightClass})'),
              _buildSharePassDetail('DATE & TIME', tournament.startDate),
              const SizedBox(height: AppSpacing.s16),
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.successGreen.withOpacity(0.2),
                    border: Border.all(color: AppColors.successGreen),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'VERIFIED COMPETITOR',
                    style: GoogleFonts.bebasNeue(
                      fontSize: 12,
                      color: AppColors.successGreen,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.s16),
        OutlinedButton.icon(
          key: const ValueKey('share_athlete_pass_button'),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: AppColors.accentGold),
            foregroundColor: AppColors.accentGold,
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          icon: const Icon(LucideIcons.share2, size: 16),
          label: Text(
            'SHARE ATHLETE PASS',
            style: GoogleFonts.bebasNeue(fontSize: 14, letterSpacing: 0.5),
          ),
          onPressed: () {
            ScaffoldMessenger.of(context).clearSnackBars();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Athlete pass graphic shared successfully!'),
                backgroundColor: AppColors.successGreen,
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSharePassDetail(String label, String val) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 8,
              fontWeight: FontWeight.bold,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            val,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomRegisterBar(BuildContext context, WidgetRef ref, Tournament tournament, double totalFee) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16, vertical: AppSpacing.s16),
      decoration: const BoxDecoration(
        color: AppColors.backgroundCard,
        border: Border(top: BorderSide(color: AppColors.divider, width: 1.0)),
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
            key: const ValueKey('register_now_cta_button'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentRed,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            onPressed: _isProcessing
                ? null
                : () async {
                    setState(() {
                      _isProcessing = true;
                    });
                    
                    // Simulate payment checkout network delay
                    await Future.delayed(const Duration(milliseconds: 1000));
                    final success = await ref.read(competeProvider.notifier).registerForTournament(tournament.id);
                    
                    if (context.mounted) {
                      setState(() {
                        _isProcessing = false;
                      });
                      if (success) {
                        HapticFeedback.mediumImpact();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Registration confirmed successfully!'),
                            backgroundColor: AppColors.successGreen,
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Registration checkout failed. Please try again.'),
                            backgroundColor: AppColors.accentRed,
                          ),
                        );
                      }
                    }
                  },
            child: _isProcessing
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(color: AppColors.textPrimary, strokeWidth: 2.0),
                  )
                : Text(
                    'Register Now — ₹${totalFee.toStringAsFixed(0)}'.toUpperCase(),
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
