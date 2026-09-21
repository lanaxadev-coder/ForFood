// ============================================================
// GEOHASH UTILITY — base32 geohash encoder + proper 3×3 neighbours
// ============================================================
// Precision 5 ≈ 4.9 km × 4.9 km cell.
// neighbours() returns the center cell + all 8 surrounding cells,
// which is what Firestore's prefix-range query expects.
// ============================================================

class GeohashUtil {
  static const String _base32 = '0123456789bcdefghjkmnpqrstuvwxyz';

  /// Encodes a lat/lng pair into a base32 geohash string.
  static String encode({
    required double latitude,
    required double longitude,
    int precision = 5,
  }) {
    double latMin = -90.0;
    double latMax = 90.0;
    double lngMin = -180.0;
    double lngMax = 180.0;

    final buffer = StringBuffer();
    bool isEvenBit = true;
    int bit = 0;
    int currentChar = 0;

    while (buffer.length < precision) {
      if (isEvenBit) {
        final midLng = (lngMin + lngMax) / 2;
        if (longitude >= midLng) {
          currentChar = (currentChar << 1) | 1;
          lngMin = midLng;
        } else {
          currentChar = currentChar << 1;
          lngMax = midLng;
        }
      } else {
        final midLat = (latMin + latMax) / 2;
        if (latitude >= midLat) {
          currentChar = (currentChar << 1) | 1;
          latMin = midLat;
        } else {
          currentChar = currentChar << 1;
          latMax = midLat;
        }
      }
      isEvenBit = !isEvenBit;

      if (++bit == 5) {
        buffer.write(_base32[currentChar]);
        bit = 0;
        currentChar = 0;
      }
    }

    return buffer.toString();
  }

  /// Standard geohash adjacency tables.
  /// Key = direction, value = [even-position alphabet, odd-position alphabet]
  static const Map<String, List<String>> _neighbours = {
    'n': ['p0r21436x8zb9dcf5h7kjnmqesgutwvy', 'bc01fg45238967deuvhjyznpkmstqrwx'],
    's': ['14365h7k9dcfesgujnmqp0r2twvyx8zb', '238967debc01fg45kmstqrwxuvhjyznp'],
    'e': ['bc01fg45238967deuvhjyznpkmstqrwx', 'p0r21436x8zb9dcf5h7kjnmqesgutwvy'],
    'w': ['238967debc01fg45kmstqrwxuvhjyznp', '14365h7k9dcfesgujnmqp0r2twvyx8zb'],
  };

  /// Border characters — when the last char is one of these, we must
  /// carry the direction change into the parent cell (recursively).
  static const Map<String, List<String>> _borders = {
    'n': ['prxz', 'bcfguvyz'],
    's': ['028b', '0145hjnp'],
    'e': ['bcfguvyz', 'prxz'],
    'w': ['0145hjnp', '028b'],
  };

  static String _adjacent(String hash, String dir) {
    hash = hash.toLowerCase();
    final lastChr = hash[hash.length - 1];
    final type = hash.length % 2;
    var base = hash.substring(0, hash.length - 1);

    if (_borders[dir]![type].contains(lastChr) && base.isNotEmpty) {
      base = _adjacent(base, dir);
    }

    final idx = _neighbours[dir]![type].indexOf(lastChr);
    return '$base${_base32[idx]}';
  }

  /// Returns the center cell plus its 8 surrounding cells (3×3 grid).
  /// Use this to build a Firestore query that covers a neighborhood.
  static List<String> neighbours(String geohash) {
    final n = _adjacent(geohash, 'n');
    final s = _adjacent(geohash, 's');
    final e = _adjacent(geohash, 'e');
    final w = _adjacent(geohash, 'w');

    return <String>[
      geohash,              // center
      n,                    // north
      s,                    // south
      e,                    // east
      w,                    // west
      _adjacent(n, 'e'),    // northeast
      _adjacent(n, 'w'),    // northwest
      _adjacent(s, 'e'),    // southeast
      _adjacent(s, 'w'),    // southwest
    ];
  }
}