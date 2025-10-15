import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../services/location_service.dart';
import 'auction_manager.dart';
import 'models/ride_request.dart';
import 'models/taxi_bid.dart';

enum TravelPhase { idle, planning, auction, assigned, enRoute }

class TravelController extends ChangeNotifier {
  TravelController(
      {required LocationService locationService,
      required RideAuctionManager auctionManager})
      : _locationService = locationService,
        _auctionManager = auctionManager;

  final LocationService _locationService;
  final RideAuctionManager _auctionManager;

  LatLng? _userLocation;
  bool _rideForSelf = true;
  RideRequest? _request;
  List<TaxiBid> _bids = const [];
  TaxiBid? _selectedBid;
  TravelPhase _phase = TravelPhase.idle;
  Timer? _auctionTimer;
  Duration _timeLeft = const Duration(seconds: 0);

  LatLng? get userLocation => _userLocation;
  bool get rideForSelf => _rideForSelf;
  RideRequest? get request => _request;
  List<TaxiBid> get bids => _bids;
  TaxiBid? get selectedBid => _selectedBid;
  TravelPhase get phase => _phase;
  Duration get timeLeft => _timeLeft;
  bool get isAuctionRunning => _auctionTimer != null;

  String get statusLabel {
    //1.- Surface a human readable status derived from the internal phase.
    return switch (_phase) {
      TravelPhase.idle => 'No active rides. Ready for dispatch.',
      TravelPhase.planning => 'Ride drafted. Awaiting auction launch.',
      TravelPhase.auction => 'Waiting for taxi bids...',
      TravelPhase.assigned => 'Driver selected. Confirm itinerary.',
      TravelPhase.enRoute =>
        'Ride in progress with ${_selectedBid?.driverName ?? 'driver'}',
    };
  }

  String get nextActionLabel {
    //1.- Describe the recommended next action for the dashboard summary.
    return switch (_phase) {
      TravelPhase.idle => 'Create a travel request to begin.',
      TravelPhase.planning => 'Review details and start the auction.',
      TravelPhase.auction => 'Monitor offers and choose the best driver.',
      TravelPhase.assigned => 'Start ride once passenger is ready.',
      TravelPhase.enRoute => 'Track arrival or finish when complete.',
    };
  }

  Future<void> loadUserLocation() async {
    //1.- Request the GPS location and expose it for the map screen.
    _userLocation = await _locationService.getCurrentLocation();
    notifyListeners();
  }

  void toggleRideForSelf(bool rideForSelf) {
    //1.- Switch between riding for self or assigning to someone else.
    _rideForSelf = rideForSelf;
    notifyListeners();
  }

  void updateRide(RideRequest request) {
    //1.- Store the planned ride and move the flow into planning mode.
    _request = request;
    _phase = TravelPhase.planning;
    notifyListeners();
  }

  void clearRide() {
    //1.- Reset the plan back to idle removing bids and timers.
    _request = null;
    _bids = const [];
    _selectedBid = null;
    _phase = TravelPhase.idle;
    _stopAuctionTimer();
    _timeLeft = const Duration(seconds: 0);
    notifyListeners();
  }

  void startAuction() {
    if (_request == null) {
      return;
    }
    //1.- Generate mock bids and start the countdown timer.
    _bids = _auctionManager.generateBids(baseFare: _request!.estimatedFare);
    _phase = TravelPhase.auction;
    _timeLeft = const Duration(seconds: 30);
    _selectedBid = null;
    _stopAuctionTimer();
    _auctionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeLeft.inSeconds <= 1) {
        timer.cancel();
        _auctionTimer = null;
        notifyListeners();
        return;
      }
      _timeLeft -= const Duration(seconds: 1);
      notifyListeners();
    });
    notifyListeners();
  }

  void selectBid(TaxiBid bid) {
    //1.- Mark the chosen bid so downstream controls can act on it.
    _selectedBid = bid;
    notifyListeners();
  }

  void confirmBid() {
    if (_selectedBid == null) {
      return;
    }
    //1.- Stop the auction once a driver is confirmed.
    _stopAuctionTimer();
    _phase = TravelPhase.assigned;
    notifyListeners();
  }

  void startRide() {
    if (_selectedBid == null) {
      return;
    }
    //1.- Transition to the live ride state so status reflects the journey.
    _phase = TravelPhase.enRoute;
    notifyListeners();
  }

  void cancelAuction() {
    //1.- Abort the auction process and keep the ride draft for edits.
    _stopAuctionTimer();
    _bids = const [];
    _selectedBid = null;
    _phase = _request == null ? TravelPhase.idle : TravelPhase.planning;
    _timeLeft = const Duration(seconds: 0);
    notifyListeners();
  }

  void _stopAuctionTimer() {
    //1.- Ensure timers are cleaned up to prevent memory leaks.
    _auctionTimer?.cancel();
    _auctionTimer = null;
  }

  @override
  void dispose() {
    //1.- Dispose timers when the provider is removed from the tree.
    _stopAuctionTimer();
    super.dispose();
  }
}
