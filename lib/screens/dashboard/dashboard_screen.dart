import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/auth_providers.dart';
import '../../services/dashboard/dashboard_current_trip_service.dart';
import '../../services/dashboard/dashboard_metrics_service.dart';
import '../ride_creation/ride_map_screen.dart';

//1.- dashboardCreateRideButtonKey permite que las pruebas verifiquen el CTA principal.
const dashboardCreateRideButtonKey = Key('dashboard_create_ride_button');

//2.- DashboardScreen compone el tablero inicial posterior al login.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    //3.- build observa el rider, métricas agregadas y viaje actual del tablero.
    final rider = ref.watch(signedInRiderProvider);
    final metricsAsync = ref.watch(dashboardMetricsProvider);
    final currentTripAsync = ref.watch(dashboardCurrentTripProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Panel de control')),
      body: rider == null
          ? const Center(child: Text('Inicia sesión para ver tu tablero.'))
          : metricsAsync.when(
              data: (metrics) {
                final currentTripSection = currentTripAsync.when(
                  data: (trip) => _buildCurrentTrip(trip),
                  loading: () => const Text('Cargando viaje en curso...'),
                  error: (error, stackTrace) => const Text('No pudimos cargar tu viaje actual.'),
                );
                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text(
                      'Hola, ${rider.name}',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 16),
                    _DashboardSection(
                      title: 'Información bancaria',
                      children: [
                        Text('Banco: ${metrics.bankName}'),
                        Text('Cuenta: ${metrics.bankAccount}'),
                      ],
                    ),
                    _DashboardSection(
                      title: 'Historial de viajes',
                      children: [
                        Text('Completados esta semana: ${metrics.completedRidesThisWeek}'),
                        Text('Cancelados esta semana: ${metrics.cancelledRidesThisWeek}'),
                      ],
                    ),
                    _DashboardSection(
                      title: 'Totales',
                      children: [
                        Text('Ingresos semanales: \$${metrics.weeklyEarnings.toStringAsFixed(2)}'),
                        Text('Ingresos mensuales: \$${metrics.monthlyEarnings.toStringAsFixed(2)}'),
                        Text('Tasa de aceptación: ${metrics.acceptanceRate}%'),
                      ],
                    ),
                    _DashboardSection(
                      title: 'Evaluación',
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.star, color: Colors.amber),
                            const SizedBox(width: 8),
                            Text('${metrics.evaluationScore} / 5.0'),
                          ],
                        ),
                      ],
                    ),
                    _DashboardSection(
                      title: 'Viaje en curso',
                      children: [currentTripSection],
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      key: dashboardCreateRideButtonKey,
                      onPressed: () {
                        //6.- Navegamos al mapa para configurar el nuevo viaje.
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const RideMapScreen()),
                        );
                      },
                      child: const Text('Crear viaje de taxi'),
                    ),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Ocurrió un problema al cargar tus métricas. Intenta nuevamente más tarde.',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
    );
  }

  //4.- _buildCurrentTrip presenta el estado del viaje o un fallback cuando no existe.
  Widget _buildCurrentTrip(DashboardCurrentTrip? trip) {
    if (trip == null) {
      return const Text('No tienes viajes activos en este momento.');
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Pasajero: ${trip.passengerName}'),
        Text('Recoger en: ${trip.pickupAddress}'),
        Text('Destino: ${trip.dropoffAddress}'),
        Text('Estado: ${trip.status}'),
        Text('Placas: ${trip.vehiclePlate}'),
        Text('ETA: ${trip.etaMinutes} min'),
      ],
    );
  }
}

//5.- _DashboardSection estiliza cada bloque de información del tablero.
class _DashboardSection extends StatelessWidget {
  const _DashboardSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      ),
    );
  }
}
