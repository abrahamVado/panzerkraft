import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'place_option.dart';

class RideRequest {
  const RideRequest({
    required this.start,
    required this.end,
    required this.rideForSelf,
    required this.distanceInKm,
    required this.routePolyline,
  });

  final PlaceOption start;
  final PlaceOption end;
  final bool rideForSelf;
  final double distanceInKm;
  final List<LatLng> routePolyline;

  double get estimatedFare => (distanceInKm * 25).clamp(80, 480);
}
