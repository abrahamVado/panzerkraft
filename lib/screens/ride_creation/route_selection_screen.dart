import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../models/ride_route_models.dart';
import '../../providers/ride_creation_providers.dart';
import '../../router/app_router.dart';

//1.- Claves globales para facilitar la interacción en pruebas automatizadas.
const routeSelectionOriginFieldKey = Key('route_selection_origin_field');
const routeSelectionDestinationFieldKey = Key('route_selection_destination_field');
const routeSelectionStartButtonKey = Key('route_selection_start_button');
const routeSelectionMapKey = Key('route_selection_map');

//2.- RouteSelectionScreen gestiona el formulario previo a lanzar la subasta de viaje.
class RouteSelectionScreen extends ConsumerStatefulWidget {
  //3.- mapBuilder permite inyectar un mapa simulado durante pruebas de widgets.
  final Widget Function(BuildContext context, Set<Marker> markers,
      Set<Polyline> polylines)? mapBuilder;

  const RouteSelectionScreen({super.key, this.mapBuilder});

  @override
  ConsumerState<RouteSelectionScreen> createState() => _RouteSelectionScreenState();
}

class _RouteSelectionScreenState extends ConsumerState<RouteSelectionScreen> {
  late final ProviderSubscription<RideRouteState> _subscription;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _originController = TextEditingController();
  final TextEditingController _destinationController = TextEditingController();
  Timer? _originDebounce;
  Timer? _destinationDebounce;

  @override
  void initState() {
    super.initState();
    //4.- Escuchamos cambios para sincronizar los campos con la selección final.
    _subscription = ref.listen<RideRouteState>(
      routeSelectionControllerProvider,
      (previous, next) {
        if (previous?.origin != next.origin) {
          if (next.origin == null) {
            _originController.clear();
          } else {
            _originController.text = next.origin!.description;
          }
        }
        if (previous?.destination != next.destination) {
          if (next.destination == null) {
            _destinationController.clear();
          } else {
            _destinationController.text = next.destination!.description;
          }
        }
      },
    );
  }

  @override
  void dispose() {
    //5.- Liberamos controladores, temporizadores y la suscripción de Riverpod.
    _originDebounce?.cancel();
    _destinationDebounce?.cancel();
    _originController.dispose();
    _destinationController.dispose();
    _subscription.close();
    super.dispose();
  }

  void _onOriginChanged(String value) {
    //6.- Utilizamos un debounce ligero para reducir llamadas a la API de sugerencias.
    _originDebounce?.cancel();
    _originDebounce = Timer(const Duration(milliseconds: 350), () {
      ref.read(routeSelectionControllerProvider.notifier).searchOrigin(value);
    });
  }

  void _onDestinationChanged(String value) {
    //7.- Repetimos el mismo enfoque para el campo de destino.
    _destinationDebounce?.cancel();
    _destinationDebounce = Timer(const Duration(milliseconds: 350), () {
      ref
          .read(routeSelectionControllerProvider.notifier)
          .searchDestination(value);
    });
  }

  void _selectOrigin(PlaceSuggestion suggestion) {
    //8.- Al tocar una sugerencia fijamos el valor y lanzamos la resolución de coordenadas.
    ref.read(routeSelectionControllerProvider.notifier).selectOrigin(suggestion);
    FocusScope.of(context).unfocus();
  }

  void _selectDestination(PlaceSuggestion suggestion) {
    //9.- Igual que con origen, resolvemos las coordenadas del destino.
    ref
        .read(routeSelectionControllerProvider.notifier)
        .selectDestination(suggestion);
    FocusScope.of(context).unfocus();
  }

  void _startAuction() {
    //10.- Validamos los campos y mostramos un mensaje provisional.
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final state = ref.read(routeSelectionControllerProvider);
    if (state.selectedRoute == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a route to continue.')),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Route stored. Proceed to auction.')),
    );
    context.pushNamed(AppRoute.auction.name);
  }

  Widget _buildSuggestionList(
    List<PlaceSuggestion> suggestions,
    void Function(PlaceSuggestion suggestion) onTap,
  ) {
    //11.- Renderizamos las coincidencias bajo el campo activo en forma de lista táctil.
    if (suggestions.isEmpty) {
      return const SizedBox.shrink();
    }
    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(12),
      child: ListView.separated(
        shrinkWrap: true,
        itemCount: suggestions.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final suggestion = suggestions[index];
          return ListTile(
            title: Text(suggestion.description),
            onTap: () => onTap(suggestion),
          );
        },
      ),
    );
  }

  Set<Polyline> _buildPolylines(RideRouteState state) {
    //12.- Convertimos las rutas sugeridas en polilíneas coloreadas para el mapa.
    final Set<Polyline> polylines = {};
    for (var i = 0; i < state.routes.length; i++) {
      final route = state.routes[i];
      final points = DirectionsService.decodePolyline(route.polyline);
      if (points.isEmpty) continue;
      polylines.add(
        Polyline(
          polylineId: PolylineId('route_$i'),
          points: points,
          color: route == state.selectedRoute
              ? Colors.blueAccent
              : Colors.grey,
          width: route == state.selectedRoute ? 6 : 4,
        ),
      );
    }
    return polylines;
  }

  Set<Marker> _buildMarkers(RideRouteState state) {
    //13.- Creamos marcadores para origen y destino cuando existen selecciones válidas.
    final Set<Marker> markers = {};
    final origin = state.origin;
    if (origin != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('origin'),
          position: origin.location,
          infoWindow: InfoWindow(title: origin.description),
        ),
      );
    }
    final destination = state.destination;
    if (destination != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('destination'),
          position: destination.location,
          infoWindow: InfoWindow(title: destination.description),
        ),
      );
    }
    return markers;
  }

  Widget _buildMap(Set<Marker> markers, Set<Polyline> polylines) {
    //14.- Permitimos reemplazar el mapa real por un contenedor simulado en pruebas.
    if (widget.mapBuilder != null) {
      return widget.mapBuilder!(context, markers, polylines);
    }
    return GoogleMap(
      key: routeSelectionMapKey,
      initialCameraPosition: const CameraPosition(
        target: LatLng(19.432608, -99.133209),
        zoom: 11,
      ),
      markers: markers,
      polylines: polylines,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    //15.- Construimos la UI principal y respondemos a cambios del estado global.
    final theme = Theme.of(context);
    final state = ref.watch(routeSelectionControllerProvider);
    final markers = _buildMarkers(state);
    final polylines = _buildPolylines(state);

    return Scaffold(
      appBar: AppBar(title: const Text('Choose your route')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  key: routeSelectionOriginFieldKey,
                  controller: _originController,
                  decoration: InputDecoration(
                    labelText: 'Origin',
                    suffixIcon: IconButton(
                      onPressed: () =>
                          ref.read(routeSelectionControllerProvider.notifier).clearOrigin(),
                      icon: const Icon(Icons.clear),
                    ),
                  ),
                  onChanged: _onOriginChanged,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Select an origin';
                    }
                    if (state.origin == null) {
                      return 'Pick one of the suggestions';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                _buildSuggestionList(state.originSuggestions, _selectOrigin),
                const SizedBox(height: 16),
                TextFormField(
                  key: routeSelectionDestinationFieldKey,
                  controller: _destinationController,
                  decoration: InputDecoration(
                    labelText: 'Destination',
                    suffixIcon: IconButton(
                      onPressed: () => ref
                          .read(routeSelectionControllerProvider.notifier)
                          .clearDestination(),
                      icon: const Icon(Icons.clear),
                    ),
                  ),
                  onChanged: _onDestinationChanged,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Select a destination';
                    }
                    if (state.destination == null) {
                      return 'Pick one of the suggestions';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                _buildSuggestionList(state.destinationSuggestions, _selectDestination),
                const SizedBox(height: 16),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: _buildMap(markers, polylines),
                  ),
                ),
                const SizedBox(height: 16),
                if (state.isLoadingRoutes)
                  const LinearProgressIndicator(),
                if (state.errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      state.errorMessage!,
                      style: theme.textTheme.bodyMedium?.copyWith(color: Colors.red),
                    ),
                  ),
                const SizedBox(height: 16),
                Text(
                  'Route options',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                ...[
                  for (var i = 0; i < state.routes.length; i++)
                    Card(
                      child: ListTile(
                        key: Key('route_option_$i'),
                        title: Text(state.routes[i].summary),
                        subtitle: Text(
                          _formatRouteMetadata(state.routes[i]),
                        ),
                        trailing: state.selectedRoute == state.routes[i]
                            ? const Icon(Icons.check_circle, color: Colors.green)
                            : null,
                        onTap: () => ref
                            .read(routeSelectionControllerProvider.notifier)
                            .selectRoute(state.routes[i]),
                      ),
                    ),
                ],
                FilledButton(
                  key: routeSelectionStartButtonKey,
                  onPressed: state.origin != null &&
                          state.destination != null &&
                          state.selectedRoute != null
                      ? _startAuction
                      : null,
                  child: const Text('Start auction'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatRouteMetadata(RideRouteOption option) {
    //16.- Convertimos distancia y duración en etiquetas amigables para el usuario.
    final distanceKm = option.distanceMeters / 1000;
    final durationMinutes = (option.durationSeconds / 60).round();
    final distanceText = distanceKm >= 1
        ? '${distanceKm.toStringAsFixed(1)} km'
        : '${option.distanceMeters} m';
    return '$distanceText · ${durationMinutes} min';
  }
}
