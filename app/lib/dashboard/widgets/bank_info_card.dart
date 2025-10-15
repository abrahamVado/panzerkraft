import 'package:flutter/material.dart';

import 'dashboard_card.dart';

class BankInfoCard extends StatelessWidget {
  const BankInfoCard({super.key, required this.balance});

  final String balance;

  @override
  Widget build(BuildContext context) {
    //1.- Present the current wallet balance with a decorative gradient header.
    return DashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.account_balance_wallet, size: 32),
              const SizedBox(width: 12),
              Text(
                'Fleet wallet',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            balance,
            style: Theme.of(context)
                .textTheme
                .headlineMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Next recharge scheduled for Friday 09:00',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
