import 'package:flutter/material.dart';

import 'dashboard_card.dart';

class RideMetricsCard extends StatelessWidget {
  const RideMetricsCard({
    super.key,
    required this.ridesThisWeek,
    required this.ridesLifetime,
    required this.totalSpent,
  });

  final int ridesThisWeek;
  final int ridesLifetime;
  final String totalSpent;

  @override
  Widget build(BuildContext context) {
    //1.- Summarize ride activity for quick fleet insights.
    return DashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ride volume',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _Metric(label: 'This week', value: ridesThisWeek.toString()),
              const SizedBox(width: 16),
              _Metric(label: 'Lifetime', value: ridesLifetime.toString()),
            ],
          ),
          const SizedBox(height: 12),
          Text('Total spent: $totalSpent'),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    //1.- Display a compact numeric value and its label.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: Theme.of(context)
              .textTheme
              .headlineSmall
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        Text(label),
      ],
    );
  }
}
