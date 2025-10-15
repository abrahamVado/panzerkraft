import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../models/ride_route_models.dart';
import '../../providers/ride_creation_providers.dart';
import '../../router/app_router.dart';
import '../../services/location/directions_service.dart';
import '../../services/location/ride_location_service.dart';

//1.- Claves globales para facilitar la interacción en pruebas automatizadas.
const routeSelectionOriginFieldKey = Key('route_selection_origin_field');
const routeSelectionDestinationFieldKey = Key(
  'route_selection_destination_field',
);
const routeSelectionStartButtonKey = Key('route_selection_start_button');
const routeSelectionMapKey = Key('route_selection_map');
const routeSelectionCalculateButtonKey = Key('route_selection_calculate_button');
const routeSelectionUseDemoButtonKey = Key('route_selection_use_demo_button');

//3.1.- _ActiveRouteField identifica el campo actualmente interactivo para rellenar con el mapa.
enum _ActiveRouteField { origin, destination }

//2.- RouteSelectionScreen gestiona el formulario previo a lanzar la subasta de viaje.
class RouteSelectionScreen extends ConsumerStatefulWidget {
  //3.- mapBuilder permite inyectar un mapa simulado durante pruebas de widgets.
  final Widget Function(
    BuildContext context,
    Set<Marker> markers,
    Set<Polyline> polylines,
    void Function(LatLng position) onTap,
  )?
  mapBuilder;

  const RouteSelectionScreen({super.key, this.mapBuilder});

  @override
  ConsumerState<RouteSelectionScreen> createState() =>
      _RouteSelectionScreenState();
}

class _RouteSelectionScreenState extends ConsumerState<RouteSelectionScreen> {
  late final ProviderSubscription<RideRouteState> _subscription;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _originController = TextEditingController();
  final TextEditingController _destinationController = TextEditingController();
  late final FocusNode _originFocusNode;
  late final FocusNode _destinationFocusNode;
  Timer? _originDebounce;
  Timer? _destinationDebounce;
  _ActiveRouteField _activeField = _ActiveRouteField.origin;
  GoogleMapController? _mapController;
  LatLng? _currentLocation;
  bool _isResolvingLocation = false;

  @override
  void initState() {
    super.initState();
    //4.- Escuchamos cambios para sincronizar los campos con la selección final.
    _subscription = ref.listenManual<RideRouteState>(
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
    _originFocusNode = FocusNode();
    _destinationFocusNode = FocusNode();
    _originFocusNode.addListener(_onOriginFocusChanged);
    _destinationFocusNode.addListener(_onDestinationFocusChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _originFocusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    //5.- Liberamos controladores, temporizadores y la suscripción de Riverpod.
    _originDebounce?.cancel();
    _destinationDebounce?.cancel();
    _originController.dispose();
    _destinationController.dispose();
    _originFocusNode.removeListener(_onOriginFocusChanged);
    _destinationFocusNode.removeListener(_onDestinationFocusChanged);
    _originFocusNode.dispose();
    _destinationFocusNode.dispose();
    final controller = _mapController;
    if (controller != null) {
      unawaited(controller.dispose());
    }
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

  void _onOriginFocusChanged() {
    if (_originFocusNode.hasFocus) {
      setState(() => _activeField = _ActiveRouteField.origin);
    }
  }

  void _onDestinationFocusChanged() {
    if (_destinationFocusNode.hasFocus) {
      setState(() => _activeField = _ActiveRouteField.destination);
    }
  }

  void _selectOrigin(PlaceSuggestion suggestion) {
    //8.- Al tocar una sugerencia fijamos el valor y lanzamos la resolución de coordenadas.
    ref
        .read(routeSelectionControllerProvider.notifier)
        .selectOrigin(suggestion);
    FocusScope.of(context).unfocus();
  }

  void _selectDestination(PlaceSuggestion suggestion) {
    //9.- Igual que con origen, resolvemos las coordenadas del destino.
    ref
        .read(routeSelectionControllerProvider.notifier)
        .selectDestination(suggestion);
    FocusScope.of(context).unfocus();
  }

  void _handleMapTap(LatLng position) {
    //9.1.- _handleMapTap asigna el punto tocado según el campo activo o disponible.
    final notifier = ref.read(routeSelectionControllerProvider.notifier);
    switch (_activeField) {
      case _ActiveRouteField.origin:
        notifier.selectOriginFromMap(position);
        _destinationFocusNode.requestFocus();
        setState(() => _activeField = _ActiveRouteField.destination);
        break;
      case _ActiveRouteField.destination:
        notifier.selectDestinationFromMap(position);
        FocusScope.of(context).unfocus();
        break;
    }
  }

  Future<void> _calculateRoutes() async {
    //9.2.- _calculateRoutes delega al controlador para generar polilíneas bajo demanda.
    await ref.read(routeSelectionControllerProvider.notifier).calculateRoutes();
  }

  Future<void> _useDemoRoute() async {
    //9.3.- _useDemoRoute aplica el ejemplo público del Directions API para rellenar ambos campos.
    FocusScope.of(context).unfocus();
    await ref
        .read(routeSelectionControllerProvider.notifier)
        .useHistoricCenterToTeotihuacanDemoRoute();
  }

  Future<void> _resolveLocationAndCalculate() async {
    //9.4.- _resolveLocationAndCalculate obtiene la ubicación actual antes de lanzar el cálculo.
    if (_isResolvingLocation) {
      return;
    }
    setState(() => _isResolvingLocation = true);
    FocusScope.of(context).unfocus();

    final locationService = ref.read(rideLocationServiceProvider);
    final locationResult = await locationService.fetchCurrentLocation();
    if (!mounted) {
      return;
    }

    if (locationResult.status == RideLocationStatus.success &&
        locationResult.position != null) {
      setState(() => _currentLocation = locationResult.position);
      if (_mapController != null) {
        await _mapController!.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(target: _currentLocation!, zoom: 14),
          ),
        );
      }
      final notifier = ref.read(routeSelectionControllerProvider.notifier);
      final state = ref.read(routeSelectionControllerProvider);
      if (state.origin == null) {
        await notifier.selectOriginFromMap(locationResult.position!);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_mapLocationErrorMessage(locationResult.status)),
        ),
      );
    }

    final updatedState = ref.read(routeSelectionControllerProvider);
    if (updatedState.origin == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select an origin before calculating.')),
      );
      if (mounted) {
        setState(() => _isResolvingLocation = false);
      }
      return;
    }
    if (updatedState.destination == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a destination before calculating.')),
      );
      if (mounted) {
        setState(() => _isResolvingLocation = false);
      }
      return;
    }

    await _calculateRoutes();
    if (mounted) {
      setState(() => _isResolvingLocation = false);
    }
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
      final isSelected = route == state.selectedRoute; //12.1.- La ruta activa recibe estilo destacado.
      polylines.add(
        Polyline(
          polylineId: PolylineId('route_$i'),
          points: points,
          color: isSelected ? Colors.blueAccent : Colors.grey,
          width: isSelected ? 6 : 4,
          zIndex: isSelected ? 1 : 0,
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
      return widget.mapBuilder!(context, markers, polylines, _handleMapTap);
    }
    return GoogleMap(
      key: routeSelectionMapKey,
      initialCameraPosition: const CameraPosition(
        target: LatLng(19.432608, -99.133209),
        zoom: 11,
      ),
      onMapCreated: (controller) {
        //14.1.- Guardamos el controlador para animar la cámara tras resolver la ubicación.
        _mapController ??= controller;
        if (_currentLocation != null) {
          controller.moveCamera(
            CameraUpdate.newLatLngZoom(_currentLocation!, 14),
          );
        }
      },
      markers: markers,
      polylines: polylines,
      myLocationEnabled: _currentLocation != null,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      onTap: _handleMapTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    //15.- Construimos la UI principal y respondemos a cambios del estado global.
    final theme = Theme.of(context);
    final state = ref.watch(routeSelectionControllerProvider);
    final markers = _buildMarkers(state);
    final polylines = _buildPolylines(state);
    final selectedRoute = state.selectedRoute;

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
                  focusNode: _originFocusNode,
                  decoration: InputDecoration(
                    labelText: 'Origin',
                    suffixIcon: IconButton(
                      onPressed: () => ref
                          .read(routeSelectionControllerProvider.notifier)
                          .clearOrigin(),
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
                  focusNode: _destinationFocusNode,
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
                _buildSuggestionList(
                  state.destinationSuggestions,
                  _selectDestination,
                ),
                const SizedBox(height: 12),
                Text(
                  'Consejo: toca el mapa mientras el campo deseado esté enfocado para rellenarlo automáticamente.',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                //15.1.- Ofrecemos un botón que carga el ejemplo con coordenadas reales.
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    key: routeSelectionUseDemoButtonKey,
                    onPressed:
                        state.isLoadingRoutes ? null : () => _useDemoRoute(),
                    icon: const Icon(Icons.map_outlined),
                    label: const Text('Use Mexico City → Teotihuacán example'),
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Stack(
                      children: [
                        _buildMap(markers, polylines),
                        if (selectedRoute != null)
                          Positioned(
                            top: 12,
                            left: 12,
                            right: 12,
                            child: _RouteSummaryBanner(
                              route: selectedRoute,
                              origin: state.origin,
                              destination: state.destination,
                              summaryLabel: _formatRouteMetadata(selectedRoute),
                            ),
                          ),
                        Positioned(
                          right: 16,
                          bottom: 16,
                          child: FloatingActionButton.extended(
                            key: routeSelectionCalculateButtonKey,
                            onPressed: state.isLoadingRoutes || _isResolvingLocation
                                ? null
                                : () => _resolveLocationAndCalculate(),
                            label: const Text('Calculate distance and minimum bid'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (state.isLoadingRoutes) const LinearProgressIndicator(),
                if (state.errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      state.errorMessage!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.red,
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                Text('Route options', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                ...[
                  for (var i = 0; i < state.routes.length; i++)
                    Card(
                      child: ListTile(
                        key: Key('route_option_$i'),
                        title: Text(state.routes[i].summary),
                        subtitle: Text(_formatRouteMetadata(state.routes[i])),
                        trailing: state.selectedRoute == state.routes[i]
                            ? const Icon(
                                Icons.check_circle,
                                color: Colors.green,
                              )
                            : null,
                        onTap: () => ref
                            .read(routeSelectionControllerProvider.notifier)
                            .selectRoute(state.routes[i]),
                      ),
                    ),
                ],
                FilledButton(
                  key: routeSelectionStartButtonKey,
                  onPressed:
                      state.origin != null &&
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
    //16.- Convertimos distancia, duración y hora estimada en texto amigable.
    final distanceKm = option.distanceMeters / 1000;
    final durationMinutes = (option.durationSeconds / 60).round();
    final distanceText = distanceKm >= 1
        ? '${distanceKm.toStringAsFixed(1)} km'
        : '${option.distanceMeters} m';
    final eta = _formatEta(option.durationSeconds);
    return '$distanceText · ${durationMinutes} min · ETA $eta';
  }
}

String _formatEta(int durationSeconds) {
  //17.- _formatEta calcula la hora estimada de llegada con formato HH:mm.
  final arrival = DateTime.now().add(Duration(seconds: durationSeconds));
  final hours = arrival.hour.toString().padLeft(2, '0');
  final minutes = arrival.minute.toString().padLeft(2, '0');
  return '$hours:$minutes';
}

String _mapLocationErrorMessage(RideLocationStatus status) {
  //17.1.- _mapLocationErrorMessage traduce el fallo de GPS a un mensaje para SnackBar.
  switch (status) {
    case RideLocationStatus.permissionsDenied:
      return 'We need location permissions to use your current position.';
    case RideLocationStatus.servicesDisabled:
      return 'Enable GPS services to use your current location.';
    case RideLocationStatus.failure:
      return 'We could not determine your current location.';
    case RideLocationStatus.success:
      return 'Location resolved successfully.';
  }
}

//18.- _RouteSummaryBanner resume distancia y duración sobre el mapa para dos puntos.
class _RouteSummaryBanner extends StatelessWidget {
  const _RouteSummaryBanner({
    required this.route,
    required this.origin,
    required this.destination,
    required this.summaryLabel,
  });

  final RideRouteOption route;
  final RideWaypoint? origin;
  final RideWaypoint? destination;
  final String summaryLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Material(
      elevation: 6,
      borderRadius: BorderRadius.circular(16),
      color: colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.timeline, size: 20),
                const SizedBox(width: 8),
                Text('Viaje estimado', style: theme.textTheme.titleSmall),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Ruta: ${route.summary}',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            Text(
              summaryLabel,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '${origin?.description ?? 'Origen sin nombre'} → ${destination?.description ?? 'Destino sin nombre'}',
              style: theme.textTheme.bodySmall,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
