import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../models/ride_model.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/feature_hint.dart';

final myRidesProvider = FutureProvider<List<RideModel>>((ref) async {
  final res = await DioClient.instance.get(ApiConstants.myRides);
  return (res.data as List)
      .map((e) => RideModel.fromJson(e as Map<String, dynamic>))
      .toList();
});

final pendingPerRideProvider = FutureProvider<Map<String, int>>((ref) async {
  try {
    final res = await DioClient.instance.get(ApiConstants.pendingPerRide);
    return (res.data as Map<String, dynamic>).map(
      (k, v) => MapEntry(k, (v as num).toInt()),
    );
  } catch (_) {
    return {};
  }
});

class MyRidesScreen extends ConsumerWidget {
  const MyRidesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(myRidesProvider);
    final pendingMap = ref.watch(pendingPerRideProvider).valueOrNull ?? {};

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(myRidesProvider);
          ref.invalidate(pendingPerRideProvider);
          await Future.wait([
            ref.read(myRidesProvider.future),
            ref.read(pendingPerRideProvider.future),
          ]);
        },
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
                    colors: [AppTheme.primary, AppTheme.tertiary],
                  ),
                  borderRadius:
                      BorderRadius.vertical(bottom: Radius.circular(28)),
                ),
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                    child: Row(
                      children: [
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'My Rides',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5,
                              ),
                            ),
                            Text(
                              'Rides you posted',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        SizedBox(
                          height: 42,
                          child: ElevatedButton.icon(
                            onPressed: () => context.push('/post-ride'),
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text('Post Ride'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: AppTheme.primary,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // ─── Feature hint ────────────────────────────────────────────────
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.only(top: 4),
                child: FeatureHint(
                  featureKey: 'my_rides',
                  icon: Icons.directions_car_outlined,
                  title: 'Your Posted Rides',
                  description:
                      'Rides you\'ve posted appear here. Tap a ride to manage it, view booking requests, and start or end the trip.',
                  color: AppTheme.primary,
                ),
              ),
            ),

            // ─── Content ─────────────────────────────────────────────────────
            ...state.when(
              data: (rides) {
                if (rides.isEmpty) {
                  return [
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: AppTheme.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: const Icon(Icons.directions_car_outlined,
                                  size: 40, color: AppTheme.primary),
                            ),
                            const SizedBox(height: 16),
                            const Text('No rides posted yet',
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.textPrimary)),
                            const SizedBox(height: 6),
                            const Text('Post a ride and start sharing',
                                style: TextStyle(
                                    fontSize: 13,
                                    color: AppTheme.textSecondary)),
                            const SizedBox(height: 24),
                            SizedBox(
                              height: 48,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [AppTheme.primary, AppTheme.tertiary],
                                  ),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: ElevatedButton.icon(
                                  onPressed: () => context.push('/post-ride'),
                                  icon: const Icon(Icons.add,
                                      color: Colors.white, size: 18),
                                  label: const Text('Post a Ride',
                                      style: TextStyle(color: Colors.white)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 24),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(14)),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ];
                }

                final sorted = [...rides]..sort((a, b) {
                    final pa = pendingMap[a.id] ?? 0;
                    final pb = pendingMap[b.id] ?? 0;
                    return pb.compareTo(pa);
                  });

                return [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                    sliver: SliverList.separated(
                      itemCount: sorted.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (_, i) => _MyRideCard(
                        ride: sorted[i],
                        pendingCount: pendingMap[sorted[i].id] ?? 0,
                      ),
                    ),
                  ),
                ];
              },
              loading: () => [
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: CircularProgressIndicator()),
                ),
              ],
              error: (e, _) => [
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Text(e.toString(),
                        style: const TextStyle(color: AppTheme.error)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MyRideCard extends ConsumerStatefulWidget {
  final RideModel ride;
  final int pendingCount;
  const _MyRideCard({required this.ride, required this.pendingCount});

  @override
  ConsumerState<_MyRideCard> createState() => _MyRideCardState();
}

class _MyRideCardState extends ConsumerState<_MyRideCard> {
  bool _isCancelling = false;

  Color _typeColor(String type) {
    switch (type) {
      case 'OFFICE':
        return AppTheme.officeColor;
      case 'UNIVERSITY':
        return AppTheme.universityColor;
      default:
        return AppTheme.discussionColor;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'ACTIVE':
        return AppTheme.secondary;
      case 'COMPLETED':
        return AppTheme.primary;
      case 'CANCELLED':
        return AppTheme.error;
      default:
        return AppTheme.warning;
    }
  }

  Future<void> _cancel() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Cancel Ride'),
        content: const Text('Are you sure you want to cancel this ride?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('No')),
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Yes, Cancel',
                  style: TextStyle(color: AppTheme.error))),
        ],
      ),
    );
    if (confirm != true) return;
    if (!mounted) return;
    setState(() => _isCancelling = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await DioClient.instance
          .patch('${ApiConstants.rides}/${widget.ride.id}/cancel');
      if (mounted) {
        ref.invalidate(myRidesProvider);
        ref.invalidate(pendingPerRideProvider);
        messenger.showSnackBar(const SnackBar(
            content: Text('Ride cancelled'),
            backgroundColor: Colors.grey));
      }
    } catch (e) {
      messenger.showSnackBar(SnackBar(
          content: Text(extractApiError(e)),
          backgroundColor: AppTheme.error));
    } finally {
      if (mounted) setState(() => _isCancelling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ride = widget.ride;
    final typeColor = _typeColor(ride.rideType);
    final statusColor = _statusColor(ride.status);

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppTheme.cardShadow,
      ),
      child: InkWell(
        onTap: () => context.push('/ride/${ride.id}'),
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Badges row
              Row(
                children: [
                  _Badge(label: ride.rideType, color: typeColor),
                  if (widget.pendingCount > 0) ...[
                    const SizedBox(width: 8),
                    _Badge(
                      label:
                          '${widget.pendingCount} new request${widget.pendingCount > 1 ? 's' : ''}',
                      color: AppTheme.warning,
                      icon: Icons.notifications_active,
                    ),
                  ],
                  const Spacer(),
                  _Badge(label: ride.status, color: statusColor),
                ],
              ),
              const SizedBox(height: 12),

              // Route
              Row(
                children: [
                  const Icon(Icons.radio_button_checked,
                      size: 14, color: AppTheme.primary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      ride.originAddress,
                      style: const TextStyle(
                          fontSize: 13, color: AppTheme.textSecondary),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(left: 7),
                child: Container(
                    width: 1, height: 12, color: AppTheme.divider),
              ),
              Row(
                children: [
                  const Icon(Icons.location_on,
                      size: 14, color: AppTheme.error),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      ride.destinationAddress,
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 10),

              // Meta row
              Row(
                children: [
                  const Icon(Icons.schedule,
                      size: 13, color: AppTheme.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat('EEE, MMM d · h:mm a')
                        .format(ride.departureTime),
                    style: const TextStyle(
                        fontSize: 12, color: AppTheme.textSecondary),
                  ),
                  const Spacer(),
                  const Icon(Icons.event_seat,
                      size: 13, color: AppTheme.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    '${ride.availableSeats}/${ride.totalSeats} seats',
                    style: const TextStyle(
                        fontSize: 12, color: AppTheme.textSecondary),
                  ),
                ],
              ),

              if (ride.status == 'ACTIVE') ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => context.push(
                            '/active-ride/${ride.id}',
                            extra: {'isDriver': true}),
                        icon: const Icon(Icons.map_outlined, size: 14),
                        label: const Text('Live Map',
                            style: TextStyle(fontSize: 13)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.primary,
                          side: const BorderSide(color: AppTheme.primary),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          padding:
                              const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isCancelling ? null : _cancel,
                        icon: _isCancelling
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2))
                            : const Icon(Icons.cancel_outlined, size: 14),
                        label: const Text('Cancel',
                            style: TextStyle(fontSize: 13)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.error,
                          side: const BorderSide(color: AppTheme.error),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          padding:
                              const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;
  const _Badge({required this.label, required this.color, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
                color: color, fontSize: 11, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

