import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/auth_providers.dart';
import '../auth/fake_credentials.dart';

//1.- DashboardCurrentTrip resume el viaje activo que la UI mostrará.
class DashboardCurrentTrip {
  const DashboardCurrentTrip({
    required this.passengerName,
    required this.pickupAddress,
    required this.dropoffAddress,
    required this.status,
    required this.vehiclePlate,
    required this.etaMinutes,
    required this.amount,
    required this.durationMinutes,
    required this.distanceKm,
    required this.vehicleModel,
    required this.driverName,
    required this.driverRating,
    required this.driverExperienceYears,
    required this.driverPhone,
  });

  final String passengerName;
  final String pickupAddress;
  final String dropoffAddress;
  final String status;
  final String vehiclePlate;
  final int etaMinutes;
  final double amount;
  final int durationMinutes;
  final double distanceKm;
  final String vehicleModel;
  final String driverName;
  final double driverRating;
  final int driverExperienceYears;
  final String driverPhone;
}

//2.- DashboardCurrentTripService genera datos mockeados reproducibles.
class DashboardCurrentTripService {
  const DashboardCurrentTripService();

  //3.- fetchCurrentTrip deriva un viaje simulado único por rider.
  Future<DashboardCurrentTrip?> fetchCurrentTrip(RiderAccount rider) async {
    final seed = rider.email.hashCode.abs();
    if (seed % 3 == 0) {
      return null;
    }
    return DashboardCurrentTrip(
      passengerName: 'Pasajero ${rider.name.split(' ').first}',
      pickupAddress: 'Av. Reforma #${100 + seed % 50}',
      dropoffAddress: 'Terminal Central ${seed % 7 + 1}',
      status: seed % 2 == 0 ? 'En curso' : 'Recogiendo pasajero',
      vehiclePlate: 'TAX-${seed % 900 + 100}',
      etaMinutes: 5 + seed % 6,
      amount: double.parse((95 + seed % 80 + 0.5).toStringAsFixed(2)),
      durationMinutes: 18 + seed % 15,
      distanceKm: double.parse((6 + seed % 5 + 0.3).toStringAsFixed(1)),
      vehicleModel: seed % 2 == 0 ? 'Sedán Confort' : 'SUV Familiar',
      driverName: 'Conductor ${rider.name.split(' ').last}',
      driverRating: double.parse((4.6 + (seed % 3) * 0.1).toStringAsFixed(1)),
      driverExperienceYears: 3 + seed % 7,
      driverPhone: '+52 55 100${seed % 9000 + 1000}',
    );
  }
}

//4.- dashboardCurrentTripServiceProvider facilita reemplazos durante pruebas.
final dashboardCurrentTripServiceProvider = Provider<DashboardCurrentTripService>((ref) {
  return const DashboardCurrentTripService();
});

//5.- dashboardCurrentTripProvider obtiene el viaje activo del servicio mock.
final dashboardCurrentTripProvider = FutureProvider<DashboardCurrentTrip?>((ref) async {
  final rider = ref.watch(signedInRiderProvider);
  final service = ref.watch(dashboardCurrentTripServiceProvider);
  if (rider == null) {
    throw StateError('Se requiere sesión para consultar el viaje actual.');
  }
  return service.fetchCurrentTrip(rider);
});
