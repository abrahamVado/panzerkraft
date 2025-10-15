import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:panzerkraft/providers/auction/auction_controller.dart';
import 'package:panzerkraft/screens/ride_creation/auction_screen.dart';

void main() {
  //1.- Validamos la transición completa desde la selección hasta el cronómetro.
  testWidgets('flujo de cuenta regresiva y cronómetro', (tester) async {
    final config = AuctionTimingConfig(
      tickInterval: const Duration(seconds: 1),
      minCountdown: const Duration(seconds: 3),
      maxCountdown: const Duration(seconds: 3),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          auctionTimingConfigProvider.overrideWithValue(config),
          auctionRandomProvider.overrideWithValue(Random(1)),
          auctionTickerProvider.overrideWithValue(
            (interval) => Stream.periodic(interval, (count) => interval * (count + 1)),
          ),
        ],
        child: const MaterialApp(
          home: AuctionScreen(baseFare: 20),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.textContaining('Oferta #'), findsWidgets);

    await tester.tap(find.byType(ListTile).first);
    await tester.pump();

    expect(find.text('Buscando conductor...'), findsOneWidget);
    expect(find.text('00:03'), findsOneWidget);

    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
    expect(find.text('00:02'), findsOneWidget);

    await tester.pump(const Duration(seconds: 2));
    await tester.pump();

    expect(find.text('Aún no hay conductores disponibles.'), findsOneWidget);

    await tester.tap(find.text('Seguir esperando'));
    await tester.pump();

    expect(find.text('Esperando confirmación'), findsOneWidget);
    expect(find.text('00:00'), findsOneWidget);

    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
    expect(find.text('00:01'), findsOneWidget);

    await tester.tap(find.text('Pausar'));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
    expect(find.text('00:01'), findsOneWidget);

    await tester.tap(find.text('Reanudar'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
    expect(find.text('00:02'), findsOneWidget);
  });
}
