// ============================================================
// LOCATION MAP VIEW — READ-ONLY WITH OSRM ROUTE
// - Geoapify base tiles
// - User blue dot + destination pin + driving route
// - Every registered restaurant as a small named marker
// - Tap a small marker → preview card → open detail
// - AppBar toggle to hide/show the crowd
// ============================================================

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_cache/flutter_map_cache.dart';
import 'package:forfood/core/widgets/catched_tile_provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:forfood/core/constants/map_config.dart';
import 'package:forfood/core/theme/app_color.dart';
import 'package:forfood/core/widgets/user_location_marker.dart';
import 'package:forfood/models/restaurant_model.dart';
import 'package:forfood/service/database/firestore_provider.dart';
import 'package:forfood/utilities/haptic_feedback.dart';
import 'package:forfood/utilities/page_transition.dart';
import 'package:forfood/view/user/retaurant_detail_screen.dart';

class LocationMapView extends StatefulWidget {
  final String title;
  final String destinationName;
  final String destinationAddress;
  final double destinationLatitude;
  final double destinationLongitude;

  const LocationMapView({
    super.key,
    required this.title,
    required this.destinationName,
    required this.destinationAddress,
    required this.destinationLatitude,
    required this.destinationLongitude,
  });

  @override
  State<LocationMapView> createState() => _LocationMapViewState();
}

class _LocationMapViewState extends State<LocationMapView> {
  final MapController _mapController = MapController();
  final FirestoreProvider _firestoreProvider = FirestoreProvider();
  CachedTileProvider? _cachedTileProvider;
  // ── route / user ──
  Position? _userPosition;
  List<LatLng> _routePoints = [];
  double? _routeDistanceKm;
  double? _routeDurationMin;

  bool _isLoading = true;
  String? _permissionError;
  bool _permissionDeniedForever = false;
  bool _isLoadingRoute = false;

  StreamSubscription<CompassEvent>? _compassSub;
  double? _heading;

  // ── all restaurants ──
  List<RestaurantModel> _allRestaurants = [];
  RestaurantModel? _previewRestaurant;
  bool _showOtherRestaurants = true;

  @override
  void initState() {
    super.initState();
    _startCompass();
    _initialize();
    _loadAllRestaurants();
        buildCachedTileProvider().then((p) {
      if (mounted) setState(() => _cachedTileProvider = p);
    });
  }

  @override
  void dispose() {
    _compassSub?.cancel();
    super.dispose();
  }

  // ✅ Compass debounced — only rebuilds when heading moves ≥5°
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
  // ALL RESTAURANTS
  // ============================================================
  Future<void> _loadAllRestaurants() async {
    try {
      final restaurants =
          await _firestoreProvider.getAllRestaurants(limit: 100);

      final notZero = restaurants
          .where((r) => r.latitude != 0 && r.longitude != 0)
          .toList();

      final notDest = notZero
          .where((r) =>
              r.latitude != widget.destinationLatitude ||
              r.longitude != widget.destinationLongitude)
          .toList();

      debugPrint('🔵 [MapView] ${notDest.length} restaurants to plot');

      if (!mounted) return;
      setState(() => _allRestaurants = notDest);
    } catch (e) {
      debugPrint('🔵 [MapView] ❌ $e');
    }
  }

  // ============================================================
  // INITIALIZATION
  // ============================================================
  Future<void> _initialize() async {
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
              'Location service is disabled. Please enable GPS to see your route.';
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
              'Location permission permanently denied. Enable it in app settings to see your route.';
          _isLoading = false;
        });
        return;
      }

      if (permission == LocationPermission.denied) {
        setState(() {
          _permissionError =
              'Location permission denied. Grant access to see your route.';
          _isLoading = false;
        });
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      setState(() {
        _userPosition = position;
        _isLoading = false;
      });

      await _fetchRoute(position);
    } catch (e) {
      setState(() {
        _permissionError = 'Failed to get your location: $e';
        _isLoading = false;
      });
    }
  }

  // ============================================================
  // OSRM ROUTE FETCH
  // ============================================================
  Future<void> _fetchRoute(Position userPos) async {
    setState(() => _isLoadingRoute = true);

    try {
      final url = Uri.parse(
        'https://router.project-osrm.org/route/v1/driving/'
        '${userPos.longitude},${userPos.latitude};'
        '${widget.destinationLongitude},${widget.destinationLatitude}'
        '?overview=full&geometries=geojson',
      );

      final response =
          await http.get(url).timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        setState(() => _isLoadingRoute = false);
        return;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final routes = data['routes'] as List?;
      if (routes == null || routes.isEmpty) {
        setState(() => _isLoadingRoute = false);
        return;
      }

      final route = routes.first as Map<String, dynamic>;
      final geometry = route['geometry'] as Map<String, dynamic>?;
      final coordinates = geometry?['coordinates'] as List?;

      if (coordinates == null) {
        setState(() => _isLoadingRoute = false);
        return;
      }

      final points = coordinates.map<LatLng>((coord) {
        final pair = coord as List;
        return LatLng(
          (pair[1] as num).toDouble(),
          (pair[0] as num).toDouble(),
        );
      }).toList();

      final distanceMeters = (route['distance'] as num?)?.toDouble() ?? 0;
      final durationSeconds = (route['duration'] as num?)?.toDouble() ?? 0;

      setState(() {
        _routePoints = points;
        _routeDistanceKm = distanceMeters / 1000;
        _routeDurationMin = durationSeconds / 60;
        _isLoadingRoute = false;
      });

      if (points.isNotEmpty && mounted) {
        _fitBounds();
      }
    } catch (e) {
      setState(() => _isLoadingRoute = false);
      debugPrint('OSRM route fetch failed: $e');
    }
  }

  void _fitBounds() {
    final userPoint = _userPosition;
    if (userPoint == null) return;

    final userLatLng = LatLng(userPoint.latitude, userPoint.longitude);
    final destLatLng = LatLng(
      widget.destinationLatitude,
      widget.destinationLongitude,
    );

    final bounds = LatLngBounds.fromPoints([userLatLng, destLatLng]);
    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.all(60),
      ),
    );
  }

  Future<void> _openGoogleMapsNavigation() async {
    final userPoint = _userPosition;
    if (userPoint == null) return;

    final url = Uri.parse(
      'https://www.google.com/maps/dir/?api=1'
      '&origin=${userPoint.latitude},${userPoint.longitude}'
      '&destination=${widget.destinationLatitude},${widget.destinationLongitude}'
      '&travelmode=driving',
    );

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _openAppSettings() async => Geolocator.openAppSettings();

  // ============================================================
  // BUILD
  // ============================================================
  @override
  Widget build(BuildContext context) {
    final destinationPoint = LatLng(
      widget.destinationLatitude,
      widget.destinationLongitude,
    );

    final userPoint = _userPosition != null
        ? LatLng(_userPosition!.latitude, _userPosition!.longitude)
        : destinationPoint;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColor.orange,
        foregroundColor: Colors.white,
        title: Text(
          widget.title,
          style: const TextStyle(
            fontFamily: 'League Spartan',
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            tooltip: _showOtherRestaurants
                ? 'Hide other restaurants'
                : 'Show other restaurants',
            onPressed: () {
              HapticFeedbackUtil.light();
              setState(() {
                _showOtherRestaurants = !_showOtherRestaurants;
                if (!_showOtherRestaurants) {
                  _previewRestaurant = null;
                }
              });
            },
            icon: Icon(
              _showOtherRestaurants
                  ? Icons.storefront
                  : Icons.storefront_outlined,
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // ═══════════════════════════════════════════════════
          // MAP
          // ═══════════════════════════════════════════════════
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: userPoint,
              initialZoom: 14,
              minZoom: 2,
              maxZoom: 20,
              onTap: (_, __) {
                if (_previewRestaurant != null) {
                  setState(() => _previewRestaurant = null);
                }
              },
            ),
            children: [
              // ── Geoapify tiles ──
              TileLayer(
                urlTemplate: MapConfig.tileUrl,
                additionalOptions: {
                  'apiKey': MapConfig.apiKey,
                },
                userAgentPackageName: 'com.forfood.forfood',
                maxZoom: 20,
                maxNativeZoom: 20,
                  keepBuffer: 5,   // ← ADD THIS
  tileProvider: _cachedTileProvider,  // null-safe; falls back to default until ready

              ),

              RichAttributionWidget(
                attributions: [
                  TextSourceAttribution(
                    'Geoapify',
                    onTap: () {
                      launchUrl(
                        Uri.parse('https://www.geoapify.com/'),
                        mode: LaunchMode.externalApplication,
                      );
                    },
                  ),
                  TextSourceAttribution(
                    'OpenStreetMap contributors',
                    onTap: () {
                      launchUrl(
                        Uri.parse('https://www.openstreetmap.org/copyright'),
                        mode: LaunchMode.externalApplication,
                      );
                    },
                  ),
                ],
              ),

              // ── Route ──
              if (_routePoints.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _routePoints,
                      strokeWidth: 5,
                      color: AppColor.orange,
                    ),
                  ],
                ),

              // ── ✅ Restaurant markers with name labels ──
              if (_showOtherRestaurants && _allRestaurants.isNotEmpty)
                MarkerLayer(
                  markers: _allRestaurants.map((r) {
                    final isPreview = _previewRestaurant?.id == r.id;
                    return Marker(
                      point: LatLng(r.latitude, r.longitude),
                      width: isPreview ? 130 : 110,
                      height: isPreview ? 74 : 58,
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedbackUtil.light();
                          setState(() => _previewRestaurant = r);
                        },
                        child: _SmallRestaurantMarker(
                          name: r.name,
                          imageUrl: r.profileImageUrl,
                          isPreview: isPreview,
                        ),
                      ),
                    );
                  }).toList(),
                ),

              // ── Destination + user ──
              MarkerLayer(
                markers: [
                  Marker(
                    point: destinationPoint,
                    width: 54,
                    height: 54,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColor.orange, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.25),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.restaurant,
                        color: AppColor.orange,
                        size: 28,
                      ),
                    ),
                  ),

                  if (_userPosition != null)
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

          // ─── Loading overlay ───
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),

          // ─── Recenter FAB ───
          if (!_isLoading)
            Positioned(
              right: 16,
              top: 16,
              child: FloatingActionButton.small(
                backgroundColor: Colors.white,
                foregroundColor: AppColor.orange,
                onPressed: () {
                  if (_routePoints.isNotEmpty) {
                    _fitBounds();
                  } else {
                    _mapController.move(destinationPoint, 15);
                  }
                },
                child: const Icon(Icons.my_location),
              ),
            ),

          // ─── Preview card ───
          if (_previewRestaurant != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: _RestaurantPreviewCard(
                restaurant: _previewRestaurant!,
                onClose: () => setState(() => _previewRestaurant = null),
                onOpen: () {
                  Navigator.of(context).push(
                    fadeSlideRoute(
                      RestaurantDetailView(
                        restaurantName: _previewRestaurant!.name,
                        restaurantId: _previewRestaurant!.id,
                      ),
                    ),
                  );
                },
              ),
            ),

          // ─── Permission error card ───
          if (!_isLoading &&
              _permissionError != null &&
              _previewRestaurant == null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Container(
                padding: const EdgeInsets.all(12),
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.location_off,
                            color: AppColor.orange, size: 22),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _permissionDeniedForever
                                ? 'Enable location to see your route'
                                : 'Location not available',
                            style: const TextStyle(
                              fontFamily: 'League Spartan',
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColor.textDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.restaurant,
                            color: AppColor.orange, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            widget.destinationName,
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
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _initialize,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColor.orange,
                              side: const BorderSide(color: AppColor.orange),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 8),
                            ),
                            child: const Text(
                              'Retry',
                              style: TextStyle(
                                fontFamily: 'League Spartan',
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
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
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8),
                              ),
                              child: const Text(
                                'Settings',
                                style: TextStyle(
                                  fontFamily: 'League Spartan',
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
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

          // ─── Destination card ───
          if (!_isLoading &&
              _permissionError == null &&
              _previewRestaurant == null)
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
                          Icons.restaurant,
                          color: AppColor.orange,
                          size: 28,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.destinationName,
                                style: const TextStyle(
                                  fontFamily: 'League Spartan',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppColor.textDark,
                                ),
                              ),
                              if (widget.destinationAddress.isNotEmpty)
                                Text(
                                  widget.destinationAddress,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontFamily: 'League Spartan',
                                    fontSize: 12,
                                    color: AppColor.gray,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    if (_routeDistanceKm != null &&
                        _routeDurationMin != null) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.route,
                              color: AppColor.orange, size: 18),
                          const SizedBox(width: 6),
                          Text(
                            '${_routeDistanceKm!.toStringAsFixed(1)} km'
                            ' • '
                            '${_routeDurationMin!.round()} min',
                            style: const TextStyle(
                              fontFamily: 'League Spartan',
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColor.textDark,
                            ),
                          ),
                          if (_isLoadingRoute) ...[
                            const SizedBox(width: 8),
                            const SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColor.orange,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],

                    const SizedBox(height: 12),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _openGoogleMapsNavigation,
                        icon: const Icon(Icons.directions, size: 20),
                        label: const Text(
                          'Get Directions',
                          style: TextStyle(
                            fontFamily: 'League Spartan',
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColor.orange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
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

// ============================================================
// SMALL RESTAURANT MARKER — circle + name label underneath
// ============================================================
class _SmallRestaurantMarker extends StatelessWidget {
  final String name;
  final String? imageUrl;
  final bool isPreview;

  const _SmallRestaurantMarker({
    required this.name,
    required this.imageUrl,
    required this.isPreview,
  });

  @override
  Widget build(BuildContext context) {
    final circleSize = isPreview ? 42.0 : 30.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Circle thumbnail ──
        AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: circleSize,
          height: circleSize,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(
              color: isPreview
                  ? AppColor.orange
                  : AppColor.orange.withOpacity(0.7),
              width: isPreview ? 3 : 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isPreview ? 0.28 : 0.15),
                blurRadius: isPreview ? 10 : 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipOval(
            child: (imageUrl != null && imageUrl!.isNotEmpty)
                ? Image.network(
                    imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _fallback(circleSize),
                  )
                : _fallback(circleSize),
          ),
        ),

        // ── Name label ──
        const SizedBox(height: 2),
        Container(
          constraints: const BoxConstraints(maxWidth: 100),
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

  Widget _fallback(double size) {
    return Container(
      color: AppColor.orange,
      child: Icon(
        Icons.restaurant,
        color: Colors.white,
        size: size * 0.47,
      ),
    );
  }
}

// ============================================================
// PREVIEW CARD
// ============================================================
class _RestaurantPreviewCard extends StatelessWidget {
  final RestaurantModel restaurant;
  final VoidCallback onClose;
  final VoidCallback onOpen;

  const _RestaurantPreviewCard({
    required this.restaurant,
    required this.onClose,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 12,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: (restaurant.profileImageUrl != null &&
                      restaurant.profileImageUrl!.isNotEmpty)
                  ? Image.network(
                      restaurant.profileImageUrl!,
                      width: 68,
                      height: 68,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _fallback(),
                    )
                  : _fallback(),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          restaurant.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColor.textDark,
                            fontSize: 15,
                            fontFamily: 'League Spartan',
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: onClose,
                        child: const Icon(
                          Icons.close,
                          size: 18,
                          color: AppColor.gray,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(Icons.star,
                          color: Color(0xFFF4BA1A), size: 13),
                      const SizedBox(width: 3),
                      Text(
                        restaurant.rating.toStringAsFixed(1),
                        style: const TextStyle(
                          color: AppColor.textDark,
                          fontSize: 12,
                          fontFamily: 'League Spartan',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: restaurant.isDeliveryEnabled
                              ? const Color(0xFFB7F8A9)
                              : const Color(0xFFFFE0B2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          restaurant.isDeliveryEnabled
                              ? 'Delivery'
                              : 'Pickup only',
                          style: const TextStyle(
                            color: AppColor.textDark,
                            fontSize: 10,
                            fontFamily: 'League Spartan',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    restaurant.address,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColor.gray,
                      fontSize: 11,
                      fontFamily: 'League Spartan',
                    ),
                  ),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: onOpen,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: AppColor.orange,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: const Text(
                        'View menu',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontFamily: 'League Spartan',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fallback() {
    return Container(
      width: 68,
      height: 68,
      color: AppColor.orange.withOpacity(0.15),
      child: const Icon(Icons.restaurant, color: AppColor.orange, size: 28),
    );
  }
}