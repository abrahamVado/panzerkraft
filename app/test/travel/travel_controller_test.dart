import 'dart:math';

import 'package:app/services/location_service.dart';
import 'package:app/travel/auction_manager.dart';
import 'package:app/travel/models/place_option.dart';
import 'package:app/travel/models/ride_request.dart';
import 'package:app/travel/travel_controller.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class _FakeLocationService extends LocationService {
  @override
  Future<LatLng> getCurrentLocation() async => const LatLng(0, 0);
}

void main() {
  test('travel controller transitions through auction lifecycle', () {
    //1.- Run timers inside fakeAsync to deterministically advance the countdown.
    fakeAsync((async) {
      final controller = TravelController(
        locationService: _FakeLocationService(),
        auctionManager: RideAuctionManager(random: Random(1)),
      );
      final start = PlaceOption(
        title: 'Origin',
        subtitle: 'Start point',
        location: const LatLng(19.4, -99.1),
      );
      final end = PlaceOption(
        title: 'Destination',
        subtitle: 'End point',
        location: const LatLng(19.42, -99.2),
      );
      final request = RideRequest(
        start: start,
        end: end,
        rideForSelf: true,
        distanceInKm: 12,
        routePolyline: [start.location, end.location],
      );
      //2.- Update ride and start the auction flow.
      controller.updateRide(request);
      expect(controller.phase, TravelPhase.planning);
      controller.startAuction();
      expect(controller.phase, TravelPhase.auction);
      final initialSeconds = controller.timeLeft.inSeconds;
      async.elapse(const Duration(seconds: 5));
      expect(controller.timeLeft.inSeconds, lessThan(initialSeconds));
      //3.- Select a bid, confirm, and walk through the ride lifecycle.
      controller.selectBid(controller.bids.first);
      controller.confirmBid();
      expect(controller.phase, TravelPhase.assigned);
      controller.startRide();
      expect(controller.phase, TravelPhase.enRoute);
      controller.clearRide();
      expect(controller.phase, TravelPhase.idle);
    });
  });
}
