import 'dart:async';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ubberapp/models/auction/auction_bid.dart';
import 'package:ubberapp/providers/auction/auction_controller.dart';
import 'package:ubberapp/providers/auction/auction_state.dart';
import 'package:ubberapp/services/auction/bid_generator.dart';

//1.- _FixedBidGenerator asegura resultados deterministas para las pruebas.
class _FixedBidGenerator extends BidGenerator {
  final List<AuctionBid> _bids;

  _FixedBidGenerator(this._bids) : super(random: Random.secure());

  //2.- Sobrescribimos generateBids para devolver siempre la misma colección.
  @override
  List<AuctionBid> generateBids({
    required double baseFare,
    int minCount = 5,
    int maxCount = 10,
  }) {
    return _bids;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'selectBid inicia cuenta regresiva y llega a prompt al agotar el tiempo',
    () async {
      //3.- Configuramos dependencias controladas para simular el temporizador.
      final fixedBid = AuctionBid(amount: 150.0);
      final tickerController = StreamController<Duration>();
      final container = ProviderContainer(
        overrides: [
          auctionTimingConfigProvider.overrideWithValue(
            AuctionTimingConfig(
              tickInterval: Duration(seconds: 1),
              minCountdown: Duration(seconds: 3),
              maxCountdown: Duration(seconds: 3),
            ),
          ),
          bidGeneratorProvider.overrideWithValue(
            _FixedBidGenerator([fixedBid]),
          ),
          auctionTickerProvider.overrideWithValue(
            (interval) => tickerController.stream,
          ),
        ],
      );
      addTearDown(() {
        //4.- Cerramos el contenedor y el flujo para liberar recursos.
        tickerController.close();
        container.dispose();
      });

      //5.- Obtenemos el controlador y su estado inicial para verificar condiciones.
      final provider = auctionControllerProvider(120.0);
      final subscription = container.listen(provider, (_, __) {});
      addTearDown(subscription.close);
      final controller = container.read(provider.notifier);
      final initialState = subscription.read();
      expect(initialState.stage, AuctionStage.selecting);
      expect(initialState.bids, [fixedBid]);

      //6.- Al seleccionar una oferta se inicia la cuenta regresiva configurada.
      controller.selectBid(fixedBid);
      await Future<void>.delayed(Duration.zero);
      final countdownState = subscription.read();
      expect(countdownState.stage, AuctionStage.countdown);
      expect(countdownState.countdownInitial, const Duration(seconds: 3));
      expect(countdownState.countdownRemaining, const Duration(seconds: 3));

      //7.- Al avanzar un segundo la cuenta regresiva se reduce acorde al tick.
      tickerController.add(const Duration(seconds: 1));
      await Future<void>.delayed(Duration.zero);
      final afterFirstTick = subscription.read();
      expect(afterFirstTick.countdownRemaining, const Duration(seconds: 2));

      //8.- Un tick que supera la duración restante fuerza el paso a prompt.
      tickerController.add(const Duration(seconds: 3));
      await Future<void>.delayed(Duration.zero);
      final promptState = subscription.read();
      expect(promptState.stage, AuctionStage.prompt);
      expect(promptState.countdownRemaining, Duration.zero);
    },
  );
}
