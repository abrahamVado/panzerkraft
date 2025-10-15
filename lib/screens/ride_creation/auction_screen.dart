import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/auction/auction_controller.dart';
import '../../providers/auction/auction_state.dart';

//1.- AuctionScreen coordina la UI completa del flujo de subasta.
class AuctionScreen extends ConsumerWidget {
  //2.- baseFare permite personalizar el punto medio de las ofertas.
  final double baseFare;

  //3.- El constructor acepta un valor por defecto conveniente.
  const AuctionScreen({super.key, this.baseFare = 24.0});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(auctionControllerProvider(baseFare));
    final controller = ref.read(auctionControllerProvider(baseFare).notifier);
    return Scaffold(
      appBar: AppBar(title: const Text('Subasta de viaje')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _AuctionContent(
          state: state,
          controller: controller,
        ),
      ),
    );
  }
}

//4.- _AuctionContent desglosa la UI dependiendo de la etapa actual.
class _AuctionContent extends StatelessWidget {
  final AuctionState state;
  final AuctionController controller;

  const _AuctionContent({
    required this.state,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    switch (state.stage) {
      case AuctionStage.selecting:
        return _SelectingView(state: state, controller: controller);
      case AuctionStage.countdown:
        return _CountdownView(state: state, controller: controller);
      case AuctionStage.prompt:
        return _PromptView(controller: controller, state: state);
      case AuctionStage.stopwatch:
        return _StopwatchView(state: state, controller: controller);
    }
  }
}

//5.- _SelectingView permite escoger una oferta resaltando la opción activa.
class _SelectingView extends StatelessWidget {
  final AuctionState state;
  final AuctionController controller;

  const _SelectingView({required this.state, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Selecciona la mejor oferta para tu viaje',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        Expanded(
          child: ListView.separated(
            itemCount: state.bids.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final bid = state.bids[index];
              final isSelected = bid == state.selectedBid;
              return GestureDetector(
                onTap: () => controller.selectBid(bid),
                child: Card(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primaryContainer
                      : null,
                  child: ListTile(
                    title: Text(_formatCurrency(bid.amount)),
                    subtitle: Text('Oferta #${index + 1}'),
                    trailing: isSelected
                        ? Icon(Icons.check_circle,
                            color: Theme.of(context).colorScheme.primary)
                        : const Icon(Icons.circle_outlined),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Las ofertas se generan alrededor de ${_formatCurrency(state.bids[state.bids.length ~/ 2].amount)}.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

//6.- _CountdownView muestra el temporizador regresivo y la oferta seleccionada.
class _CountdownView extends StatelessWidget {
  final AuctionState state;
  final AuctionController controller;

  const _CountdownView({required this.state, required this.controller});

  @override
  Widget build(BuildContext context) {
    final remaining = state.countdownRemaining ?? Duration.zero;
    final selected = state.selectedBid;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(Icons.hourglass_bottom,
            size: 72, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 24),
        Text(
          'Buscando conductor...',
          style: Theme.of(context).textTheme.titleLarge,
          textAlign: TextAlign.center,
        ),
        if (selected != null) ...[
          const SizedBox(height: 12),
          Text(
            'Oferta elegida: ${_formatCurrency(selected.amount)}',
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
        ],
        const SizedBox(height: 24),
        Text(
          _formatDuration(remaining),
          style: Theme.of(context).textTheme.displayMedium,
        ),
        const SizedBox(height: 24),
        OutlinedButton(
          onPressed: controller.cancelAuction,
          child: const Text('Cancelar subasta'),
        ),
      ],
    );
  }
}

//7.- _PromptView ofrece elegir entre cancelar o seguir esperando.
class _PromptView extends StatelessWidget {
  final AuctionController controller;
  final AuctionState state;

  const _PromptView({required this.controller, required this.state});

  @override
  Widget build(BuildContext context) {
    final selected = state.selectedBid;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.info_outline,
            size: 64, color: Theme.of(context).colorScheme.secondary),
        const SizedBox(height: 16),
        Text(
          'Aún no hay conductores disponibles.',
          style: Theme.of(context).textTheme.titleLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        if (selected != null)
          Text(
            'Oferta vigente: ${_formatCurrency(selected.amount)}',
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: controller.continueWaiting,
          child: const Text('Seguir esperando'),
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: controller.cancelAuction,
          child: const Text('Cancelar subasta'),
        ),
      ],
    );
  }
}

//8.- _StopwatchView habilita controles manuales para esperar indefinidamente.
class _StopwatchView extends StatelessWidget {
  final AuctionState state;
  final AuctionController controller;

  const _StopwatchView({required this.state, required this.controller});

  @override
  Widget build(BuildContext context) {
    final elapsed = state.stopwatchElapsed;
    final running = state.stopwatchRunning;
    final selected = state.selectedBid;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.access_time,
            size: 72, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 24),
        Text(
          'Esperando confirmación',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        if (selected != null)
          Text(
            'Oferta: ${_formatCurrency(selected.amount)}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        const SizedBox(height: 24),
        Text(
          _formatDuration(elapsed),
          style: Theme.of(context).textTheme.displayMedium,
        ),
        const SizedBox(height: 24),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: WrapAlignment.center,
          children: [
            OutlinedButton(
              onPressed: controller.cancelAuction,
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: running
                  ? controller.pauseStopwatch
                  : controller.startStopwatch,
              child: Text(running ? 'Pausar' : 'Reanudar'),
            ),
          ],
        ),
      ],
    );
  }
}

//9.- _formatCurrency ofrece una representación sencilla con dos decimales.
String _formatCurrency(double amount) {
  return 'S/ ' + amount.toStringAsFixed(2);
}

//10.- _formatDuration renderiza el tiempo como mm:ss independientemente de la hora.
String _formatDuration(Duration duration) {
  final minutes = duration.inMinutes.remainder(60).abs().toString().padLeft(2, '0');
  final seconds = duration.inSeconds.remainder(60).abs().toString().padLeft(2, '0');
  final hours = duration.inHours;
  if (hours > 0) {
    return hours.toString().padLeft(2, '0') + ':' + minutes + ':' + seconds;
  }
  return minutes + ':' + seconds;
}
