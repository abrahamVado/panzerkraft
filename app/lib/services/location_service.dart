import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class LocationService {
  Future<LatLng> getCurrentLocation() async {
    //1.- Verify permissions before reading the GPS location.
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    //2.- Return a safe fallback when permissions are denied forever.
    if (permission == LocationPermission.deniedForever ||
        permission == LocationPermission.denied) {
      return const LatLng(19.4326, -99.1332);
    }
    //3.- Query the device position and convert it into a Google Maps LatLng.
    final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best);
    return LatLng(position.latitude, position.longitude);
  }
}
