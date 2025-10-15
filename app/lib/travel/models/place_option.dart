import 'package:google_maps_flutter/google_maps_flutter.dart';

class PlaceOption {
  const PlaceOption(
      {required this.title, required this.subtitle, required this.location});

  final String title;
  final String subtitle;
  final LatLng location;
}
