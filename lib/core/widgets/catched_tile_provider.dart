import 'package:dio_cache_interceptor_hive_store/dio_cache_interceptor_hive_store.dart';
import 'package:flutter_map_cache/flutter_map_cache.dart';
import 'package:path_provider/path_provider.dart';

/// Singleton tile provider with a persistent Hive disk cache.
/// First view of a tile hits the network; every view after reads from disk.
CachedTileProvider? _instance;

Future<CachedTileProvider> buildCachedTileProvider() async {
  if (_instance != null) return _instance!;

  final cacheDir = await getTemporaryDirectory();
  final store = HiveCacheStore(
    '${cacheDir.path}/mapTiles',
    hiveBoxName: 'MapTiles',
  );

  _instance = CachedTileProvider(
    store: store,
    maxStale: const Duration(days: 30),
  );

  return _instance!;
}