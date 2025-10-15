import 'package:flutter/material.dart';

import 'dashboard_card.dart';

class StatusCard extends StatelessWidget {
  const StatusCard(
      {super.key, required this.statusLabel, required this.nextStep});

  final String statusLabel;
  final String nextStep;

  @override
  Widget build(BuildContext context) {
    //1.- Highlight the current travel orchestration state.
    return DashboardCard(
      width: 580,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Travel status', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          Text(
            statusLabel,
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(nextStep),
        ],
      ),
    );
  }
}
