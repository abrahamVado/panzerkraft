import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/auth_providers.dart';
import '../auth/fake_credentials.dart';

//1.- FinanceRange delimita los periodos mostrados en la sección de finanzas.
enum FinanceRange { today, week, month }

//2.- FinanceSnapshot resume viajes y montos agrupados por periodo.
class FinanceSnapshot {
  const FinanceSnapshot({
    required this.tripCount,
    required this.totalAmount,
    required this.averagePrice,
  });

  final int tripCount;
  final double totalAmount;
  final double averagePrice;
}

//3.- DashboardMetrics encapsula los datos agregados que consume la pantalla principal.
class DashboardMetrics {
  const DashboardMetrics({
    required this.bankName,
    required this.bankAccount,
    required this.completedRidesThisWeek,
    required this.cancelledRidesThisWeek,
    required this.weeklyEarnings,
    required this.monthlyEarnings,
    required this.evaluationScore,
    required this.acceptanceRate,
    required this.financeSnapshots,
  });

  final String bankName;
  final String bankAccount;
  final int completedRidesThisWeek;
  final int cancelledRidesThisWeek;
  final double weeklyEarnings;
  final double monthlyEarnings;
  final double evaluationScore;
  final int acceptanceRate;

  //3.1.- financeSnapshots expone métricas calculadas por periodo.
  final Map<FinanceRange, FinanceSnapshot> financeSnapshots;

  //3.2.- snapshotFor ofrece un acceso seguro al periodo solicitado.
  FinanceSnapshot snapshotFor(FinanceRange range) {
    return financeSnapshots[range] ??
        financeSnapshots[FinanceRange.week] ??
        const FinanceSnapshot(tripCount: 0, totalAmount: 0, averagePrice: 0);
  }
}

//4.- DashboardMetricsService simula un backend devolviendo datos deterministas.
class DashboardMetricsService {
  const DashboardMetricsService();

  //5.- loadMetrics devuelve cifras fijas derivadas del correo para pruebas consistentes.
  Future<DashboardMetrics> loadMetrics(RiderAccount rider) async {
    final seed = rider.email.hashCode.abs();
    final completed = 22 + seed % 5;
    final cancelled = 1 + seed % 2;
    final weeklyEarnings = 1350.75 + (seed % 250);
    final monthlyEarnings = 5600.20 + (seed % 500);
    final evaluationScore = 4.6 + (seed % 4) * 0.1;
    final acceptanceRate = 94 + seed % 5;

    final todayTrips = 4 + seed % 3;
    final todayTotal = 220.0 + (seed % 90);
    final weekTrips = 26 + seed % 6;
    final weekTotal = weeklyEarnings;
    final monthTrips = 110 + seed % 20;
    final monthTotal = monthlyEarnings;

    return DashboardMetrics(
      bankName: 'Banco Andariego',
      bankAccount: '**** ${seed % 9000 + 1000}',
      completedRidesThisWeek: completed,
      cancelledRidesThisWeek: cancelled,
      weeklyEarnings: double.parse(weeklyEarnings.toStringAsFixed(2)),
      monthlyEarnings: double.parse(monthlyEarnings.toStringAsFixed(2)),
      evaluationScore: double.parse(evaluationScore.toStringAsFixed(1)),
      acceptanceRate: acceptanceRate,
      financeSnapshots: {
        FinanceRange.today: FinanceSnapshot(
          tripCount: todayTrips,
          totalAmount: double.parse(todayTotal.toStringAsFixed(2)),
          averagePrice: double.parse((todayTotal / todayTrips).toStringAsFixed(2)),
        ),
        FinanceRange.week: FinanceSnapshot(
          tripCount: weekTrips,
          totalAmount: double.parse(weekTotal.toStringAsFixed(2)),
          averagePrice: double.parse((weekTotal / weekTrips).toStringAsFixed(2)),
        ),
        FinanceRange.month: FinanceSnapshot(
          tripCount: monthTrips,
          totalAmount: double.parse(monthTotal.toStringAsFixed(2)),
          averagePrice: double.parse((monthTotal / monthTrips).toStringAsFixed(2)),
        ),
      },
    );
  }
}

//6.- dashboardMetricsServiceProvider expone la instancia para permitir overrides en tests.
final dashboardMetricsServiceProvider = Provider<DashboardMetricsService>((ref) {
  return const DashboardMetricsService();
});

//7.- dashboardMetricsProvider consulta el servicio usando el rider autenticado.
final dashboardMetricsProvider = FutureProvider<DashboardMetrics>((ref) async {
  final rider = ref.watch(signedInRiderProvider);
  final service = ref.watch(dashboardMetricsServiceProvider);
  if (rider == null) {
    throw StateError('Se requiere un rider autenticado para cargar el tablero.');
  }
  return service.loadMetrics(rider);
});
