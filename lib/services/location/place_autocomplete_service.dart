import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

import '../../config.dart';
import '../../models/ride_route_models.dart';

//1.- PlaceAutocompleteService encapsula las llamadas al Google Places Autocomplete API.
class PlaceAutocompleteService {
  //2.- _client permite inyectar un cliente HTTP personalizado en pruebas.
  final http.Client _client;

  //3.- _apiKey almacena la llave necesaria para autenticar la petición.
  final String _apiKey;

  PlaceAutocompleteService({http.Client? client, String? apiKey})
      : _client = client ?? http.Client(),
        _apiKey = apiKey ?? AppConfig.googleMapsApiKey;

  //4.- search consulta coincidencias de texto libre en la API de autocompletado.
  Future<List<PlaceSuggestion>> search(String query) async {
    if (_apiKey.isEmpty) {
      return const [];
    }
    final uri = Uri.https('maps.googleapis.com', '/maps/api/place/autocomplete/json', {
      'input': query,
      'key': _apiKey,
      'language': 'en',
    });
    final response = await _client.get(uri);
    if (response.statusCode != 200) {
      throw Exception('Places autocomplete failed');
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final predictions = data['predictions'];
    if (predictions is List) {
      return predictions
          .whereType<Map<String, dynamic>>()
          .map(
            (item) => PlaceSuggestion(
              description: item['description'] as String? ?? 'Unknown place',
              placeId: item['place_id'] as String? ?? '',
            ),
          )
          .where((suggestion) => suggestion.placeId.isNotEmpty)
          .toList();
    }
    return const [];
  }

  //5.- resolveSuggestion obtiene las coordenadas de un lugar seleccionado.
  Future<RideWaypoint?> resolveSuggestion(PlaceSuggestion suggestion) async {
    if (_apiKey.isEmpty) {
      return null;
    }
    final uri = Uri.https('maps.googleapis.com', '/maps/api/place/details/json', {
      'place_id': suggestion.placeId,
      'key': _apiKey,
      'fields': 'geometry/location,name',
    });
    final response = await _client.get(uri);
    if (response.statusCode != 200) {
      return null;
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final result = data['result'];
    if (result is! Map<String, dynamic>) {
      return null;
    }
    final geometry = result['geometry'];
    if (geometry is! Map<String, dynamic>) {
      return null;
    }
    final location = geometry['location'];
    if (location is! Map<String, dynamic>) {
      return null;
    }
    final lat = location['lat'];
    final lng = location['lng'];
    if (lat is! num || lng is! num) {
      return null;
    }
    final description = result['name'] as String? ?? suggestion.description;
    return RideWaypoint(
      placeId: suggestion.placeId,
      description: description,
      location: LatLng(lat.toDouble(), lng.toDouble()),
    );
  }
}

//6.- placeAutocompleteServiceProvider permite inyectar implementaciones falsas en pruebas.
final placeAutocompleteServiceProvider = Provider<PlaceAutocompleteService>((ref) {
  return PlaceAutocompleteService();
});
