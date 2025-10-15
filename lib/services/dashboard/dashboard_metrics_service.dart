import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/auth_providers.dart';
import '../auth/fake_credentials.dart';

//1.- DashboardMetrics encapsula los datos agregados que consume la pantalla principal.
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
  });

  final String bankName;
  final String bankAccount;
  final int completedRidesThisWeek;
  final int cancelledRidesThisWeek;
  final double weeklyEarnings;
  final double monthlyEarnings;
  final double evaluationScore;
  final int acceptanceRate;
}

//2.- DashboardMetricsService simula un backend devolviendo datos deterministas.
class DashboardMetricsService {
  const DashboardMetricsService();

  //3.- loadMetrics devuelve cifras fijas derivadas del correo para pruebas consistentes.
  Future<DashboardMetrics> loadMetrics(RiderAccount rider) async {
    final seed = rider.email.hashCode.abs();
    final completed = 22 + seed % 5;
    final cancelled = 1 + seed % 2;
    final weeklyEarnings = 1350.75 + (seed % 250);
    final monthlyEarnings = 5600.20 + (seed % 500);
    final evaluationScore = 4.6 + (seed % 4) * 0.1;
    final acceptanceRate = 94 + seed % 5;

    return DashboardMetrics(
      bankName: 'Banco Andariego',
      bankAccount: '**** ${seed % 9000 + 1000}',
      completedRidesThisWeek: completed,
      cancelledRidesThisWeek: cancelled,
      weeklyEarnings: double.parse(weeklyEarnings.toStringAsFixed(2)),
      monthlyEarnings: double.parse(monthlyEarnings.toStringAsFixed(2)),
      evaluationScore: double.parse(evaluationScore.toStringAsFixed(1)),
      acceptanceRate: acceptanceRate,
    );
  }
}

//4.- dashboardMetricsServiceProvider expone la instancia para permitir overrides en tests.
final dashboardMetricsServiceProvider = Provider<DashboardMetricsService>((ref) {
  return const DashboardMetricsService();
});

//5.- dashboardMetricsProvider consulta el servicio usando el rider autenticado.
final dashboardMetricsProvider = FutureProvider<DashboardMetrics>((ref) async {
  final rider = ref.watch(signedInRiderProvider);
  final service = ref.watch(dashboardMetricsServiceProvider);
  if (rider == null) {
    throw StateError('Se requiere un rider autenticado para cargar el tablero.');
  }
  return service.loadMetrics(rider);
});
