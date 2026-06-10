import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/coaching_provider.dart';

class BookingConfirmationScreen extends ConsumerStatefulWidget {
  const BookingConfirmationScreen({super.key});

  @override
  ConsumerState<BookingConfirmationScreen> createState() => _BookingConfirmationScreenState();
}

class _BookingConfirmationScreenState extends ConsumerState<BookingConfirmationScreen> {
  bool _showSuccessAnimation = false;
  bool _hasTriggeredSuccessEffects = false;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(coachingProvider);
    final coach = state.coach;

    if (coach == null) {
      return Scaffold(
        backgroundColor: AppColors.backgroundPrimary,
        appBar: AppBar(
          title: const Text('CONFIRMATION'),
          backgroundColor: AppColors.backgroundCard,
        ),
        body: const Center(
          child: Text(
            'Error: No coach profile selected.',
            style: TextStyle(color: AppColors.textPrimary),
          ),
        ),
      );
    }

    // Trigger success animations and haptic feedback once status changes to success
    if (state.status == BookingStatus.success && !_hasTriggeredSuccessEffects) {
      _hasTriggeredSuccessEffects = true;
      HapticFeedback.lightImpact();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _showSuccessAnimation = true;
        });
      });
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: AppBar(
        title: Text(
          state.status == BookingStatus.success ? 'BOOKING CONFIRMED' : 'CONFIRM BOOKING',
          style: GoogleFonts.bebasNeue(letterSpacing: 1.0),
        ),
        backgroundColor: AppColors.backgroundCard,
        elevation: 0,
        leading: state.status == BookingStatus.success
            ? const SizedBox.shrink()
            : IconButton(
                icon: const Icon(LucideIcons.arrowLeft, color: AppColors.textPrimary),
                onPressed: () => Navigator.of(context).pop(),
              ),
      ),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          child: state.status == BookingStatus.success
              ? _buildSuccessView(context, state, coach)
              : _buildCheckoutForm(context, state, coach),
        ),
      ),
    );
  }

  Widget _buildCheckoutForm(BuildContext context, BookingState state, CoachDetail coach) {
    final formattedDate = state.selectedSlot != null
        ? DateFormat('EEEE, d MMMM yyyy').format(state.selectedSlot!)
        : 'Not Selected';
    final formattedTime = state.selectedSlot != null
        ? DateFormat('h:mm a').format(state.selectedSlot!)
        : 'Not Selected';
    final totalAmount = coach.hourlyRate * state.durationHours;

    return SingleChildScrollView(
      key: const ValueKey('checkout_form'),
      padding: const EdgeInsets.all(AppSpacing.s24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Booking Header
          Text(
            'REVIEW YOUR SESSION',
            style: GoogleFonts.bebasNeue(fontSize: 24, color: AppColors.textPrimary),
          ),
          const SizedBox(height: AppSpacing.s16),

          // Summary Card
          Container(
            padding: const EdgeInsets.all(AppSpacing.s16),
            decoration: BoxDecoration(
              color: AppColors.backgroundCard,
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: Border.all(color: AppColors.divider),
            ),
            child: Column(
              children: [
                _buildSummaryDetailRow('Coach', coach.name, isBold: true),
                const Divider(color: AppColors.divider, height: 24),
                _buildSummaryDetailRow('Date', formattedDate),
                const Divider(color: AppColors.divider, height: 24),
                _buildSummaryDetailRow('Time', formattedTime),
                const Divider(color: AppColors.divider, height: 24),
                _buildSummaryDetailRow(
                  'Session Type',
                  state.sessionType == BookingSessionType.online ? 'Online (HD Stream)' : 'In-Person',
                ),
                const Divider(color: AppColors.divider, height: 24),
                
                // Duration Select/Display Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'DURATION',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: const Icon(LucideIcons.minusCircle, color: AppColors.textSecondary, size: 20),
                          onPressed: state.durationHours > 1
                              ? () => ref.read(coachingProvider.notifier).selectDuration(state.durationHours - 1)
                              : null,
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            '${state.durationHours} hr',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: const Icon(LucideIcons.plusCircle, color: AppColors.accentGold, size: 20),
                          onPressed: state.durationHours < 4
                              ? () => ref.read(coachingProvider.notifier).selectDuration(state.durationHours + 1)
                              : null,
                        ),
                      ],
                    ),
                  ],
                ),
                const Divider(color: AppColors.divider, height: 24),
                
                _buildSummaryDetailRow(
                  'TOTAL PRICE',
                  '₹$totalAmount',
                  valueColor: AppColors.accentGold,
                  isPrice: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.s32),

          // Payment Selector Header
          Text(
            'SELECT PAYMENT PROCESSOR',
            style: GoogleFonts.bebasNeue(fontSize: 18, color: AppColors.textPrimary, letterSpacing: 0.8),
          ),
          const SizedBox(height: AppSpacing.s12),

          // Stripe vs Razorpay Segmented Selector
          Row(
            children: [
              Expanded(
                child: _buildPaymentMethodOption(
                  label: 'STRIPE',
                  sub: 'Cards & Apple Pay',
                  icon: LucideIcons.creditCard,
                  isSelected: state.selectedPaymentMethod == 'stripe',
                  onTap: () => ref.read(coachingProvider.notifier).selectPaymentMethod('stripe'),
                ),
              ),
              const SizedBox(width: AppSpacing.s12),
              Expanded(
                child: _buildPaymentMethodOption(
                  label: 'RAZORPAY',
                  sub: 'UPI & NetBanking',
                  icon: LucideIcons.wallet,
                  isSelected: state.selectedPaymentMethod == 'razorpay',
                  onTap: () => ref.read(coachingProvider.notifier).selectPaymentMethod('razorpay'),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s32),

          // Payment processing button
          ElevatedButton(
            key: const ValueKey('confirm_payment_button'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentRed,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.card),
              ),
            ),
            onPressed: state.status == BookingStatus.loading
                ? null
                : () async {
                    final success = await ref.read(coachingProvider.notifier).processBookingPayment();
                    if (!success && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(state.errorMessage ?? 'Payment failed. Please try again.'),
                          backgroundColor: AppColors.accentRed,
                        ),
                      );
                    }
                  },
            child: state.status == BookingStatus.loading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: AppColors.textPrimary,
                      strokeWidth: 2.0,
                    ),
                  )
                : Text(
                    'Confirm and Pay ₹$totalAmount'.toUpperCase(),
                    style: GoogleFonts.bebasNeue(fontSize: 18, letterSpacing: 1.0),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessView(BuildContext context, BookingState state, CoachDetail coach) {
    final totalAmount = coach.hourlyRate * state.durationHours;
    final formattedDate = state.selectedSlot != null
        ? DateFormat('EEEE, d MMMM').format(state.selectedSlot!)
        : 'Date';
    final formattedTime = state.selectedSlot != null
        ? DateFormat('h:mm a').format(state.selectedSlot!)
        : 'Time';

    return SingleChildScrollView(
      key: const ValueKey('success_view'),
      padding: const EdgeInsets.all(AppSpacing.s24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSpacing.s16),
          // Scale & Fade Animated Checkmark Circle
          Center(
            child: AnimatedScale(
              scale: _showSuccessAnimation ? 1.0 : 0.4,
              duration: const Duration(milliseconds: 600),
              curve: Curves.elasticOut,
              child: AnimatedOpacity(
                opacity: _showSuccessAnimation ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 350),
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: const BoxDecoration(
                    color: AppColors.successGreen,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.successGreen,
                        blurRadius: 16,
                        spreadRadius: 2,
                      )
                    ],
                  ),
                  child: const Icon(LucideIcons.check, size: 48, color: AppColors.textPrimary),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.s32),

          // Title & Message
          Text(
            'SESSION BOOKED!',
            textAlign: TextAlign.center,
            style: GoogleFonts.bebasNeue(
              fontSize: 36,
              color: AppColors.textPrimary,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: AppSpacing.s12),
          Text(
            'Your private session with ${coach.name} has been secured.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 14,
              height: 1.5,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.s24),

          // Summary Box
          Container(
            padding: const EdgeInsets.all(AppSpacing.s16),
            decoration: BoxDecoration(
              color: AppColors.backgroundCard,
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: Border.all(color: AppColors.divider),
            ),
            child: Column(
              children: [
                _buildSummaryDetailRow('Instructor', coach.name, isBold: true),
                const Divider(color: AppColors.divider, height: 24),
                _buildSummaryDetailRow('Date', formattedDate),
                const Divider(color: AppColors.divider, height: 24),
                _buildSummaryDetailRow('Time', formattedTime),
                const Divider(color: AppColors.divider, height: 24),
                _buildSummaryDetailRow('Duration', '${state.durationHours} Hours'),
                const Divider(color: AppColors.divider, height: 24),
                _buildSummaryDetailRow(
                  'Payment Status',
                  'PAID via ${state.selectedPaymentMethod.toUpperCase()}',
                  valueColor: AppColors.successGreen,
                  isBold: true,
                ),
                const Divider(color: AppColors.divider, height: 24),
                _buildSummaryDetailRow('Amount Paid', '₹$totalAmount', isPrice: true, valueColor: AppColors.accentGold),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.s24),

          // Auto-add to Calendar Integration Prompt
          ElevatedButton.icon(
            key: const ValueKey('add_to_calendar_button'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.backgroundCard,
              foregroundColor: AppColors.textPrimary,
              side: const BorderSide(color: AppColors.divider),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            icon: const Icon(LucideIcons.calendarPlus, color: AppColors.accentGold, size: 18),
            label: Text(
              'ADD TO CALENDAR',
              style: GoogleFonts.bebasNeue(fontSize: 14, letterSpacing: 0.5),
            ),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: AppColors.backgroundCard,
                  title: Text(
                    'ADD TO SYSTEM CALENDAR',
                    style: GoogleFonts.bebasNeue(color: AppColors.textPrimary),
                  ),
                  content: Text(
                    'Do you want to sync this session with your Google/Apple calendar?',
                    style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 13),
                  ),
                  actions: [
                    TextButton(
                      child: Text('CANCEL', style: GoogleFonts.inter(color: AppColors.textSecondary)),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    TextButton(
                      key: const ValueKey('calendar_confirm_yes'),
                      child: Text('YES, ADD', style: GoogleFonts.inter(color: AppColors.accentGold, fontWeight: FontWeight.bold)),
                      onPressed: () {
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Session successfully synced to your local calendar!'),
                            backgroundColor: AppColors.successGreen,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: AppSpacing.s16),

          // Push Notification Alert Reminder
          Container(
            padding: const EdgeInsets.all(AppSpacing.s12),
            decoration: BoxDecoration(
              color: AppColors.accentGold.withOpacity(0.1),
              border: Border.all(color: AppColors.accentGold.withOpacity(0.3)),
              borderRadius: BorderRadius.circular(AppRadius.element),
            ),
            child: Row(
              children: [
                const Icon(LucideIcons.bellRing, color: AppColors.accentGold, size: 18),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Reminder push notification scheduled for 1 hour before session.',
                    style: GoogleFonts.inter(
                      color: AppColors.textPrimary,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.s32),

          // Back to Coach Profile button
          ElevatedButton(
            key: const ValueKey('back_to_profile_button'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentRed,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            onPressed: () {
              ref.read(coachingProvider.notifier).resetBookingState();
              Navigator.of(context).pop();
            },
            child: Text(
              'BACK TO COACH PROFILE',
              style: GoogleFonts.bebasNeue(fontSize: 16, letterSpacing: 1.0),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryDetailRow(
    String label,
    String value, {
    bool isBold = false,
    bool isPrice = false,
    Color? valueColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label.toUpperCase(),
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: isPrice
              ? GoogleFonts.bebasNeue(
                  fontSize: 18,
                  color: valueColor ?? AppColors.textPrimary,
                  letterSpacing: 0.5,
                )
              : GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                  color: valueColor ?? AppColors.textPrimary,
                ),
        ),
      ],
    );
  }

  Widget _buildPaymentMethodOption({
    required String label,
    required String sub,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.s16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accentRed.withOpacity(0.2) : AppColors.backgroundCard,
          border: Border.all(
            color: isSelected ? AppColors.accentRed : AppColors.divider,
            width: isSelected ? 1.5 : 1.0,
          ),
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.accentRedLight : AppColors.textSecondary,
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.bebasNeue(
                fontSize: 14,
                color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              sub,
              style: GoogleFonts.inter(
                fontSize: 9,
                color: AppColors.textSecondary.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
