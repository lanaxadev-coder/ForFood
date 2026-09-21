import 'package:geolocator/geolocator.dart';

class LocationService {
  Future<bool> isLocationServiceEnabled() async {
    print('📡 [LocationService] Checking service...');  // ✅ DEBUG
    final result = await Geolocator.isLocationServiceEnabled();
    print('📡 [LocationService] Service enabled: $result');  // ✅ DEBUG
    return result;
  }

  Future<LocationPermission> checkPermission() async {
    print('🔐 [LocationService] Checking permission...');  // ✅ DEBUG
    final result = await Geolocator.checkPermission();
    print('🔐 [LocationService] Permission: $result');  // ✅ DEBUG
    return result;
  }

  Future<LocationPermission> requestPermission() async {
    print('🙏 [LocationService] Requesting permission...');  // ✅ DEBUG
    final result = await Geolocator.requestPermission();
    print('🙏 [LocationService] Permission result: $result');  // ✅ DEBUG
    return result;
  }

  Future<Position?> getCurrentPosition() async {
    print('📡 [LocationService] Getting current position...');  // ✅ DEBUG

    final serviceEnabled = await isLocationServiceEnabled();

    if (!serviceEnabled) {
      print('❌ [LocationService] Service disabled');  // ✅ DEBUG
      return null;
    }

    var permission = await checkPermission();

    if (permission == LocationPermission.denied) {
      print('⚠️ [LocationService] Permission denied, requesting...');  // ✅ DEBUG
      permission = await requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      print('❌ [LocationService] Permission denied forever');  // ✅ DEBUG
      return null;
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      print('✅ [LocationService] Position: ${position.latitude}, ${position.longitude}');  // ✅ DEBUG
      return position;
    } catch (e) {
      print('❌ [LocationService] Error: $e');  // ✅ DEBUG
      return null;
    }
  }

  Future<void> openLocationSettings() async {
    print('⚙️ [LocationService] Opening location settings...');  // ✅ DEBUG
    await Geolocator.openLocationSettings();
  }

  Future<void> openAppSettings() async {
    print('⚙️ [LocationService] Opening app settings...');  // ✅ DEBUG
    await Geolocator.openAppSettings();
  }
}