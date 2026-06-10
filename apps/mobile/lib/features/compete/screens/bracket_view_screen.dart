import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import '../../../core/theme/app_theme.dart';

class BracketViewScreen extends StatefulWidget {
  final String tournamentId;
  const BracketViewScreen({super.key, required this.tournamentId});

  @override
  State<BracketViewScreen> createState() => _BracketViewScreenState();
}

class _BracketViewScreenState extends State<BracketViewScreen> {
  // Static mock bracket data matching the backend format
  static final Map<String, dynamic> _karateMockBracket = {
    'rounds': [
      {
        'name': 'Quarterfinals',
        'matches': [
          {
            'id': 'm1',
            'competitor1': { 'name': 'Arjun Mehta', 'belt': 'brown', 'gym': 'Dharavi MMA & BJJ', 'isWinner': false, 'score': '2' },
            'competitor2': { 'name': 'Rohan Sharma', 'belt': 'black', 'gym': 'Mumbai Karate Club', 'isWinner': true, 'score': '3' },
            'winnerName': 'Rohan Sharma',
            'time': '10:30 AM',
            'result': 'Rohan Sharma won by Decision (3-2) after close striking exchange.',
            'status': 'completed'
          },
          {
            'id': 'm2',
            'competitor1': { 'name': 'Pooja Patel', 'belt': 'green', 'gym': 'Dojo Pro Mumbai', 'isWinner': true, 'score': '2' },
            'competitor2': { 'name': 'Aisha Khan', 'belt': 'blue', 'gym': 'West Mumbai Karate', 'isWinner': false, 'score': '0' },
            'winnerName': 'Pooja Patel',
            'time': '11:00 AM',
            'result': 'Pooja Patel won by Ippon (2-0) using leverage throws.',
            'status': 'completed'
          },
          {
            'id': 'm3',
            'competitor1': { 'name': 'Vikram Malhotra', 'belt': 'brown', 'gym': 'Pune Fighter Gym', 'isWinner': true, 'score': '1' },
            'competitor2': { 'name': 'Sameer Joshi', 'belt': 'yellow', 'gym': 'Thane Martial Arts', 'isWinner': false, 'score': '0' },
            'winnerName': 'Vikram Malhotra',
            'time': '11:30 AM',
            'result': 'Vikram Malhotra won by Yuko (1-0).',
            'status': 'completed'
          },
          {
            'id': 'm4',
            'competitor1': { 'name': 'Rahul Sen', 'belt': 'blue', 'gym': 'Navi Mumbai Karate Academy', 'isWinner': false, 'score': '' },
            'competitor2': null,
            'winnerName': null,
            'time': '12:00 PM',
            'result': 'Waiting for opponent allocation.',
            'status': 'pending'
          }
        ]
      },
      {
        'name': 'Semifinals',
        'matches': [
          {
            'id': 'm5',
            'competitor1': { 'name': 'Rohan Sharma', 'belt': 'black', 'gym': 'Mumbai Karate Club', 'isWinner': true, 'score': '2' },
            'competitor2': { 'name': 'Pooja Patel', 'belt': 'green', 'gym': 'Dojo Pro Mumbai', 'isWinner': false, 'score': '0' },
            'winnerName': 'Rohan Sharma',
            'time': '02:30 PM',
            'result': 'Rohan Sharma won by Ippon (2-0) with explosive roundhouse kicks.',
            'status': 'completed'
          },
          {
            'id': 'm6',
            'competitor1': { 'name': 'Vikram Malhotra', 'belt': 'brown', 'gym': 'Pune Fighter Gym', 'isWinner': false, 'score': '' },
            'competitor2': null,
            'winnerName': null,
            'time': '03:00 PM',
            'result': 'TBD Semifinal Match.',
            'status': 'pending'
          }
        ]
      },
      {
        'name': 'Finals',
        'matches': [
          {
            'id': 'm7',
            'competitor1': { 'name': 'Rohan Sharma', 'belt': 'black', 'gym': 'Mumbai Karate Club', 'isWinner': false, 'score': '' },
            'competitor2': null,
            'winnerName': null,
            'time': '05:00 PM',
            'result': 'Championship Final Match.',
            'status': 'pending'
          }
        ]
      }
    ]
  };

  static final Map<String, dynamic> _completedMockBracket = {
    'rounds': [
      {
        'name': 'Quarterfinals',
        'matches': [
          {
            'id': 'm1',
            'competitor1': { 'name': 'Arjun Mehta', 'belt': 'brown', 'gym': 'Dharavi MMA & BJJ', 'isWinner': false, 'score': '2' },
            'competitor2': { 'name': 'Rohan Sharma', 'belt': 'black', 'gym': 'Mumbai Karate Club', 'isWinner': true, 'score': '3' },
            'winnerName': 'Rohan Sharma',
            'time': '10:30 AM',
            'result': 'Rohan Sharma won by Decision (3-2) after close striking exchange.',
            'status': 'completed'
          },
          {
            'id': 'm2',
            'competitor1': { 'name': 'Pooja Patel', 'belt': 'green', 'gym': 'Dojo Pro Mumbai', 'isWinner': true, 'score': '2' },
            'competitor2': { 'name': 'Aisha Khan', 'belt': 'blue', 'gym': 'West Mumbai Karate', 'isWinner': false, 'score': '0' },
            'winnerName': 'Pooja Patel',
            'time': '11:00 AM',
            'result': 'Pooja Patel won by Ippon (2-0) using leverage throws.',
            'status': 'completed'
          },
          {
            'id': 'm3',
            'competitor1': { 'name': 'Vikram Malhotra', 'belt': 'brown', 'gym': 'Pune Fighter Gym', 'isWinner': true, 'score': '1' },
            'competitor2': { 'name': 'Sameer Joshi', 'belt': 'yellow', 'gym': 'Thane Martial Arts', 'isWinner': false, 'score': '0' },
            'winnerName': 'Vikram Malhotra',
            'time': '11:30 AM',
            'result': 'Vikram Malhotra won by Yuko (1-0).',
            'status': 'completed'
          },
          {
            'id': 'm4',
            'competitor1': { 'name': 'Rahul Sen', 'belt': 'blue', 'gym': 'Navi Mumbai Karate Academy', 'isWinner': true, 'score': '2' },
            'competitor2': { 'name': 'Aman Gupta', 'belt': 'white', 'gym': 'Ghatkopar Dojo', 'isWinner': false, 'score': '0' },
            'winnerName': 'Rahul Sen',
            'time': '12:00 PM',
            'result': 'Rahul Sen won by Decision (2-0).',
            'status': 'completed'
          }
        ]
      },
      {
        'name': 'Semifinals',
        'matches': [
          {
            'id': 'm5',
            'competitor1': { 'name': 'Rohan Sharma', 'belt': 'black', 'gym': 'Mumbai Karate Club', 'isWinner': true, 'score': '2' },
            'competitor2': { 'name': 'Pooja Patel', 'belt': 'green', 'gym': 'Dojo Pro Mumbai', 'isWinner': false, 'score': '0' },
            'winnerName': 'Rohan Sharma',
            'time': '02:30 PM',
            'result': 'Rohan Sharma won by Ippon (2-0) with explosive roundhouse kicks.',
            'status': 'completed'
          },
          {
            'id': 'm6',
            'competitor1': { 'name': 'Vikram Malhotra', 'belt': 'brown', 'gym': 'Pune Fighter Gym', 'isWinner': true, 'score': '3' },
            'competitor2': { 'name': 'Rahul Sen', 'belt': 'blue', 'gym': 'Navi Mumbai Karate Academy', 'isWinner': false, 'score': '2' },
            'winnerName': 'Vikram Malhotra',
            'time': '03:00 PM',
            'result': 'Vikram Malhotra won by Decision (3-2).',
            'status': 'completed'
          }
        ]
      },
      {
        'name': 'Finals',
        'matches': [
          {
            'id': 'm7',
            'competitor1': { 'name': 'Rohan Sharma', 'belt': 'black', 'gym': 'Mumbai Karate Club', 'isWinner': true, 'score': '3' },
            'competitor2': { 'name': 'Vikram Malhotra', 'belt': 'brown', 'gym': 'Pune Fighter Gym', 'isWinner': false, 'score': '1' },
            'winnerName': 'Rohan Sharma',
            'time': '05:00 PM',
            'result': 'Rohan Sharma won the Championship by Decision (3-1) with dominant striking.',
            'status': 'completed'
          }
        ]
      }
    ]
  };

  @override
  Widget build(BuildContext context) {
    // Determine which mock data to use (completed vs upcoming)
    final bool isCompleted = widget.tournamentId.contains('789'); // Taekwondo league tourn_tkd_league_789 is completed
    final bracketData = isCompleted ? _completedMockBracket : _karateMockBracket;
    final String tournamentTitle = isCompleted 
        ? 'Maharashtra Taekwondo League' 
        : 'Mumbai Open Karate Championship';

    final List<dynamic> rounds = bracketData['rounds'] as List<dynamic>;

    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundPrimary,
        elevation: 0,
        title: Text(
          'TOURNAMENT BRACKET',
          style: GoogleFonts.bebasNeue(fontSize: 24, letterSpacing: 1.0),
        ),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16, top: 12, bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isCompleted ? AppColors.successGreen.withOpacity(0.2) : AppColors.accentGold.withOpacity(0.2),
              borderRadius: BorderRadius.circular(AppRadius.badge),
              border: Border.all(
                color: isCompleted ? AppColors.successGreen : AppColors.accentGold,
                width: 1.0,
              ),
            ),
            child: Center(
              child: Text(
                isCompleted ? 'COMPLETED' : 'LIVE BRACKET',
                style: GoogleFonts.bebasNeue(
                  fontSize: 10,
                  color: isCompleted ? AppColors.successGreen : AppColors.accentGold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Tournament Header Title Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                tournamentTitle.toUpperCase(),
                style: GoogleFonts.bebasNeue(
                  fontSize: 18,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.8,
                ),
              ),
            ),

            // Share Card Generator if Completed
            if (isCompleted) ...[
              _buildCompletedBanner(context, tournamentTitle),
              const SizedBox(height: 8),
            ],

            // The main interactive tree diagram
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  physics: const BouncingScrollPhysics(),
                  child: Container(
                    height: 620, // fixed height for perfect alignment
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: List.generate(rounds.length, (roundIndex) {
                        final round = rounds[roundIndex];
                        final String roundName = round['name'].toString().toUpperCase();
                        final List<dynamic> matches = round['matches'] as List<dynamic>;

                        return Container(
                          width: 280,
                          margin: const EdgeInsets.only(right: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Round Header
                              Container(
                                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                                decoration: const BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(color: AppColors.accentRed, width: 2.0),
                                  ),
                                ),
                                child: Text(
                                  roundName,
                                  style: GoogleFonts.bebasNeue(
                                    fontSize: 18,
                                    color: AppColors.textPrimary,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Matches list with calculated margins for vertical centering
                              Expanded(
                                child: Stack(
                                  children: List.generate(matches.length, (matchIndex) {
                                    final match = matches[matchIndex];
                                    final double topOffset = _calculateTopOffset(roundIndex, matchIndex);

                                    return Positioned(
                                      top: topOffset,
                                      left: 0,
                                      right: 0,
                                      child: _buildMatchNodeCard(context, match, roundName),
                                    );
                                  }),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _calculateTopOffset(int roundIndex, int matchIndex) {
    const double cardHeight = 130.0;
    const double round0Spacing = 32.0;

    if (roundIndex == 0) {
      // Quarterfinals
      return matchIndex * (cardHeight + round0Spacing);
    } else if (roundIndex == 1) {
      // Semifinals
      // centered between Quarterfinal pairs
      final double firstCenter = (cardHeight + round0Spacing) / 2;
      return firstCenter - (cardHeight / 2) + matchIndex * (cardHeight + 193.0);
    } else {
      // Finals
      // centered in the middle of Semifinals
      return 243.0;
    }
  }

  Widget _buildMatchNodeCard(BuildContext context, Map<String, dynamic> match, String roundName) {
    final String time = match['time'] ?? 'TBD';
    final String status = match['status'] ?? 'pending';
    final competitor1 = match['competitor1'];
    final competitor2 = match['competitor2'];

    return GestureDetector(
      onTap: () => _showMatchDetailsModal(context, match, roundName),
      child: Container(
        height: 130,
        decoration: BoxDecoration(
          color: AppColors.backgroundCard,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(
            color: status == 'completed' ? AppColors.accentRed.withOpacity(0.5) : AppColors.divider,
            width: 1.0,
          ),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 6,
              offset: Offset(0, 3),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Mini-Header with time/status
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              color: AppColors.backgroundElevated,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'MATCH ${match['id']}'.toUpperCase(),
                    style: GoogleFonts.bebasNeue(
                      fontSize: 10,
                      color: AppColors.accentGold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Row(
                    children: [
                      const Icon(LucideIcons.clock, size: 10, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        time,
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Competitors info
            Expanded(
              child: Column(
                children: [
                  // Competitor 1
                  Expanded(
                    child: _buildCompetitorRow(competitor1),
                  ),
                  const Divider(height: 1, color: AppColors.divider),
                  // Competitor 2
                  Expanded(
                    child: _buildCompetitorRow(competitor2),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompetitorRow(dynamic competitor) {
    if (competitor == null) {
      // Grey Placeholder for TBD slots
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        color: AppColors.backgroundCard,
        child: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                color: Colors.grey,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'TBD Slot',
              style: GoogleFonts.inter(
                color: Colors.grey,
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      );
    }

    final String name = competitor['name'] ?? '';
    final String belt = competitor['belt'] ?? 'white';
    final String gym = competitor['gym'] ?? '';
    final String score = competitor['score'] ?? '';
    final bool isWinner = competitor['isWinner'] == true;

    Color beltColor = AppColors.beltColors[belt.toLowerCase()] ?? Colors.white;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      // Highlight winner in red background
      color: isWinner ? AppColors.accentRed.withOpacity(0.12) : AppColors.backgroundCard,
      child: Row(
        children: [
          // Belt indicator dot
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: beltColor,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey.shade400, width: 0.5),
            ),
          ),
          const SizedBox(width: 8),

          // Name and Gym
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: isWinner ? FontWeight.bold : FontWeight.normal,
                    // Highlight winner text in red
                    color: isWinner ? AppColors.accentRedLight : AppColors.textPrimary,
                  ),
                ),
                Text(
                  gym,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // Score
          if (score.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: isWinner ? AppColors.accentRed : AppColors.backgroundElevated,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                score,
                style: GoogleFonts.bebasNeue(
                  fontSize: 12,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCompletedBanner(BuildContext context, String title) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(AppSpacing.s16),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        border: Border.all(color: AppColors.accentGold, width: 1.0),
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.trophy, color: AppColors.accentGold, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'RESULTS PUBLISHED',
                  style: GoogleFonts.bebasNeue(
                    fontSize: 16,
                    color: AppColors.textPrimary,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Matches are complete and verified on athlete profiles.',
                  style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            key: const ValueKey('completed_bracket_generate_share_button'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentRed,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              minimumSize: Size.zero,
            ),
            onPressed: () => _showShareCardModal(context, title),
            child: Text(
              'SHARE CARD',
              style: GoogleFonts.bebasNeue(fontSize: 11, letterSpacing: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  void _showMatchDetailsModal(BuildContext context, Map<String, dynamic> match, String roundName) {
    final competitor1 = match['competitor1'];
    final competitor2 = match['competitor2'];
    final String time = match['time'] ?? 'TBD';
    final String status = match['status'] ?? 'pending';
    final String result = match['result'] ?? '';

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.backgroundCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.card)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(AppSpacing.s24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Modal Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$roundName — MATCH ${match['id']}'.toUpperCase(),
                          style: GoogleFonts.bebasNeue(
                            fontSize: 20,
                            color: AppColors.textPrimary,
                            letterSpacing: 0.8,
                          ),
                        ),
                        Text(
                          'Scheduled Time: $time',
                          style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: status == 'completed' ? AppColors.successGreen.withOpacity(0.2) : AppColors.backgroundElevated,
                      borderRadius: BorderRadius.circular(AppRadius.badge),
                    ),
                    child: Text(
                      status.toUpperCase(),
                      style: GoogleFonts.bebasNeue(
                        fontSize: 10,
                        color: status == 'completed' ? AppColors.successGreen : AppColors.textSecondary,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.s24),

              // VS Athlete Cards
              Row(
                children: [
                  // Athlete 1
                  Expanded(child: _buildModalAthleteProfile(competitor1)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'VS',
                      style: GoogleFonts.bebasNeue(
                        fontSize: 28,
                        color: AppColors.accentGold,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                  // Athlete 2
                  Expanded(child: _buildModalAthleteProfile(competitor2)),
                ],
              ),
              const SizedBox(height: AppSpacing.s24),

              // Match Result Banner
              if (result.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundElevated,
                    borderRadius: BorderRadius.circular(AppRadius.element),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'OFFICIAL MATCH RESULT',
                        style: GoogleFonts.bebasNeue(
                          fontSize: 12,
                          color: AppColors.accentGold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        result,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.textPrimary,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.s24),
              ],

              // Close CTA
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentRed,
                ),
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'CLOSE DETAILS',
                  style: GoogleFonts.bebasNeue(fontSize: 14, letterSpacing: 0.5),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildModalAthleteProfile(dynamic competitor) {
    if (competitor == null) {
      return Column(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.backgroundElevated,
            child: const Icon(LucideIcons.helpCircle, color: Colors.grey, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            'TBD',
            style: GoogleFonts.bebasNeue(fontSize: 16, color: Colors.grey),
          ),
          Text(
            'To Be Decided',
            style: GoogleFonts.inter(fontSize: 10, color: Colors.grey),
          ),
        ],
      );
    }

    final String name = competitor['name'] ?? '';
    final String belt = competitor['belt'] ?? 'white';
    final String gym = competitor['gym'] ?? '';
    final String score = competitor['score'] ?? '0';
    final bool isWinner = competitor['isWinner'] == true;

    Color beltColor = AppColors.beltColors[belt.toLowerCase()] ?? Colors.white;

    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: isWinner ? AppColors.accentRed.withOpacity(0.3) : AppColors.backgroundElevated,
              child: Text(
                name.isNotEmpty ? name.substring(0, 1).toUpperCase() : 'A',
                style: GoogleFonts.bebasNeue(
                  fontSize: 22,
                  color: isWinner ? AppColors.accentRedLight : AppColors.textPrimary,
                ),
              ),
            ),
            // Belt Color Badge overlay
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: beltColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey.shade400, width: 1.0),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: isWinner ? AppColors.accentRedLight : AppColors.textPrimary,
          ),
        ),
        Text(
          gym,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 9,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        // Big Score
        Text(
          score.isNotEmpty ? score : '-',
          style: GoogleFonts.bebasNeue(
            fontSize: 22,
            color: isWinner ? AppColors.accentGold : AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  void _showShareCardModal(BuildContext context, String tournamentTitle) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Share Card UI
              Container(
                key: const ValueKey('shareable_graphics_results_pass'),
                padding: const EdgeInsets.all(AppSpacing.s24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.backgroundCard, AppColors.backgroundElevated],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  border: Border.all(color: AppColors.accentGold, width: 2.0),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black54,
                      blurRadius: 16,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'DOJOPRO EVENT RECORD',
                          style: GoogleFonts.bebasNeue(
                            fontSize: 14,
                            color: AppColors.accentGold,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const Icon(LucideIcons.trophy, color: AppColors.accentGold, size: 20),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      tournamentTitle.toUpperCase(),
                      style: GoogleFonts.bebasNeue(
                        fontSize: 22,
                        color: AppColors.textPrimary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildSharePassDetail('CHAMPION', 'Rohan Sharma (Black Belt)'),
                    _buildSharePassDetail('RUNNER-UP', 'Vikram Malhotra (Brown Belt)'),
                    _buildSharePassDetail('ATHLETE IN FOCUS', 'Arjun Mehta (Quarterfinalist)'),
                    const SizedBox(height: 20),
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.accentRed.withOpacity(0.2),
                          border: Border.all(color: AppColors.accentRed),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(LucideIcons.award, color: AppColors.accentRedLight, size: 14),
                            const SizedBox(width: 6),
                            Text(
                              'VERIFIED RESULTS',
                              style: GoogleFonts.bebasNeue(
                                fontSize: 12,
                                color: AppColors.accentRedLight,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.textSecondary),
                        foregroundColor: AppColors.textPrimary,
                        backgroundColor: AppColors.backgroundCard,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      icon: const Icon(LucideIcons.x, size: 14),
                      label: Text(
                        'CLOSE',
                        style: GoogleFonts.bebasNeue(fontSize: 14, letterSpacing: 0.5),
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      key: const ValueKey('results_share_card_trigger_button'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accentGold,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      icon: const Icon(LucideIcons.share2, size: 14, color: Colors.black),
                      label: Text(
                        'SHARE RESULTS',
                        style: GoogleFonts.bebasNeue(fontSize: 14, letterSpacing: 0.5, color: Colors.black),
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).clearSnackBars();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Championship results card shared successfully!'),
                            backgroundColor: AppColors.successGreen,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              )
            ],
          ),
        );
      },
    );
  }

  Widget _buildSharePassDetail(String label, String val) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            val,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
