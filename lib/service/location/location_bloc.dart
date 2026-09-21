import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:forfood/service/location/geocoding_service.dart';
import 'package:forfood/service/location/location_service.dart';

import 'location_event.dart';
import 'location_state.dart';

class LocationBloc extends Bloc<LocationEvent, LocationState> {
  final GeocodingService _geocodingService;
  final LocationService _locationService;

  int _searchRequestId = 0;

  LocationBloc({
    required GeocodingService geocodingService,
    required LocationService locationService,
  })  : _geocodingService = geocodingService,
        _locationService = locationService,
        super(const LocationState()) {
    print('🚀 [LocationBloc] Initialized');
    on<LocationSearchChanged>(_onSearchChanged);
    on<LocationSuggestionSelected>(_onSuggestionSelected);
    on<LocationMapMoved>(_onMapMoved);
    on<LocationUseCurrentPosition>(_onUseCurrentPosition);
    on<LocationClearSearch>(_onClearSearch);
  }

  Future<void> _onSearchChanged(
    LocationSearchChanged event,
    Emitter<LocationState> emit,
  ) async {
    final query = event.query.trim();
    print('🔍 [LocationBloc] Search: "$query"');

    if (query.length < 3) {
      print('⚠️ [LocationBloc] Too short');
      emit(state.copyWith(
        searchQuery: query,
        suggestions: const [],
        searchStatus: LocationSearchStatus.initial,
      ));
      return;
    }

    emit(state.copyWith(
      searchQuery: query,
      suggestions: const [],
      searchStatus: LocationSearchStatus.loading,
    ));

    final requestId = ++_searchRequestId;

    try {
      final results = await _geocodingService.searchAddress(query);

      if (isClosed || requestId != _searchRequestId) {
        print('⚠️ [LocationBloc] Stale');
        return;
      }

      print('✅ [LocationBloc] ${results.length} results');
      emit(state.copyWith(
        suggestions: results,
        searchStatus: results.isEmpty
            ? LocationSearchStatus.empty
            : LocationSearchStatus.success,
      ));
    } catch (e) {
      print('❌ [LocationBloc] Error: $e');
      if (isClosed || requestId != _searchRequestId) return;
      emit(state.copyWith(
        suggestions: const [],
        searchStatus: LocationSearchStatus.error,
        errorMessage: _friendlyError(e),
      ));
    }
  }

  Future<void> _onSuggestionSelected(
    LocationSuggestionSelected event,
    Emitter<LocationState> emit,
  ) async {
    print('📍 [LocationBloc] Selected: ${event.suggestion.displayName}');
    emit(state.copyWith(
      searchQuery: event.suggestion.displayName,
      suggestions: const [],
      searchStatus: LocationSearchStatus.success,
      selectedLocation: event.suggestion,
      mapLatitude: event.suggestion.latitude,
      mapLongitude: event.suggestion.longitude,
      mapAddress: event.suggestion.displayName,
      mapStatus: LocationMapStatus.ready,
      clearError: true,
    ));
  }

  Future<void> _onMapMoved(
    LocationMapMoved event,
    Emitter<LocationState> emit,
  ) async {
    // ✅ NO TIMER - just update lat/lng directly
    emit(state.copyWith(
      mapLatitude: event.latitude,
      mapLongitude: event.longitude,
      clearError: true,
    ));
  }

  Future<void> _onUseCurrentPosition(
    LocationUseCurrentPosition event,
    Emitter<LocationState> emit,
  ) async {
    print('📡 [LocationBloc] Current position');
    
    emit(state.copyWith(
      currentLocationStatus: CurrentLocationStatus.loading,
    ));

    final position = await _locationService.getCurrentPosition();

    if (isClosed) return;

    if (position == null) {
      print('❌ [LocationBloc] No position');
      emit(state.copyWith(
        currentLocationStatus: CurrentLocationStatus.error,
        errorMessage: 'Unable to access your current location.',
      ));
      return;
    }

    print('✅ [LocationBloc] Position: ${position.latitude}, ${position.longitude}');
    emit(state.copyWith(
      currentLocationStatus: CurrentLocationStatus.success,
      mapLatitude: position.latitude,
      mapLongitude: position.longitude,
      mapStatus: LocationMapStatus.ready,
    ));
  }

  Future<void> _onClearSearch(
    LocationClearSearch event,
    Emitter<LocationState> emit,
  ) async {
    ++_searchRequestId;
    emit(state.copyWith(
      searchQuery: '',
      suggestions: const [],
      searchStatus: LocationSearchStatus.initial,
    ));
  }

  String _friendlyError(Object error) {
    if (error is GeocodingException) return error.message;
    return 'Something went wrong.';
  }
}