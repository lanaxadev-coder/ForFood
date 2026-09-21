class LocationSuggestion {
  final String placeId;
  final String displayName;
  final double latitude;
  final double longitude;
  final String? city;
  final String? state;
  final String? country;
  final String? countryCode;

  const LocationSuggestion({
    required this.placeId,
    required this.displayName,
    required this.latitude,
    required this.longitude,
    this.city,
    this.state,
    this.country,
    this.countryCode,
  });

  factory LocationSuggestion.fromJson(Map<String, dynamic> json) {
    final address = json['address'] as Map<String, dynamic>?;

    return LocationSuggestion(
      placeId: json['place_id']?.toString() ?? '',
      displayName: json['display_name']?.toString() ?? '',
      latitude: double.tryParse(json['lat']?.toString() ?? '') ?? 0,
      longitude: double.tryParse(json['lon']?.toString() ?? '') ?? 0,
      city: _firstNonNull([
        address?['city'],
        address?['town'],
        address?['village'],
        address?['municipality'],
      ]),
      state: address?['state']?.toString(),
      country: address?['country']?.toString(),
      countryCode: address?['country_code']?.toString(),
    );
  }

  static String? _firstNonNull(List<dynamic> values) {
    for (final value in values) {
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString();
      }
    }

    return null;
  }

  LocationSuggestion copyWith({
    String? placeId,
    String? displayName,
    double? latitude,
    double? longitude,
    String? city,
    String? state,
    String? country,
    String? countryCode,
  }) {
    return LocationSuggestion(
      placeId: placeId ?? this.placeId,
      displayName: displayName ?? this.displayName,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      city: city ?? this.city,
      state: state ?? this.state,
      country: country ?? this.country,
      countryCode: countryCode ?? this.countryCode,
    );
  }
}