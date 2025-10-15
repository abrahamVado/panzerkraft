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

  test('status and action labels reflect controller phase', () {
    //1.- Build a controller with deterministic collaborators for the assertions.
    final controller = TravelController(
      locationService: _FakeLocationService(),
      auctionManager: RideAuctionManager(random: Random(1)),
    );
    //2.- Verify the idle state messaging before any ride is planned.
    expect(controller.statusLabel,
        'No active rides. Ready for dispatch.');
    expect(controller.nextActionLabel,
        'Create a travel request to begin.');
    //3.- Move through each phase and ensure the paired messages match the intent.
    controller.updateRide(
      RideRequest(
        start: PlaceOption(
          title: 'Origin',
          subtitle: 'Start point',
          location: const LatLng(19.4, -99.1),
        ),
        end: PlaceOption(
          title: 'Destination',
          subtitle: 'End point',
          location: const LatLng(19.42, -99.2),
        ),
        rideForSelf: true,
        distanceInKm: 12,
        routePolyline: const [LatLng(19.4, -99.1), LatLng(19.42, -99.2)],
      ),
    );
    expect(controller.statusLabel,
        'Ride drafted. Awaiting auction launch.');
    expect(controller.nextActionLabel,
        'Review details and start the auction.');
    controller.startAuction();
    expect(controller.statusLabel, 'Waiting for taxi bids...');
    controller.selectBid(controller.bids.first);
    controller.confirmBid();
    expect(controller.statusLabel,
        'Driver selected. Confirm itinerary.');
    controller.startRide();
    expect(
      controller.statusLabel,
      'Ride in progress with ${controller.selectedBid?.driverName ?? 'driver'}',
    );
    controller.clearRide();
    expect(controller.statusLabel,
        'No active rides. Ready for dispatch.');
  });

  test('cancel auction clears bids and restores planning state', () {
    //1.- Prepare a controller with a seeded request so the auction can run.
    final controller = TravelController(
      locationService: _FakeLocationService(),
      auctionManager: RideAuctionManager(random: Random(4)),
    );
    final request = RideRequest(
      start: PlaceOption(
        title: 'Origin',
        subtitle: 'Start point',
        location: const LatLng(19.4, -99.1),
      ),
      end: PlaceOption(
        title: 'Destination',
        subtitle: 'End point',
        location: const LatLng(19.42, -99.2),
      ),
      rideForSelf: true,
      distanceInKm: 12,
      routePolyline: const [LatLng(19.4, -99.1), LatLng(19.42, -99.2)],
    );
    //2.- Move into the auction phase to populate bids and start the timer.
    controller.updateRide(request);
    controller.startAuction();
    expect(controller.phase, TravelPhase.auction);
    expect(controller.bids, isNotEmpty);
    expect(controller.isAuctionRunning, isTrue);
    //3.- Cancel the auction and verify the controller retains the draft ride without bids.
    controller.cancelAuction();
    expect(controller.phase, TravelPhase.planning);
    expect(controller.bids, isEmpty);
    expect(controller.selectedBid, isNull);
    expect(controller.isAuctionRunning, isFalse);
    expect(controller.timeLeft.inSeconds, 0);
    expect(controller.request, isNotNull);
  });
}
