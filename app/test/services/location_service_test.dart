import 'package:app/services/location_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geolocator_platform_interface/geolocator_platform_interface.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class _FakeGeolocator extends GeolocatorPlatform {
  _FakeGeolocator({
    required this.initialPermission,
    LocationPermission? permissionAfterRequest,
    Position? position,
  })  : _permissionAfterRequest =
            permissionAfterRequest ?? initialPermission,
        _position = position;

  final LocationPermission initialPermission;
  final LocationPermission _permissionAfterRequest;
  Position? _position;

  @override
  Future<LocationPermission> checkPermission() async => initialPermission;

  @override
  Future<LocationPermission> requestPermission() async =>
      _permissionAfterRequest;

  @override
  Future<bool> isLocationServiceEnabled() async => true;

  @override
  Future<Position?> getLastKnownPosition({
    bool forceLocationManager = false,
  }) async =>
      _position;

  @override
  Future<Position> getCurrentPosition({
    LocationSettings? locationSettings,
  }) async {
    final current = _position;
    if (current == null) {
      throw StateError('No position configured');
    }
    return current;
  }

  @override
  Stream<ServiceStatus> getServiceStatusStream() => const Stream.empty();

  @override
  Stream<Position> getPositionStream({
    LocationSettings? locationSettings,
  }) =>
      const Stream.empty();

  @override
  Future<LocationAccuracyStatus> requestTemporaryFullAccuracy({
    required String purposeKey,
  }) async =>
      LocationAccuracyStatus.precise;

  @override
  Future<LocationAccuracyStatus> getLocationAccuracy() async =>
      LocationAccuracyStatus.precise;

  @override
  Future<bool> openAppSettings() async => true;

  @override
  Future<bool> openLocationSettings() async => true;
}

void main() {
  test('returns fallback location when permissions stay denied', () async {
    //1.- Configure a fake geolocator that keeps denying permissions.
    final service = LocationService(
      geolocator: _FakeGeolocator(
        initialPermission: LocationPermission.denied,
        permissionAfterRequest: LocationPermission.deniedForever,
      ),
    );
    //2.- Expect the service to yield the predefined Mexico City coordinates.
    final location = await service.getCurrentLocation();
    expect(location, const LatLng(19.4326, -99.1332));
  });

  test('returns actual coordinates once permission is granted', () async {
    //1.- Provide a deterministic mock position to return after permission.
    final position = Position(
      latitude: 10.5,
      longitude: -66.9,
      //1.1.- Provide a deterministic timestamp because newer geolocator versions require un valor concreto.
      timestamp: DateTime.fromMillisecondsSinceEpoch(0),
      accuracy: 5,
      altitude: 0,
      altitudeAccuracy: 1,
      heading: 0,
      headingAccuracy: 1,
      speed: 0,
      speedAccuracy: 1,
    );
    final service = LocationService(
      geolocator: _FakeGeolocator(
        initialPermission: LocationPermission.denied,
        permissionAfterRequest: LocationPermission.whileInUse,
        position: position,
      ),
    );
    //2.- Verify the reported coordinates match the mocked device reading.
    final location = await service.getCurrentLocation();
    expect(location.latitude, position.latitude);
    expect(location.longitude, position.longitude);
  });
}
