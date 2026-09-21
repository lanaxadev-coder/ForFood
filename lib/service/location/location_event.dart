import 'package:forfood/service/location/location_suggestion.dart';


abstract class LocationEvent {
  const LocationEvent();
}

class LocationSearchChanged extends LocationEvent {
  final String query;

  const LocationSearchChanged(this.query);
}

class LocationSuggestionSelected extends LocationEvent {
  final LocationSuggestion suggestion;

  const LocationSuggestionSelected(this.suggestion);
}

class LocationMapMoved extends LocationEvent {
  final double latitude;
  final double longitude;

  const LocationMapMoved({
    required this.latitude,
    required this.longitude,
  });
}

class LocationUseCurrentPosition extends LocationEvent {
  const LocationUseCurrentPosition();
}

class LocationClearSearch extends LocationEvent {
  const LocationClearSearch();
}

class LocationReset extends LocationEvent {
  const LocationReset();
}