import 'package:flutter_riverpod/flutter_riverpod.dart';

//1.- RideCreationMode define los modos disponibles para iniciar un viaje.
enum RideCreationMode {
  forSelf,
  forOther,
}

//2.- rideCreationModeProvider guarda la selección del modo para compartirla entre pantallas.
final rideCreationModeProvider = StateProvider<RideCreationMode?>((ref) => null);
