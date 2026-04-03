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

  Future<void> _loadRides() => ref.read(ridesProvider.notifier).searchRides(
        rideType: _selectedType == 'ALL' ? null : _selectedType,
      );

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final ridesState = ref.watch(ridesProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: RefreshIndicator(
        onRefresh: _loadRides,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
          // ─── Gradient header ────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppTheme.primary, Color(0xFF1E40AF)],
                ),
                borderRadius:
                    BorderRadius.vertical(bottom: Radius.circular(28)),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top row: greeting + avatar
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${_greeting()} 👋',
                                  style: TextStyle(
                                    color:
                                        Colors.white.withValues(alpha: 0.8),
                                    fontSize: 13,
                                  ),
                                ),
                                Text(
                                  user?.firstName ?? 'Welcome',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: () => context.go('/profile'),
                            child: CircleAvatar(
                              radius: 22,
                              backgroundColor:
                                  Colors.white.withValues(alpha: 0.2),
                              backgroundImage: user?.avatarUrl != null
                                  ? NetworkImage(user!.avatarUrl!)
                                  : null,
                              child: user?.avatarUrl == null
                                  ? Text(
                                      user != null
                                          ? '${user.firstName[0]}${user.lastName[0]}'
                                          : '?',
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold),
                                    )
                                  : null,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Search bar (tappable)
                      GestureDetector(
                        onTap: () => context.push('/search-rides'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x1A000000),
                                blurRadius: 12,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.search, color: AppTheme.textHint),
                              SizedBox(width: 10),
                              Text(
                                'Where are you going?',
                                style: TextStyle(
                                    color: AppTheme.textHint, fontSize: 14),
                              ),
                              Spacer(),
                              Icon(Icons.tune,
                                  color: AppTheme.primary, size: 18),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ─── Quick actions bento grid ─────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Quick Actions',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _QuickAction(
                        icon: Icons.search_rounded,
                        label: 'Find a Ride',
                        gradient: const [AppTheme.primary, Color(0xFF1E40AF)],
                        onTap: () => context.push('/search-rides'),
                      ),
                      const SizedBox(width: 12),
                      _QuickAction(
                        icon: Icons.add_circle_outline_rounded,
                        label: 'Post a Ride',
                        gradient: const [AppTheme.tertiary, Color(0xFF4338CA)],
                        onTap: () => context.push('/post-ride'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _QuickAction(
                        icon: Icons.bookmark_outline_rounded,
                        label: 'My Bookings',
                        gradient: const [AppTheme.tertiary, Color(0xFF4338CA)],
                        onTap: () => context.go('/bookings'),
                      ),
                      const SizedBox(width: 12),
                      _QuickAction(
                        icon: Icons.directions_car_rounded,
                        label: 'My Rides',
                        gradient: const [AppTheme.primary, Color(0xFF1E40AF)],
                        onTap: () => context.go('/my-rides'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // ─── Feature hint ─────────────────────────────────────────────────
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

          // ─── Ride type filter chips ───────────────────────────────────────
          SliverToBoxAdapter(
            child: SizedBox(
              height: 52,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                itemCount: _types.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final type = _types[i];
                  final selected = _selectedType == type['key'] as String;
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
                        color: selected ? AppTheme.primary : AppTheme.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color:
                              selected ? AppTheme.primary : AppTheme.divider,
                        ),
                        boxShadow: selected
                            ? [
                                BoxShadow(
                                  color:
                                      AppTheme.primary.withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                )
                              ]
                            : null,
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

          // ─── Section header ───────────────────────────────────────────────
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Text(
                'Available Rides',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary),
              ),
            ),
          ),

          // ─── Rides list ───────────────────────────────────────────────────
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
                            style:
                                TextStyle(color: AppTheme.textSecondary)),
                        SizedBox(height: 4),
                        Text('Be the first to post a ride!',
                            style: TextStyle(
                                fontSize: 12, color: AppTheme.textHint)),
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
                      onTap: () => context.push('/ride/${rides[i].id}'),
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

// ─── Quick action bento card ──────────────────────────────────────────────────

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final List<Color> gradient;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 80,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradient,
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: gradient[0].withValues(alpha: 0.35),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 0),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
