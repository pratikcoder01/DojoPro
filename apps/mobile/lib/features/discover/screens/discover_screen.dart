import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:io';

import '../../../core/theme/app_theme.dart';
import '../providers/discover_provider.dart';

// Dark Google Map Style String mapping DojoPro's Dark Premium aesthetic
const String _darkMapStyle = '''
[
  {
    "elementType": "geometry",
    "stylers": [
      {"color": "#0D0D1A"}
    ]
  },
  {
    "elementType": "labels.text.fill",
    "stylers": [
      {"color": "#A0A0B0"}
    ]
  },
  {
    "elementType": "labels.text.stroke",
    "stylers": [
      {"color": "#0D0D1A"}
    ]
  },
  {
    "featureType": "administrative",
    "elementType": "geometry",
    "stylers": [
      {"color": "#2E2E4A"}
    ]
  },
  {
    "featureType": "poi",
    "elementType": "geometry",
    "stylers": [
      {"color": "#1A1A2E"}
    ]
  },
  {
    "featureType": "road",
    "elementType": "geometry",
    "stylers": [
      {"color": "#1A1A2E"}
    ]
  },
  {
    "featureType": "road",
    "elementType": "geometry.stroke",
    "stylers": [
      {"color": "#2E2E4A"}
    ]
  },
  {
    "featureType": "water",
    "elementType": "geometry",
    "stylers": [
      {"color": "#070710"}
    ]
  }
]
''';

class DiscoverScreen extends ConsumerStatefulWidget {
  const DiscoverScreen({super.key});

  @override
  ConsumerState<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends ConsumerState<DiscoverScreen> {
  GoogleMapController? _mapController;
  String? _expandedGymId;

  // Center on map marker when tapped
  void _centerOnLocation(double lat, double lng) {
    if (_mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(LatLng(lat, lng), 14.5),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(discoverProvider);
    final notifier = ref.read(discoverProvider.notifier);

    // If permission has not been granted, show the motivational preview step
    if (!state.hasPermission) {
      return _buildPermissionPreview(notifier);
    }

    // Otherwise show the active Gym Discovery Screen with full-screen map & bottom sheet
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      body: Stack(
        children: [
          // 1. Google Map Base Layer
          _buildGoogleMap(state, notifier),

          // 2. Floating Filter Chips (Top Overlay)
          _buildFilterChips(state, notifier),

          // 3. Loading overlay spinner
          if (state.isLoading)
            Positioned(
              top: 130,
              left: MediaQuery.of(context).size.width / 2 - 20,
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.s8),
                decoration: const BoxDecoration(
                  color: AppColors.backgroundCard,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: Colors.black54, blurRadius: 8, offset: Offset(0, 4)),
                  ],
                ),
                width: 40,
                height: 40,
                child: const CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.accentRed),
                ),
              ),
            ),

          // 4. Swipe-Up Draggable Bottom Sheet
          _buildDraggableBottomSheet(state),
        ],
      ),
    );
  }

  // 1. Full-screen Google Map Base Layer
  Widget _buildGoogleMap(DiscoverState state, DiscoverNotifier notifier) {
    // Generate markers dynamically
    final Set<Marker> markers = state.gyms.map((gym) {
      return Marker(
        markerId: MarkerId(gym.id),
        position: LatLng(gym.lat, gym.lng),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: InfoWindow(
          title: gym.name,
          snippet: '${gym.styles.join(', ')} • ${gym.rating} ★',
        ),
        onTap: () {
          setState(() {
            _expandedGymId = gym.id;
          });
          _centerOnLocation(gym.lat, gym.lng);
        },
      );
    }).toSet();

    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: LatLng(state.userLat ?? 19.0760, state.userLng ?? 72.8777),
        zoom: 12.0,
      ),
      myLocationEnabled: true,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      mapToolbarEnabled: false,
      markers: markers,
      onMapCreated: (GoogleMapController controller) {
        _mapController = controller;
        // Apply Dark theme styles
        controller.setMapStyle(_darkMapStyle);
      },
    );
  }

  // 2. Floating Filter Chips Row (Top Overlay)
  Widget _buildFilterChips(DiscoverState state, DiscoverNotifier notifier) {
    final styles = ['All Styles', 'Karate', 'BJJ', 'MMA', 'Judo'];

    return Positioned(
      top: 55,
      left: 0,
      right: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row A: Discipline Filters
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
            child: Row(
              children: styles.map((style) {
                final isSelected = state.selectedStyleFilter == style;
                return Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.s8),
                  child: FilterChip(
                    selected: isSelected,
                    label: Text(
                      style,
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                      ),
                    ),
                    onSelected: (_) => notifier.setStyleFilter(style),
                    backgroundColor: AppColors.backgroundCard,
                    selectedColor: AppColors.accentRed,
                    checkmarkColor: AppColors.textPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.badge),
                      side: BorderSide(
                        color: isSelected ? AppColors.accentGold : AppColors.divider,
                        width: 1.0,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: AppSpacing.s8),
          // Row B: Helper Toggle filters
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
            child: Row(
              children: [
                _buildToggleChip(
                  label: '< 5km',
                  isSelected: state.distanceFilter,
                  onTap: () => notifier.toggleDistanceFilter(),
                ),
                _buildToggleChip(
                  label: 'Open Now',
                  isSelected: state.openNowFilter,
                  onTap: () => notifier.toggleOpenNowFilter(),
                ),
                _buildToggleChip(
                  label: '4★+',
                  isSelected: state.highRatingFilter,
                  onTap: () => notifier.toggleHighRatingFilter(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.s8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s12, vertical: 6.0),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.accentRed : AppColors.backgroundCard,
            borderRadius: BorderRadius.circular(AppRadius.badge),
            border: Border.all(
              color: isSelected ? AppColors.accentGold : AppColors.divider,
              width: 1.0,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isSelected) ...[
                const Icon(LucideIcons.check, size: 14, color: AppColors.textPrimary),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 3. Swipe-Up Draggable Bottom Sheet
  Widget _buildDraggableBottomSheet(DiscoverState state) {
    return DraggableScrollableSheet(
      initialChildSize: 0.25, // Peek size (~200px)
      minChildSize: 0.22,
      maxChildSize: 0.95, // Expanded size
      builder: (BuildContext context, ScrollController scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.backgroundCard,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(AppRadius.card),
              topRight: Radius.circular(AppRadius.card),
            ),
            boxShadow: [
              BoxShadow(color: Colors.black87, blurRadius: 16, spreadRadius: 2),
            ],
          ),
          child: Column(
            children: [
              // Drag Swipe Handle indicator bar
              const SizedBox(height: AppSpacing.s12),
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(2.5),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.s12),
              // Header description row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'DOJOS NEARBY',
                      style: Theme.of(context).textTheme.displaySmall,
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s8, vertical: AppSpacing.s4),
                      decoration: BoxDecoration(
                        color: AppColors.backgroundElevated,
                        borderRadius: BorderRadius.circular(AppRadius.element),
                      ),
                      child: Text(
                        '${state.gyms.length} FOUND',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.accentGold,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.s8),
              const Divider(color: AppColors.divider),
              // List view displaying dojos
              Expanded(
                child: state.gyms.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16, vertical: AppSpacing.s8),
                        itemCount: state.gyms.length,
                        itemBuilder: (context, index) {
                          final gym = state.gyms[index];
                          return _buildGymCard(gym);
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(LucideIcons.mapPinOff, size: 48, color: AppColors.textSecondary),
          const SizedBox(height: AppSpacing.s16),
          const Text(
            'No Training Dojos Found',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary),
          ),
          const SizedBox(height: AppSpacing.s8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Try adjusting your filter parameters or search radius to expand your discovery bounds.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(height: AppSpacing.s16),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(180, 40),
            ),
            onPressed: () {
              ref.read(discoverProvider.notifier).setStyleFilter('All Styles');
              if (ref.read(discoverProvider).distanceFilter) {
                ref.read(discoverProvider.notifier).toggleDistanceFilter();
              }
              if (ref.read(discoverProvider).openNowFilter) {
                ref.read(discoverProvider.notifier).toggleOpenNowFilter();
              }
              if (ref.read(discoverProvider).highRatingFilter) {
                ref.read(discoverProvider.notifier).toggleHighRatingFilter();
              }
            },
            child: const Text('Reset Filters'),
          ),
        ],
      ),
    );
  }

  Widget _buildGymCard(DiscoverGym gym) {
    final isExpanded = _expandedGymId == gym.id;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.s12),
      decoration: BoxDecoration(
        color: AppColors.backgroundElevated,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(
          color: isExpanded ? AppColors.accentGold : Colors.transparent,
          width: 1.0,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.card),
        onTap: () {
          setState(() {
            _expandedGymId = isExpanded ? null : gym.id;
          });
          if (!isExpanded) {
            _centerOnLocation(gym.lat, gym.lng);
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.s12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Collapsed Header Row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Gym Image Preview
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.element),
                    child: CachedNetworkImage(
                      imageUrl: gym.photos.isNotEmpty ? gym.photos[0] : '',
                      width: 70,
                      height: 70,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(color: AppColors.backgroundCard),
                      errorWidget: (context, url, error) => Container(
                        color: AppColors.backgroundCard,
                        child: const Icon(LucideIcons.home, color: AppColors.textSecondary, size: 24),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.s12),
                  // Info Details Column
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          gym.name,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4.0),
                        // Style pills row
                        Row(
                          children: gym.styles.map((style) {
                            return Container(
                              margin: const EdgeInsets.only(right: 6.0),
                              padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
                              decoration: BoxDecoration(
                                color: AppColors.backgroundCard,
                                borderRadius: BorderRadius.circular(4.0),
                              ),
                              child: Text(
                                style,
                                style: const TextStyle(fontSize: 10, color: AppColors.accentGold),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 6.0),
                        // Rating & Distance Row
                        Row(
                          children: [
                            const Icon(Icons.star, color: AppColors.accentGold, size: 14),
                            const SizedBox(width: 2.0),
                            Text(
                              '${gym.rating}',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                            ),
                            const SizedBox(width: 6.0),
                            const Text('•', style: TextStyle(color: AppColors.textSecondary)),
                            const SizedBox(width: 6.0),
                            Text(
                              '${gym.distanceKm} km',
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                            const Spacer(),
                            // Open / Closed badge
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
                              decoration: BoxDecoration(
                                color: gym.isOpen
                                    ? AppColors.successGreen.withOpacity(0.1)
                                    : AppColors.accentRed.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4.0),
                              ),
                              child: Text(
                                gym.isOpen ? 'OPEN NOW' : 'CLOSED',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: gym.isOpen ? AppColors.successGreen : AppColors.accentRedLight,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Expanded Details view
              if (isExpanded) ...[
                const SizedBox(height: AppSpacing.s12),
                const Divider(color: AppColors.divider),
                const SizedBox(height: AppSpacing.s8),

                // Gym Carousel Image Slider
                const Text(
                  'PHOTOS',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                ),
                const SizedBox(height: AppSpacing.s8),
                SizedBox(
                  height: 90,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: gym.photos.length,
                    itemBuilder: (context, idx) {
                      return Container(
                        margin: const EdgeInsets.only(right: AppSpacing.s8),
                        width: 130,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(AppRadius.element),
                          child: CachedNetworkImage(
                            imageUrl: gym.photos[idx],
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(color: AppColors.backgroundCard),
                            errorWidget: (context, url, error) => const Icon(LucideIcons.image),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: AppSpacing.s12),

                // Certified Coaches summary
                const Text(
                  'COACHES & LEADERSHIP',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                ),
                const SizedBox(height: AppSpacing.s4),
                Row(
                  children: [
                    const Icon(LucideIcons.users, size: 14, color: AppColors.accentGold),
                    const SizedBox(width: AppSpacing.s8),
                    Text(
                      '${gym.coaches.length} Coaches: ${gym.coaches.join(", ")}',
                      style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.s12),

                // Class Timetable Schedule Summary
                const Text(
                  'CLASS TIMETABLE',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                ),
                const SizedBox(height: AppSpacing.s4),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.s8),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundCard,
                    borderRadius: BorderRadius.circular(AppRadius.element),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: gym.schedule.map((item) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4.0),
                        child: Text(
                          '• $item',
                          style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: AppSpacing.s16),

                // "Book Trial Class" Button Action
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentRed,
                    minimumSize: const Size(double.infinity, 44),
                  ),
                  icon: const Icon(LucideIcons.calendarCheck, size: 16),
                  label: const Text('Book Trial Class'),
                  onPressed: () {
                    // Navigate to Coaching booking screen with pre-selected dojo routing context
                    if (!Platform.environment.containsKey('FLUTTER_TEST')) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Booking Trial at ${gym.name}... redirecting to bookings.'),
                          backgroundColor: AppColors.successGreen,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                    context.go('/book');
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // Permission Request motivational mockup screen
  Widget _buildPermissionPreview(DiscoverNotifier notifier) {
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: CachedNetworkImageProvider(
              'https://images.unsplash.com/photo-1517649763962-0c623066013b?w=500',
            ),
            fit: BoxFit.cover,
            opacity: 0.15,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.s24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),
              const Center(
                child: Icon(
                  LucideIcons.map,
                  size: 80,
                  color: AppColors.accentGold,
                ),
              ),
              const Spacer(),
              Text(
                'DISCOVER YOUR DOJO',
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      fontSize: 40,
                      color: AppColors.textPrimary,
                    ),
              ),
              const SizedBox(height: AppSpacing.s12),
              Text(
                'Enable locations to map nearby professional gyms, schedule verified belt checks, and find local sparring matches in Mumbai.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
              ),
              const SizedBox(height: AppSpacing.s32),
              ElevatedButton.icon(
                icon: const Icon(LucideIcons.navigation, size: 18),
                label: const Text('GRANT LOCATION PERMISSION'),
                onPressed: () => notifier.requestLocationPermission(),
              ),
              const SizedBox(height: AppSpacing.s24),
            ],
          ),
        ),
      ),
    );
  }
}
