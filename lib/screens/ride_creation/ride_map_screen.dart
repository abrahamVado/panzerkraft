import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../providers/ride_creation_providers.dart';
import '../../services/location/ride_location_service.dart';

//1.- Claves globales para acceder a los elementos principales durante las pruebas de widgets.
const rideMapPermissionMessageKey = Key('ride_map_permission_message');
const rideMapMenuButtonKey = Key('ride_map_menu_button');
const rideMapModeForSelfKey = Key('ride_map_mode_for_self');
const rideMapModeForOtherKey = Key('ride_map_mode_for_other');

//2.- RideMapScreen muestra el mapa centrado en la ubicación del rider y permite elegir el modo de viaje.
class RideMapScreen extends ConsumerStatefulWidget {
  const RideMapScreen({super.key});

  @override
  ConsumerState<RideMapScreen> createState() => _RideMapScreenState();
}

class _RideMapScreenState extends ConsumerState<RideMapScreen> {
  static const CameraPosition _defaultCamera = CameraPosition(
    target: LatLng(19.4326, -99.1332),
    zoom: 12,
  );

  static const double _targetZoom = 16;

  final Completer<GoogleMapController> _controller = Completer<GoogleMapController>();
  LatLng? _currentTarget;
  String? _statusMessage;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    //3.- initState dispara la carga inicial de la ubicación GPS.
    scheduleMicrotask(_resolveLocation);
  }

  Future<void> _resolveLocation() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Obteniendo tu ubicación actual...';
    });

    final service = ref.read(rideLocationServiceProvider);
    final result = await service.fetchCurrentLocation();
    if (!mounted) return;

    switch (result.status) {
      case RideLocationStatus.success:
        setState(() {
          _currentTarget = result.position;
          _statusMessage = null;
          _isLoading = false;
        });
        final controller = await _controller.future;
        if (_currentTarget != null) {
          //4.- Al contar con coordenadas animamos la cámara hacia la posición del rider.
          await controller.animateCamera(
            CameraUpdate.newCameraPosition(
              CameraPosition(target: _currentTarget!, zoom: _targetZoom),
            ),
          );
        }
        break;
      case RideLocationStatus.permissionsDenied:
        setState(() {
          _statusMessage = 'Necesitamos permisos de ubicación para centrar el mapa en ti.';
          _isLoading = false;
        });
        break;
      case RideLocationStatus.servicesDisabled:
        setState(() {
          _statusMessage = 'Activa el GPS para localizarte automáticamente.';
          _isLoading = false;
        });
        break;
      case RideLocationStatus.failure:
        setState(() {
          _statusMessage = 'No pudimos determinar tu ubicación actual.';
          _isLoading = false;
        });
        break;
    }
  }

  void _showModeMenu() {
    //5.- Mostramos un menú inferior para elegir a quién pertenece el viaje.
    showModalBottomSheet<void>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FilledButton(
                  key: rideMapModeForSelfKey,
                  onPressed: () => _selectMode(RideCreationMode.forSelf),
                  child: const Text('Create a ride for me'),
                ),
                const SizedBox(height: 12),
                FilledButton.tonal(
                  key: rideMapModeForOtherKey,
                  onPressed: () => _selectMode(RideCreationMode.forOther),
                  child: const Text('Create a ride for someone else'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _selectMode(RideCreationMode mode) {
    //6.- Guardamos la elección en el estado compartido y cerramos el menú.
    ref.read(rideCreationModeProvider.notifier).state = mode;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          mode == RideCreationMode.forSelf
              ? 'Prepararemos tu viaje personal.'
              : 'Prepararemos un viaje para otra persona.',
        ),
      ),
    );
  }

  void _onMapCreated(GoogleMapController controller) {
    //7.- Completer permite reutilizar el controlador para animar la cámara tras cargar la ubicación.
    if (!_controller.isCompleted) {
      _controller.complete(controller);
    }
  }

  @override
  Widget build(BuildContext context) {
    //8.- La pantalla combina el mapa con mensajes de permiso y un botón flotante contextual.
    return Scaffold(
      appBar: AppBar(title: const Text('Elige el punto de partida')),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: _defaultCamera,
            myLocationEnabled: _currentTarget != null,
            onMapCreated: _onMapCreated,
          ),
          if (_statusMessage != null)
            Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Material(
                  elevation: 4,
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_isLoading) const CircularProgressIndicator(),
                        if (_isLoading) const SizedBox(width: 12),
                        Flexible(
                          child: Text(
                            _statusMessage!,
                            key: rideMapPermissionMessageKey,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: rideMapMenuButtonKey,
        onPressed: _showModeMenu,
        icon: const Icon(Icons.directions_car),
        label: const Text('Crear viaje'),
      ),
    );
  }
}
