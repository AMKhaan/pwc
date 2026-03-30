import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../providers/rides_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/feature_hint.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/constants/api_constants.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/custom_text_field.dart';
import '../../auth/providers/auth_provider.dart';
import 'location_picker_screen.dart';

class PostRideScreen extends ConsumerStatefulWidget {
  const PostRideScreen({super.key});

  @override
  ConsumerState<PostRideScreen> createState() => _PostRideScreenState();
}

class _PostRideScreenState extends ConsumerState<PostRideScreen> {
  final _formKey = GlobalKey<FormState>();
  final _notesCtrl = TextEditingController();
  final _topicCtrl = TextEditingController();
  final _expertiseCtrl = TextEditingController();
  final _seatsCtrl = TextEditingController(text: '3');

  String _rideType = 'OFFICE';
  DateTime _departureTime = DateTime.now().add(const Duration(hours: 1));
  bool _isRecurring = false;
  bool _isLoading = false;
  String? _error;
  String? _vehicleId;
  List<Map<String, dynamic>> _vehicles = [];

  LocationResult? _origin;
  LocationResult? _destination;

  @override
  void initState() {
    super.initState();
    _loadVehicles();
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    _topicCtrl.dispose();
    _expertiseCtrl.dispose();
    _seatsCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadVehicles() async {
    try {
      final res = await DioClient.instance.get(ApiConstants.myVehicles);
      setState(() {
        _vehicles = (res.data as List).cast<Map<String, dynamic>>();
        if (_vehicles.isNotEmpty) _vehicleId = _vehicles.first['id'] as String;
      });
    } catch (_) {}
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _departureTime,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (date == null) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_departureTime),
    );
    if (time == null) return;
    setState(() {
      _departureTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _pickLocation(bool isOrigin) async {
    final result = await Navigator.push<LocationResult>(
      context,
      MaterialPageRoute(
        builder: (_) => LocationPickerScreen(
          title: isOrigin ? 'Pick Pickup Location' : 'Pick Destination',
          initial: isOrigin ? _origin : _destination,
        ),
      ),
    );
    if (result != null) {
      setState(() {
        if (isOrigin) {
          _origin = result;
        } else {
          _destination = result;
        }
      });
    }
  }

  Future<void> _submit() async {
    final user = ref.read(currentUserProvider);
    if (user != null && !user.isVerified) {
      final isUnderReview = user.hasSubmittedProfile;
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text(
              isUnderReview ? 'Profile Under Review' : 'Complete Your Profile'),
          content: Text(
            isUnderReview
                ? 'Your profile is being reviewed. You\'ll be able to post rides once approved (within 24 hours).'
                : 'You need to complete your profile verification before posting rides.',
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
      return;
    }

    if (!_formKey.currentState!.validate()) return;
    if (_vehicleId == null) {
      setState(() => _error = 'Please add a vehicle first');
      return;
    }
    if (_origin == null) {
      setState(() => _error = 'Please select pickup location');
      return;
    }
    if (_destination == null) {
      setState(() => _error = 'Please select destination');
      return;
    }

    setState(() { _isLoading = true; _error = null; });

    try {
      final data = {
        'rideType': _rideType,
        'vehicleId': _vehicleId,
        'originAddress': _origin!.address,
        'originLat': _origin!.lat,
        'originLng': _origin!.lng,
        'destinationAddress': _destination!.address,
        'destinationLat': _destination!.lat,
        'destinationLng': _destination!.lng,
        'departureTime': _departureTime.toIso8601String(),
        'totalSeats': int.parse(_seatsCtrl.text),
        'isRecurring': _isRecurring,
        if (_notesCtrl.text.isNotEmpty) 'notes': _notesCtrl.text.trim(),
        if (_rideType == 'DISCUSSION') ...{
          'discussionTopic': _topicCtrl.text.trim(),
          'discussionFee': 0,
          'hostExpertise': _expertiseCtrl.text.trim(),
        },
      };

      await DioClient.instance.post(ApiConstants.rides, data: data);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ride posted successfully!'),
            backgroundColor: AppTheme.secondary,
          ),
        );
        ref.invalidate(ridesProvider);
        context.pop();
      }
    } catch (e) {
      setState(() => _error = extractApiError(e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Post a Ride')),
      body: Column(
        children: [
          const FeatureHint(
            featureKey: 'post_ride',
            icon: Icons.add_road_outlined,
            title: 'Post a Ride',
            description:
                'Fill in your route, pick a vehicle, and set departure time. Verified passengers will request to join your ride.',
            color: AppTheme.primary,
          ),
          Expanded(
            child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Ride type
              const Text('Ride Type',
                  style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
              const SizedBox(height: 10),
              _RideTypeSelector(
                selected: _rideType,
                onChanged: (t) => setState(() => _rideType = t),
              ),
              const SizedBox(height: 24),

              // Error
              if (_error != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      color: AppTheme.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8)),
                  child: Text(_error!, style: const TextStyle(color: AppTheme.error, fontSize: 13)),
                ),
                const SizedBox(height: 16),
              ],

              // Vehicle
              if (_vehicles.isEmpty)
                OutlinedButton.icon(
                  onPressed: () async {
                    await context.push('/profile/vehicles');
                    _loadVehicles();
                  },
                  icon: const Icon(Icons.directions_car),
                  label: const Text('Add a vehicle first'),
                )
              else ...[
                const Text('Vehicle',
                    style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _vehicleId,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppTheme.surfaceVariant,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  ),
                  items: _vehicles
                      .map((v) => DropdownMenuItem<String>(
                            value: v['id'] as String,
                            child: Text('${v['make']} ${v['model']} (${v['year']})'),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _vehicleId = v),
                ),
              ],

              const SizedBox(height: 20),

              // Origin
              const Text('From (Pickup)',
                  style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
              const SizedBox(height: 8),
              _LocationField(
                result: _origin,
                hint: 'Tap to select pickup location',
                onTap: () => _pickLocation(true),
              ),
              const SizedBox(height: 16),

              // Destination
              const Text('To (Destination)',
                  style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
              const SizedBox(height: 8),
              _LocationField(
                result: _destination,
                hint: 'Tap to select destination',
                onTap: () => _pickLocation(false),
              ),
              const SizedBox(height: 20),

              // Date & time
              const Text('Departure Time',
                  style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickDateTime,
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.divider),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.schedule, color: AppTheme.textSecondary),
                      const SizedBox(width: 10),
                      Text(
                        DateFormat('EEE, MMM d · h:mm a').format(_departureTime),
                        style: const TextStyle(fontSize: 14, color: AppTheme.textPrimary),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Seats
              CustomTextField(
                label: 'Available Seats',
                controller: _seatsCtrl,
                keyboardType: TextInputType.number,
                validator: (v) {
                  final n = int.tryParse(v ?? '');
                  if (n == null || n < 1 || n > 8) return 'Enter 1-8 seats';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Recurring
              SwitchListTile(
                value: _isRecurring,
                onChanged: (v) => setState(() => _isRecurring = v),
                title: const Text('Recurring daily ride',
                    style: TextStyle(fontWeight: FontWeight.w500)),
                subtitle: const Text('Repeat this ride on selected days'),
                contentPadding: EdgeInsets.zero,
                activeColor: AppTheme.primary,
              ),

              // Discussion fields
              if (_rideType == 'DISCUSSION') ...[
                const SizedBox(height: 8),
                const Divider(),
                const SizedBox(height: 8),
                const Text('Discussion Details',
                    style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                const SizedBox(height: 12),
                CustomTextField(
                  label: 'Topic',
                  hint: 'e.g. Product-Market Fit for SaaS startups',
                  controller: _topicCtrl,
                  validator: (v) =>
                      _rideType == 'DISCUSSION' && v!.isEmpty ? 'Required for DriveDesk rides' : null,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  label: 'Your Expertise',
                  hint: 'e.g. Product Management, FinTech',
                  controller: _expertiseCtrl,
                ),
              ],

              const SizedBox(height: 16),
              CustomTextField(
                label: 'Notes (optional)',
                hint: 'Any preferences or instructions',
                controller: _notesCtrl,
                maxLines: 2,
              ),
              const SizedBox(height: 28),

              PrimaryButton(
                label: 'Post Ride',
                isLoading: _isLoading,
                onPressed: _submit,
                icon: Icons.directions_car,
              ),
            ],
          ),
        ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Location field widget ─────────────────────────────────────────────────────

class _LocationField extends StatelessWidget {
  final LocationResult? result;
  final String hint;
  final VoidCallback onTap;

  const _LocationField({required this.result, required this.hint, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.surfaceVariant,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: result != null ? AppTheme.primary : AppTheme.divider,
            width: result != null ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              result != null ? Icons.location_on : Icons.location_on_outlined,
              color: result != null ? AppTheme.primary : AppTheme.textSecondary,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                result?.address ?? hint,
                style: TextStyle(
                  fontSize: 14,
                  color: result != null ? AppTheme.textPrimary : AppTheme.textHint,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(Icons.chevron_right, color: AppTheme.textHint, size: 18),
          ],
        ),
      ),
    );
  }
}

// ─── Ride type selector ────────────────────────────────────────────────────────

class _RideTypeSelector extends StatelessWidget {
  final String selected;
  final void Function(String) onChanged;

  const _RideTypeSelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final types = [
      {'key': 'OFFICE', 'label': 'Office', 'icon': Icons.business, 'color': AppTheme.officeColor},
      {'key': 'UNIVERSITY', 'label': 'Campus', 'icon': Icons.school, 'color': AppTheme.universityColor},
      {'key': 'DISCUSSION', 'label': 'DriveDesk', 'icon': Icons.record_voice_over, 'color': AppTheme.discussionColor},
    ];

    return Row(
      children: types
          .map((t) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => onChanged(t['key'] as String),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: selected == t['key']
                            ? (t['color'] as Color).withOpacity(0.1)
                            : AppTheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: selected == t['key'] ? t['color'] as Color : AppTheme.divider,
                          width: selected == t['key'] ? 1.5 : 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(t['icon'] as IconData,
                              color: selected == t['key'] ? t['color'] as Color : AppTheme.textSecondary,
                              size: 20),
                          const SizedBox(height: 4),
                          Text(t['label'] as String,
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: selected == t['key'] ? t['color'] as Color : AppTheme.textSecondary)),
                        ],
                      ),
                    ),
                  ),
                ),
              ))
          .toList(),
    );
  }
}
