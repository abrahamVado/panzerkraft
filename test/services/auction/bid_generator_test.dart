import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:panzerkraft/services/auction/bid_generator.dart';

void main() {
  //1.- Configuramos un generador determinista para validar la cantidad de ofertas.
  test('generateBids respeta los límites de cantidad', () {
    final generator = BidGenerator(random: Random(1));
    final bids = generator.generateBids(baseFare: 30);
    expect(bids.length, inInclusiveRange(5, 10));
  });

  //2.- Verificamos que los valores se mantengan acotados alrededor de la tarifa base.
  test('generateBids mantiene montos cercanos a la tarifa base', () {
    final generator = BidGenerator(random: Random(7));
    final baseFare = 42.0;
    final bids = generator.generateBids(baseFare: baseFare);
    final minExpected = baseFare * (1 - generator.spread * 3);
    final maxExpected = baseFare * (1 + generator.spread * 3);
    expect(bids.every((bid) => bid.amount >= minExpected && bid.amount <= maxExpected), isTrue);
  });

  //3.- Evaluamos que las ofertas se entreguen en orden ascendente para simplificar la UI.
  test('generateBids retorna las ofertas ordenadas ascendentemente', () {
    final generator = BidGenerator(random: Random(3));
    final bids = generator.generateBids(baseFare: 18);
    final sorted = [...bids]..sort((a, b) => a.amount.compareTo(b.amount));
    expect(bids, sorted);
  });
}
