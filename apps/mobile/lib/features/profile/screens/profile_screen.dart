import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../core/theme/app_theme.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Premium dark design system elements for Arjun Mehta
    const String athleteName = 'ARJUN MEHTA';
    const String activeBelt = 'brown';
    final Color beltColor = AppColors.beltColors[activeBelt] ?? Colors.white;

    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Cover Photo & Profile Avatar Hero Section
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.bottomCenter,
              children: [
                // Cover Photo
                CachedNetworkImage(
                  imageUrl: 'https://images.unsplash.com/photo-1555597673-b21d5c935865?w=800',
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(color: AppColors.backgroundCard),
                  errorWidget: (context, url, error) => Container(color: AppColors.backgroundCard),
                ),
                // Dark Gradient overlay
                Container(
                  height: 180,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withOpacity(0.4),
                        AppColors.backgroundPrimary.withOpacity(0.9),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
                // Circular Avatar with belt color ring boundary
                Positioned(
                  bottom: -50,
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 54,
                        backgroundColor: beltColor,
                        child: CircleAvatar(
                          radius: 50,
                          backgroundColor: AppColors.backgroundPrimary,
                          child: const CircleAvatar(
                            radius: 46,
                            backgroundImage: CachedNetworkImageProvider(
                              'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150',
                            ),
                          ),
                        ),
                      ),
                      // Gold checkmark badge
                      Container(
                        padding: const EdgeInsets.all(6.0),
                        decoration: const BoxDecoration(
                          color: AppColors.accentGold,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          LucideIcons.shieldCheck,
                          size: 16,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 60),

            // 2. Athlete Headers & Verified Badge
            Center(
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        athleteName,
                        style: GoogleFonts.bebasNeue(
                          fontSize: 32,
                          color: AppColors.textPrimary,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.s8),
                      const Icon(
                        LucideIcons.badgeCheck,
                        color: AppColors.accentGold,
                        size: 24,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.s4),
                  const Text(
                    'Shotokan Karate • Mumbai, India',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.accentGold,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s32),
                    child: Text(
                      'Recreational karate athlete training 4x/week at Bandra Dojo. Specializing in kumite sparring, active competition formats, and kata forms.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                            height: 1.4,
                          ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.s24),

            // 3. Stats Row Summary Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.s16),
                decoration: BoxDecoration(
                  color: AppColors.backgroundCard,
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStatCol('18', 'SPARRINGS'),
                    Container(height: 30, width: 1.0, color: AppColors.divider),
                    _buildStatCol('4', 'TOURNAMENTS'),
                    Container(height: 30, width: 1.0, color: AppColors.divider),
                    _buildStatCol('BROWN', 'BELT LEVEL'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.s24),

            // 4. Belt verification CTA Action Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.s16),
                decoration: BoxDecoration(
                  color: AppColors.backgroundElevated,
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(LucideIcons.shieldAlert, color: AppColors.accentGold, size: 20),
                        SizedBox(width: AppSpacing.s8),
                        Text(
                          'BELT REGISTRY SYSTEM',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.s8),
                    const Text(
                      'Submit grade evidence (video demonstrations or certificates) to earn a digital blockchain verified belt badge visible on your DojoPro profile.',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
                    ),
                    const SizedBox(height: AppSpacing.s16),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accentRed,
                        minimumSize: const Size(double.infinity, 48),
                      ),
                      icon: const Icon(LucideIcons.shieldCheck, size: 18),
                      label: const Text('VERIFY A NEW RANK'),
                      onPressed: () => context.push('/verify-belt'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.s32),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCol(String count, String label) {
    return Column(
      children: [
        Text(
          count,
          style: GoogleFonts.bebasNeue(
            fontSize: 22,
            color: AppColors.textPrimary,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 4.0),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
