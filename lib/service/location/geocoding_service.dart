import 'dart:convert';

import 'package:http/http.dart' as http;

import 'location_suggestion.dart';

abstract class GeocodingService {
  Future<List<LocationSuggestion>> searchAddress(String query);

  Future<LocationSuggestion?> reverseGeocode({
    required double latitude,
    required double longitude,
  });
}

class NominatimGeocodingService implements GeocodingService {
  final http.Client _client;

  NominatimGeocodingService({
    http.Client? client,
  }) : _client = client ?? http.Client();

  static const String _host = 'nominatim.openstreetmap.org';

  static const Map<String, String> _headers = {
    'User-Agent': 'ForFoodApp/1.0',
    'Accept': 'application/json',
  };

  @override
  Future<List<LocationSuggestion>> searchAddress(String query) async {
    print('🔍 [Geocoding] Searching: "$query"');  // ✅ DEBUG

    final cleanQuery = query.trim();

    if (cleanQuery.length < 3) {
      print('⚠️ [Geocoding] Query too short, skipping');  // ✅ DEBUG
      return [];
    }

    final uri = Uri.https(
      _host,
      '/search',
      {
        'q': cleanQuery,
        'format': 'json',
        'addressdetails': '1',
        'limit': '5',
        'dedupe': '1',
      },
    );

    print('🌐 [Geocoding] URL: $uri');  // ✅ DEBUG

    final response = await _client
        .get(uri, headers: _headers)
        .timeout(const Duration(seconds: 15));

    print('📡 [Geocoding] Status: ${response.statusCode}');  // ✅ DEBUG

    if (response.statusCode != 200) {
      print('❌ [Geocoding] Search failed: ${response.statusCode}');  // ✅ DEBUG
      throw GeocodingException(
        'Address search failed (${response.statusCode}).',
      );
    }

    final decoded = jsonDecode(response.body);

    if (decoded is! List) {
      print('❌ [Geocoding] Invalid response type');  // ✅ DEBUG
      throw const GeocodingException(
        'Invalid response from location service.',
      );
    }

    final results = decoded
        .whereType<Map<String, dynamic>>()
        .map(LocationSuggestion.fromJson)
        .where(
          (location) =>
              location.displayName.isNotEmpty &&
              location.latitude != 0 &&
              location.longitude != 0,
        )
        .toList();

    print('✅ [Geocoding] Found ${results.length} results');  // ✅ DEBUG

    return results;
  }

  @override
  Future<LocationSuggestion?> reverseGeocode({
    required double latitude,
    required double longitude,
  }) async {
    print('🔄 [Geocoding] Reverse: $latitude, $longitude');  // ✅ DEBUG

    final uri = Uri.https(
      _host,
      '/reverse',
      {
        'lat': latitude.toString(),
        'lon': longitude.toString(),
        'format': 'json',
        'addressdetails': '1',
        'zoom': '18',
      },
    );

    print('🌐 [Geocoding] URL: $uri');  // ✅ DEBUG

    final response = await _client
        .get(uri, headers: _headers)
        .timeout(const Duration(seconds: 15));

    print('📡 [Geocoding] Status: ${response.statusCode}');  // ✅ DEBUG

    if (response.statusCode != 200) {
      print('❌ [Geocoding] Reverse failed: ${response.statusCode}');  // ✅ DEBUG
      throw GeocodingException(
        'Reverse geocoding failed (${response.statusCode}).',
      );
    }

    final decoded = jsonDecode(response.body);

    if (decoded is! Map<String, dynamic>) {
      print('❌ [Geocoding] Invalid response type');  // ✅ DEBUG
      throw const GeocodingException(
        'Invalid reverse-geocoding response.',
      );
    }

    if (decoded['lat'] == null || decoded['lon'] == null) {
      print('⚠️ [Geocoding] No lat/lon in response');  // ✅ DEBUG
      return null;
    }

    final result = LocationSuggestion.fromJson(decoded);
    print('✅ [Geocoding] Address: ${result.displayName}');  // ✅ DEBUG

    return result;
  }

  void dispose() {
    print('🗑️ [Geocoding] Client disposed');  // ✅ DEBUG
    _client.close();
  }
}

class GeocodingException implements Exception {
  final String message;

  const GeocodingException(this.message);

  @override
  String toString() => message;
}