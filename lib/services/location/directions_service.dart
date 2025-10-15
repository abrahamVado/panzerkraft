import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

import '../../config.dart';
import '../../models/ride_route_models.dart';

//1.- DirectionsService realiza peticiones al Google Directions API para obtener rutas.
class DirectionsService {
  //2.- _client facilita la inyección de clientes simulados durante las pruebas.
  final http.Client _client;

  //3.- _apiKey almacena la credencial de autenticación para la API de rutas.
  final String _apiKey;

  DirectionsService({http.Client? client, String? apiKey})
      : _client = client ?? http.Client(),
        _apiKey = apiKey ?? AppConfig.googleMapsApiKey;

  //4.- routesBetween devuelve una lista de alternativas disponibles entre dos coordenadas.
  Future<List<RideRouteOption>> routesBetween(
    LatLng origin,
    LatLng destination,
  ) async {
    if (_apiKey.isEmpty) {
      return const [];
    }
    final uri = Uri.https('maps.googleapis.com', '/maps/api/directions/json', {
      'origin': '${origin.latitude},${origin.longitude}',
      'destination': '${destination.latitude},${destination.longitude}',
      'key': _apiKey,
      'alternatives': 'true',
    });
    final response = await _client.get(uri);
    if (response.statusCode != 200) {
      throw Exception('Directions request failed');
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final routes = data['routes'];
    if (routes is! List) {
      return const [];
    }
    return routes
        .whereType<Map<String, dynamic>>()
        .map((route) {
          final polyline = (route['overview_polyline'] as Map<String, dynamic>?)?
                  ['points'] as String? ??
              '';
          final summary = route['summary'] as String? ?? 'Unnamed route';
          final legs = route['legs'];
          int distance = 0;
          int duration = 0;
          if (legs is List && legs.isNotEmpty) {
            final firstLeg = legs.first as Map<String, dynamic>;
            final distanceValue =
                (firstLeg['distance'] as Map<String, dynamic>?)?['value'];
            final durationValue =
                (firstLeg['duration'] as Map<String, dynamic>?)?['value'];
            if (distanceValue is num) {
              distance = distanceValue.round();
            }
            if (durationValue is num) {
              duration = durationValue.round();
            }
          }
          return RideRouteOption(
            id: '${route['routeIndex'] ?? summary}-${polyline.hashCode}',
            polyline: polyline,
            distanceMeters: math.max(distance, 0),
            durationSeconds: math.max(duration, 0),
            summary: summary,
          );
        })
        .where((route) => route.polyline.isNotEmpty)
        .toList();
  }

  //5.- decodePolyline convierte la cadena codificada en puntos LatLng para el mapa.
  static List<LatLng> decodePolyline(String encoded) {
    final List<LatLng> points = [];
    int index = 0;
    int lat = 0;
    int lng = 0;

    while (index < encoded.length) {
      int result = 0;
      int shift = 0;
      int b;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      final dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      result = 0;
      shift = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      final dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      points.add(
        LatLng(lat / 1e5, lng / 1e5),
      );
    }
    return points;
  }
}

//6.- directionsServiceProvider expone el servicio a través de Riverpod para facilitar overrides.
final directionsServiceProvider = Provider<DirectionsService>((ref) {
  return DirectionsService();
});
