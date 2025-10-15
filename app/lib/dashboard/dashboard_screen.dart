import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../travel/travel_controller.dart';
import '../travel/travel_screen.dart';
import 'widgets/bank_info_card.dart';
import 'widgets/ride_metrics_card.dart';
import 'widgets/evaluation_card.dart';
import 'widgets/status_card.dart';
import 'widgets/travel_cta_button.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen(
      {super.key, required this.displayName, required this.onLogout});

  final String displayName;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    //1.- Prepare the formatter and access the travel controller for live data.
    final currency = NumberFormat.simpleCurrency(locale: 'es_MX');
    final travel = context.watch<TravelController>();
    final snapshot = _DashboardSnapshot(
      balance: 12850.75,
      ridesThisWeek: 9,
      ridesLifetime: 486,
      totalSpent: 98520.40,
      evaluationScore: 4.8,
      pendingReviews: 2,
    );
    //2.- Build a scrollable dashboard made of self-contained cards.
    return Scaffold(
      appBar: AppBar(
        title: Text('Hola, $displayName'),
        actions: [
          IconButton(
            onPressed: onLogout,
            icon: const Icon(Icons.logout),
            tooltip: 'Sign out',
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 700;
          final cards = <Widget>[
            BankInfoCard(balance: currency.format(snapshot.balance)),
            RideMetricsCard(
              ridesThisWeek: snapshot.ridesThisWeek,
              ridesLifetime: snapshot.ridesLifetime,
              totalSpent: currency.format(snapshot.totalSpent),
            ),
            EvaluationCard(
              score: snapshot.evaluationScore,
              pendingReviews: snapshot.pendingReviews,
            ),
            StatusCard(
                statusLabel: travel.statusLabel,
                nextStep: travel.nextActionLabel),
          ];
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: isWide ? 960 : 520),
                child: Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    ...cards,
                    TravelCtaButton(onPressed: () {
                      Navigator.of(context).pushNamed(TravelScreen.routeName);
                    }),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _DashboardSnapshot {
  const _DashboardSnapshot({
    required this.balance,
    required this.ridesThisWeek,
    required this.ridesLifetime,
    required this.totalSpent,
    required this.evaluationScore,
    required this.pendingReviews,
  });

  final double balance;
  final int ridesThisWeek;
  final int ridesLifetime;
  final double totalSpent;
  final double evaluationScore;
  final int pendingReviews;
}
