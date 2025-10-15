import 'package:flutter_test/flutter_test.dart';

import 'package:ubberapp/screens/dashboard/travel/travel_history_screen.dart';
import 'package:ubberapp/services/dashboard/dashboard_travel_history_service.dart';

void main() {
  //1.- Grupo de pruebas para garantizar la selección consistente de miniaturas.
  group('TravelHistoryThumbnailResolver', () {
    test('elige determinísticamente una imagen entre las disponibles', () {
      final resolver = TravelHistoryThumbnailResolver();
      const entry = TravelHistoryEntry(
        date: DateTime(2024, 7, 10),
        origin: 'Origen Central',
        destination: 'Destino Norte',
        fare: 120.75,
        distanceKm: 8.4,
        durationMinutes: 17,
      );

      final asset = resolver.assetForEntry(entry);

      expect(travelHistoryVehicleThumbnails, contains(asset));
      expect(resolver.assetForEntry(entry), asset);
    });

    test('usa el recurso por defecto si no hay imágenes personalizadas', () {
      final resolver = TravelHistoryThumbnailResolver(vehicleAssets: []);
      const entry = TravelHistoryEntry(
        date: DateTime(2024, 1, 5),
        origin: 'Base',
        destination: 'Destino',
        fare: 88.0,
        distanceKm: 5.0,
        durationMinutes: 12,
      );

      final asset = resolver.assetForEntry(entry);

      expect(asset, travelHistoryThumbnailAsset);
    });

    test('diferentes viajes pueden mapear a imágenes distintas', () {
      final resolver = TravelHistoryThumbnailResolver();
      const firstEntry = TravelHistoryEntry(
        date: DateTime(2024, 5, 2),
        origin: 'Centro',
        destination: 'Playa',
        fare: 95.50,
        distanceKm: 12.2,
        durationMinutes: 23,
      );
      const secondEntry = TravelHistoryEntry(
        date: DateTime(2024, 5, 3),
        origin: 'Centro',
        destination: 'Bosque',
        fare: 110.80,
        distanceKm: 9.6,
        durationMinutes: 19,
      );

      final firstAsset = resolver.assetForEntry(firstEntry);
      final secondAsset = resolver.assetForEntry(secondEntry);

      expect(travelHistoryVehicleThumbnails, contains(firstAsset));
      expect(travelHistoryVehicleThumbnails, contains(secondAsset));
      expect(firstAsset, isNot(equals(secondAsset)));
    });

    test('ignora rutas vacías y conserva el fallback cuando es necesario', () {
      //4.- Preparamos un resolver con rutas vacías para verificar que se ignore ruido.
      final resolver = TravelHistoryThumbnailResolver(
        vehicleAssets: ['   ', '', travelHistoryThumbnailAsset],
      );
      const entry = TravelHistoryEntry(
        date: DateTime(2024, 8, 21),
        origin: 'Centro',
        destination: 'Sur',
        fare: 50,
        distanceKm: 3.4,
        durationMinutes: 9,
      );

      final asset = resolver.assetForEntry(entry);

      expect(asset, travelHistoryThumbnailAsset);
    });
  });
}
