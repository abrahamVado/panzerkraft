import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import 'travel_controller.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _controller;
  LatLng? _lastCameraTarget;

  @override
  void initState() {
    super.initState();
    //1.- Load the user position once the widget has been inserted in the tree.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TravelController>().loadUserLocation();
    });
  }

  @override
  Widget build(BuildContext context) {
    //1.- Listen to travel updates to render markers, polylines, and toggles.
    final travel = context.watch<TravelController>();
    final userLocation = travel.userLocation ?? const LatLng(19.4326, -99.1332);
    final markers = <Marker>{
      if (travel.request != null)
        Marker(
          markerId: const MarkerId('start'),
          position: travel.request!.start.location,
          infoWindow: InfoWindow(title: travel.request!.start.title),
        ),
      if (travel.request != null)
        Marker(
          markerId: const MarkerId('end'),
          position: travel.request!.end.location,
          infoWindow: InfoWindow(title: travel.request!.end.title),
        ),
    };
    final polylines = <Polyline>{
      if (travel.request != null)
        Polyline(
          polylineId: const PolylineId('route'),
          color: Theme.of(context).colorScheme.primary,
          width: 5,
          points: travel.request!.routePolyline,
        ),
    };
    //2.- Keep the camera synced with the latest user location.
    if (_controller != null &&
        travel.userLocation != null &&
        _lastCameraTarget != travel.userLocation) {
      _lastCameraTarget = travel.userLocation;
      _controller!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: travel.userLocation!, zoom: 18),
        ),
      );
    }

    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: CameraPosition(target: userLocation, zoom: 16),
          myLocationEnabled: true,
          myLocationButtonEnabled: false,
          markers: markers,
          polylines: polylines,
          onMapCreated: (controller) {
            //3.- Remember the map controller to adjust zoom preferences later.
            _controller = controller;
            _controller?.setMapStyle(null);
            _controller?.moveCamera(CameraUpdate.newCameraPosition(
                CameraPosition(target: userLocation, zoom: 18)));
            _lastCameraTarget = userLocation;
          },
        ),
        Positioned(
          right: 16,
          top: 16,
          child: _RideModeToggle(
            rideForSelf: travel.rideForSelf,
            onChanged: travel.toggleRideForSelf,
          ),
        ),
      ],
    );
  }
}

class _RideModeToggle extends StatelessWidget {
  const _RideModeToggle({required this.rideForSelf, required this.onChanged});

  final bool rideForSelf;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    //1.- Render the floating menu between "for me" and "for someone else".
    return Material(
      elevation: 6,
      borderRadius: BorderRadius.circular(20),
      color: Theme.of(context).colorScheme.surface,
      child: ToggleButtons(
        isSelected: [rideForSelf, !rideForSelf],
        borderRadius: BorderRadius.circular(20),
        onPressed: (index) => onChanged(index == 0),
        children: const [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Text('Ride for me'),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Text('Ride for someone else'),
          ),
        ],
      ),
    );
  }
}
