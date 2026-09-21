class MapConfig {
  MapConfig._();

  /// Read at compile time from --dart-define-from-file=.env.json
  /// Required key: GEOAPIFY_API_KEY
  static const String apiKey = String.fromEnvironment(
    'c5e2266b1f7048ad8d6bfdfa91fda594',
    defaultValue: '',
  );

  static const String tileUrl =
      'https://maps.geoapify.com/v1/tile/osm-bright/'
      '{z}/{x}/{y}.png?apiKey={apiKey}';
}



