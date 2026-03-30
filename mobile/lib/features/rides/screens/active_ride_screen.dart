import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../../../core/constants/api_constants.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/storage/secure_storage.dart';
import '../../../core/theme/app_theme.dart';

class ActiveRideScreen extends ConsumerStatefulWidget {
  final String rideId;
  final bool isDriver;

  const ActiveRideScreen({
    super.key,
    required this.rideId,
    required this.isDriver,
  });

  @override
  ConsumerState<ActiveRideScreen> createState() => _ActiveRideScreenState();
}

class _ActiveRideScreenState extends ConsumerState<ActiveRideScreen> {
  final _mapController = MapController();
  io.Socket? _socket;

  LatLng? _myLocation;
  LatLng? _driverLocation; // passenger sees driver here
  bool _isConnected = false;
  bool _sosTriggered = false;
  bool _locationReady = false;

  StreamSubscription<Position>? _locationSub;

  @override
  void initState() {
    super.initState();
    _initLocation();
    _connectSocket();
  }

  @override
  void dispose() {
    _locationSub?.cancel();
    _socket?.disconnect();
    _mapController.dispose();
    super.dispose();
  }

  // ─── Location ──────────────────────────────────────────────────────────────

  Future<void> _initLocation() async {
    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.denied ||
        perm == LocationPermission.deniedForever) {
      setState(() => _locationReady = true);
      return;
    }

    try {
      final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      if (!mounted) return;
      final point = LatLng(pos.latitude, pos.longitude);
      setState(() {
        _myLocation = point;
        _locationReady = true;
        if (widget.isDriver) _driverLocation = point;
      });
      _mapController.move(point, 15);
    } catch (_) {
      if (mounted) setState(() => _locationReady = true);
    }

    if (widget.isDriver) {
      _locationSub = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        ),
      ).listen((pos) {
        if (!mounted) return;
        final loc = LatLng(pos.latitude, pos.longitude);
        setState(() {
          _myLocation = loc;
          _driverLocation = loc;
        });
        if (_socket != null && _isConnected) {
          _socket!.emit('location_update', {
            'rideId': widget.rideId,
            'lat': pos.latitude,
            'lng': pos.longitude,
            'heading': pos.heading,
          });
        }
        _mapController.move(loc, _mapController.camera.zoom);
      });
    }
  }

  // ─── Socket connection ─────────────────────────────────────────────────────

  Future<void> _connectSocket() async {
    final token = await SecureStorage.getToken();
    if (token == null) return;

    _socket = io.io(
      '${ApiConstants.wsUrl}${ApiConstants.wsNamespace}',
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': token})
          .build(),
    );

    _socket!.onConnect((_) {
      setState(() => _isConnected = true);
      _socket!.emit('join_ride', {'rideId': widget.rideId});
    });

    _socket!.onDisconnect((_) {
      if (mounted) setState(() => _isConnected = false);
    });

    // Passenger receives driver location
    _socket!.on('location_received', (data) {
      if (!mounted || widget.isDriver) return;
      final lat = (data['lat'] as num).toDouble();
      final lng = (data['lng'] as num).toDouble();
      final loc = LatLng(lat, lng);
      setState(() => _driverLocation = loc);
      _mapController.move(loc, _mapController.camera.zoom);
    });

    _socket!.on('ride_status_changed', (data) {
      if (!mounted) return;
      _onRideStatusChanged(data['status'] as String);
    });

    _socket!.on('sos_received', (data) {
      if (!mounted) return;
      _showSosAlert(data);
    });

    _socket!.connect();
  }

  // ─── SOS ───────────────────────────────────────────────────────────────────

  Future<void> _triggerSos() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Send SOS Alert?'),
        content: const Text(
          'This will alert all ride participants immediately.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            child: const Text('Send SOS'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    Position? position;
    try {
      position = await Geolocator.getCurrentPosition();
    } catch (_) {}

    _socket?.emit('sos_alert', {
      'rideId': widget.rideId,
      if (position != null) 'lat': position.latitude,
      if (position != null) 'lng': position.longitude,
      'message': 'Emergency assistance needed',
    });

    setState(() => _sosTriggered = true);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🚨 SOS alert sent to all participants'),
          backgroundColor: AppTheme.error,
          duration: Duration(seconds: 5),
        ),
      );
    }
  }

  void _showSosAlert(Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.error,
        title: const Text('🚨 SOS Alert',
            style: TextStyle(color: Colors.white)),
        content: Text(
          '${data['triggeredBy']?['name'] ?? 'Someone'} needs help!\n\n'
          '${data['message'] ?? ''}',
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _onRideStatusChanged(String status) {
    final messages = {
      'IN_PROGRESS': 'Ride has started!',
      'COMPLETED': 'Ride completed. Safe travels!',
      'CANCELLED': 'Ride was cancelled.',
    };
    final msg = messages[status];
    if (msg != null && mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final center = _myLocation ??
        _driverLocation ??
        const LatLng(AppConstants.lahoreLat, AppConstants.lahoreLng);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isDriver ? 'Live Map — Driver' : 'Track Ride'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Icon(
              Icons.circle,
              size: 12,
              color: _isConnected ? AppTheme.secondary : AppTheme.error,
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // ── Map ─────────────────────────────────────────────────────────
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: center,
              initialZoom: 15,
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://server.arcgisonline.com/ArcGIS/rest/services/World_Street_Map/MapServer/tile/{z}/{y}/{x}',
                userAgentPackageName: 'pk.ridesync.ridesync',
              ),
              MarkerLayer(
                markers: [
                  // My location
                  if (_myLocation != null)
                    Marker(
                      point: _myLocation!,
                      width: 56,
                      height: 56,
                      alignment: Alignment.bottomCenter,
                      child: _LocationMarker(
                        label: 'You',
                        color: widget.isDriver
                            ? AppTheme.primary
                            : AppTheme.secondary,
                        icon: widget.isDriver
                            ? Icons.directions_car
                            : Icons.person,
                      ),
                    ),
                  // Driver location (passenger view)
                  if (!widget.isDriver && _driverLocation != null)
                    Marker(
                      point: _driverLocation!,
                      width: 56,
                      height: 56,
                      alignment: Alignment.bottomCenter,
                      child: const _LocationMarker(
                        label: 'Driver',
                        color: AppTheme.primary,
                        icon: Icons.directions_car,
                      ),
                    ),
                ],
              ),
            ],
          ),

          // ── Loading overlay ──────────────────────────────────────────────
          if (!_locationReady)
            Container(
              color: Colors.white.withValues(alpha: 0.85),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 12),
                    Text('Getting your location…',
                        style: TextStyle(color: AppTheme.textSecondary)),
                  ],
                ),
              ),
            ),

          // ── Re-center FAB ────────────────────────────────────────────────
          if (_myLocation != null)
            Positioned(
              bottom: 180,
              right: 16,
              child: FloatingActionButton.small(
                heroTag: 'recenter',
                backgroundColor: Colors.white,
                onPressed: () =>
                    _mapController.move(_myLocation!, 15),
                child: const Icon(Icons.my_location,
                    color: Colors.black87),
              ),
            ),

          // ── Bottom panel ─────────────────────────────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
              decoration: const BoxDecoration(
                color: AppTheme.surface,
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10,
                      offset: Offset(0, -4)),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Status chip
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.secondary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.radio_button_checked,
                            size: 12, color: AppTheme.secondary),
                        const SizedBox(width: 6),
                        Text(
                          _isConnected
                              ? 'Connected — Live Tracking'
                              : 'Connecting…',
                          style: const TextStyle(
                              color: AppTheme.secondary,
                              fontSize: 13,
                              fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // SOS button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _sosTriggered ? null : _triggerSos,
                      icon: const Icon(Icons.emergency,
                          color: Colors.white),
                      label: Text(
                        _sosTriggered ? 'SOS Sent' : 'SOS — Emergency',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _sosTriggered
                            ? Colors.grey
                            : AppTheme.error,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LocationMarker extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  const _LocationMarker(
      {required this.label, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: const [
              BoxShadow(color: Colors.black26, blurRadius: 4)
            ],
          ),
          child: Icon(icon, color: Colors.white, size: 16),
        ),
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            label,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
