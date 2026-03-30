import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/ride_model.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/ride_card.dart';
import 'location_picker_screen.dart';

class SearchRidesScreen extends StatefulWidget {
  const SearchRidesScreen({super.key});

  @override
  State<SearchRidesScreen> createState() => _SearchRidesScreenState();
}

class _SearchRidesScreenState extends State<SearchRidesScreen> {
  LocationResult? _origin;
  LocationResult? _destination;
  String _rideType = 'ALL';
  DateTime? _date;

  List<RideModel> _results = [];
  bool _loading = false;
  bool _searched = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _search());
  }

  final _types = [
    {'key': 'ALL', 'label': 'All'},
    {'key': 'OFFICE', 'label': 'Office'},
    {'key': 'UNIVERSITY', 'label': 'Campus'},
    {'key': 'DISCUSSION', 'label': 'DriveDesk'},
  ];

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
        if (isOrigin) _origin = result;
        else _destination = result;
      });
    }
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _date ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (date != null) setState(() => _date = date);
  }

  Future<void> _search() async {
    setState(() { _loading = true; _error = null; _searched = true; });
    try {
      final params = <String, dynamic>{
        if (_rideType != 'ALL') 'rideType': _rideType,
        if (_date != null) 'date': _date!.toIso8601String(),
        if (_origin != null) ...{
          'originLat': _origin!.lat,
          'originLng': _origin!.lng,
        },
        if (_destination != null) ...{
          'destinationLat': _destination!.lat,
          'destinationLng': _destination!.lng,
        },
      };
      final res = await DioClient.instance.get(ApiConstants.rides, queryParameters: params);
      setState(() {
        _results = (res.data as List)
            .map((e) => RideModel.fromJson(e as Map<String, dynamic>))
            .toList();
      });
    } catch (e) {
      setState(() => _error = extractApiError(e));
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Search Rides')),
      body: Column(
        children: [
          // ── Filters ────────────────────────────────────────────────────────
          Container(
            color: AppTheme.surface,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              children: [
                // From
                _LocationTile(
                  icon: Icons.trip_origin,
                  iconColor: AppTheme.primary,
                  label: _origin?.address ?? 'From (optional)',
                  isEmpty: _origin == null,
                  onTap: () => _pickLocation(true),
                  onClear: _origin != null ? () => setState(() => _origin = null) : null,
                ),
                const SizedBox(height: 8),
                // To
                _LocationTile(
                  icon: Icons.location_on,
                  iconColor: AppTheme.error,
                  label: _destination?.address ?? 'To (optional)',
                  isEmpty: _destination == null,
                  onTap: () => _pickLocation(false),
                  onClear: _destination != null ? () => setState(() => _destination = null) : null,
                ),
                const SizedBox(height: 12),

                // Date + type row
                Row(
                  children: [
                    // Date
                    Expanded(
                      child: GestureDetector(
                        onTap: _pickDate,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: _date != null
                                ? AppTheme.primary.withOpacity(0.08)
                                : AppTheme.surfaceVariant,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _date != null ? AppTheme.primary : AppTheme.divider,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.calendar_today,
                                  size: 14,
                                  color: _date != null ? AppTheme.primary : AppTheme.textSecondary),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  _date != null
                                      ? '${_date!.day}/${_date!.month}/${_date!.year}'
                                      : 'Any date',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: _date != null ? AppTheme.primary : AppTheme.textSecondary,
                                  ),
                                ),
                              ),
                              if (_date != null)
                                GestureDetector(
                                  onTap: () => setState(() => _date = null),
                                  child: const Icon(Icons.close, size: 14, color: AppTheme.textHint),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Ride type
                    Expanded(
                      child: DropdownButtonHideUnderline(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: _rideType != 'ALL'
                                ? AppTheme.primary.withOpacity(0.08)
                                : AppTheme.surfaceVariant,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _rideType != 'ALL' ? AppTheme.primary : AppTheme.divider,
                            ),
                          ),
                          child: DropdownButton<String>(
                            value: _rideType,
                            isDense: true,
                            style: TextStyle(
                              fontSize: 13,
                              color: _rideType != 'ALL' ? AppTheme.primary : AppTheme.textSecondary,
                            ),
                            items: _types
                                .map((t) => DropdownMenuItem(
                                      value: t['key'],
                                      child: Text(t['label']!),
                                    ))
                                .toList(),
                            onChanged: (v) => setState(() => _rideType = v ?? 'ALL'),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Search button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _loading ? null : _search,
                    icon: _loading
                        ? const SizedBox(
                            width: 16, height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.search, size: 18),
                    label: Text(_loading ? 'Searching...' : 'Search Rides'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Results ────────────────────────────────────────────────────────
          Expanded(
            child: _error != null
                ? Center(
                    child: Text(_error!, style: const TextStyle(color: AppTheme.error)))
                : !_searched
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search, size: 56, color: AppTheme.textHint),
                            SizedBox(height: 12),
                            Text('Set filters and tap Search',
                                style: TextStyle(color: AppTheme.textSecondary)),
                          ],
                        ),
                      )
                    : _results.isEmpty
                        ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.directions_car_outlined,
                                    size: 56, color: AppTheme.textHint),
                                SizedBox(height: 12),
                                Text('No rides found',
                                    style: TextStyle(color: AppTheme.textSecondary)),
                                SizedBox(height: 4),
                                Text('Try different filters',
                                    style: TextStyle(fontSize: 12, color: AppTheme.textHint)),
                              ],
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: _results.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 10),
                            itemBuilder: (_, i) => RideCard(
                              ride: _results[i],
                              onTap: () => context.push('/ride/${_results[i].id}'),
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}

class _LocationTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final bool isEmpty;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  const _LocationTile({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.isEmpty,
    required this.onTap,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: isEmpty ? AppTheme.surfaceVariant : AppTheme.primary.withOpacity(0.06),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isEmpty ? AppTheme.divider : AppTheme.primary,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: isEmpty ? AppTheme.textSecondary : iconColor),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: isEmpty ? AppTheme.textHint : AppTheme.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (onClear != null)
              GestureDetector(
                onTap: onClear,
                child: const Icon(Icons.close, size: 16, color: AppTheme.textHint),
              )
            else
              const Icon(Icons.chevron_right, size: 16, color: AppTheme.textHint),
          ],
        ),
      ),
    );
  }
}
