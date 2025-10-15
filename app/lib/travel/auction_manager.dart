import 'dart:math';

import 'models/taxi_bid.dart';

class RideAuctionManager {
  RideAuctionManager({Random? random}) : _random = random ?? Random();

  final Random _random;
  final List<String> _names = const [
    'Carlos',
    'Andrea',
    'Rogelio',
    'Montserrat',
    'Diana',
    'Luis',
    'Fernanda',
    'Jorge',
    'Beatriz',
    'Miguel',
  ];

  List<TaxiBid> generateBids(
      {required double baseFare, int minDrivers = 5, int maxDrivers = 10}) {
    //1.- Decide how many drivers will respond within the allowed window.
    final driverCount =
        minDrivers + _random.nextInt(maxDrivers - minDrivers + 1);
    final bids = <TaxiBid>[];
    for (var index = 0; index < driverCount; index++) {
      //2.- Perturb the base fare with a gaussian noise of ~10 MXN deviation.
      final noise = _nextGaussian() * 10;
      final amount = (baseFare + noise).clamp(50, 600);
      //3.- Create a mock driver profile with ETA and rating variation.
      bids.add(
        TaxiBid(
          id: 'bid-$index',
          driverName: _names[index % _names.length],
          amount: double.parse(amount.toStringAsFixed(2)),
          etaMinutes: 4 + _random.nextInt(9),
          rating: double.parse((4 + _random.nextDouble()).toStringAsFixed(1)),
        ),
      );
    }
    bids.sort((a, b) => a.amount.compareTo(b.amount));
    return bids;
  }

  double _nextGaussian() {
    //1.- Use the Box-Muller transform to create a gaussian distribution from random doubles.
    final u1 = _random.nextDouble();
    final u2 = _random.nextDouble();
    final radius = sqrt(-2.0 * log(u1.clamp(1e-7, 1.0)));
    final theta = 2 * pi * u2;
    return radius * cos(theta);
  }
}
