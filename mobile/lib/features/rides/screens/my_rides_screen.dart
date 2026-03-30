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
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              child: Row(
                children: [
                  const Text('My Rides',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary)),
                  const Spacer(),
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
            const FeatureHint(
              featureKey: 'my_rides',
              icon: Icons.directions_car_outlined,
              title: 'Your Posted Rides',
              description:
                  'Rides you\'ve posted appear here. Tap a ride to manage it, view booking requests, and start or end the trip.',
              color: AppTheme.primary,
            ),
            Expanded(
              child: state.when(
                data: (rides) {
                  if (rides.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.directions_car_outlined,
                              size: 56, color: AppTheme.textHint),
                          const SizedBox(height: 16),
                          const Text('No rides posted yet',
                              style: TextStyle(
                                  fontSize: 16,
                                  color: AppTheme.textSecondary)),
                          const SizedBox(height: 8),
                          const Text('Post a ride and start sharing',
                              style: TextStyle(
                                  fontSize: 13, color: AppTheme.textHint)),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: () => context.push('/post-ride'),
                            icon: const Icon(Icons.add),
                            label: const Text('Post a Ride'),
                            style: ElevatedButton.styleFrom(
                                minimumSize: const Size(160, 44)),
                          ),
                        ],
                      ),
                    );
                  }

                  // Sort: rides with pending requests first
                  final sorted = [...rides]..sort((a, b) {
                      final pa = pendingMap[a.id] ?? 0;
                      final pb = pendingMap[b.id] ?? 0;
                      return pb.compareTo(pa);
                    });

                  return RefreshIndicator(
                    onRefresh: () async {
                      ref.invalidate(myRidesProvider);
                      ref.invalidate(pendingPerRideProvider);
                    },
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      itemCount: sorted.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: 10),
                      itemBuilder: (_, i) => _MyRideCard(
                        ride: sorted[i],
                        pendingCount: pendingMap[sorted[i].id] ?? 0,
                      ),
                    ),
                  );
                },
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(
                    child: Text(e.toString(),
                        style:
                            const TextStyle(color: AppTheme.error))),
              ),
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

    return Card(
      child: InkWell(
        onTap: () => context.push('/ride/${ride.id}'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: typeColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(ride.rideType,
                        style: TextStyle(
                            color: typeColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w600)),
                  ),
                  if (widget.pendingCount > 0) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade600,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.notifications_active,
                              size: 11, color: Colors.white),
                          const SizedBox(width: 4),
                          Text(
                            '${widget.pendingCount} new request${widget.pendingCount > 1 ? 's' : ''}',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(ride.status,
                        style: TextStyle(
                            color: statusColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                '${ride.originAddress} → ${ride.destinationAddress}',
                style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: AppTheme.textPrimary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
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
                          side:
                              const BorderSide(color: AppTheme.primary),
                          padding:
                              const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed:
                            _isCancelling ? null : _cancel,
                        icon: _isCancelling
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2))
                            : const Icon(Icons.cancel_outlined,
                                size: 14),
                        label: const Text('Cancel',
                            style: TextStyle(fontSize: 13)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.error,
                          side:
                              const BorderSide(color: AppTheme.error),
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
