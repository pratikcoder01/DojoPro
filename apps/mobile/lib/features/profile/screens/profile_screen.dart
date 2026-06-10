import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

import '../../../core/theme/app_theme.dart';
import '../providers/profile_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  final String userId;
  const ProfileScreen({super.key, this.userId = 'mock_user_arjun'});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  VideoPlayerController? _heroVideoController;
  ChewieController? _heroChewieController;
  bool _isHeroVideoInit = false;

  @override
  void initState() {
    super.initState();
    _initHeroVideo();
  }

  Future<void> _initHeroVideo() async {
    try {
      _heroVideoController = VideoPlayerController.networkUrl(
        Uri.parse('https://assets.mixkit.co/videos/preview/mixkit-martial-arts-trainer-practicing-karate-kicks-40334-large.mp4'),
      );
      await _heroVideoController!.initialize();
      _heroVideoController!.setVolume(0.0); // Muted
      _heroVideoController!.setLooping(true);
      _heroVideoController!.play();

      _heroChewieController = ChewieController(
        videoPlayerController: _heroVideoController!,
        autoPlay: true,
        looping: true,
        showControls: false,
        aspectRatio: _heroVideoController!.value.aspectRatio,
      );

      if (mounted) {
        setState(() {
          _isHeroVideoInit = true;
        });
      }
    } catch (e) {
      debugPrint('Hero background video player init failed: $e');
    }
  }

  @override
  void dispose() {
    _heroVideoController?.dispose();
    _heroChewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(profileProvider(widget.userId));
    final notifier = ref.read(profileProvider(widget.userId).notifier);

    if (state.isLoading && state.user == null) {
      return const Scaffold(
        backgroundColor: AppColors.backgroundPrimary,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.accentRed),
        ),
      );
    }

    final user = state.user;
    final stats = state.stats;
    if (user == null || stats == null) {
      return const Scaffold(
        backgroundColor: AppColors.backgroundPrimary,
        body: Center(
          child: Text(
            'Failed to load profile.',
            style: TextStyle(color: AppColors.textPrimary),
          ),
        ),
      );
    }

    final beltColor = AppColors.beltColors[user.beltLevel.toLowerCase()] ?? Colors.white;

    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Hero Section
            Stack(
              clipBehavior: Clip.none,
              children: [
                // Background video player / static photo
                Container(
                  height: 280,
                  width: double.infinity,
                  color: AppColors.backgroundCard,
                  child: _isHeroVideoInit && _heroChewieController != null
                      ? FittedBox(
                          fit: BoxFit.cover,
                          child: SizedBox(
                            width: _heroVideoController!.value.size.width,
                            height: _heroVideoController!.value.size.height,
                            child: Chewie(controller: _heroChewieController!),
                          ),
                        )
                      : CachedNetworkImage(
                          imageUrl: 'https://images.unsplash.com/photo-1555597673-b21d5c935865?w=800',
                          fit: BoxFit.cover,
                        ),
                ),
                // Premium dark gradient scrim overlay
                Container(
                  height: 280,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withOpacity(0.2),
                        AppColors.backgroundPrimary.withOpacity(0.95),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
                // Athlete Profile Headers
                Positioned(
                  bottom: 16,
                  left: 16,
                  right: 16,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Verified Belt Badge
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.backgroundCard,
                              borderRadius: BorderRadius.circular(AppRadius.badge),
                              border: Border.all(color: beltColor, width: 1.5),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: beltColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.s8),
                                Text(
                                  '${user.beltLevel.toUpperCase()} BELT',
                                  style: GoogleFonts.bebasNeue(
                                    fontSize: 12,
                                    color: AppColors.textPrimary,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (user.verified) ...[
                            const SizedBox(width: AppSpacing.s8),
                            const Icon(
                              LucideIcons.badgeCheck,
                              color: AppColors.accentGold,
                              size: 20,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: AppSpacing.s8),
                      // Athlete Name in Bebas Neue 48px
                      Text(
                        user.displayName,
                        style: GoogleFonts.bebasNeue(
                          fontSize: 48,
                          color: AppColors.textPrimary,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.s4),
                      Text(
                        '${user.discipline} • Mumbai, India',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.s12),
                      // Brief Bio
                      Text(
                        user.bio,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.s16),
                      // Hero action buttons
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: stats.isFollowing
                                    ? AppColors.backgroundElevated
                                    : AppColors.accentRed,
                                minimumSize: const Size(0, 40),
                              ),
                              onPressed: () => notifier.toggleFollow(),
                              child: Text(
                                stats.isFollowing ? 'FOLLOWING' : 'FOLLOW',
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.s8),
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.textPrimary,
                                side: const BorderSide(color: AppColors.divider),
                                minimumSize: const Size(0, 40),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(AppRadius.element),
                                ),
                              ),
                              icon: const Icon(LucideIcons.messageSquare, size: 16),
                              label: const Text(
                                'MESSAGE',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                              ),
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Chat messages coming soon in Phase 2.')),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.s16),

            // 2. Stats Bar Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.s12),
                decoration: BoxDecoration(
                  color: AppColors.backgroundCard,
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStatItem(
                      context,
                      '${stats.sessions} SESSIONS',
                      () => _showStatsDetail(context, 'Sessions History', [
                        'Shotokan Karate Kata Class - 2026-06-08',
                        'Kumite Sparring Practice - 2026-06-05',
                        'Strength & Conditioning - 2026-06-03',
                        'Special Dojo Seminar - 2026-05-28',
                      ]),
                    ),
                    Container(height: 24, width: 1.0, color: AppColors.divider),
                    _buildStatItem(
                      context,
                      '${stats.wins} WINS',
                      () => _showStatsDetail(context, 'Fight Wins Record', [
                        'Mumbai Open Karate Cup - Gold (Kumite Under 75kg)',
                        'Bandra Sparring Meet - Win by Ippon vs Rohan Sharma',
                        'Maharashtra State League - Win by Decision vs Vikram Malhotra',
                      ]),
                    ),
                    Container(height: 24, width: 1.0, color: AppColors.divider),
                    _buildStatItem(
                      context,
                      '${stats.certs} CERTS',
                      () => _showStatsDetail(context, 'Digital Belt Certificates', [
                        'Brown Belt Registry Certificate - Issued by Sensei Priya Rao',
                        'Blue Belt Registry Certificate - Issued by DojoPro Registry',
                      ]),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.s24),

            // 3. Belt Progression Timeline Section
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.s16),
              child: Text(
                'BELT PROGRESSION',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textSecondary,
                  letterSpacing: 1.0,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.s12),
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
                itemCount: state.timeline.length,
                itemBuilder: (context, index) {
                  final node = state.timeline[index];
                  final nodeColor = AppColors.beltColors[node.level.toLowerCase()] ?? Colors.white;

                  return Row(
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          node.isCurrent
                              ? _PulsingBeltNode(
                                  color: nodeColor,
                                  child: CircleAvatar(
                                    radius: 20,
                                    backgroundColor: nodeColor,
                                    child: node.verified
                                        ? const Icon(LucideIcons.shieldCheck, size: 18, color: Colors.black)
                                        : null,
                                  ),
                                )
                              : CircleAvatar(
                                  radius: 16,
                                  backgroundColor: nodeColor,
                                  child: node.verified
                                      ? Icon(
                                          LucideIcons.shieldCheck,
                                          size: 14,
                                          color: nodeColor == Colors.white ? Colors.black : Colors.white,
                                        )
                                      : null,
                                ),
                          const SizedBox(height: AppSpacing.s8),
                          Text(
                            node.title,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: node.isCurrent ? FontWeight.bold : FontWeight.normal,
                              color: node.isCurrent ? AppColors.accentGold : AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.s4),
                          Text(
                            node.earnedDate,
                            style: const TextStyle(fontSize: 9, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                      if (index < state.timeline.length - 1)
                        Container(
                          width: 40,
                          height: 2,
                          color: AppColors.divider,
                        ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: AppSpacing.s24),

            // 4. Trophy Shelf Section
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.s16),
              child: Text(
                'TROPHY SHELF',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textSecondary,
                  letterSpacing: 1.0,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.s12),
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
                itemCount: state.badges.length,
                itemBuilder: (context, index) {
                  final badge = state.badges[index];
                  IconData badgeIcon;
                  switch (badge.icon) {
                    case 'star':
                      badgeIcon = LucideIcons.star;
                      break;
                    case 'shield_check':
                      badgeIcon = LucideIcons.shieldCheck;
                      break;
                    case 'trophy':
                      badgeIcon = LucideIcons.trophy;
                      break;
                    case 'flame':
                      badgeIcon = LucideIcons.flame;
                      break;
                    case 'video':
                    default:
                      badgeIcon = LucideIcons.video;
                      break;
                  }

                  return GestureDetector(
                    onTap: () => _showBadgeDetail(context, badge),
                    child: Container(
                      width: 80,
                      margin: const EdgeInsets.only(right: AppSpacing.s16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: const BoxDecoration(
                              color: AppColors.backgroundCard,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              badgeIcon,
                              color: AppColors.accentGold,
                              size: 24,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.s8),
                          Text(
                            badge.title,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: AppSpacing.s24),

            // 5. Video Grid Section
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.s16),
              child: Text(
                'TECHNIQUE VIDEOS',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textSecondary,
                  letterSpacing: 1.0,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.s12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: AppSpacing.s8,
                mainAxisSpacing: AppSpacing.s8,
                childAspectRatio: 1.0,
              ),
              itemCount: state.videos.length,
              itemBuilder: (context, index) {
                final video = state.videos[index];

                return GestureDetector(
                  onTap: () => _playVideo(context, video),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: AppColors.beltColors[user.beltLevel.toLowerCase()] ?? Colors.white,
                        width: 1.5,
                      ),
                      borderRadius: BorderRadius.circular(AppRadius.element),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.element - 1),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          CachedNetworkImage(
                            imageUrl: video.thumbnailUrl,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(color: AppColors.backgroundCard),
                            errorWidget: (context, url, error) => Container(color: AppColors.backgroundCard),
                          ),
                          Container(
                            color: Colors.black.withOpacity(0.3),
                          ),
                          const Center(
                            child: Icon(
                              LucideIcons.playCircle,
                              color: AppColors.textPrimary,
                              size: 28,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: AppSpacing.s24),

            // 6. Social Stats & Sparring Challenge
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${stats.followersCount} Followers',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.s16),
                      Text(
                        '${stats.followingCount} Following',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.s16),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentRed,
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    icon: const Icon(LucideIcons.swords, size: 20),
                    label: const Text('ISSUE SPARRING CHALLENGE'),
                    onPressed: () async {
                      final success = await notifier.challengeSparring('mock_current_user');
                      if (success && context.mounted) {
                        _showChallengeSuccess(context);
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.s48),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, String title, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s12, vertical: AppSpacing.s4),
        child: Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: AppColors.accentGold,
          ),
        ),
      ),
    );
  }

  void _showStatsDetail(BuildContext context, String title, List<String> details) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.backgroundCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.card)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(AppSpacing.s24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title.toUpperCase(),
                style: GoogleFonts.bebasNeue(
                  fontSize: 24,
                  color: AppColors.textPrimary,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: AppSpacing.s16),
              ...details.map((detail) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.s8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(LucideIcons.circleDot, size: 12, color: AppColors.accentGold),
                        const SizedBox(width: AppSpacing.s8),
                        Expanded(
                          child: Text(
                            detail,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
              const SizedBox(height: AppSpacing.s24),
            ],
          ),
        );
      },
    );
  }

  void _showBadgeDetail(BuildContext context, BadgeItem badge) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.backgroundCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.card),
          ),
          title: Text(
            badge.title.toUpperCase(),
            style: GoogleFonts.bebasNeue(
              fontSize: 22,
              color: AppColors.accentGold,
              letterSpacing: 1.0,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                badge.description,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.s12),
              Text(
                'Earned Date: ${badge.earnedDate}',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'CLOSE',
                style: TextStyle(color: AppColors.accentRed, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  void _playVideo(BuildContext context, ProfileVideo video) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.card)),
      ),
      builder: (context) {
        return _VideoPlaySheet(videoUrl: video.videoUrl, title: video.title);
      },
    );
  }

  void _showChallengeSuccess(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.backgroundCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.card),
          ),
          title: const Row(
            children: [
              Icon(LucideIcons.swords, color: AppColors.accentRed),
              SizedBox(width: AppSpacing.s8),
              Text('CHALLENGE SENT'),
            ],
          ),
          content: const Text(
            'Your sparring request was sent! You will receive a notification once the target athlete responds.',
            style: TextStyle(color: AppColors.textPrimary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'AWESOME',
                style: TextStyle(color: AppColors.accentGold, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _PulsingBeltNode extends StatefulWidget {
  final Color color;
  final Widget child;
  const _PulsingBeltNode({required this.color, required this.child});

  @override
  State<_PulsingBeltNode> createState() => _PulsingBeltNodeState();
}

class _PulsingBeltNodeState extends State<_PulsingBeltNode> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    
    final isTest = Platform.environment.containsKey('FLUTTER_TEST');
    if (!isTest) {
      _controller.repeat(reverse: true);
    } else {
      _controller.value = 1.0;
    }

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.15).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: widget.color.withOpacity(0.4),
              blurRadius: 12,
              spreadRadius: 3,
            ),
          ],
        ),
        child: widget.child,
      ),
    );
  }
}

class _VideoPlaySheet extends StatefulWidget {
  final String videoUrl;
  final String title;
  const _VideoPlaySheet({required this.videoUrl, required this.title});

  @override
  State<_VideoPlaySheet> createState() => _VideoPlaySheetState();
}

class _VideoPlaySheetState extends State<_VideoPlaySheet> {
  late VideoPlayerController _videoPlayerController;
  ChewieController? _chewieController;
  bool _isInit = false;

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    try {
      _videoPlayerController = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
      await _videoPlayerController.initialize();
      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController,
        autoPlay: true,
        looping: true,
        showControls: true,
        aspectRatio: _videoPlayerController.value.aspectRatio,
      );
      if (mounted) {
        setState(() {
          _isInit = true;
        });
      }
    } catch (e) {
      debugPrint('Video sheet play failed: $e');
    }
  }

  @override
  void dispose() {
    _videoPlayerController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      padding: EdgeInsets.only(
        top: 40,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        left: AppSpacing.s16,
        right: AppSpacing.s16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  widget.title.toUpperCase(),
                  style: GoogleFonts.bebasNeue(
                    fontSize: 20,
                    color: AppColors.textPrimary,
                    letterSpacing: 1.0,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(LucideIcons.x, color: AppColors.textPrimary),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s16),
          _isInit && _chewieController != null
              ? AspectRatio(
                  aspectRatio: _videoPlayerController.value.aspectRatio,
                  child: Chewie(controller: _chewieController!),
                )
              : const SizedBox(
                  height: 200,
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.accentRed),
                  ),
                ),
          const SizedBox(height: AppSpacing.s24),
        ],
      ),
    );
  }
}
