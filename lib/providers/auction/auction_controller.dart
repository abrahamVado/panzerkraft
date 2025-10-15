import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/auction/auction_bid.dart';
import '../../services/auction/bid_generator.dart';
import 'auction_state.dart';

//1.- AuctionTimingConfig centraliza la configuración de ticks y duraciones.
class AuctionTimingConfig {
  //2.- tickInterval define cada cuánto se actualizan los contadores.
  final Duration tickInterval;
  //3.- minCountdown delimita la duración mínima del conteo regresivo inicial.
  final Duration minCountdown;
  //4.- maxCountdown delimita la duración máxima del conteo regresivo inicial.
  final Duration maxCountdown;

  //5.- El constructor valida que minCountdown no exceda maxCountdown.
  const AuctionTimingConfig({
    required this.tickInterval,
    required this.minCountdown,
    required this.maxCountdown,
  }) : assert(!minCountdown.isNegative && !maxCountdown.isNegative),
        assert(!tickInterval.isNegative && !tickInterval.isZero),
        assert(!maxCountdown.isNegative && maxCountdown >= minCountdown);
}

//6.- TickStreamFactory crea flujos de Durations para alimentar temporizadores.
typedef TickStreamFactory = Stream<Duration> Function(Duration interval);

//7.- auctionRandomProvider expone Random para poder fijar semillas en tests.
final auctionRandomProvider = Provider<Random>((ref) {
  return Random();
});

//8.- auctionTimingConfigProvider establece los parámetros por defecto del flujo.
final auctionTimingConfigProvider = Provider<AuctionTimingConfig>((ref) {
  return const AuctionTimingConfig(
    tickInterval: Duration(seconds: 1),
    minCountdown: Duration(minutes: 5),
    maxCountdown: Duration(minutes: 7),
  );
});

//9.- auctionTickerProvider permite reemplazar la mecánica de ticks durante pruebas.
final auctionTickerProvider = Provider<TickStreamFactory>((ref) {
  return (Duration interval) {
    return Stream.periodic(interval, (count) => interval * (count + 1));
  };
});

//10.- bidGeneratorProvider reutiliza el servicio capaz de producir ofertas.
final bidGeneratorProvider = Provider<BidGenerator>((ref) {
  return BidGenerator(random: ref.watch(auctionRandomProvider));
});

//11.- auctionControllerProvider orquesta el estado usando un parámetro baseFare.
final auctionControllerProvider = AutoDisposeNotifierProviderFamily<
    AuctionController, AuctionState, double>(AuctionController.new);

//12.- AuctionController implementa el flujo completo de selección y espera.
class AuctionController extends AutoDisposeNotifier<AuctionState> {
  StreamSubscription<Duration>? _tickerSub;
  Duration _stopwatchBase = Duration.zero;
  late double _baseFare;

  @override
  AuctionState build(double baseFare) {
    _baseFare = baseFare;
    ref.onDispose(_cancelTicker);
    final bids = ref.read(bidGeneratorProvider).generateBids(baseFare: baseFare);
    return AuctionState.initial(bids);
  }

  //13.- refresh reinicia la subasta con nuevas ofertas.
  void refresh() {
    _cancelTicker();
    state = AuctionState.initial(
      ref.read(bidGeneratorProvider).generateBids(baseFare: _baseFare),
    );
  }

  //14.- selectBid fija la oferta elegida y dispara el conteo regresivo.
  void selectBid(AuctionBid bid) {
    if (state.stage != AuctionStage.selecting) {
      return;
    }
    state = state.copyWith(selectedBid: bid);
    _startCountdown();
  }

  //15.- cancelAuction vuelve al listado inicial sin conservar selección.
  void cancelAuction() {
    refresh();
  }

  //16.- continueWaiting pasa del prompt al cronómetro indefinido.
  void continueWaiting() {
    if (state.stage != AuctionStage.prompt) {
      return;
    }
    state = state.copyWith(
      stage: AuctionStage.stopwatch,
      countdownInitial: null,
      countdownRemaining: null,
      stopwatchElapsed: Duration.zero,
      stopwatchRunning: true,
    );
    _stopwatchBase = Duration.zero;
    _startStopwatchTicker();
  }

  //17.- pauseStopwatch detiene temporalmente la medición indefinida.
  void pauseStopwatch() {
    if (state.stage != AuctionStage.stopwatch || !state.stopwatchRunning) {
      return;
    }
    _cancelTicker();
    state = state.copyWith(stopwatchRunning: false);
  }

  //18.- startStopwatch reanuda la espera indefinida acumulando el tiempo previo.
  void startStopwatch() {
    if (state.stage != AuctionStage.stopwatch || state.stopwatchRunning) {
      return;
    }
    state = state.copyWith(stopwatchRunning: true);
    _startStopwatchTicker();
  }

  //19.- _startCountdown calcula una duración dentro del rango y genera ticks.
  void _startCountdown() {
    final config = ref.read(auctionTimingConfigProvider);
    final random = ref.read(auctionRandomProvider);
    final range = config.maxCountdown - config.minCountdown;
    final extra = range.inSeconds == 0
        ? 0
        : random.nextInt(range.inSeconds + 1);
    final duration = config.minCountdown + Duration(seconds: extra);
    state = state.copyWith(
      stage: AuctionStage.countdown,
      countdownInitial: duration,
      countdownRemaining: duration,
    );
    _cancelTicker();
    final tickerFactory = ref.read(auctionTickerProvider);
    _tickerSub = tickerFactory(config.tickInterval).listen((elapsed) {
      final remaining = duration - elapsed;
      if (remaining <= Duration.zero) {
        _cancelTicker();
        state = state.copyWith(
          stage: AuctionStage.prompt,
          countdownRemaining: Duration.zero,
        );
      } else {
        state = state.copyWith(countdownRemaining: remaining);
      }
    });
  }

  //20.- _startStopwatchTicker avanza el cronómetro acumulando el tiempo previo.
  void _startStopwatchTicker() {
    _cancelTicker();
    final config = ref.read(auctionTimingConfigProvider);
    final tickerFactory = ref.read(auctionTickerProvider);
    _stopwatchBase = state.stopwatchElapsed;
    _tickerSub = tickerFactory(config.tickInterval).listen((elapsed) {
      if (!state.stopwatchRunning) {
        return;
      }
      state = state.copyWith(stopwatchElapsed: _stopwatchBase + elapsed);
    });
  }

  //21.- _cancelTicker limpia subscripciones activas para evitar fugas de memoria.
  void _cancelTicker() {
    _tickerSub?.cancel();
    _tickerSub = null;
  }
}
