import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../models/booking_model.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/feature_hint.dart';
import '../../../core/router/app_router.dart';

final myBookingsProvider = FutureProvider<List<BookingModel>>((ref) async {
  final res = await DioClient.instance.get(ApiConstants.myBookings);
  return (res.data as List)
      .map((e) => BookingModel.fromJson(e as Map<String, dynamic>))
      .toList();
});

class MyBookingsScreen extends ConsumerStatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  ConsumerState<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends ConsumerState<MyBookingsScreen> {
  @override
  void initState() {
    super.initState();
    _markRead();
  }

  Future<void> _markRead() async {
    try {
      await DioClient.instance.patch(ApiConstants.markNotificationsRead);
      ref.invalidate(unreadNotificationsCountProvider);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(myBookingsProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: CustomScrollView(
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
                            'My Bookings',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                            ),
                          ),
                          Text(
                            'Rides you booked',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Consumer(builder: (context, ref, _) {
                        final count = ref.watch(unreadNotificationsCountProvider).valueOrNull ?? 0;
                        return GestureDetector(
                          onTap: () => context.push('/notifications'),
                          child: Badge(
                            isLabelVisible: count > 0,
                            label: Text(count > 9 ? '9+' : '$count'),
                            child: Container(
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(Icons.notifications_outlined,
                                  color: Colors.white, size: 22),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ─── Feature hint ──────────────────────────────────────────────
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.only(top: 4),
              child: FeatureHint(
                featureKey: 'bookings',
                icon: Icons.bookmark_outline,
                title: 'Your Booked Rides',
                description:
                    'Rides you\'ve booked appear here. Track your booking status and get in touch with the driver before your trip.',
                color: AppTheme.tertiary,
              ),
            ),
          ),

          // ─── Content ────────────────────────────────────────────────────
          SliverFillRemaining(
            child: state.when(
              data: (bookings) {
                if (bookings.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: AppTheme.tertiary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: const Icon(Icons.bookmark_border,
                              size: 40, color: AppTheme.tertiary),
                        ),
                        const SizedBox(height: 16),
                        const Text('No bookings yet',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimary)),
                        const SizedBox(height: 6),
                        const Text('Browse rides and book your first trip!',
                            style: TextStyle(
                                fontSize: 13,
                                color: AppTheme.textSecondary)),
                        const SizedBox(height: 24),
                        SizedBox(
                          height: 48,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: [
                                AppTheme.tertiary,
                                Color(0xFF4338CA)
                              ]),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: ElevatedButton.icon(
                              onPressed: () => context.go('/home'),
                              icon: const Icon(Icons.search,
                                  color: Colors.white, size: 18),
                              label: const Text('Find a Ride',
                                  style: TextStyle(color: Colors.white)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 24),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14)),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () => ref.refresh(myBookingsProvider.future),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                    itemCount: bookings.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, i) =>
                        _BookingCard(booking: bookings[i]),
                  ),
                );
              },
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                  child: Text(e.toString(),
                      style: const TextStyle(color: AppTheme.error))),
            ),
          ),
        ],
      ),
    );
  }
}

class _BookingCard extends ConsumerStatefulWidget {
  final BookingModel booking;
  const _BookingCard({required this.booking});

  @override
  ConsumerState<_BookingCard> createState() => _BookingCardState();
}

class _BookingCardState extends ConsumerState<_BookingCard> {
  bool _isCancelling = false;

  Color _statusColor(String status) {
    switch (status) {
      case 'CONFIRMED':
        return AppTheme.secondary;
      case 'PENDING':
        return AppTheme.warning;
      case 'COMPLETED':
        return AppTheme.primary;
      case 'CANCELLED':
        return AppTheme.error;
      default:
        return AppTheme.textSecondary;
    }
  }

  Future<void> _cancel() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Cancel Booking'),
        content:
            const Text('Are you sure you want to cancel this booking?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('No')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Yes, Cancel',
                  style: TextStyle(color: AppTheme.error))),
        ],
      ),
    );
    if (confirm != true || !mounted) return;

    setState(() => _isCancelling = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await DioClient.instance.patch(
          '${ApiConstants.bookings}/${widget.booking.id}/cancel');
      if (mounted) {
        ref.invalidate(myBookingsProvider);
        messenger.showSnackBar(const SnackBar(
            content: Text('Booking cancelled'),
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
    final booking = widget.booking;
    final ride = booking.ride;
    final statusColor = _statusColor(booking.status);
    final canCancel =
        booking.status == 'PENDING' || booking.status == 'CONFIRMED';

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status badge
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    booking.status,
                    style: TextStyle(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w700),
                  ),
                ),
                const Spacer(),
                Text(
                  'PKR ${booking.totalAmount.toStringAsFixed(0)}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppTheme.tertiary,
                      fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Route
            Row(
              children: [
                const Icon(Icons.radio_button_checked,
                    size: 14, color: AppTheme.tertiary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    ride?['originAddress'] as String? ??
                        'Ride #${booking.rideId.substring(0, 8)}',
                    style: const TextStyle(
                        fontSize: 13, color: AppTheme.textSecondary),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(left: 7),
              child:
                  Container(width: 1, height: 10, color: AppTheme.divider),
            ),
            Row(
              children: [
                const Icon(Icons.location_on,
                    size: 14, color: AppTheme.error),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    ride?['destinationAddress'] as String? ?? '—',
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 10),

            Row(
              children: [
                const Icon(Icons.schedule,
                    size: 13, color: AppTheme.textSecondary),
                const SizedBox(width: 4),
                Text(
                  ride?['departureTime'] != null
                      ? DateFormat('EEE, MMM d · h:mm a').format(
                          DateTime.parse(ride!['departureTime'] as String))
                      : '—',
                  style: const TextStyle(
                      fontSize: 12, color: AppTheme.textSecondary),
                ),
              ],
            ),

            if (booking.isConfirmed || canCancel) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  if (booking.isConfirmed)
                    Expanded(
                      child: SizedBox(
                        height: 42,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [
                              AppTheme.tertiary,
                              Color(0xFF4338CA)
                            ]),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ElevatedButton.icon(
                            onPressed: () => context.push(
                              '/active-ride/${booking.rideId}',
                              extra: {'isDriver': false},
                            ),
                            icon: const Icon(Icons.map_outlined,
                                size: 14, color: Colors.white),
                            label: const Text('Track Ride',
                                style: TextStyle(
                                    color: Colors.white, fontSize: 13)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ),
                    ),
                  if (booking.isConfirmed && canCancel)
                    const SizedBox(width: 10),
                  if (canCancel)
                    Expanded(
                      child: SizedBox(
                        height: 42,
                        child: OutlinedButton.icon(
                          onPressed:
                              _isCancelling ? null : _cancel,
                          icon: _isCancelling
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppTheme.error))
                              : const Icon(Icons.cancel_outlined,
                                  size: 14, color: AppTheme.error),
                          label: const Text('Cancel',
                              style: TextStyle(
                                  fontSize: 13, color: AppTheme.error)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.error,
                            side: const BorderSide(color: AppTheme.error),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
