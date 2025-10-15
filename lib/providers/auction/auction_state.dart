import '../../models/auction/auction_bid.dart';

//1.- AuctionStage describe el flujo completo de la subasta.
enum AuctionStage {
  //2.- selecting refleja la etapa inicial donde se evalúan ofertas.
  selecting,
  //3.- countdown indica que se espera confirmación de un conductor.
  countdown,
  //4.- prompt informa que se agotó la espera mínima y se requiere decisión.
  prompt,
  //5.- stopwatch mantiene la espera indefinida con control manual.
  stopwatch,
}

//6.- AuctionState encapsula la información necesaria para renderizar la pantalla.
class AuctionState {
  final List<AuctionBid> bids;
  final AuctionBid? selectedBid;
  final AuctionStage stage;
  final Duration? countdownInitial;
  final Duration? countdownRemaining;
  final Duration stopwatchElapsed;
  final bool stopwatchRunning;

  //7.- Constructor inmutable que asegura consistencia entre campos.
  const AuctionState({
    required this.bids,
    required this.selectedBid,
    required this.stage,
    required this.countdownInitial,
    required this.countdownRemaining,
    required this.stopwatchElapsed,
    required this.stopwatchRunning,
  });

  //8.- initial genera el estado base antes de seleccionar oferta.
  factory AuctionState.initial(List<AuctionBid> bids) {
    return AuctionState(
      bids: bids,
      selectedBid: null,
      stage: AuctionStage.selecting,
      countdownInitial: null,
      countdownRemaining: null,
      stopwatchElapsed: Duration.zero,
      stopwatchRunning: false,
    );
  }

  //9.- copyWith permite evolucionar el estado sin mutar instancias previas.
  AuctionState copyWith({
    List<AuctionBid>? bids,
    AuctionBid? selectedBid,
    AuctionStage? stage,
    Object? countdownInitial = _unset,
    Object? countdownRemaining = _unset,
    Duration? stopwatchElapsed,
    bool? stopwatchRunning,
  }) {
    return AuctionState(
      bids: bids ?? this.bids,
      selectedBid: selectedBid ?? this.selectedBid,
      stage: stage ?? this.stage,
      countdownInitial: countdownInitial == _unset
          ? this.countdownInitial
          : countdownInitial as Duration?,
      countdownRemaining: countdownRemaining == _unset
          ? this.countdownRemaining
          : countdownRemaining as Duration?,
      stopwatchElapsed: stopwatchElapsed ?? this.stopwatchElapsed,
      stopwatchRunning: stopwatchRunning ?? this.stopwatchRunning,
    );
  }
}

//10.- _unset diferencia entre asignar null explícito y conservar el valor previo.
const _unset = Object();
