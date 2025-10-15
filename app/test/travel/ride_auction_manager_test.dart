import 'dart:math';

import 'package:app/travel/auction_manager.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RideAuctionManager', () {
    test('generates between five and ten bids', () {
      //1.- Instantiate with deterministic randomness for repeatable assertions.
      final manager = RideAuctionManager(random: Random(3));
      //2.- Request a bid set using a representative base fare.
      final bids = manager.generateBids(baseFare: 150);
      //3.- Validate the amount of responses fits within the contract.
      expect(bids.length, inInclusiveRange(5, 10));
    });

    test('produces price variance close to 10 MXN standard deviation', () {
      //1.- Keep the generator deterministic so the expected range stays stable.
      final manager = RideAuctionManager(random: Random(8));
      //2.- Generate multiple rounds to compute a sample deviation.
      final bids = manager.generateBids(baseFare: 180);
      final mean =
          bids.map((bid) => bid.amount).reduce((a, b) => a + b) / bids.length;
      final variance =
          bids.map((bid) => pow(bid.amount - mean, 2)).reduce((a, b) => a + b) /
              bids.length;
      final stdDeviation = sqrt(variance);
      //3.- Accept a tolerance band that still reflects ~10 MXN variability.
      expect(stdDeviation, inInclusiveRange(5, 20));
    });

    test('orders bids from lowest to highest amount', () {
      //1.- Usa una semilla fija para producir un set repetible de ofertas.
      final manager = RideAuctionManager(random: Random(5));
      //2.- Genera las ofertas simuladas empleando un precio base.
      final bids = manager.generateBids(baseFare: 200);
      //3.- Verifica que las ofertas queden ordenadas ascendentemente por monto.
      final sorted = [...bids]..sort((a, b) => a.amount.compareTo(b.amount));
      expect(bids, sorted);
    });
  });
}
