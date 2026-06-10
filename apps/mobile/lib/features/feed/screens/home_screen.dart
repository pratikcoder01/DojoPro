import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:shimmer/shimmer.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/feed_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(feedProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: AppBar(
        title: const Text('DOJOPRO'),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.bell, color: AppColors.textPrimary, size: 20),
            onPressed: () {},
          ),
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.s16),
            child: Row(
              children: [
                const Icon(LucideIcons.flame, color: AppColors.accentGold, size: 20),
                const SizedBox(width: AppSpacing.s4),
                Text(
                  '7',
                  style: GoogleFonts.bebasNeue(fontSize: 18, color: AppColors.textPrimary),
                ),
              ],
            ),
          )
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(feedProvider.notifier).fetchFeed(isRefresh: true),
        color: AppColors.accentRed,
        backgroundColor: AppColors.backgroundCard,
        child: state.isLoading && state.items.isEmpty
            ? const _FeedSkeletonLoader()
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Stories Row
                  const _StoriesRow(),
                  const Divider(color: AppColors.divider, height: 1),

                  // Vertical TikTok Scroll Feed
                  Expanded(
                    child: PageView.builder(
                      scrollDirection: Axis.vertical,
                      itemCount: state.items.length,
                      onPageChanged: (index) {
                        // Check if we need to load more items (infinite scroll trigger)
                        if (index == state.items.length - 2) {
                          ref.read(feedProvider.notifier).fetchFeed();
                        }
                      },
                      itemBuilder: (context, index) {
                        final item = state.items[index];
                        return _VideoFeedCard(item: item);
                      },
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

// --- SUB WIDGETS ---

class _StoriesRow extends StatelessWidget {
  const _StoriesRow();

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> stories = [
      {'name': 'Sensei Priya', 'beltColor': AppColors.beltColors['black'] ?? Colors.black, 'isLive': true},
      {'name': 'Arjun M.', 'beltColor': AppColors.beltColors['brown'] ?? Colors.brown, 'isLive': false},
      {'name': 'Mumbai Gym', 'beltColor': AppColors.beltColors['blue'] ?? Colors.blue, 'isLive': false},
      {'name': 'Karan Dojo', 'beltColor': AppColors.beltColors['green'] ?? Colors.green, 'isLive': false},
    ];

    return Container(
      height: 90,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.s8),
      color: AppColors.backgroundPrimary,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s12),
        itemCount: stories.length,
        itemBuilder: (context, index) {
          final s = stories[index];
          final color = s['beltColor'] as Color;
          final isLive = s['isLive'] as bool;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s8),
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isLive ? AppColors.accentRed : color,
                          width: 2.0,
                        ),
                      ),
                      child: const CircleAvatar(
                        radius: 24,
                        backgroundColor: AppColors.backgroundCard,
                        child: Icon(LucideIcons.user, size: 20, color: AppColors.textSecondary),
                      ),
                    ),
                    if (isLive)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.accentRed,
                          borderRadius: BorderRadius.circular(AppRadius.badge),
                        ),
                        child: Text(
                          'LIVE',
                          style: GoogleFonts.inter(fontSize: 8, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.s4),
                Text(
                  s['name'] as String,
                  style: GoogleFonts.inter(fontSize: 10, color: AppColors.textSecondary),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _VideoFeedCard extends StatefulWidget {
  final FeedItem item;
  const _VideoFeedCard({required this.item});

  @override
  State<_VideoFeedCard> createState() => _VideoFeedCardState();
}

class _VideoFeedCardState extends State<_VideoFeedCard> {
  late VideoPlayerController _videoPlayerController;
  ChewieController? _chewieController;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    try {
      _videoPlayerController = VideoPlayerController.networkUrl(Uri.parse(widget.item.videoUrl));
      await _videoPlayerController.initialize();
      
      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController,
        autoPlay: true,
        looping: true,
        showControls: false, // Clean TikTok overlay look
        allowedScreenSleep: false,
        aspectRatio: _videoPlayerController.value.aspectRatio,
        placeholder: Container(
          color: Colors.black,
          child: const Center(
            child: CircularProgressIndicator(color: AppColors.accentRed),
          ),
        ),
      );
      
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('Video player init error: $e');
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
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Player
          if (_isInitialized && _chewieController != null)
            Center(
              child: AspectRatio(
                aspectRatio: _videoPlayerController.value.aspectRatio,
                child: Chewie(controller: _chewieController!),
              ),
            )
          else
            const Center(
              child: CircularProgressIndicator(color: AppColors.accentRed),
            ),

          // Top Right Discipline Pill
          Positioned(
            top: AppSpacing.s16,
            right: AppSpacing.s16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.accentRed.withAlpha(200),
                borderRadius: BorderRadius.circular(AppRadius.badge),
              ),
              child: Text(
                widget.item.discipline.toUpperCase(),
                style: GoogleFonts.bebasNeue(
                  fontSize: 12,
                  color: AppColors.textPrimary,
                  letterSpacing: 1.0,
                ),
              ),
            ),
          ),

          // Bottom Left Profile Details Overlay
          Positioned(
            bottom: AppSpacing.s24,
            left: AppSpacing.s16,
            right: 80,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        const CircleAvatar(
                          radius: 18,
                          backgroundColor: AppColors.backgroundCard,
                          child: Icon(LucideIcons.user, size: 16, color: AppColors.textPrimary),
                        ),
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: AppColors.beltColors[widget.item.authorBelt.toLowerCase()] ?? Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.black, width: 1),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: AppSpacing.s8),
                    Text(
                      widget.item.authorName,
                      style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: AppColors.textPrimary, fontSize: 14),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.s8),
                Text(
                  widget.item.title,
                  style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 13, height: 1.3),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Bottom Right Engagement Bar Overlay
          Positioned(
            bottom: AppSpacing.s24,
            right: AppSpacing.s16,
            child: Consumer(
              builder: (context, ref, child) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Fist Bump (Like) Button
                    _buildEngagementItem(
                      icon: LucideIcons.thumbsUp,
                      label: widget.item.likesCount.toString(),
                      color: widget.item.isLiked ? AppColors.accentRed : AppColors.textPrimary,
                      onTap: () {
                        ref.read(feedProvider.notifier).toggleLike(widget.item.id);
                      },
                    ),
                    const SizedBox(height: AppSpacing.s24),
                    
                    // Comments Button
                    _buildEngagementItem(
                      icon: LucideIcons.messageSquare,
                      label: widget.item.commentsCount.toString(),
                      onTap: () {},
                    ),
                    const SizedBox(height: AppSpacing.s24),
                    
                    // Share Button
                    _buildEngagementItem(
                      icon: LucideIcons.share2,
                      label: 'Share',
                      onTap: () {},
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEngagementItem({
    required IconData icon,
    required String label,
    Color color = AppColors.textPrimary,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withAlpha(150),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: AppSpacing.s4),
          Text(
            label,
            style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }
}

class _FeedSkeletonLoader extends StatelessWidget {
  const _FeedSkeletonLoader();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.backgroundCard,
      highlightColor: AppColors.backgroundElevated,
      child: Column(
        children: [
          // Mock Stories
          SizedBox(
            height: 90,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: 4,
              itemBuilder: (context, index) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Column(
                  children: [
                    Container(width: 54, height: 54, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
                    const SizedBox(height: 6),
                    Container(width: 40, height: 8, color: Colors.white),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Mock Video Card
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppRadius.card),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
