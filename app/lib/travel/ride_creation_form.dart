import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import 'models/place_option.dart';
import 'models/ride_request.dart';
import 'places_repository.dart';
import 'travel_controller.dart';

class RideCreationForm extends StatefulWidget {
  const RideCreationForm({super.key});

  @override
  State<RideCreationForm> createState() => _RideCreationFormState();
}

class _RideCreationFormState extends State<RideCreationForm> {
  final PlacesRepository _repository = const PlacesRepository();
  final TextEditingController _startController = TextEditingController();
  final TextEditingController _endController = TextEditingController();
  PlaceOption? _start;
  PlaceOption? _end;
  List<PlaceOption> _startSuggestions = const [];
  List<PlaceOption> _endSuggestions = const [];
  bool _loadingStart = false;
  bool _loadingEnd = false;

  @override
  void dispose() {
    //1.- Clean up controllers because the widget manages their lifecycle.
    _startController.dispose();
    _endController.dispose();
    super.dispose();
  }

  Future<void> _searchStart(String query) async {
    //1.- Request filtered suggestions for the start field.
    setState(() => _loadingStart = true);
    final results = await _repository.search(query);
    setState(() {
      _startSuggestions = results;
      _loadingStart = false;
    });
  }

  Future<void> _searchEnd(String query) async {
    //1.- Request filtered suggestions for the destination field.
    setState(() => _loadingEnd = true);
    final results = await _repository.search(query);
    setState(() {
      _endSuggestions = results;
      _loadingEnd = false;
    });
  }

  void _selectStart(PlaceOption option) {
    //1.- Cache the selection and reflect it on the text input.
    setState(() {
      _start = option;
      _startController.text = option.title;
      _startSuggestions = const [];
    });
  }

  void _selectEnd(PlaceOption option) {
    //1.- Cache the selection and reflect it on the text input.
    setState(() {
      _end = option;
      _endController.text = option.title;
      _endSuggestions = const [];
    });
  }

  Future<void> _planRide() async {
    if (_start == null || _end == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select both start and end locations.')),
      );
      return;
    }
    //1.- Calculate a straight-line distance to estimate fare and travel time.
    final distanceMeters = Geolocator.distanceBetween(
      _start!.location.latitude,
      _start!.location.longitude,
      _end!.location.latitude,
      _end!.location.longitude,
    );
    final distanceKm = (distanceMeters / 1000).clamp(0.1, 45);
    //2.- Build a simple polyline between both points to preview on the map.
    final polyline = <LatLng>[_start!.location, _end!.location];
    final request = RideRequest(
      start: _start!,
      end: _end!,
      rideForSelf: context.read<TravelController>().rideForSelf,
      distanceInKm: double.parse(distanceKm.toStringAsFixed(2)),
      routePolyline: polyline,
    );
    //3.- Update the controller so the dashboard and map reflect the plan.
    context.read<TravelController>().updateRide(request);
  }

  @override
  Widget build(BuildContext context) {
    //1.- React to ride status to show plan summary when available.
    final travel = context.watch<TravelController>();
    final request = travel.request;
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Plan a ride', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            _AutocompleteField(
              label: 'Pickup',
              controller: _startController,
              loading: _loadingStart,
              suggestions: _startSuggestions,
              onChanged: _searchStart,
              onSelected: _selectStart,
            ),
            const SizedBox(height: 12),
            _AutocompleteField(
              label: 'Drop-off',
              controller: _endController,
              loading: _loadingEnd,
              suggestions: _endSuggestions,
              onChanged: _searchEnd,
              onSelected: _selectEnd,
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _planRide,
              child: const Text('Preview route'),
            ),
            if (request != null) ...[
              const SizedBox(height: 16),
              Text('Distance: ${request.distanceInKm.toStringAsFixed(1)} km'),
              Text(
                  'Estimated fare: ${request.estimatedFare.toStringAsFixed(2)} MXN'),
              Text(
                  'Mode: ${request.rideForSelf ? 'Ride for me' : 'Ride for someone else'}'),
            ],
          ],
        ),
      ),
    );
  }
}

class _AutocompleteField extends StatelessWidget {
  const _AutocompleteField({
    required this.label,
    required this.controller,
    required this.loading,
    required this.suggestions,
    required this.onChanged,
    required this.onSelected,
  });

  final String label;
  final TextEditingController controller;
  final bool loading;
  final List<PlaceOption> suggestions;
  final ValueChanged<String> onChanged;
  final ValueChanged<PlaceOption> onSelected;

  @override
  Widget build(BuildContext context) {
    //1.- Compose the text field with a trailing suggestion list.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: label,
            suffixIcon: loading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: Padding(
                      padding: EdgeInsets.all(4),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : null,
          ),
          onChanged: onChanged,
        ),
        if (suggestions.isNotEmpty)
          Card(
            margin: const EdgeInsets.only(top: 8),
            child: Column(
              children: suggestions
                  .map(
                    (option) => ListTile(
                      title: Text(option.title),
                      subtitle: Text(option.subtitle),
                      onTap: () => onSelected(option),
                    ),
                  )
                  .toList(),
            ),
          ),
      ],
    );
  }
}
