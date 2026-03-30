import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/rides_provider.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/ride_card.dart';
import '../../../core/widgets/feature_hint.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String _selectedType = 'ALL';

  final _types = [
    {'key': 'ALL', 'label': 'All Rides', 'icon': Icons.directions_car},
    {'key': 'OFFICE', 'label': 'Office', 'icon': Icons.business},
    {'key': 'UNIVERSITY', 'label': 'Campus', 'icon': Icons.school},
    {'key': 'DISCUSSION', 'label': 'DriveDesk', 'icon': Icons.record_voice_over},
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadRides());
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  void _loadRides() {
    ref.read(ridesProvider.notifier).searchRides(
          rideType: _selectedType == 'ALL' ? null : _selectedType,
        );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final ridesState = ref.watch(ridesProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ─── Header ──────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${_greeting()}, ${user?.firstName ?? ''} 👋',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const Text(
                            'Find or offer a verified ride',
                            style: TextStyle(
                                fontSize: 13, color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    // Post ride FAB-style
                    ElevatedButton.icon(
                      onPressed: () => context.push('/post-ride'),
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Post Ride'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: Size.zero,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ─── Feature hint ─────────────────────────────────────────────
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.only(top: 12),
                child: FeatureHint(
                  featureKey: 'home',
                  icon: Icons.explore_outlined,
                  title: 'Discover Rides',
                  description:
                      'Browse available rides below or tap Search to filter by route. Tap a ride to view details and book your seat.',
                  color: AppTheme.primary,
                ),
              ),
            ),

            // ─── Search bar ───────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: GestureDetector(
                  onTap: () => context.push('/search-rides'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.divider),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.search, color: AppTheme.textHint),
                        SizedBox(width: 10),
                        Text('Where are you going?',
                            style: TextStyle(
                                color: AppTheme.textHint, fontSize: 14)),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // ─── Ride type filter ─────────────────────────────────────────
            SliverToBoxAdapter(
              child: SizedBox(
                height: 56,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  itemCount: _types.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    final type = _types[i];
                    final selected =
                        _selectedType == type['key'] as String;
                    return GestureDetector(
                      onTap: () {
                        setState(() => _selectedType = type['key'] as String);
                        _loadRides();
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: selected
                              ? AppTheme.primary
                              : AppTheme.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: selected
                                ? AppTheme.primary
                                : AppTheme.divider,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              type['icon'] as IconData,
                              size: 14,
                              color: selected
                                  ? Colors.white
                                  : AppTheme.textSecondary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              type['label'] as String,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: selected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                                color: selected
                                    ? Colors.white
                                    : AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            // ─── Rides list ───────────────────────────────────────────────
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, 20, 20, 8),
                child: Text('Available Rides',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary)),
              ),
            ),

            ridesState.when(
              data: (rides) {
                if (rides.isEmpty) {
                  return const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: Column(
                        children: [
                          Icon(Icons.directions_car_outlined,
                              size: 48, color: AppTheme.textHint),
                          SizedBox(height: 12),
                          Text('No rides available',
                              style: TextStyle(color: AppTheme.textSecondary)),
                          SizedBox(height: 4),
                          Text('Be the first to post a ride!',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textHint)),
                        ],
                      ),
                    ),
                  );
                }
                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) => RideCard(
                        ride: rides[i],
                        onTap: () =>
                            context.push('/ride/${rides[i].id}'),
                      ),
                      childCount: rides.length,
                    ),
                  ),
                );
              },
              loading: () => const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
              error: (e, _) => SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(e.toString(),
                      style: const TextStyle(color: AppTheme.error)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
