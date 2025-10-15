import 'package:equatable/equatable.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

//1.- PlaceSuggestion representa un resultado de autocompletado proveniente de Google Places.
class PlaceSuggestion extends Equatable {
  //2.- description es el texto legible que se muestra en la lista de coincidencias.
  final String description;

  //3.- placeId identifica de forma única al lugar para solicitar sus coordenadas.
  final String placeId;

  const PlaceSuggestion({required this.description, required this.placeId});

  @override
  List<Object?> get props => [description, placeId];
}

//4.- RideWaypoint almacena los datos mínimos de origen o destino seleccionados por el usuario.
class RideWaypoint extends Equatable {
  //5.- placeId mantiene la referencia al lugar en Google para futuras consultas.
  final String placeId;

  //6.- description permite mostrar el valor seleccionado dentro del formulario.
  final String description;

  //7.- location contiene las coordenadas para dibujar marcadores y solicitar rutas.
  final LatLng location;

  const RideWaypoint({
    required this.placeId,
    required this.description,
    required this.location,
  });

  @override
  List<Object?> get props => [placeId, description, location.latitude, location.longitude];
}

//8.- RideRouteOption resume cada alternativa devuelta por el Directions API.
class RideRouteOption extends Equatable {
  //9.- id facilita identificar la ruta elegida dentro de la lista renderizada.
  final String id;

  //10.- polyline almacena la ruta codificada utilizada para dibujar el recorrido.
  final String polyline;

  //11.- distanceMeters indica la longitud total del recorrido en metros.
  final int distanceMeters;

  //12.- durationSeconds representa el tiempo estimado de traslado en segundos.
  final int durationSeconds;

  //13.- summary expone una etiqueta corta (por ejemplo nombre de avenida principal).
  final String summary;

  const RideRouteOption({
    required this.id,
    required this.polyline,
    required this.distanceMeters,
    required this.durationSeconds,
    required this.summary,
  });

  @override
  List<Object?> get props => [id, polyline, distanceMeters, durationSeconds, summary];
}
