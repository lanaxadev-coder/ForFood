import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:forfood/service/location/location_bloc.dart';
import 'package:forfood/service/location/location_event.dart';
import 'package:forfood/service/location/location_state.dart';
import 'package:latlong2/latlong.dart';

import '../../service/location/location_suggestion.dart';

class PreciseLocationMap extends StatefulWidget {
  final double initialLat;
  final double initialLng;
  final String initialAddress;
  final Function(String address, double latitude, double longitude) onConfirmed;

  const PreciseLocationMap({
    super.key,
    required this.initialLat,
    required this.initialLng,
    required this.initialAddress,
    required this.onConfirmed,
  });

  @override
  State<PreciseLocationMap> createState() => _PreciseLocationMapState();
}

class _PreciseLocationMapState extends State<PreciseLocationMap> {
  late final MapController _mapController;

  @override
  void initState() {
    super.initState();
    print('🗺️ [LocationMap] Initialized');  // ✅ DEBUG
    print('🗺️ [LocationMap] Initial: ${widget.initialLat}, ${widget.initialLng}');  // ✅ DEBUG

    _mapController = MapController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      print('🗺️ [LocationMap] Dispatching initial location');  // ✅ DEBUG
      context.read<LocationBloc>().add(
            LocationSuggestionSelected(_initialLocation()),
          );
    });
  }

  LocationSuggestion _initialLocation() {
    return LocationSuggestion(
      placeId: '',
      displayName: widget.initialAddress,
      latitude: widget.initialLat,
      longitude: widget.initialLng,
    );
  }

  void _confirm(LocationState state) {
    print('✅ [LocationMap] Confirm pressed');  // ✅ DEBUG
    final latitude = state.mapLatitude;
    final longitude = state.mapLongitude;

    if (latitude == null || longitude == null) {
      print('❌ [LocationMap] No lat/lng');  // ✅ DEBUG
      return;
    }

    final address = state.mapAddress.trim().isEmpty
        ? widget.initialAddress
        : state.mapAddress.trim();

    print('✅ [LocationMap] Address: $address');  // ✅ DEBUG
    print('✅ [LocationMap] Lat: $latitude, Lng: $longitude');  // ✅ DEBUG

    widget.onConfirmed(address, latitude, longitude);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<LocationBloc, LocationState>(
      listenWhen: (previous, current) =>
          previous.selectedLocation != current.selectedLocation &&
          current.selectedLocation != null,
      listener: (context, state) {
        final location = state.selectedLocation;
        if (location == null) return;
        print('🗺️ [LocationMap] Moving to: ${location.latitude}, ${location.longitude}');  // ✅ DEBUG
        _mapController.move(
          LatLng(location.latitude, location.longitude),
          17,
        );
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Confirm Location'),
          backgroundColor: const Color(0xFFE95322),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: BlocBuilder<LocationBloc, LocationState>(
          builder: (context, state) {
            final latitude = state.mapLatitude ?? widget.initialLat;
            final longitude = state.mapLongitude ?? widget.initialLng;

            return Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: LatLng(widget.initialLat, widget.initialLng),
                    initialZoom: 17,
                    minZoom: 3,
                    maxZoom: 19,
                    onPositionChanged: (position, hasGesture) {
                      final center = position.center;
                      if (center == null || !hasGesture) return;
                      print('🗺️ [LocationMap] Position changed: ${center.latitude}, ${center.longitude}');  // ✅ DEBUG
                      context.read<LocationBloc>().add(
                            LocationMapMoved(
                              latitude: center.latitude,
                              longitude: center.longitude,
                            ),
                          );
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                   'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.forfood.forfood',
                      maxZoom: 19,
                    ),
                  ],
                ),
                const Center(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: 38),
                    child: Icon(
                      Icons.location_pin,
                      size: 48,
                      color: Color(0xFFE95322),
                    ),
                  ),
                ),
                Positioned(
                  right: 16,
                  top: 16,
                  child: Material(
                    color: Colors.white,
                    elevation: 4,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () {
                        print('📡 [LocationMap] Use current position tapped');  // ✅ DEBUG
                        context.read<LocationBloc>().add(
                              const LocationUseCurrentPosition(),
                            );
                      },
                      child: SizedBox(
                        width: 48,
                        height: 48,
                        child: state.currentLocationStatus ==
                                CurrentLocationStatus.loading
                            ? const Padding(
                                padding: EdgeInsets.all(14),
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.my_location, color: Color(0xFFE95322)),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 20,
                  left: 20,
                  right: 80,
                  child: IgnorePointer(
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.95),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              blurRadius: 8,
                              color: Colors.black.withValues(alpha: 0.12),
                            ),
                          ],
                        ),
                        child: const Text(
                          'Move the map to place the pin',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: 12,
                  child: _LocationBottomCard(
                    state: state,
                    latitude: latitude,
                    longitude: longitude,
                    onConfirm: () => _confirm(state),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _LocationBottomCard extends StatelessWidget {
  final LocationState state;
  final double latitude;
  final double longitude;
  final VoidCallback onConfirm;

  const _LocationBottomCard({
    required this.state,
    required this.latitude,
    required this.longitude,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final isLoading = state.mapStatus == LocationMapStatus.loadingAddress;
    final address = state.mapAddress.trim().isEmpty
        ? 'Move the map to select your location'
        : state.mapAddress;

    return Material(
      color: Colors.white,
      elevation: 8,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFE6DC),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.location_on, color: Color(0xFFE95322)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Selected location', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      const SizedBox(height: 4),
                      Text(
                        address,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (isLoading) ...[
              const SizedBox(height: 10),
              const Row(
                children: [
                  SizedBox(width: 15, height: 15, child: CircularProgressIndicator(strokeWidth: 2)),
                  SizedBox(width: 8),
                  Text('Finding address...', style: TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ],
            if (state.mapStatus == LocationMapStatus.error) ...[
              const SizedBox(height: 8),
              Text(state.errorMessage ?? 'Could not determine the address.', style: const TextStyle(fontSize: 12, color: Colors.red)),
            ],
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoading ? null : onConfirm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE95322),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.shade300,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                child: const Text('Confirm Location', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}