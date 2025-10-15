import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:equatable/equatable.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../models/ride_route_models.dart';
import '../services/location/directions_service.dart';
import '../services/location/place_autocomplete_service.dart';

//1.- RideCreationMode define los modos disponibles para iniciar un viaje.
enum RideCreationMode {
  forSelf,
  forOther,
}

//2.- rideCreationModeProvider guarda la selección del modo para compartirla entre pantallas.
final rideCreationModeProvider = StateProvider<RideCreationMode?>((ref) => null);

//3.- RideRouteState encapsula el avance del formulario de origen, destino y rutas sugeridas.
class RideRouteState extends Equatable {
  //4.- origin almacena el punto de partida confirmado por el usuario.
  final RideWaypoint? origin;

  //5.- destination guarda el punto de llegada confirmado por el usuario.
  final RideWaypoint? destination;

  //6.- originSuggestions contiene las coincidencias disponibles para el campo de origen.
  final List<PlaceSuggestion> originSuggestions;

  //7.- destinationSuggestions agrupa las coincidencias para el campo de destino.
  final List<PlaceSuggestion> destinationSuggestions;

  //8.- isLoadingRoutes indica cuándo esperamos respuesta del Directions API.
  final bool isLoadingRoutes;

  //9.- routes expone las alternativas de trayecto calculadas.
  final List<RideRouteOption> routes;

  //10.- selectedRoute señala la opción final elegida para iniciar la subasta.
  final RideRouteOption? selectedRoute;

  //11.- errorMessage muestra fallas en autocompletado o cálculo de rutas.
  final String? errorMessage;

  const RideRouteState({
    this.origin,
    this.destination,
    this.originSuggestions = const [],
    this.destinationSuggestions = const [],
    this.isLoadingRoutes = false,
    this.routes = const [],
    this.selectedRoute,
    this.errorMessage,
  });

  RideRouteState copyWith({
    RideWaypoint? origin,
    RideWaypoint? destination,
    List<PlaceSuggestion>? originSuggestions,
    List<PlaceSuggestion>? destinationSuggestions,
    bool? isLoadingRoutes,
    List<RideRouteOption>? routes,
    RideRouteOption? selectedRoute,
    String? errorMessage,
    bool clearError = false,
    bool clearSelectedRoute = false,
  }) {
    return RideRouteState(
      origin: origin ?? this.origin,
      destination: destination ?? this.destination,
      originSuggestions: originSuggestions ?? this.originSuggestions,
      destinationSuggestions:
          destinationSuggestions ?? this.destinationSuggestions,
      isLoadingRoutes: isLoadingRoutes ?? this.isLoadingRoutes,
      routes: routes ?? this.routes,
      selectedRoute: clearSelectedRoute
          ? null
          : selectedRoute ?? this.selectedRoute,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        origin,
        destination,
        originSuggestions,
        destinationSuggestions,
        isLoadingRoutes,
        routes,
        selectedRoute,
        errorMessage,
      ];
}

//12.- RouteSelectionController coordina autocompletado, rutas y selección final.
class RouteSelectionController extends StateNotifier<RideRouteState> {
  //13.- _places permite consumir el servicio de autocompletado externo.
  final PlaceAutocompleteService _places;

  //14.- _directions interactúa con el Directions API para obtener rutas.
  final DirectionsService _directions;

  RouteSelectionController({
    required PlaceAutocompleteService places,
    required DirectionsService directions,
  })  : _places = places,
        _directions = directions,
        super(const RideRouteState());

  //15.- searchOrigin consulta coincidencias y limpia errores previos.
  Future<void> searchOrigin(String query) async {
    if (query.trim().length < 3) {
      state = state.copyWith(originSuggestions: const []);
      return;
    }
    try {
      final results = await _places.search(query);
      state = state.copyWith(
        originSuggestions: results,
        errorMessage: null,
      );
    } catch (err) {
      state = state.copyWith(
        originSuggestions: const [],
        errorMessage: 'We could not find origin suggestions.',
      );
    }
  }

  //16.- searchDestination opera de forma análoga para el campo de destino.
  Future<void> searchDestination(String query) async {
    if (query.trim().length < 3) {
      state = state.copyWith(destinationSuggestions: const []);
      return;
    }
    try {
      final results = await _places.search(query);
      state = state.copyWith(
        destinationSuggestions: results,
        errorMessage: null,
      );
    } catch (err) {
      state = state.copyWith(
        destinationSuggestions: const [],
        errorMessage: 'We could not find destination suggestions.',
      );
    }
  }

  //17.- selectOrigin fija el punto elegido, elimina sugerencias y reinicia rutas.
  Future<void> selectOrigin(PlaceSuggestion suggestion) async {
    final waypoint = await _places.resolveSuggestion(suggestion);
    if (waypoint == null) {
      state = state.copyWith(
        errorMessage: 'Unable to resolve origin coordinates.',
      );
      return;
    }
    state = state.copyWith(
      origin: waypoint,
      originSuggestions: const [],
      clearSelectedRoute: true,
      routes: const [],
      clearError: true,
    );
    await _refreshRoutesIfReady();
  }

  //18.1.- selectOriginFromMap crea un waypoint directo tomando la coordenada elegida en el mapa.
  Future<void> selectOriginFromMap(LatLng position) async {
    final waypoint = _createMapWaypoint(position, isOrigin: true);
    state = state.copyWith(
      origin: waypoint,
      originSuggestions: const [],
      clearSelectedRoute: true,
      routes: const [],
      clearError: true,
    );
    await _refreshRoutesIfReady();
  }

  //18.- selectDestination actúa igual pero para el punto de llegada.
  Future<void> selectDestination(PlaceSuggestion suggestion) async {
    final waypoint = await _places.resolveSuggestion(suggestion);
    if (waypoint == null) {
      state = state.copyWith(
        errorMessage: 'Unable to resolve destination coordinates.',
      );
      return;
    }
    state = state.copyWith(
      destination: waypoint,
      destinationSuggestions: const [],
      clearSelectedRoute: true,
      routes: const [],
      clearError: true,
    );
    await _refreshRoutesIfReady();
  }

  //18.2.- selectDestinationFromMap replica el flujo anterior pero con coordenadas sin Place ID.
  Future<void> selectDestinationFromMap(LatLng position) async {
    final waypoint = _createMapWaypoint(position, isOrigin: false);
    state = state.copyWith(
      destination: waypoint,
      destinationSuggestions: const [],
      clearSelectedRoute: true,
      routes: const [],
      clearError: true,
    );
    await _refreshRoutesIfReady();
  }

  //19.- clearOrigin restablece el formulario cuando el usuario cambia de opinión.
  void clearOrigin() {
    state = state.copyWith(
      origin: null,
      originSuggestions: const [],
      routes: const [],
      selectedRoute: null,
    );
  }

  //20.- clearDestination remueve la selección previa del destino.
  void clearDestination() {
    state = state.copyWith(
      destination: null,
      destinationSuggestions: const [],
      routes: const [],
      selectedRoute: null,
    );
  }

  //21.- selectRoute persiste la alternativa elegida para arrancar la subasta.
  void selectRoute(RideRouteOption option) {
    state = state.copyWith(selectedRoute: option, clearError: true);
  }

  //21.1.- calculateRoutes permite al usuario detonar manualmente el cálculo del trayecto.
  Future<void> calculateRoutes() async {
    if (state.origin == null || state.destination == null) {
      return;
    }
    await _fetchRoutes();
  }

  //21.2.- _refreshRoutesIfReady invoca Directions API cuando hay origen y destino válidos.
  Future<void> _refreshRoutesIfReady() async {
    if (state.isLoadingRoutes) {
      return;
    }
    final origin = state.origin;
    final destination = state.destination;
    if (origin == null || destination == null) {
      return;
    }
    await _fetchRoutes();
  }

  //22.- _fetchRoutes solicita rutas sólo cuando tenemos ambos waypoints.
  Future<void> _fetchRoutes() async {
    final origin = state.origin;
    final destination = state.destination;
    if (origin == null || destination == null) {
      return;
    }
    state = state.copyWith(isLoadingRoutes: true, clearError: true);
    try {
      final results = await _directions.routesBetween(
        origin.location,
        destination.location,
      );
      final selected = _chooseBestRoute(results);
      state = state.copyWith(
        isLoadingRoutes: false,
        routes: results,
        selectedRoute: selected,
      );
    } catch (err) {
      state = state.copyWith(
        isLoadingRoutes: false,
        routes: const [],
        selectedRoute: null,
        errorMessage: 'Unable to load routes for the selected points.',
      );
    }
  }

  //22.1.- _createMapWaypoint genera una descripción textual para selecciones hechas sobre el mapa.
  RideWaypoint _createMapWaypoint(LatLng position, {required bool isOrigin}) {
    final label = isOrigin ? 'Origen seleccionado' : 'Destino seleccionado';
    final coordinates =
        '(${position.latitude.toStringAsFixed(5)}, ${position.longitude.toStringAsFixed(5)})';
    final idPrefix = isOrigin ? 'origin' : 'destination';
    return RideWaypoint(
      placeId: 'map_${idPrefix}_${position.latitude}_${position.longitude}',
      description: '$label $coordinates',
      location: position,
    );
  }

  RideRouteOption? _chooseBestRoute(List<RideRouteOption> options) {
    //22.2.- _chooseBestRoute selecciona la ruta con menor duración y distancia.
    if (options.isEmpty) {
      return null;
    }
    final sorted = [...options]
      ..sort(
        (a, b) {
          final durationCompare = a.durationSeconds.compareTo(b.durationSeconds);
          if (durationCompare != 0) {
            return durationCompare;
          }
          return a.distanceMeters.compareTo(b.distanceMeters);
        },
      );
    return sorted.first;
  }
}

//23.- routeSelectionControllerProvider expone el controlador a la capa de UI.
final routeSelectionControllerProvider =
    StateNotifierProvider<RouteSelectionController, RideRouteState>((ref) {
  final places = ref.watch(placeAutocompleteServiceProvider);
  final directions = ref.watch(directionsServiceProvider);
  return RouteSelectionController(places: places, directions: directions);
});

//24.- routePolylineProvider genera las polilíneas para el mapa a partir de la ruta elegida.
final routePolylineProvider = Provider<List<LatLng>>((ref) {
  final route = ref.watch(routeSelectionControllerProvider).selectedRoute;
  if (route == null) {
    return const [];
  }
  return DirectionsService.decodePolyline(route.polyline);
});
