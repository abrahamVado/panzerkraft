import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:ubberapp/models/ride_route_models.dart';
import 'package:ubberapp/providers/ride_creation_providers.dart';
import 'package:ubberapp/services/location/directions_service.dart';
import 'package:ubberapp/services/location/place_autocomplete_service.dart';

//1.- _FakePlaceAutocompleteService evita llamadas reales y mantiene la API del servicio.
class _FakePlaceAutocompleteService extends PlaceAutocompleteService {
  _FakePlaceAutocompleteService() : super(apiKey: 'test');

  @override
  Future<List<PlaceSuggestion>> search(String query) async => const [];

  @override
  Future<RideWaypoint?> resolveSuggestion(PlaceSuggestion suggestion) async =>
      null;
}

//2.- _FakeDirectionsService registra los parámetros recibidos y retorna rutas simuladas.
class _FakeDirectionsService extends DirectionsService {
  LatLng? lastOrigin;
  LatLng? lastDestination;
  final List<RideRouteOption> routesToReturn;

  _FakeDirectionsService({this.routesToReturn = const []}) : super(apiKey: 'test');

  @override
  Future<List<RideRouteOption>> routesBetween(
    LatLng origin,
    LatLng destination,
  ) async {
    lastOrigin = origin;
    lastDestination = destination;
    return routesToReturn;
  }
}

void main() {
  //3.- group organiza las pruebas del controlador que maneja la selección de rutas.
  group('RouteSelectionController map selection', () {
    //4.- El controlador debe crear un waypoint válido cuando se elige un origen en el mapa.
    test('selectOriginFromMap builds waypoint with map identifier', () async {
      final directions = _FakeDirectionsService();
      final controller = RouteSelectionController(
        places: _FakePlaceAutocompleteService(),
        directions: directions,
      );
      final position = const LatLng(19.432608, -99.133209);

      await controller.selectOriginFromMap(position);

      final origin = controller.state.origin;
      expect(origin, isNotNull);
      expect(
        origin!.placeId,
        'map_origin_${position.latitude}_${position.longitude}',
      );
      expect(origin.description, contains('Origen seleccionado'));
      expect(origin.location, position);
      expect(directions.lastOrigin, isNull);
      expect(controller.state.routes, isEmpty);
    });

    //5.- Cuando origen y destino provienen del mapa, la app calcula la ruta bajo demanda.
    test('calculateRoutes fetches directions after selecting both waypoints', () async {
      final expectedRoutes = [
        const RideRouteOption(
          id: 'route-1',
          polyline: 'abc',
          distanceMeters: 1000,
          durationSeconds: 600,
          summary: 'Main Ave',
        ),
      ];
      final directions = _FakeDirectionsService(routesToReturn: expectedRoutes);
      final controller = RouteSelectionController(
        places: _FakePlaceAutocompleteService(),
        directions: directions,
      );
      final origin = const LatLng(40.416775, -3.70379);
      final destination = const LatLng(41.385064, 2.173404);

      await controller.selectOriginFromMap(origin);
      await controller.selectDestinationFromMap(destination);

      expect(directions.lastOrigin, isNull);
      expect(controller.state.routes, isEmpty);

      await controller.calculateRoutes();

      expect(directions.lastOrigin, origin);
      expect(directions.lastDestination, destination);
      expect(controller.state.routes, expectedRoutes);
      expect(controller.state.isLoadingRoutes, isFalse);
      expect(controller.state.selectedRoute, expectedRoutes.first);
    });

    //6.- El controlador debe elegir automáticamente la ruta más rápida entre opciones.
    test('auto select fastest route when multiple options', () async {
      final fastRoute = const RideRouteOption(
        id: 'fast',
        polyline: 'abc',
        distanceMeters: 1500,
        durationSeconds: 600,
        summary: 'Fast Lane',
      );
      final scenicRoute = const RideRouteOption(
        id: 'scenic',
        polyline: 'def',
        distanceMeters: 1300,
        durationSeconds: 620,
        summary: 'Scenic',
      );
      final directions =
          _FakeDirectionsService(routesToReturn: [scenicRoute, fastRoute]);
      final controller = RouteSelectionController(
        places: _FakePlaceAutocompleteService(),
        directions: directions,
      );
      final origin = const LatLng(10, 10);
      final destination = const LatLng(11, 11);

      await controller.selectOriginFromMap(origin);
      await controller.selectDestinationFromMap(destination);

      await controller.calculateRoutes();

      expect(controller.state.routes, containsAll([scenicRoute, fastRoute]));
      expect(controller.state.selectedRoute, fastRoute);
    });

    //7.- Cuando ambos puntos están definidos la ruta se calcula automáticamente.
    test('auto refresh routes once origin and destination exist', () async {
      final autoRoute = const RideRouteOption(
        id: 'auto',
        polyline: 'xyz',
        distanceMeters: 4200,
        durationSeconds: 1800,
        summary: 'Direct path',
      );
      final directions = _FakeDirectionsService(routesToReturn: [autoRoute]);
      final controller = RouteSelectionController(
        places: _FakePlaceAutocompleteService(),
        directions: directions,
      );

      const origin = LatLng(48.8566, 2.3522);
      const destination = LatLng(51.5074, -0.1278);

      await controller.selectOriginFromMap(origin);
      expect(controller.state.routes, isEmpty);

      await controller.selectDestinationFromMap(destination);

      expect(directions.lastOrigin, origin);
      expect(directions.lastDestination, destination);
      expect(controller.state.routes, [autoRoute]);
      expect(controller.state.selectedRoute, autoRoute);
      expect(controller.state.isLoadingRoutes, isFalse);
      expect(controller.state.errorMessage, isNull);
    });
  });
}
