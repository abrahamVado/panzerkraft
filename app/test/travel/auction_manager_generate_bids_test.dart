import 'dart:math';

import 'package:app/travel/auction_manager.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ride auction manager returns sorted bids within bounds', () {
    //1.- Generate bids with a seeded Random so the sample is deterministic.
    final manager = RideAuctionManager(random: Random(42));
    final bids = manager.generateBids(baseFare: 120, minDrivers: 6, maxDrivers: 6);

    //2.- Assert the fixed driver count and verify sorting by amount.
    expect(bids, hasLength(6));
    final sorted = [...bids]..sort((a, b) => a.amount.compareTo(b.amount));
    expect(bids.map((e) => e.id), sorted.map((e) => e.id));

    //3.- Ensure amounts stay in the mocked marketplace range and ratings remain realistic.
    for (final bid in bids) {
      expect(bid.amount, inInclusiveRange(50, 600));
      expect(bid.rating, inInclusiveRange(4, 5));
    }
  });
}
