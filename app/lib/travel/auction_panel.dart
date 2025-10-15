import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'models/taxi_bid.dart';
import 'travel_controller.dart';

class AuctionPanel extends StatelessWidget {
  const AuctionPanel({super.key});

  @override
  Widget build(BuildContext context) {
    //1.- Consume the travel controller to reflect live auction state.
    final travel = context.watch<TravelController>();
    final currency = NumberFormat.simpleCurrency(locale: 'es_MX');
    final request = travel.request;
    if (request == null) {
      return const SizedBox.shrink();
    }

    final actions = _buildActions(context, travel);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Auction', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
                'Base fare suggestion: ${currency.format(request.estimatedFare)}'),
            if (travel.phase == TravelPhase.auction)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text('Time remaining: ${travel.timeLeft.inSeconds}s'),
              ),
            if (travel.bids.isNotEmpty)
              _BidsList(
                bids: travel.bids,
                selected: travel.selectedBid,
                currency: currency,
                onSelected: travel.selectBid,
              ),
            const SizedBox(height: 12),
            Wrap(spacing: 8, children: actions),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildActions(BuildContext context, TravelController travel) {
    //1.- Render context-aware action buttons for the auction lifecycle.
    switch (travel.phase) {
      case TravelPhase.idle:
        return [
          FilledButton(
            onPressed: travel.request == null ? null : travel.startAuction,
            child: const Text('Start auction'),
          ),
        ];
      case TravelPhase.planning:
        return [
          FilledButton(
            onPressed: travel.startAuction,
            child: const Text('Start auction'),
          ),
          TextButton(
            onPressed: travel.clearRide,
            child: const Text('Discard plan'),
          ),
        ];
      case TravelPhase.auction:
        return [
          FilledButton(
            onPressed: travel.selectedBid == null ? null : travel.confirmBid,
            child: const Text('Continue'),
          ),
          OutlinedButton(
            onPressed: travel.cancelAuction,
            child: const Text('Cancel'),
          ),
        ];
      case TravelPhase.assigned:
        return [
          FilledButton(
            onPressed: travel.startRide,
            child: const Text('Start ride'),
          ),
          OutlinedButton(
            onPressed: travel.cancelAuction,
            child: const Text('Modify bids'),
          ),
        ];
      case TravelPhase.enRoute:
        return [
          FilledButton(
            onPressed: travel.clearRide,
            child: const Text('Finish ride'),
          ),
        ];
    }
  }
}

class _BidsList extends StatelessWidget {
  const _BidsList({
    required this.bids,
    required this.selected,
    required this.currency,
    required this.onSelected,
  });

  final List<TaxiBid> bids;
  final TaxiBid? selected;
  final NumberFormat currency;
  final ValueChanged<TaxiBid> onSelected;

  @override
  Widget build(BuildContext context) {
    //1.- Present driver bids ordered by price and allow selection.
    return SizedBox(
      height: 220,
      child: ListView.builder(
        itemCount: bids.length,
        itemBuilder: (context, index) {
          final bid = bids[index];
          return Card(
            color: selected == bid
                ? Theme.of(context).colorScheme.primaryContainer
                : null,
            child: ListTile(
              title: Text('${bid.driverName} • ${currency.format(bid.amount)}'),
              subtitle: Text(
                  'ETA ${bid.etaMinutes} min • Rating ${bid.rating.toStringAsFixed(1)}'),
              trailing: const Icon(Icons.local_taxi),
              onTap: () => onSelected(bid),
            ),
          );
        },
      ),
    );
  }
}
