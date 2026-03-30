import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/ride_model.dart';
import '../../bookings/models/booking_model.dart';
import 'location_picker_screen.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/router/app_router.dart' show pendingRequestsCountProvider;
import '../../../shared/widgets/primary_button.dart';
import '../../auth/providers/auth_provider.dart';

final rideDetailProvider =
    FutureProvider.family<RideModel, String>((ref, rideId) async {
  final res = await DioClient.instance.get('${ApiConstants.rides}/$rideId');
  return RideModel.fromJson(res.data as Map<String, dynamic>);
});

final rideBookingsProvider =
    FutureProvider.family<List<BookingModel>, String>((ref, rideId) async {
  final res = await DioClient.instance
      .get('${ApiConstants.rideBookings}/$rideId');
  return (res.data as List)
      .map((e) => BookingModel.fromJson(e as Map<String, dynamic>))
      .toList();
});

class RideDetailScreen extends ConsumerWidget {
  final String rideId;
  const RideDetailScreen({super.key, required this.rideId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(rideDetailProvider(rideId));
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Ride Details')),
      body: state.when(
        data: (ride) {
          final isOwnRide = ride.driverId == currentUser?.id;
          final typeColor = _typeColor(ride.rideType);
          final typeName = _typeName(ride.rideType);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ─── Type badge ───────────────────────────────────────────
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: typeColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(_typeIcon(ride.rideType),
                              size: 14, color: typeColor),
                          const SizedBox(width: 6),
                          Text(typeName,
                              style: TextStyle(
                                  color: typeColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                    const Spacer(),
                    _StatusBadge(status: ride.status),
                  ],
                ),

                const SizedBox(height: 20),

                // ─── Route ────────────────────────────────────────────────
                _SectionCard(children: [
                  _RouteRow(
                      icon: Icons.radio_button_checked,
                      color: AppTheme.secondary,
                      label: 'From',
                      value: ride.originAddress),
                  Padding(
                    padding: const EdgeInsets.only(left: 20),
                    child: Column(
                      children: List.generate(
                          3,
                          (_) => Container(
                                width: 1,
                                height: 6,
                                color: AppTheme.divider,
                                margin:
                                    const EdgeInsets.symmetric(vertical: 2),
                              )),
                    ),
                  ),
                  _RouteRow(
                      icon: Icons.location_on,
                      color: AppTheme.error,
                      label: 'To',
                      value: ride.destinationAddress),
                ]),

                const SizedBox(height: 16),

                // ─── Details ─────────────────────────────────────────────
                _SectionCard(children: [
                  _DetailRow(
                    icon: Icons.schedule,
                    label: 'Departure',
                    value: DateFormat('EEE, MMM d · h:mm a')
                        .format(ride.departureTime),
                  ),
                  _DetailRow(
                    icon: Icons.event_seat,
                    label: 'Available Seats',
                    value: '${ride.availableSeats} of ${ride.totalSeats}',
                  ),
                  _DetailRow(
                    icon: Icons.payments_outlined,
                    label: 'Price per Seat',
                    value: ride.pricePerSeat > 0
                        ? 'PKR ${ride.pricePerSeat.toStringAsFixed(0)}'
                        : 'Shared equally',
                  ),
                  if (ride.distanceKm != null)
                    _DetailRow(
                      icon: Icons.route,
                      label: 'Distance',
                      value: '${ride.distanceKm!.toStringAsFixed(1)} km',
                    ),
                  if (ride.isRecurring)
                    const _DetailRow(
                      icon: Icons.repeat,
                      label: 'Recurring',
                      value: 'Daily ride',
                    ),
                ]),

                // ─── Discussion details ───────────────────────────────────
                if (ride.rideType == 'DISCUSSION' &&
                    ride.discussionTopic != null) ...[
                  const SizedBox(height: 16),
                  _SectionCard(children: [
                    _DetailRow(
                      icon: Icons.record_voice_over,
                      label: 'Topic',
                      value: ride.discussionTopic!,
                    ),
                    if (ride.hostExpertise != null)
                      _DetailRow(
                        icon: Icons.workspace_premium,
                        label: 'Expertise',
                        value: ride.hostExpertise!,
                      ),
                    if (ride.discussionFee != null && ride.discussionFee! > 0)
                      _DetailRow(
                        icon: Icons.monetization_on_outlined,
                        label: 'Discussion Fee',
                        value: 'PKR ${ride.discussionFee!.toStringAsFixed(0)}',
                      ),
                  ]),
                ],

                if (ride.notes != null && ride.notes!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _SectionCard(children: [
                    _DetailRow(
                      icon: Icons.notes,
                      label: 'Notes',
                      value: ride.notes!,
                    ),
                  ]),
                ],

                const SizedBox(height: 16),

                // ─── Driver card ──────────────────────────────────────────
                if (ride.driver != null)
                  _DriverCard(driver: ride.driver!),

                const SizedBox(height: 12),

                // ─── Vehicle card ─────────────────────────────────────────
                if (ride.vehicle != null)
                  _VehicleCard(vehicle: ride.vehicle!),

                const SizedBox(height: 28),

                // ─── Book button ──────────────────────────────────────────
                if (!isOwnRide && ride.status == 'ACTIVE' && ride.availableSeats > 0)
                  _BookButton(ride: ride),

                if (isOwnRide) ...[
                  OutlinedButton.icon(
                    onPressed: () => context.push(
                      '/active-ride/${ride.id}',
                      extra: {'isDriver': true},
                    ),
                    icon: const Icon(Icons.map_outlined),
                    label: const Text('Open Live Map'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      foregroundColor: AppTheme.primary,
                      side: const BorderSide(color: AppTheme.primary),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _RideBookingsSection(rideId: ride.id),
                ],

                if (!isOwnRide && ride.availableSeats == 0)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                        color: AppTheme.error.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10)),
                    child: const Text('No seats available',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppTheme.error)),
                  ),
              ],
            ),
          );
        },
        loading: () =>
            const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
            child: Text(e.toString(),
                style: const TextStyle(color: AppTheme.error))),
      ),
    );
  }

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

  IconData _typeIcon(String type) {
    switch (type) {
      case 'OFFICE':
        return Icons.business;
      case 'UNIVERSITY':
        return Icons.school;
      default:
        return Icons.record_voice_over;
    }
  }

  String _typeName(String type) {
    switch (type) {
      case 'OFFICE':
        return 'CommuteShare';
      case 'UNIVERSITY':
        return 'CampusRide';
      default:
        return 'DriveDesk';
    }
  }
}

// ─── Driver card ─────────────────────────────────────────────────────────────

class _DriverCard extends StatelessWidget {
  final Map<String, dynamic> driver;
  const _DriverCard({required this.driver});

  @override
  Widget build(BuildContext context) {
    final firstName = driver['firstName'] as String? ?? '';
    final lastName = driver['lastName'] as String? ?? '';
    final initials = '${firstName.isNotEmpty ? firstName[0] : ''}${lastName.isNotEmpty ? lastName[0] : ''}'.toUpperCase();
    final avatarUrl = driver['avatarUrl'] as String?;
    final isVerified = driver['verificationStatus'] == 'VERIFIED';
    final trustScore = double.tryParse(driver['trustScore']?.toString() ?? '0') ?? 0;
    final userType = driver['userType'] as String? ?? '';

    return GestureDetector(
      onTap: () => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _DriverProfileSheet(driver: driver),
      ),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Avatar
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: AppTheme.primary.withOpacity(0.1),
                    backgroundImage: avatarUrl != null
                        ? CachedNetworkImageProvider(avatarUrl)
                        : null,
                    child: avatarUrl == null
                        ? Text(initials,
                            style: const TextStyle(
                                color: AppTheme.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 16))
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text('$firstName $lastName',
                                style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textPrimary)),
                            if (isVerified) ...[
                              const SizedBox(width: 6),
                              const Icon(Icons.verified,
                                  color: AppTheme.secondary, size: 16),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          userType == 'PROFESSIONAL' ? 'Professional' : 'Student',
                          style: const TextStyle(
                              fontSize: 12, color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  // Trust score
                  Column(
                    children: [
                      Text(
                        trustScore.toStringAsFixed(0),
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primary),
                      ),
                      const Text('trust',
                          style: TextStyle(
                              fontSize: 10, color: AppTheme.textHint)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text('View driver profile',
                      style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.primary.withOpacity(0.8),
                          fontWeight: FontWeight.w500)),
                  const SizedBox(width: 4),
                  Icon(Icons.arrow_forward_ios,
                      size: 11, color: AppTheme.primary.withOpacity(0.8)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Vehicle card ─────────────────────────────────────────────────────────────

class _VehicleCard extends StatelessWidget {
  final Map<String, dynamic> vehicle;
  const _VehicleCard({required this.vehicle});

  @override
  Widget build(BuildContext context) {
    final make = vehicle['make'] as String? ?? '';
    final model = vehicle['model'] as String? ?? '';
    final year = vehicle['year']?.toString() ?? '';
    final color = vehicle['color'] as String? ?? '';
    final plate = vehicle['licensePlate'] as String? ?? '';
    final fuelType = vehicle['fuelType'] as String? ?? '';
    final vehicleType = vehicle['vehicleType'] as String? ?? 'CAR';
    final seats = vehicle['totalSeats']?.toString() ?? '';
    final engineCC = vehicle['engineCC']?.toString();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    vehicleType == 'BIKE'
                        ? Icons.two_wheeler_outlined
                        : Icons.directions_car_outlined,
                    color: AppTheme.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('$make $model',
                          style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary)),
                      Text(year,
                          style: const TextStyle(
                              fontSize: 12, color: AppTheme.textSecondary)),
                    ],
                  ),
                ),
                // Color chip
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.divider),
                  ),
                  child: Text(color,
                      style: const TextStyle(
                          fontSize: 12, color: AppTheme.textSecondary)),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 12),
            // Detail rows
            Wrap(
              spacing: 20,
              runSpacing: 8,
              children: [
                _VehicleChip(
                    icon: Icons.confirmation_number_outlined, label: plate),
                _VehicleChip(
                    icon: Icons.local_gas_station_outlined,
                    label: _fuelLabel(fuelType)),
                _VehicleChip(
                    icon: Icons.event_seat_outlined, label: '$seats seats'),
                if (engineCC != null && engineCC != 'null')
                  _VehicleChip(
                      icon: Icons.speed_outlined, label: '${engineCC}cc'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _fuelLabel(String fuel) {
    switch (fuel) {
      case 'CNG':
        return 'CNG';
      case 'ELECTRIC':
        return 'Electric';
      case 'HYBRID':
        return 'Hybrid';
      case 'DIESEL':
        return 'Diesel';
      default:
        return 'Petrol';
    }
  }
}

class _VehicleChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _VehicleChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppTheme.textSecondary),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(
                fontSize: 12, color: AppTheme.textSecondary)),
      ],
    );
  }
}

// ─── Driver profile bottom sheet ─────────────────────────────────────────────

class _DriverProfileSheet extends StatelessWidget {
  final Map<String, dynamic> driver;
  const _DriverProfileSheet({required this.driver});

  @override
  Widget build(BuildContext context) {
    final firstName = driver['firstName'] as String? ?? '';
    final lastName = driver['lastName'] as String? ?? '';
    final initials = '${firstName.isNotEmpty ? firstName[0] : ''}${lastName.isNotEmpty ? lastName[0] : ''}'.toUpperCase();
    final avatarUrl = driver['avatarUrl'] as String?;
    final isVerified = driver['verificationStatus'] == 'VERIFIED';
    final trustScore = double.tryParse(driver['trustScore']?.toString() ?? '0') ?? 0;
    final userType = driver['userType'] as String? ?? '';
    final isProfessional = userType == 'PROFESSIONAL';
    final createdAt = driver['createdAt'] as String?;
    final memberSince = createdAt != null
        ? DateFormat('MMM yyyy').format(DateTime.parse(createdAt))
        : null;

    // Professional fields
    final officeName = driver['officeName'] as String?;
    final jobTitle = driver['jobTitle'] as String?;
    final linkedinUrl = driver['linkedinUrl'] as String?;
    final officeLinkedinUrl = driver['officeLinkedinUrl'] as String?;

    // Student fields
    final universityName = driver['universityName'] as String?;
    final degreeDesignation = driver['degreeDesignation'] as String?;
    final staffType = driver['staffType'] as String?;

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
          children: [
            // Handle bar
            Center(
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.textHint.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Avatar + name
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: AppTheme.primary.withOpacity(0.1),
                    backgroundImage: avatarUrl != null
                        ? CachedNetworkImageProvider(avatarUrl)
                        : null,
                    child: avatarUrl == null
                        ? Text(initials,
                            style: const TextStyle(
                                color: AppTheme.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 24))
                        : null,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('$firstName $lastName',
                          style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary)),
                      if (isVerified) ...[
                        const SizedBox(width: 6),
                        const Icon(Icons.verified,
                            color: AppTheme.secondary, size: 20),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Verified badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: isVerified
                          ? AppTheme.secondary.withOpacity(0.1)
                          : AppTheme.textHint.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isVerified
                          ? 'Verified ${isProfessional ? 'Professional' : 'Student'}'
                          : isProfessional
                              ? 'Professional'
                              : 'Student',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isVerified
                              ? AppTheme.secondary
                              : AppTheme.textSecondary),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Stats row
            Row(
              children: [
                Expanded(
                  child: _StatBox(
                    value: trustScore.toStringAsFixed(0),
                    label: 'Trust Score',
                    icon: Icons.star_outline,
                  ),
                ),
                const SizedBox(width: 12),
                if (memberSince != null)
                  Expanded(
                    child: _StatBox(
                      value: memberSince,
                      label: 'Member Since',
                      icon: Icons.calendar_today_outlined,
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 20),

            // Professional info
            if (isProfessional) ...[
              if (officeName != null || jobTitle != null) ...[
                _SheetSectionHeader(label: 'Work'),
                const SizedBox(height: 8),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    child: Column(
                      children: [
                        if (jobTitle != null)
                          _ProfileInfoRow(
                              icon: Icons.work_outline,
                              label: 'Job Title',
                              value: jobTitle),
                        if (officeName != null)
                          _ProfileInfoRow(
                              icon: Icons.business_outlined,
                              label: 'Company',
                              value: officeName),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              if (linkedinUrl != null || officeLinkedinUrl != null) ...[
                _SheetSectionHeader(label: 'LinkedIn'),
                const SizedBox(height: 8),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    child: Column(
                      children: [
                        if (linkedinUrl != null)
                          _ProfileInfoRow(
                              icon: Icons.person_outline,
                              label: 'Personal',
                              value: linkedinUrl),
                        if (officeLinkedinUrl != null)
                          _ProfileInfoRow(
                              icon: Icons.business_outlined,
                              label: 'Company',
                              value: officeLinkedinUrl),
                      ],
                    ),
                  ),
                ),
              ],
            ],

            // Student info
            if (!isProfessional) ...[
              if (universityName != null || degreeDesignation != null) ...[
                _SheetSectionHeader(label: 'Education'),
                const SizedBox(height: 8),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    child: Column(
                      children: [
                        if (universityName != null)
                          _ProfileInfoRow(
                              icon: Icons.school_outlined,
                              label: 'University',
                              value: universityName),
                        if (degreeDesignation != null)
                          _ProfileInfoRow(
                              icon: Icons.menu_book_outlined,
                              label: 'Degree',
                              value: degreeDesignation),
                        if (staffType != null)
                          _ProfileInfoRow(
                              icon: Icons.badge_outlined,
                              label: 'Role',
                              value: staffType == 'STAFF' ? 'Staff' : 'Student'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              if (linkedinUrl != null) ...[
                _SheetSectionHeader(label: 'LinkedIn'),
                const SizedBox(height: 8),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    child: _ProfileInfoRow(
                        icon: Icons.person_outline,
                        label: 'Profile',
                        value: linkedinUrl),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  const _StatBox(
      {required this.value, required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primary.withOpacity(0.12)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 18, color: AppTheme.primary),
          const SizedBox(height: 6),
          Text(value,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary)),
          Text(label,
              style: const TextStyle(
                  fontSize: 11, color: AppTheme.textSecondary)),
        ],
      ),
    );
  }
}

class _SheetSectionHeader extends StatelessWidget {
  final String label;
  const _SheetSectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppTheme.textHint,
          letterSpacing: 0.8),
    );
  }
}

class _ProfileInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _ProfileInfoRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppTheme.textSecondary),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 11, color: AppTheme.textHint)),
              const SizedBox(height: 2),
              Text(value,
                  style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Book button — opens pickup picker then confirmation sheet ────────────────

class _BookButton extends ConsumerWidget {
  final RideModel ride;
  const _BookButton({required this.ride});

  void _showVerificationRequired(BuildContext context, bool isUnderReview) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(isUnderReview ? 'Profile Under Review' : 'Complete Your Profile'),
        content: Text(
          isUnderReview
              ? 'Your profile is being reviewed by our team. You\'ll be able to book rides once approved (within 24 hours).'
              : 'You need to complete your profile verification before booking rides.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Later'),
          ),
          if (!isUnderReview)
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                context.push('/profile/complete');
              },
              child: const Text('Complete Profile'),
            ),
        ],
      ),
    );
  }

  Future<void> _startBooking(BuildContext context, WidgetRef ref) async {
    final user = ref.read(currentUserProvider);
    if (user != null && !user.isVerified) {
      _showVerificationRequired(context, user.hasSubmittedProfile);
      return;
    }

    // Step 1: pick up location
    final pickup = await Navigator.push<LocationResult>(
      context,
      MaterialPageRoute(
        builder: (_) => const LocationPickerScreen(title: 'Your Pickup Point'),
        fullscreenDialog: true,
      ),
    );
    if (pickup == null || !context.mounted) return;

    // Step 2: confirm sheet
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _BookingConfirmSheet(ride: ride, pickup: pickup),
    );
    if (confirmed != true || !context.mounted) return;

    // Step 3: submit
    await _submitBooking(context, pickup);
  }

  Future<void> _submitBooking(
      BuildContext context, LocationResult pickup) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await DioClient.instance.post(ApiConstants.bookings, data: {
        'rideId': ride.id,
        'pickupAddress': pickup.address,
        'pickupLat': pickup.lat,
        'pickupLng': pickup.lng,
      });
      messenger.showSnackBar(const SnackBar(
        content: Text('Booking request sent! Waiting for driver to confirm.'),
        backgroundColor: AppTheme.secondary,
        duration: Duration(seconds: 3),
      ));
      if (context.mounted) context.pop();
    } catch (e) {
      messenger.showSnackBar(SnackBar(
        content: Text(extractApiError(e)),
        backgroundColor: AppTheme.error,
      ));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PrimaryButton(
      label: 'Request to Book',
      onPressed: () => _startBooking(context, ref),
      icon: Icons.bookmark_add_outlined,
    );
  }
}

// ─── Booking confirmation bottom sheet ───────────────────────────────────────

class _BookingConfirmSheet extends StatefulWidget {
  final RideModel ride;
  final LocationResult pickup;
  const _BookingConfirmSheet({required this.ride, required this.pickup});

  @override
  State<_BookingConfirmSheet> createState() => _BookingConfirmSheetState();
}

class _BookingConfirmSheetState extends State<_BookingConfirmSheet> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final ride = widget.ride;
    final pickup = widget.pickup;
    final price = ride.pricePerSeat > 0
        ? 'PKR ${ride.pricePerSeat.toStringAsFixed(0)}'
        : 'Shared equally';

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(
          20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          const Text('Confirm Booking',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary)),
          const SizedBox(height: 20),

          // Route
          _SheetRow(
            icon: Icons.route_outlined,
            iconColor: AppTheme.primary,
            label: 'Route',
            value:
                '${ride.originAddress} → ${ride.destinationAddress}',
          ),
          const SizedBox(height: 14),

          // Pickup
          _SheetRow(
            icon: Icons.my_location,
            iconColor: AppTheme.secondary,
            label: 'Your pickup',
            value: pickup.address,
          ),
          const SizedBox(height: 14),

          // Price
          _SheetRow(
            icon: Icons.payments_outlined,
            iconColor: AppTheme.textSecondary,
            label: 'Price per seat',
            value: price,
          ),
          const SizedBox(height: 28),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading
                  ? null
                  : () {
                      setState(() => _isLoading = true);
                      Navigator.pop(context, true);
                    },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text('Confirm & Send Request',
                      style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel',
                  style: TextStyle(color: AppTheme.textSecondary)),
            ),
          ),
        ],
      ),
    );
  }
}

class _SheetRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  const _SheetRow(
      {required this.icon,
      required this.iconColor,
      required this.label,
      required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: iconColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 11, color: AppTheme.textHint)),
              const SizedBox(height: 2),
              Text(value,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textPrimary)),
            ],
          ),
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  final List<Widget> children;
  const _SectionCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children),
      ),
    );
  }
}

class _RouteRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;

  const _RouteRow(
      {required this.icon,
      required this.color,
      required this.label,
      required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 11, color: AppTheme.textHint)),
              Text(value,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textPrimary)),
            ],
          ),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppTheme.textSecondary),
          const SizedBox(width: 10),
          Text('$label: ',
              style: const TextStyle(
                  fontSize: 13, color: AppTheme.textSecondary)),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textPrimary)),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case 'ACTIVE':
        color = AppTheme.secondary;
        break;
      case 'COMPLETED':
        color = AppTheme.primary;
        break;
      case 'CANCELLED':
        color = AppTheme.error;
        break;
      default:
        color = AppTheme.warning;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12)),
      child: Text(status,
          style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600)),
    );
  }
}

// ─── Booking requests section (driver view) ───────────────────────────────────

class _RideBookingsSection extends ConsumerWidget {
  final String rideId;
  const _RideBookingsSection({required this.rideId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(rideBookingsProvider(rideId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Booking Requests',
          style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary),
        ),
        const SizedBox(height: 12),
        state.when(
          data: (bookings) {
            if (bookings.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.divider),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.inbox_outlined,
                        size: 36, color: AppTheme.textHint),
                    SizedBox(height: 8),
                    Text('No booking requests yet',
                        style: TextStyle(color: AppTheme.textSecondary)),
                  ],
                ),
              );
            }
            return Column(
              children: bookings
                  .map((b) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _BookingRequestCard(
                          booking: b,
                          onChanged: () =>
                              ref.invalidate(rideBookingsProvider(rideId)),
                        ),
                      ))
                  .toList(),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text(e.toString(),
              style: const TextStyle(color: AppTheme.error)),
        ),
      ],
    );
  }
}

class _BookingRequestCard extends ConsumerStatefulWidget {
  final BookingModel booking;
  final VoidCallback onChanged;
  const _BookingRequestCard(
      {required this.booking, required this.onChanged});

  @override
  ConsumerState<_BookingRequestCard> createState() =>
      _BookingRequestCardState();
}

class _BookingRequestCardState extends ConsumerState<_BookingRequestCard> {
  bool _isLoading = false;

  String get _riderName {
    final rider = widget.booking.rider;
    if (rider == null) return 'Passenger';
    final first = rider['firstName'] as String? ?? '';
    final last = rider['lastName'] as String? ?? '';
    return '$first $last'.trim().isEmpty ? 'Passenger' : '$first $last'.trim();
  }

  String get _riderInitials {
    final rider = widget.booking.rider;
    if (rider == null) return 'P';
    final first = (rider['firstName'] as String? ?? '');
    final last = (rider['lastName'] as String? ?? '');
    return '${first.isNotEmpty ? first[0] : ''}${last.isNotEmpty ? last[0] : ''}'
        .toUpperCase();
  }

  Future<void> _confirm() async {
    setState(() => _isLoading = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await DioClient.instance
          .patch('${ApiConstants.bookings}/${widget.booking.id}/confirm');
      ref.invalidate(pendingRequestsCountProvider);
      widget.onChanged();
      messenger.showSnackBar(const SnackBar(
          content: Text('Booking confirmed'),
          backgroundColor: AppTheme.secondary));
    } catch (e) {
      messenger.showSnackBar(SnackBar(
          content: Text(extractApiError(e)),
          backgroundColor: AppTheme.error));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _reject() async {
    setState(() => _isLoading = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await DioClient.instance
          .patch('${ApiConstants.bookings}/${widget.booking.id}/cancel');
      ref.invalidate(pendingRequestsCountProvider);
      widget.onChanged();
      messenger.showSnackBar(const SnackBar(
          content: Text('Booking rejected'),
          backgroundColor: Colors.grey));
    } catch (e) {
      messenger.showSnackBar(SnackBar(
          content: Text(extractApiError(e)),
          backgroundColor: AppTheme.error));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final booking = widget.booking;
    Color statusColor;
    switch (booking.status) {
      case 'CONFIRMED':
        statusColor = AppTheme.secondary;
        break;
      case 'CANCELLED':
        statusColor = AppTheme.error;
        break;
      case 'COMPLETED':
        statusColor = AppTheme.primary;
        break;
      default:
        statusColor = AppTheme.warning;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
                  child: Text(_riderInitials,
                      style: const TextStyle(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 13)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_riderName,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: AppTheme.textPrimary)),
                      Text(
                        '${booking.seatsBooked} seat${booking.seatsBooked > 1 ? 's' : ''} · PKR ${booking.totalAmount.toStringAsFixed(0)}',
                        style: const TextStyle(
                            fontSize: 12, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(booking.status,
                      style: TextStyle(
                          color: statusColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            if (booking.pickupAddress != null) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.my_location,
                      size: 13, color: AppTheme.secondary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Pickup: ${booking.pickupAddress}',
                      style: const TextStyle(
                          fontSize: 12, color: AppTheme.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
            if (booking.isPending) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : _confirm,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.secondary,
                        side: const BorderSide(color: AppTheme.secondary),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('Accept',
                              style: TextStyle(fontSize: 13)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : _reject,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.error,
                        side: const BorderSide(color: AppTheme.error),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      child: const Text('Reject',
                          style: TextStyle(fontSize: 13)),
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
