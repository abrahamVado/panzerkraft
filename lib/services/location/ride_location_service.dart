import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

//1.- RideLocationStatus modela las salidas posibles al intentar obtener la ubicación.
enum RideLocationStatus {
  success,
  permissionsDenied,
  servicesDisabled,
  failure,
}

//2.- RideLocationResult encapsula el resultado y la coordenada encontrada.
class RideLocationResult {
  const RideLocationResult({required this.status, this.position});

  final RideLocationStatus status;
  final LatLng? position;
}

//3.- RideLocationService solicita permisos y obtiene la ubicación actual del rider.
class RideLocationService {
  const RideLocationService();

  Future<RideLocationResult> fetchCurrentLocation() async {
    //4.- Primero validamos que el servicio de ubicación esté disponible en el dispositivo.
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return const RideLocationResult(status: RideLocationStatus.servicesDisabled);
    }

    //5.- Luego comprobamos y solicitamos permisos si es necesario.
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      return const RideLocationResult(status: RideLocationStatus.permissionsDenied);
    }

    try {
      //6.- Con permisos y servicios activos obtenemos la posición GPS actual.
      final position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.best);
      return RideLocationResult(
        status: RideLocationStatus.success,
        position: LatLng(position.latitude, position.longitude),
      );
    } catch (_) {
      //7.- Si ocurre un fallo inesperado devolvemos un estado de error genérico.
      return const RideLocationResult(status: RideLocationStatus.failure);
    }
  }
}

//8.- rideLocationServiceProvider expone el servicio para facilitar pruebas y reemplazos.
final rideLocationServiceProvider = Provider<RideLocationService>((ref) {
  return const RideLocationService();
});
