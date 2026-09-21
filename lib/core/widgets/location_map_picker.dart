// ============================================================
// LOCATION MAP PICKER — SELF-CONTAINED
// User drags map OR taps anywhere, pin stays centered,
// address updates live. Search bar at top.
// Returns (address, lat, lng) on confirm.
// ✅ NEW: registered restaurants appear as small markers
// ============================================================

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import 'package:forfood/core/constants/map_config.dart';
import 'package:forfood/core/theme/app_color.dart';
import 'package:forfood/core/widgets/user_location_marker.dart';
import 'package:forfood/models/restaurant_model.dart';
import 'package:forfood/service/database/firestore_provider.dart';
import 'package:forfood/service/location/geocoding_service.dart';
import 'package:forfood/service/location/location_suggestion.dart';
import 'package:forfood/utilities/haptic_feedback.dart';

class LocationMapPicker extends StatefulWidget {
  final double? initialLatitude;
  final double? initialLongitude;
  final String? initialAddress;
  final Function(String address, double latitude, double longitude) onConfirmed;

  const LocationMapPicker({
    super.key,
    this.initialLatitude,
    this.initialLongitude,
    this.initialAddress,
    required this.onConfirmed,
  });

  @override
  State<LocationMapPicker> createState() => _LocationMapPickerState();
}

class _LocationMapPickerState extends State<LocationMapPicker> {
  final MapController _mapController = MapController();
  final GeocodingService _geocodingService = NominatimGeocodingService();
  final FirestoreProvider _firestoreProvider = FirestoreProvider();

  static const double _defaultLat = 36.7538;
  static const double _defaultLng = 3.0588;

  LatLng _center = const LatLng(_defaultLat, _defaultLng);
  String _address = '';

  Position? _userPosition;
  bool _isLoading = true;
  bool _isLoadingAddress = false;
  String? _permissionError;
  bool _permissionDeniedForever = false;

  Timer? _reverseGeocodeDebounce;

  // Search bar
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  List<LocationSuggestion> _searchResults = [];
  bool _isSearching = false;
  bool _showResults = false;
  Timer? _searchDebounce;

  // Compass
  StreamSubscription<CompassEvent>? _compassSub;
  double? _heading;

  // ✅ Restaurants
  List<RestaurantModel> _allRestaurants = [];
  bool _showRestaurants = true;

  @override
  void initState() {
    super.initState();
    _startCompass();
    _initialize();
    _loadAllRestaurants();
  }

  @override
  void dispose() {
    _reverseGeocodeDebounce?.cancel();
    _searchDebounce?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    _compassSub?.cancel();
    super.dispose();
  }

  // ============================================================
  // ✅ RESTAURANTS
  // ============================================================
  Future<void> _loadAllRestaurants() async {
    try {
      final restaurants =
          await _firestoreProvider.getAllRestaurants(limit: 100);
      if (!mounted) return;
      setState(() {
        _allRestaurants = restaurants
            .where((r) => r.latitude != 0 && r.longitude != 0)
            .toList();
      });
      debugPrint('🔵 [Picker] loaded ${_allRestaurants.length} restaurants');
    } catch (e) {
      debugPrint('🔵 [Picker] ❌ $e');
    }
  }

  // ============================================================
  // COMPASS — debounced
  // ============================================================
  void _startCompass() {
    _compassSub = FlutterCompass.events?.listen((event) {
      if (!mounted) return;
      final h = event.heading;
      if (h == null || h < 0) return;
      if (_heading != null && (h - _heading!).abs() < 5) return;
      setState(() => _heading = h);
    });
  }

  // ============================================================
  // INIT
  // ============================================================
  Future<void> _initialize() async {
    final gpsPosition = await _tryGetGpsPosition();

    if (gpsPosition != null && mounted) {
      setState(() {
        _userPosition = gpsPosition;
        _center = LatLng(gpsPosition.latitude, gpsPosition.longitude);
        _address = '';
        _isLoading = false;
      });
      _mapController.move(_center, 16);
      _reverseGeocode(_center);
      return;
    }

    if (widget.initialLatitude != null && widget.initialLongitude != null) {
      setState(() {
        _center = LatLng(widget.initialLatitude!, widget.initialLongitude!);
        _address = widget.initialAddress ?? '';
        _isLoading = false;
      });
      _mapController.move(_center, 16);
      _reverseGeocode(_center);
      return;
    }

    await _fetchUserPosition();
  }

  Future<Position?> _tryGetGpsPosition() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }

      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _fetchUserPosition() async {
    setState(() {
      _isLoading = true;
      _permissionError = null;
      _permissionDeniedForever = false;
    });

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _permissionError =
              'Location service is disabled. Please enable GPS.';
          _isLoading = false;
        });
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _permissionDeniedForever = true;
          _permissionError =
              'Location permission permanently denied. Enable it in settings.';
          _isLoading = false;
        });
        return;
      }

      if (permission == LocationPermission.denied) {
        setState(() {
          _permissionError =
              'Location permission denied. Grant access to pick your location.';
          _isLoading = false;
        });
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      if (!mounted) return;

      setState(() {
        _userPosition = pos;
        _center = LatLng(pos.latitude, pos.longitude);
        _isLoading = false;
      });

      _mapController.move(_center, 16);
      _reverseGeocode(_center);
    } catch (e) {
      setState(() {
        _permissionError = 'Failed to get your location: $e';
        _isLoading = false;
      });
    }
  }

  // ============================================================
  // SEARCH
  // ============================================================
  void _onSearchChanged(String query) {
    _searchDebounce?.cancel();
    if (query.trim().length < 3) {
      setState(() {
        _searchResults = [];
        _showResults = false;
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);

    _searchDebounce = Timer(const Duration(milliseconds: 500), () async {
      try {
        final results = await _geocodingService.searchAddress(query);
        if (!mounted) return;
        setState(() {
          _searchResults = results;
          _showResults = true;
          _isSearching = false;
        });
      } catch (_) {
        if (!mounted) return;
        setState(() {
          _searchResults = [];
          _showResults = false;
          _isSearching = false;
        });
      }
    });
  }

  void _selectSearchResult(LocationSuggestion suggestion) {
    final point = LatLng(suggestion.latitude, suggestion.longitude);
    _searchFocusNode.unfocus();
    setState(() {
      _center = point;
      _address = suggestion.displayName;
      _showResults = false;
      _searchResults = [];
      _searchController.text = suggestion.displayName;
    });
    _mapController.move(point, 16);
  }

  // ============================================================
  // REVERSE GEOCODE
  // ============================================================
  void _onPositionChanged(MapPosition position, bool hasGesture) {
    if (!hasGesture) return;
    final newCenter = position.center;
    if (newCenter == null) return;

    setState(() {
      _center = newCenter;
      _address = '';
    });

    _reverseGeocodeDebounce?.cancel();
    _reverseGeocodeDebounce = Timer(
      const Duration(milliseconds: 500),
      () => _reverseGeocode(newCenter),
    );
  }

  Future<void> _reverseGeocode(LatLng point) async {
    setState(() => _isLoadingAddress = true);
    try {
      final result = await _geocodingService.reverseGeocode(
        latitude: point.latitude,
        longitude: point.longitude,
      );
      if (!mounted) return;
      setState(() {
        _address = result?.displayName ?? 'Unknown address';
        _isLoadingAddress = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _address = 'Unable to get address';
        _isLoadingAddress = false;
      });
    }
  }

  // ============================================================
  // USE MY LOCATION
  // ============================================================
  Future<void> _useMyLocation() async {
    if (_userPosition == null) {
      await _fetchUserPosition();
      return;
    }
    final point = LatLng(_userPosition!.latitude, _userPosition!.longitude);
    setState(() {
      _center = point;
      _address = '';
    });
    _mapController.move(point, 16);
    _reverseGeocode(point);
  }

  // ============================================================
  // CONFIRM
  // ============================================================
  void _confirm() {
    if (_address.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please wait for address to load')),
      );
      return;
    }
    widget.onConfirmed(_address, _center.latitude, _center.longitude);
    Navigator.pop(context);
  }

  Future<void> _openAppSettings() async => Geolocator.openAppSettings();

  // ============================================================
  // BUILD
  // ============================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColor.orange,
        foregroundColor: Colors.white,
        title: const Text(
          'Pick a Location',
          style: TextStyle(
            fontFamily: 'League Spartan',
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          // ✅ Toggle restaurants
          IconButton(
            tooltip: _showRestaurants
                ? 'Hide restaurants'
                : 'Show restaurants',
            onPressed: () {
              HapticFeedbackUtil.light();
              setState(() => _showRestaurants = !_showRestaurants);
            },
            icon: Icon(
              _showRestaurants
                  ? Icons.storefront
                  : Icons.storefront_outlined,
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // ─── MAP ───
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _center,
              initialZoom: 16,
              minZoom: 2,
              maxZoom: 20,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
              onPositionChanged: _onPositionChanged,
              onTap: (_, point) {
                _mapController.move(point, _mapController.camera.zoom);
                setState(() {
                  _center = point;
                  _address = '';
                });
                _reverseGeocode(point);
              },
            ),
            children: [
              TileLayer(
                urlTemplate: MapConfig.tileUrl,
                additionalOptions: {
                  'apiKey': MapConfig.apiKey,
                },
                userAgentPackageName: 'com.forfood.forfood',
                maxZoom: 20,
                maxNativeZoom: 20,
              ),

              // ✅ Restaurant markers (small, non-interactive)
             if (_showRestaurants && _allRestaurants.isNotEmpty)
  MarkerLayer(
    markers: _allRestaurants.map((r) {
      return Marker(
        point: LatLng(r.latitude, r.longitude),
        width: 100,      // ✅ wider to fit the label
        height: 52,      // ✅ taller to fit the label
        child: _SmallPickerMarker(
          name: r.name,              // ✅ NEW
          imageUrl: r.profileImageUrl,
        ),
      );
    }).toList(),
  ),

              // User blue dot
              if (_userPosition != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: LatLng(
                        _userPosition!.latitude,
                        _userPosition!.longitude,
                      ),
                      width: 70,
                      height: 70,
                      child: UserLocationMarker(heading: _heading),
                    ),
                  ],
                ),
            ],
          ),

          // ─── Center pin ───
          const IgnorePointer(
            child: Center(
              child: Padding(
                padding: EdgeInsets.only(bottom: 30),
                child: Icon(
                  Icons.location_pin,
                  size: 48,
                  color: AppColor.orange,
                ),
              ),
            ),
          ),

          // ─── Use-my-location FAB ───
          if (!_isLoading && _permissionError == null)
            Positioned(
              right: 16,
              bottom: 220,
              child: FloatingActionButton.small(
                backgroundColor: Colors.white,
                foregroundColor: AppColor.orange,
                onPressed: _useMyLocation,
                child: const Icon(Icons.my_location),
              ),
            ),

          // ─── Loading overlay ───
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),

          // ─── Permission error card ───
          if (!_isLoading && _permissionError != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.location_off,
                      color: AppColor.orange,
                      size: 40,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _permissionError!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'League Spartan',
                        fontSize: 14,
                        color: AppColor.textDark,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _fetchUserPosition,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColor.orange,
                              side: const BorderSide(color: AppColor.orange),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: const Text(
                              'Retry',
                              style: TextStyle(
                                fontFamily: 'League Spartan',
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        if (_permissionDeniedForever) ...[
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _openAppSettings,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColor.orange,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                              child: const Text(
                                'Open Settings',
                                style: TextStyle(
                                  fontFamily: 'League Spartan',
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),

          // ─── Bottom card ───
          if (!_isLoading && _permissionError == null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          color: AppColor.orange,
                          size: 24,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _isLoadingAddress
                              ? const SizedBox(
                                  height: 18,
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppColor.orange,
                                      ),
                                    ),
                                  ),
                                )
                              : Text(
                                  _address.isEmpty
                                      ? 'Move the map to pick a location'
                                      : _address,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontFamily: 'League Spartan',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: AppColor.textDark,
                                  ),
                                ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoadingAddress ? null : _confirm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColor.orange,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.grey.shade300,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: const Text(
                          'Confirm Location',
                          style: TextStyle(
                            fontFamily: 'League Spartan',
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // ─── Search bar (top layer) ───
          Positioned(
            left: 16,
            right: 16,
            top: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    onChanged: _onSearchChanged,
                    decoration: InputDecoration(
                      hintText: 'Search address...',
                      hintStyle: const TextStyle(
                        fontFamily: 'League Spartan',
                        fontSize: 14,
                        color: AppColor.gray,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      prefixIcon:
                          const Icon(Icons.search, color: AppColor.orange),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchResults = [];
                                  _showResults = false;
                                });
                              },
                            )
                          : null,
                    ),
                  ),
                ),
                if (_showResults)
                  Container(
                    margin: const EdgeInsets.only(top: 6),
                    constraints: const BoxConstraints(maxHeight: 220),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      itemCount: _searchResults.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final s = _searchResults[index];
                        return ListTile(
                          dense: true,
                          onTap: () => _selectSearchResult(s),
                          leading: const Icon(
                            Icons.location_on_outlined,
                            color: AppColor.orange,
                            size: 20,
                          ),
                          title: Text(
                            s.displayName,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'League Spartan',
                              fontSize: 13,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                if (_isSearching)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColor.orange,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// SMALL MARKER FOR PICKER — non-interactive, just visual context
// ============================================================
// ============================================================
// SMALL MARKER FOR PICKER — circle + name label
// ============================================================
class _SmallPickerMarker extends StatelessWidget {
  final String name;
  final String? imageUrl;

  const _SmallPickerMarker({
    required this.name,
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Circle thumbnail
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColor.orange.withOpacity(0.8),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipOval(
            child: (imageUrl != null && imageUrl!.isNotEmpty)
                ? Image.network(
                    imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _fallback(),
                  )
                : _fallback(),
          ),
        ),

        // Name label
        const SizedBox(height: 2),
        Container(
          constraints: const BoxConstraints(maxWidth: 90),
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.92),
            borderRadius: BorderRadius.circular(6),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 2,
              ),
            ],
          ),
          child: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColor.textDark,
              fontSize: 9,
              fontFamily: 'League Spartan',
              fontWeight: FontWeight.w600,
              height: 1.1,
            ),
          ),
        ),
      ],
    );
  }

  Widget _fallback() {
    return Container(
      color: AppColor.orange,
      child: const Icon(
        Icons.restaurant,
        color: Colors.white,
        size: 13,
      ),
    );
  }
}