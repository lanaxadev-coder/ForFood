class MapConfig {
  MapConfig._();

  /// Read at compile time from --dart-define-from-file=.env.json
  /// Required env var name: GEOAPIFY_API_KEY
  static const String apiKey = String.fromEnvironment(
    'GEOAPIFY_API_KEY',
    defaultValue: '',
  );

 static const String tileUrl =
    'https://maps.geoapify.com/v1/tile/osm-bright-grey/'
    '{z}/{x}/{y}.png?apiKey={apiKey}';
}