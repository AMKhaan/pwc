import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../models/booking_model.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/feature_hint.dart';

final myBookingsProvider = FutureProvider<List<BookingModel>>((ref) async {
  final res = await DioClient.instance.get(ApiConstants.myBookings);
  return (res.data as List)
      .map((e) => BookingModel.fromJson(e as Map<String, dynamic>))
      .toList();
});

class MyBookingsScreen extends ConsumerWidget {
  const MyBookingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(myBookingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My Bookings')),
      body: Column(
        children: [
          const FeatureHint(
            featureKey: 'bookings',
            icon: Icons.bookmark_outline,
            title: 'Your Booked Rides',
            description:
                'Rides you\'ve booked appear here. Track your booking status and get in touch with the driver before your trip.',
            color: AppTheme.primary,
          ),
          Expanded(child: state.when(
        data: (bookings) {
          if (bookings.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.bookmark_border,
                      size: 48, color: AppTheme.textHint),
                  SizedBox(height: 12),
                  Text('No bookings yet',
                      style: TextStyle(color: AppTheme.textSecondary)),
                  SizedBox(height: 4),
                  Text('Browse rides and book your first trip!',
                      style:
                          TextStyle(fontSize: 12, color: AppTheme.textHint)),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () =>
                ref.refresh(myBookingsProvider.future),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: bookings.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
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
      )),
        ],
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  final BookingModel booking;
  const _BookingCard({required this.booking});

  @override
  Widget build(BuildContext context) {
    final ride = booking.ride;
    final statusColor = _statusColor(booking.status);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    ride != null
                        ? '${ride['originAddress']} → ${ride['destinationAddress']}'
                        : 'Ride #${booking.rideId.substring(0, 8)}',
                    style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: AppTheme.textPrimary),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    booking.status,
                    style: TextStyle(
                        color: statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
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
                const Spacer(),
                Text(
                  'PKR ${booking.totalAmount.toStringAsFixed(0)}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primary,
                      fontSize: 15),
                ),
              ],
            ),
            if (booking.isConfirmed) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => context.push(
                    '/active-ride/${booking.rideId}',
                    extra: {'isDriver': false},
                  ),
                  icon: const Icon(Icons.map_outlined, size: 16),
                  label: const Text('Track Ride'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primary,
                    side: const BorderSide(color: AppTheme.primary),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

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
}
