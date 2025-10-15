import 'dart:math';

import '../../models/auction/auction_bid.dart';

//1.- BidGenerator produce ofertas simuladas alrededor de una tarifa base usando una distribución normal.
class BidGenerator {
  //2.- _random permite inyectar una fuente determinista durante las pruebas.
  final Random _random;

  //3.- spread controla el desvío estándar relativo respecto a la tarifa base.
  final double spread;

  //4.- El constructor acepta Random personalizado y un spread configurable.
  BidGenerator({Random? random, this.spread = 0.12}) : _random = random ?? Random();

  //5.- generateBids crea entre minCount y maxCount ofertas ordenadas de menor a mayor.
  List<AuctionBid> generateBids({
    required double baseFare,
    int minCount = 5,
    int maxCount = 10,
  }) {
    assert(minCount > 0 && maxCount >= minCount, 'El rango de ofertas debe ser válido.');
    final count = minCount + _random.nextInt(maxCount - minCount + 1);
    final bids = <AuctionBid>[];
    for (var i = 0; i < count; i++) {
      bids.add(AuctionBid(amount: _nextAmount(baseFare)));
    }
    bids.sort((a, b) => a.amount.compareTo(b.amount));
    return bids;
  }

  //6.- _nextAmount aplica Box-Muller para obtener un valor normal centrado en la tarifa base.
  double _nextAmount(double baseFare) {
    final u1 = _random.nextDouble().clamp(1e-6, 1 - 1e-6);
    final u2 = _random.nextDouble();
    final radius = sqrt(-2 * log(u1));
    final theta = 2 * pi * u2;
    final gaussian = radius * cos(theta);
    final candidate = baseFare * (1 + gaussian * spread);
    final minBound = baseFare * (1 - spread * 3);
    final maxBound = baseFare * (1 + spread * 3);
    final clamped = candidate.clamp(minBound, maxBound);
    return double.parse(clamped.toStringAsFixed(2));
  }
}
