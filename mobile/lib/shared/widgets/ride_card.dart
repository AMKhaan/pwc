import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../features/rides/models/ride_model.dart';

class RideCard extends StatelessWidget {
  final RideModel ride;
  final VoidCallback onTap;

  const RideCard({super.key, required this.ride, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  _RideTypeBadge(type: ride.rideType),
                  const Spacer(),
                  Text(
                    'PKR ${ride.pricePerSeat.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primary,
                    ),
                  ),
                  const Text(
                    ' / seat',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Route
              _RouteRow(
                origin: ride.originAddress,
                destination: ride.destinationAddress,
              ),
              const SizedBox(height: 12),

              // Footer
              Row(
                children: [
                  const Icon(Icons.schedule, size: 14, color: AppTheme.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat('EEE, MMM d · h:mm a').format(ride.departureTime),
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const Spacer(),
                  const Icon(Icons.airline_seat_recline_normal,
                      size: 14, color: AppTheme.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    '${ride.availableSeats} left',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),

              // Discussion topic (if applicable)
              if (ride.rideType == 'DISCUSSION' && ride.discussionTopic != null) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.discussionColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.chat_bubble_outline,
                          size: 13, color: AppTheme.discussionColor),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          ride.discussionTopic!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.discussionColor,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _RideTypeBadge extends StatelessWidget {
  final String type;
  const _RideTypeBadge({required this.type});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    IconData icon;

    switch (type) {
      case 'OFFICE':
        color = AppTheme.officeColor;
        label = 'Office';
        icon = Icons.business;
        break;
      case 'UNIVERSITY':
        color = AppTheme.universityColor;
        label = 'Campus';
        icon = Icons.school;
        break;
      default:
        color = AppTheme.discussionColor;
        label = 'DriveDesk';
        icon = Icons.record_voice_over;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 11, color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _RouteRow extends StatelessWidget {
  final String origin;
  final String destination;
  const _RouteRow({required this.origin, required this.destination});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            const Icon(Icons.circle, size: 10, color: AppTheme.primary),
            Container(width: 2, height: 28, color: AppTheme.divider),
            const Icon(Icons.location_on, size: 14, color: AppTheme.error),
          ],
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(origin,
                  style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary),
                  overflow: TextOverflow.ellipsis),
              const SizedBox(height: 16),
              Text(destination,
                  style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary),
                  overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ],
    );
  }
}
