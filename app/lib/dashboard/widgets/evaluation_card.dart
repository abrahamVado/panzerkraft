import 'package:flutter/material.dart';

import 'dashboard_card.dart';

class EvaluationCard extends StatelessWidget {
  const EvaluationCard(
      {super.key, required this.score, required this.pendingReviews});

  final double score;
  final int pendingReviews;

  @override
  Widget build(BuildContext context) {
    //1.- Visualize average evaluations and highlight pending feedback tasks.
    return DashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Driver evaluations',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.star, color: Colors.amber.shade600, size: 28),
              const SizedBox(width: 8),
              Text(
                score.toStringAsFixed(1),
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 8),
              const Text('average rating'),
            ],
          ),
          const SizedBox(height: 12),
          Text('Pending evaluations: $pendingReviews'),
        ],
      ),
    );
  }
}
