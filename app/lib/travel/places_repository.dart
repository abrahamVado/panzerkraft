import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'models/place_option.dart';

class PlacesRepository {
  const PlacesRepository();

  static final List<PlaceOption> _options = [
    PlaceOption(
      title: 'Panzerkraft HQ',
      subtitle: 'Av. Paseo de la Reforma 10, CDMX',
      location: const LatLng(19.4326, -99.1332),
    ),
    PlaceOption(
      title: 'Terminal 1 AICM',
      subtitle: 'Aeropuerto Internacional de la Ciudad de México',
      location: const LatLng(19.4361, -99.0719),
    ),
    PlaceOption(
      title: 'Polanco Business Center',
      subtitle: 'Ejército Nacional 843, CDMX',
      location: const LatLng(19.439, -99.2002),
    ),
    PlaceOption(
      title: 'Santa Fe Campus',
      subtitle: 'Av. Vasco de Quiroga 4871, Santa Fe',
      location: const LatLng(19.3655, -99.2674),
    ),
    PlaceOption(
      title: 'Guadalajara Hub',
      subtitle: 'Av. Vallarta 6503, Zapopan',
      location: const LatLng(20.6736, -103.344),
    ),
    PlaceOption(
      title: 'Monterrey Downtown',
      subtitle: 'Av. Constitución 300, Monterrey',
      location: const LatLng(25.6866, -100.3161),
    ),
  ];

  Future<List<PlaceOption>> search(String query) async {
    //1.- Simulate an async autocomplete by returning filtered static data.
    await Future<void>.delayed(const Duration(milliseconds: 120));
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) {
      return _options.take(4).toList();
    }
    return _options
        .where((option) =>
            option.title.toLowerCase().contains(normalized) ||
            option.subtitle.toLowerCase().contains(normalized))
        .toList();
  }
}
