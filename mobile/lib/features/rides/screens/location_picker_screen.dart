import 'dart:async';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

class LocationResult {
  final String address;
  final double lat;
  final double lng;
  const LocationResult({required this.address, required this.lat, required this.lng});
}

class LocationPickerScreen extends StatefulWidget {
  final String title;
  final LocationResult? initial;
  const LocationPickerScreen({super.key, required this.title, this.initial});

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  final _searchCtrl = TextEditingController();
  final _mapCtrl = MapController();
  final _dio = Dio();
  final _focusNode = FocusNode();

  List<Map<String, dynamic>> _suggestions = [];
  bool _searching = false;
  bool _reverseGeocoding = false;
  bool _gettingLocation = false;

  Timer? _debounce;
  CancelToken? _cancelToken;

  LatLng _pinPosition = const LatLng(31.5204, 74.3587); // Lahore center
  String _selectedAddress = '';
  bool _hasSelection = false;

  // Lahore bounding box for Nominatim viewbox
  static const _viewbox = '74.15,31.35,74.55,31.65';

  @override
  void initState() {
    super.initState();
    if (widget.initial != null) {
      _pinPosition = LatLng(widget.initial!.lat, widget.initial!.lng);
      _selectedAddress = widget.initial!.address;
      _searchCtrl.text = widget.initial!.address;
      _hasSelection = true;
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _cancelToken?.cancel();
    _searchCtrl.dispose();
    _focusNode.dispose();
    _dio.close();
    super.dispose();
  }

  void _search(String query) {
    _debounce?.cancel();
    if (query.length < 2) {
      _cancelToken?.cancel();
      setState(() { _suggestions = []; _searching = false; });
      return;
    }
    setState(() => _searching = true);
    _debounce = Timer(const Duration(milliseconds: 400), () => _doSearch(query));
  }

  Future<void> _doSearch(String query) async {
    _cancelToken?.cancel();
    _cancelToken = CancelToken();
    try {
      final res = await _dio.get(
        'https://nominatim.openstreetmap.org/search',
        queryParameters: {
          'q': query,
          'format': 'json',
          'limit': '7',
          'countrycodes': 'pk',
          'viewbox': _viewbox,
          'bounded': '0',
          'addressdetails': '1',
        },
        options: Options(
          headers: {'User-Agent': 'RideSync/1.0', 'Accept-Language': 'en'},
          receiveTimeout: const Duration(seconds: 8),
        ),
        cancelToken: _cancelToken,
      );
      if (!mounted) return;
      final list = (res.data as List).cast<Map<String, dynamic>>();
      setState(() { _suggestions = list; _searching = false; });
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) return; // ignore cancelled requests
      if (!mounted) return;
      setState(() { _suggestions = []; _searching = false; });
    } catch (_) {
      if (!mounted) return;
      setState(() { _suggestions = []; _searching = false; });
    }
  }

  void _selectSuggestion(Map<String, dynamic> place) {
    final lat = double.parse(place['lat'] as String);
    final lng = double.parse(place['lon'] as String);
    final displayName = place['display_name'] as String;
    final parts = displayName.split(',');
    // Build a clean short address: first meaningful part + city
    final shortAddress = parts.take(3).join(', ').trim();

    _debounce?.cancel();
    _cancelToken?.cancel();
    _focusNode.unfocus();
    setState(() {
      _pinPosition = LatLng(lat, lng);
      _selectedAddress = shortAddress;
      _searchCtrl.text = shortAddress;
      _suggestions = [];
      _searching = false;
      _hasSelection = true;
    });

    _mapCtrl.move(_pinPosition, 15);
  }

  void _onMapTap(TapPosition _, LatLng point) {
    _focusNode.unfocus();
    // Drop pin immediately — no waiting for reverse geocode
    setState(() {
      _pinPosition = point;
      _hasSelection = true;
      _reverseGeocoding = true;
      _selectedAddress = 'Getting address...';
      _searchCtrl.text = '';
      _suggestions = [];
    });

    _reverseGeocode(point);
  }

  Future<void> _reverseGeocode(LatLng point) async {
    try {
      final res = await _dio.get(
        'https://nominatim.openstreetmap.org/reverse',
        queryParameters: {
          'lat': point.latitude.toString(),
          'lon': point.longitude.toString(),
          'format': 'json',
          'zoom': '16',
        },
        options: Options(
          headers: {'User-Agent': 'RideSync/1.0', 'Accept-Language': 'en'},
          receiveTimeout: const Duration(seconds: 8),
        ),
      );
      if (!mounted) return;
      final displayName = res.data['display_name'] as String? ?? '';
      final shortAddress = displayName.split(',').take(3).join(', ').trim();
      setState(() {
        _selectedAddress = shortAddress.isNotEmpty
            ? shortAddress
            : '${point.latitude.toStringAsFixed(5)}, ${point.longitude.toStringAsFixed(5)}';
        _searchCtrl.text = _selectedAddress;
        _reverseGeocoding = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _selectedAddress = '${point.latitude.toStringAsFixed(5)}, ${point.longitude.toStringAsFixed(5)}';
        _searchCtrl.text = _selectedAddress;
        _reverseGeocoding = false;
      });
    }
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _gettingLocation = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permission denied')),
          );
        }
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final point = LatLng(pos.latitude, pos.longitude);
      _mapCtrl.move(point, 16);
      setState(() {
        _pinPosition = point;
        _hasSelection = true;
        _reverseGeocoding = true;
        _selectedAddress = 'Getting address...';
      });
      _reverseGeocode(point);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not get current location')),
        );
      }
    } finally {
      if (mounted) setState(() => _gettingLocation = false);
    }
  }

  void _confirmSelection() {
    if (_reverseGeocoding) return; // wait for address
    Navigator.pop(
      context,
      LocationResult(
        address: _selectedAddress,
        lat: _pinPosition.latitude,
        lng: _pinPosition.longitude,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          if (_hasSelection && !_reverseGeocoding)
            TextButton(
              onPressed: _confirmSelection,
              child: const Text('Confirm', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
        ],
      ),
      body: Stack(
        children: [
          // ── Map ────────────────────────────────────────────────────────────
          FlutterMap(
            mapController: _mapCtrl,
            options: MapOptions(
              initialCenter: _pinPosition,
              initialZoom: 13,
              onTap: _onMapTap,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Street_Map/MapServer/tile/{z}/{y}/{x}',
                userAgentPackageName: 'pk.ridesync.ridesync',
              ),
              if (_hasSelection)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _pinPosition,
                      width: 44,
                      height: 44,
                      alignment: Alignment.bottomCenter,
                      child: Icon(
                        Icons.location_pin,
                        color: _reverseGeocoding ? Colors.orange : Colors.red,
                        size: 44,
                      ),
                    ),
                  ],
                ),
            ],
          ),

          // ── Search bar + suggestions ──────────────────────────────────────
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Material(
                  elevation: 4,
                  borderRadius: BorderRadius.circular(10),
                  child: TextField(
                    controller: _searchCtrl,
                    focusNode: _focusNode,
                    decoration: InputDecoration(
                      hintText: 'Search address...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searching
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2)),
                            )
                          : _searchCtrl.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    _searchCtrl.clear();
                                    setState(() => _suggestions = []);
                                  },
                                )
                              : null,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onChanged: _search,
                  ),
                ),
                if (_suggestions.isNotEmpty)
                  Material(
                    elevation: 4,
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(10)),
                    child: ListView.separated(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      itemCount: _suggestions.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (_, i) {
                        final place = _suggestions[i];
                        final parts = (place['display_name'] as String).split(',');
                        final name = parts.first.trim();
                        final sub = parts.skip(1).take(2).join(',').trim();
                        return ListTile(
                          dense: true,
                          leading: const Icon(Icons.place_outlined, size: 18),
                          title: Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                          subtitle: sub.isNotEmpty
                              ? Text(sub, style: const TextStyle(fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis)
                              : null,
                          onTap: () => _selectSuggestion(place),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),

          // ── Tap hint (shown when no pin yet) ──────────────────────────────
          if (!_hasSelection)
            const Positioned(
              bottom: 100,
              left: 0,
              right: 0,
              child: Center(
                child: Material(
                  color: Colors.black54,
                  borderRadius: BorderRadius.all(Radius.circular(20)),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text('Tap anywhere on map to pin location',
                        style: TextStyle(color: Colors.white, fontSize: 13)),
                  ),
                ),
              ),
            ),

          // ── Current location FAB ──────────────────────────────────────────
          Positioned(
            bottom: _hasSelection ? 160 : 20,
            right: 16,
            child: FloatingActionButton.small(
              heroTag: 'location',
              backgroundColor: Colors.white,
              onPressed: _gettingLocation ? null : _useCurrentLocation,
              child: _gettingLocation
                  ? const SizedBox(
                      width: 18, height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.my_location, color: Colors.black87),
            ),
          ),

          // ── Bottom confirm bar ────────────────────────────────────────────
          if (_hasSelection)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Selected location',
                        style: TextStyle(fontSize: 11, color: Colors.grey)),
                    const SizedBox(height: 4),
                    _reverseGeocoding
                        ? const Row(children: [
                            SizedBox(
                                width: 14, height: 14,
                                child: CircularProgressIndicator(strokeWidth: 2)),
                            SizedBox(width: 8),
                            Text('Getting address...', style: TextStyle(fontSize: 13, color: Colors.grey)),
                          ])
                        : Text(
                            _selectedAddress,
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _reverseGeocoding ? null : _confirmSelection,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('Confirm Location',
                            style: TextStyle(fontWeight: FontWeight.bold)),
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
