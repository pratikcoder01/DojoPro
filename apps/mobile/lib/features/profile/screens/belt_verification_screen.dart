import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'dart:math';

import '../../../core/theme/app_theme.dart';
import '../providers/belt_verification_provider.dart';

// Custom Painter for Gold Shimmer Particle Burst
class ParticleBurstPainter extends CustomPainter {
  final double progress;
  ParticleBurstPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..color = AppColors.accentGold.withOpacity(max(0.0, 1.0 - progress))
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 12; i++) {
      final double angle = (i * 30) * pi / 180;
      final double distance = progress * 120;
      final offset = Offset(
        center.dx + distance * cos(angle),
        center.dy + distance * sin(angle),
      );
      canvas.drawCircle(offset, 6.0 * (1.0 - progress), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class BeltVerificationScreen extends ConsumerStatefulWidget {
  const BeltVerificationScreen({super.key});

  @override
  ConsumerState<BeltVerificationScreen> createState() => _BeltVerificationScreenState();
}

class _BeltVerificationScreenState extends ConsumerState<BeltVerificationScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _clockRotation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
    _clockRotation = Tween<double>(begin: 0, end: 2 * pi).animate(_animationController);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(beltVerificationProvider);
    final notifier = ref.read(beltVerificationProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: AppBar(
        title: Text(
          'BELT VERIFICATION',
          style: GoogleFonts.bebasNeue(
            fontSize: 24,
            letterSpacing: 1.2,
            color: AppColors.textPrimary,
          ),
        ),
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronLeft),
          onPressed: () {
            if (state.wizardStep > 1 && state.wizardStep < 4) {
              notifier.setWizardStep(state.wizardStep - 1);
            } else {
              notifier.resetFlow();
              context.go('/profile');
            }
          },
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Top Progress bar (Step 1-4 indicator)
            _buildProgressBar(state.wizardStep),
            const SizedBox(height: AppSpacing.s16),

            // Step Content Switcher
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
                child: _buildStepContent(state, notifier),
              ),
            ),

            // Fixed Continue action bar at bottom
            if (state.wizardStep < 4) _buildBottomBar(state, notifier),
          ],
        ),
      ),
    );
  }

  // Top Progress bar indicating wizard steps
  Widget _buildProgressBar(int currentStep) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16, vertical: AppSpacing.s8),
      child: Row(
        children: List.generate(4, (index) {
          final stepNum = index + 1;
          final isActive = stepNum <= currentStep;
          final isCompleted = stepNum < currentStep;

          return Expanded(
            child: Row(
              children: [
                // Step circle
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? AppColors.successGreen
                        : isActive
                            ? AppColors.accentRed
                            : AppColors.backgroundElevated,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isActive ? AppColors.accentGold : Colors.transparent,
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: isCompleted
                        ? const Icon(LucideIcons.check, size: 14, color: AppColors.textPrimary)
                        : Text(
                            '$stepNum',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                  ),
                ),
                // Step connector divider
                if (index < 3)
                  Expanded(
                    child: Container(
                      height: 2.0,
                      color: stepNum < currentStep ? AppColors.successGreen : AppColors.divider,
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  // Render step contents based on current step
  Widget _buildStepContent(BeltVerificationState state, BeltVerificationNotifier notifier) {
    switch (state.wizardStep) {
      case 1:
        return _buildStep1DisciplineAndBelt(state, notifier);
      case 2:
        return _buildStep2UploadEvidence(state, notifier);
      case 3:
        return _buildStep3GymVerification(state, notifier);
      case 4:
        return _buildStep4VerifiedBadge(state, notifier);
      default:
        return const SizedBox();
    }
  }

  // STEP 1 - Select Discipline and Belt Level
  Widget _buildStep1DisciplineAndBelt(
      BeltVerificationState state, BeltVerificationNotifier notifier) {
    final disciplines = [
      {'name': 'Karate', 'icon': LucideIcons.swords},
      {'name': 'BJJ', 'icon': LucideIcons.shieldCheck},
      {'name': 'Judo', 'icon': LucideIcons.scale},
      {'name': 'Muay Thai', 'icon': LucideIcons.flame},
      {'name': 'MMA', 'icon': LucideIcons.activity},
      {'name': 'Taekwondo', 'icon': LucideIcons.zap},
    ];

    final belts = ['white', 'yellow', 'green', 'blue', 'brown', 'black'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Grid Title
        Text(
          'CHOOSE DISCIPLINE',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 16),
        ),
        const SizedBox(height: AppSpacing.s12),
        // Grid of cards
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: AppSpacing.s8,
            mainAxisSpacing: AppSpacing.s8,
            childAspectRatio: 1.1,
          ),
          itemCount: disciplines.length,
          itemBuilder: (context, index) {
            final disc = disciplines[index];
            final name = disc['name'] as String;
            final icon = disc['icon'] as IconData;
            final isSelected = state.selectedDiscipline == name;

            return Container(
              decoration: BoxDecoration(
                color: AppColors.backgroundElevated,
                borderRadius: BorderRadius.circular(AppRadius.element),
                border: Border.all(
                  color: isSelected ? AppColors.accentGold : Colors.transparent,
                  width: 1.5,
                ),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(AppRadius.element),
                onTap: () => notifier.setDiscipline(name),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      icon,
                      color: isSelected ? AppColors.accentRedLight : AppColors.textSecondary,
                      size: 24,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: AppSpacing.s24),

        // Belt Title
        Text(
          'SELECT BELT LEVEL',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 16),
        ),
        const SizedBox(height: AppSpacing.s12),

        // Horizontal Belt Picker Row
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: belts.map((belt) {
              final isSelected = state.selectedBelt == belt;
              final beltColor = AppColors.beltColors[belt] ?? Colors.white;

              return Padding(
                padding: const EdgeInsets.only(right: AppSpacing.s12),
                child: GestureDetector(
                  onTap: () => notifier.setBelt(belt),
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: beltColor,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? AppColors.accentGold : AppColors.divider,
                        width: isSelected ? 3.0 : 1.5,
                      ),
                      boxShadow: [
                        if (isSelected)
                          BoxShadow(
                            color: AppColors.accentGold.withOpacity(0.5),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                      ],
                    ),
                    child: Center(
                      child: isSelected
                          ? Icon(
                              LucideIcons.check,
                              color: belt == 'white' || belt == 'yellow'
                                  ? Colors.black87
                                  : Colors.white,
                              size: 20,
                            )
                          : const SizedBox(),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: AppSpacing.s32),

        // visual Name display in Bebas Neue
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s24, vertical: AppSpacing.s12),
            decoration: BoxDecoration(
              color: AppColors.backgroundCard,
              borderRadius: BorderRadius.circular(AppRadius.element),
              border: Border.all(color: AppColors.divider),
            ),
            child: Column(
              children: [
                Text(
                  state.selectedBelt.toUpperCase(),
                  style: GoogleFonts.bebasNeue(
                    fontSize: 42,
                    color: AppColors.beltColors[state.selectedBelt] ?? AppColors.textPrimary,
                    letterSpacing: 2.0,
                  ),
                ),
                Text(
                  'CURRENTLY SELECTED GRADE',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: AppColors.textSecondary,
                        letterSpacing: 1.0,
                      ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.s24),
      ],
    );
  }

  // STEP 2 - Upload Evidence
  Widget _buildStep2UploadEvidence(
      BeltVerificationState state, BeltVerificationNotifier notifier) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'UPLOAD EVIDENCE',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 16),
        ),
        const SizedBox(height: AppSpacing.s12),

        // Guidance alert overlay info card
        Container(
          padding: const EdgeInsets.all(AppSpacing.s16),
          decoration: BoxDecoration(
            color: AppColors.backgroundCard,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: AppColors.divider),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(LucideIcons.info, color: AppColors.accentGold, size: 20),
              const SizedBox(width: AppSpacing.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'REQUIREMENT INSTRUCTIONS',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 4.0),
                    Text(
                      'Film yourself performing your grade requirements. 2-3 minutes. Make sure your footwork, technique, and stance are clearly visible.',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.s24),

        // Video Demonstration upload target
        GestureDetector(
          onTap: () {
            if (!state.isUploading) {
              notifier.setVideoPath('/mock/videos/kata_grade.mp4');
            }
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.s32),
            decoration: BoxDecoration(
              color: AppColors.backgroundElevated,
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: Border.all(
                color: state.videoPath != null ? AppColors.successGreen : AppColors.divider,
                width: 1.5,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  state.videoPath != null ? LucideIcons.checkCircle2 : LucideIcons.video,
                  size: 40,
                  color: state.videoPath != null ? AppColors.successGreen : AppColors.accentRed,
                ),
                const SizedBox(height: AppSpacing.s12),
                Text(
                  state.videoPath != null ? 'KATA_DEMO.MP4 ATTACHED' : 'UPLOAD KATA VIDEO DEMO',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 4.0),
                const Text(
                  'Primary evidence • via MUX upload',
                  style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.s16),

        // Certificate Upload target
        GestureDetector(
          onTap: () {
            if (!state.isUploading) {
              notifier.setCertificatePath('/mock/photos/certificate.jpg');
            }
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.s24),
            decoration: BoxDecoration(
              color: AppColors.backgroundElevated,
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: Border.all(
                color: state.certificatePath != null ? AppColors.successGreen : AppColors.divider,
                width: 1.5,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  state.certificatePath != null ? LucideIcons.checkCircle2 : LucideIcons.uploadCloud,
                  size: 30,
                  color: state.certificatePath != null ? AppColors.successGreen : AppColors.accentGold,
                ),
                const SizedBox(height: AppSpacing.s8),
                Text(
                  state.certificatePath != null ? 'CERTIFICATE_PHOTO.JPG ATTACHED' : 'UPLOAD CERTIFICATE / CREDENTIAL PHOTO',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 4.0),
                const Text(
                  'Secondary evidence • via Secure S3 Bucket',
                  style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.s32),

        // Upload progress bar layout
        if (state.isUploading) ...[
          Container(
            padding: const EdgeInsets.all(AppSpacing.s16),
            decoration: BoxDecoration(
              color: AppColors.backgroundCard,
              borderRadius: BorderRadius.circular(AppRadius.element),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'UPLOADING EVIDENCE TO DOJOPRO CDNs...',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.accentGold),
                    ),
                    Text(
                      '${(state.uploadProgress * 100).toInt()}%',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.s8),
                LinearProgressIndicator(
                  value: state.uploadProgress,
                  backgroundColor: AppColors.divider,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accentRed),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.s16),
        ],
      ],
    );
  }

  // STEP 3 - Gym Cross-Verification
  Widget _buildStep3GymVerification(
      BeltVerificationState state, BeltVerificationNotifier notifier) {
    if (state.verificationStatus == 'pending') {
      return _buildPendingVerificationOverlay();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'SELECT VERIFYING GYM',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 16),
        ),
        const SizedBox(height: AppSpacing.s12),

        // Search text field
        TextField(
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: 'Search dojos for verification...',
            prefixIcon: const Icon(LucideIcons.search, color: AppColors.textSecondary),
            suffixIcon: state.searchedGymQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(LucideIcons.x, color: AppColors.textSecondary),
                    onPressed: () => notifier.searchGyms(''),
                  )
                : null,
          ),
          onChanged: (val) => notifier.searchGyms(val),
        ),
        const SizedBox(height: AppSpacing.s16),

        // Gyms List
        state.isLoadingGyms
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.s24),
                  child: CircularProgressIndicator(color: AppColors.accentRed),
                ),
              )
            : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: state.gymsList.length,
                itemBuilder: (context, index) {
                  final gym = state.gymsList[index];
                  final id = gym['id'] as String;
                  final name = gym['name'] as String;
                  final isSelected = state.selectedGymId == id;

                  return Container(
                    margin: const EdgeInsets.only(bottom: AppSpacing.s8),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundElevated,
                      borderRadius: BorderRadius.circular(AppRadius.element),
                      border: Border.all(
                        color: isSelected ? AppColors.accentGold : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: ListTile(
                      title: Text(
                        name,
                        style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
                      ),
                      leading: Icon(
                        LucideIcons.home,
                        color: isSelected ? AppColors.accentRed : AppColors.textSecondary,
                        size: 20,
                      ),
                      trailing: isSelected
                          ? const Icon(LucideIcons.checkCircle, color: AppColors.accentGold, size: 20)
                          : null,
                      onTap: () => notifier.selectGym(id, name),
                    ),
                  );
                },
              ),
        const SizedBox(height: AppSpacing.s24),
      ],
    );
  }

  // Pending approval visual overlays
  Widget _buildPendingVerificationOverlay() {
    final state = ref.read(beltVerificationProvider);

    return Column(
      children: [
        const SizedBox(height: AppSpacing.s48),
        // Animated clock icon
        AnimatedBuilder(
          animation: _clockRotation,
          builder: (context, child) {
            return Transform.rotate(
              angle: _clockRotation.value,
              child: child,
            );
          },
          child: const Icon(
            LucideIcons.clock,
            size: 80,
            color: AppColors.accentGold,
          ),
        ),
        const SizedBox(height: AppSpacing.s32),

        Text(
          'PENDING GYM APPROVAL',
          style: GoogleFonts.bebasNeue(
            fontSize: 32,
            letterSpacing: 1.5,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.s16),

        Container(
          padding: const EdgeInsets.all(AppSpacing.s24),
          decoration: BoxDecoration(
            color: AppColors.backgroundCard,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: AppColors.divider),
          ),
          child: Column(
            children: [
              Text(
                'YOUR REQUEST HAS BEEN SUBMITTED TO:',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: AppColors.textSecondary,
                      letterSpacing: 0.8,
                    ),
              ),
              const SizedBox(height: 8.0),
              Text(
                state.selectedGymName ?? 'Dharavi MMA & BJJ Academy',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.s16),
              const Divider(color: AppColors.divider),
              const SizedBox(height: AppSpacing.s16),
              const Text(
                'Dojo owner is currently verifying your video kata credentials and certificate authenticity. Verified checks will post automatically.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.5),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.s48),
      ],
    );
  }

  // STEP 4 - Verified Badge Issued
  Widget _buildStep4VerifiedBadge(
      BeltVerificationState state, BeltVerificationNotifier notifier) {
    final beltColor = AppColors.beltColors[state.selectedBelt] ?? Colors.white;

    return Column(
      children: [
        const SizedBox(height: AppSpacing.s24),

        // Gold Shimmer Particle Burst Animation Overlay
        if (state.isBurstActive)
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 1500),
            builder: (context, val, child) {
              return CustomPaint(
                painter: ParticleBurstPainter(val),
                child: SizedBox(
                  width: double.infinity,
                  height: 120,
                  child: child,
                ),
              );
            },
          ),

        // Gold Shield Check verified Badge
        const Center(
          child: Icon(
            LucideIcons.shieldCheck,
            size: 96,
            color: AppColors.accentGold,
          ),
        ),
        const SizedBox(height: AppSpacing.s16),

        Text(
          'VERIFICATION SUCCESSFUL',
          style: GoogleFonts.bebasNeue(
            fontSize: 36,
            letterSpacing: 1.5,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.s8),

        const Text(
          'Your belt level has been successfully verified on the blockchain registry.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.s32),

        // Shareable Card Layout
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.backgroundCard,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: AppColors.accentGold, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: AppColors.accentGold.withOpacity(0.15),
                blurRadius: 16,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            children: [
              // Card Header banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                color: AppColors.accentGold,
                child: const Center(
                  child: Text(
                    'DOJOPRO VERIFIED RANK',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.s24),
                child: Column(
                  children: [
                    // Mock Avatar + Badge circle
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: beltColor,
                          child: CircleAvatar(
                            radius: 36,
                            backgroundColor: AppColors.backgroundPrimary,
                            child: const Icon(LucideIcons.user, size: 36, color: AppColors.textSecondary),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(4.0),
                          decoration: const BoxDecoration(
                            color: AppColors.accentGold,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(LucideIcons.shieldAlert, size: 14, color: Colors.black),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.s16),

                    Text(
                      'I earned my ${state.selectedBelt.toUpperCase()} BELT in ${state.selectedDiscipline}!',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.bebasNeue(
                        fontSize: 28,
                        letterSpacing: 1.0,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s8),

                    const Text(
                      'Verified by Bandra Striking & Karate Dojo',
                      style: TextStyle(fontSize: 12, color: AppColors.accentGold, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: AppSpacing.s24),

                    // Share Trigger buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildShareIcon(LucideIcons.camera, 'Instagram'),
                        const SizedBox(width: AppSpacing.s24),
                        _buildShareIcon(LucideIcons.messageSquare, 'WhatsApp'),
                        const SizedBox(width: AppSpacing.s24),
                        _buildShareIcon(LucideIcons.share2, 'Share Link'),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.s32),

        // Back to Profile button
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.backgroundElevated,
            minimumSize: const Size(double.infinity, 50),
          ),
          onPressed: () {
            notifier.resetFlow();
            context.go('/profile');
          },
          child: const Text('BACK TO ATHLETE PROFILE'),
        ),
        const SizedBox(height: AppSpacing.s32),
      ],
    );
  }

  Widget _buildShareIcon(IconData icon, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.s12),
          decoration: BoxDecoration(
            color: AppColors.backgroundElevated,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.divider),
          ),
          child: Icon(icon, size: 20, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 6.0),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  // BOTTOM ACTION BAR (Step 1-3 continue triggers)
  Widget _buildBottomBar(BeltVerificationState state, BeltVerificationNotifier notifier) {
    final isStep1Ready = true; // Always ready
    final isStep2Ready = state.videoPath != null && state.certificatePath != null;
    final isStep3Ready = state.selectedGymId != null;

    final isContinueEnabled = state.wizardStep == 1
        ? isStep1Ready
        : state.wizardStep == 2
            ? isStep2Ready
            : isStep3Ready;

    final buttonText = state.wizardStep == 1
        ? 'CONTINUE TO UPLOAD'
        : state.wizardStep == 2
            ? 'CONTINUE TO GYM VERIFICATION'
            : 'SUBMIT FOR VERIFICATION';

    return Container(
      padding: const EdgeInsets.all(AppSpacing.s16),
      decoration: const BoxDecoration(
        color: AppColors.backgroundCard,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: isContinueEnabled ? AppColors.accentRed : AppColors.backgroundElevated,
          foregroundColor: isContinueEnabled ? AppColors.textPrimary : AppColors.textSecondary,
        ),
        onPressed: !isContinueEnabled || state.isUploading || state.verificationStatus == 'submitting'
            ? null
            : () async {
                if (state.wizardStep == 1) {
                  notifier.setWizardStep(2);
                } else if (state.wizardStep == 2) {
                  notifier.startUploadSimulation();
                } else if (state.wizardStep == 3) {
                  await notifier.submitVerificationRequest();
                }
              },
        child: state.isUploading
            ? const Text('UPLOADING EVIDENCE...')
            : state.verificationStatus == 'submitting'
                ? const Text('SUBMITTING...')
                : Text(buttonText),
      ),
    );
  }
}
