import 'package:forfood/service/location/location_suggestion.dart';

enum LocationSearchStatus {
  initial,
  loading,
  success,
  empty,
  error,
}

enum LocationMapStatus {
  idle,
  loadingAddress,
  ready,
  error,
}

enum CurrentLocationStatus {
  idle,
  loading,
  success,
  error,
}

class LocationState {
  final String searchQuery;
  final List<LocationSuggestion> suggestions;
  final LocationSearchStatus searchStatus;

  final LocationSuggestion? selectedLocation;

  final double? mapLatitude;
  final double? mapLongitude;

  final String mapAddress;
  final LocationMapStatus mapStatus;

  final CurrentLocationStatus currentLocationStatus;

  final String? errorMessage;

  const LocationState({
    this.searchQuery = '',
    this.suggestions = const [],
    this.searchStatus = LocationSearchStatus.initial,
    this.selectedLocation,
    this.mapLatitude,
    this.mapLongitude,
    this.mapAddress = '',
    this.mapStatus = LocationMapStatus.idle,
    this.currentLocationStatus = CurrentLocationStatus.idle,
    this.errorMessage,
  });

  LocationState copyWith({
    String? searchQuery,
    List<LocationSuggestion>? suggestions,
    LocationSearchStatus? searchStatus,
    LocationSuggestion? selectedLocation,
    bool clearSelectedLocation = false,
    double? mapLatitude,
    double? mapLongitude,
    String? mapAddress,
    LocationMapStatus? mapStatus,
    CurrentLocationStatus? currentLocationStatus,
    String? errorMessage,
    bool clearError = false,
  }) {
    return LocationState(
      searchQuery: searchQuery ?? this.searchQuery,
      suggestions: suggestions ?? this.suggestions,
      searchStatus: searchStatus ?? this.searchStatus,
      selectedLocation: clearSelectedLocation
          ? null
          : selectedLocation ?? this.selectedLocation,
      mapLatitude: mapLatitude ?? this.mapLatitude,
      mapLongitude: mapLongitude ?? this.mapLongitude,
      mapAddress: mapAddress ?? this.mapAddress,
      mapStatus: mapStatus ?? this.mapStatus,
      currentLocationStatus:
          currentLocationStatus ?? this.currentLocationStatus,
      errorMessage: clearError
          ? null
          : errorMessage ?? this.errorMessage,
    );
  }
}