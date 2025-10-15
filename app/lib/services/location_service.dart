import 'package:geolocator/geolocator.dart';
import 'package:geolocator_platform_interface/geolocator_platform_interface.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class LocationService {
  LocationService({GeolocatorPlatform? geolocator})
      : _geolocator = geolocator ?? GeolocatorPlatform.instance;

  final GeolocatorPlatform _geolocator;

  Future<LatLng> getCurrentLocation() async {
    //1.- Verify permissions before reading the GPS location.
    var permission = await _geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await _geolocator.requestPermission();
    }
    //2.- Return a safe fallback when permissions are denied forever.
    if (permission == LocationPermission.deniedForever ||
        permission == LocationPermission.denied) {
      return const LatLng(19.4326, -99.1332);
    }
    //3.- Query the device position and convert it into a Google Maps LatLng.
    final position = await _geolocator.getCurrentPosition(
      locationSettings:
          const LocationSettings(accuracy: LocationAccuracy.best),
    );
    return LatLng(position.latitude, position.longitude);
  }
}
