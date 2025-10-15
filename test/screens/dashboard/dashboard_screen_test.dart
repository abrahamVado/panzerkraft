import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mictlan_client/providers/auth_providers.dart';
import 'package:mictlan_client/screens/dashboard/dashboard_screen.dart';
import 'package:mictlan_client/services/auth/fake_credentials.dart';
import 'package:mictlan_client/services/dashboard/dashboard_current_trip_service.dart';
import 'package:mictlan_client/services/dashboard/dashboard_metrics_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('muestra datos del tablero y habilita el CTA', (tester) async {
    //1.- Definimos datos deterministas para reemplazar los servicios en el árbol de pruebas.
    const rider = RiderAccount(email: 'itzel.rider@example.com', name: 'Itzel Rider');
    const metrics = DashboardMetrics(
      bankName: 'Banco Uno',
      bankAccount: '**** 1234',
      completedRidesThisWeek: 24,
      cancelledRidesThisWeek: 1,
      weeklyEarnings: 1520.50,
      monthlyEarnings: 6400.75,
      evaluationScore: 4.8,
      acceptanceRate: 97,
    );
    const currentTrip = DashboardCurrentTrip(
      passengerName: 'Luz Marina',
      pickupAddress: 'Calle 5 #123',
      dropoffAddress: 'Aeropuerto T1',
      status: 'En curso',
      vehiclePlate: 'TAX-456',
      etaMinutes: 8,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          signedInRiderProvider.overrideWith((ref) => StateController<RiderAccount?>(rider)),
          dashboardMetricsProvider.overrideWith((ref) => Future.value(metrics)),
          dashboardCurrentTripProvider.overrideWith((ref) => Future.value(currentTrip)),
        ],
        child: const MaterialApp(home: DashboardScreen()),
      ),
    );

    await tester.pumpAndSettle();

    //2.- Comprobamos que el saludo incluya el nombre del rider autenticado.
    expect(find.textContaining('Hola, Itzel Rider'), findsOneWidget);

    //3.- Validamos que las secciones rendericen los datos provistos por los mocks.
    expect(find.text('Banco: Banco Uno'), findsOneWidget);
    expect(find.text('Cuenta: **** 1234'), findsOneWidget);
    expect(find.text('Completados esta semana: 24'), findsOneWidget);
    expect(find.text('Cancelados esta semana: 1'), findsOneWidget);
    expect(find.text('Ingresos semanales: \$1520.50'), findsOneWidget);
    expect(find.text('Ingresos mensuales: \$6400.75'), findsOneWidget);
    expect(find.text('Tasa de aceptación: 97%'), findsOneWidget);
    expect(find.text('4.8 / 5.0'), findsOneWidget);

    //4.- Revisamos que la sección de viaje en curso muestre el resumen esperado.
    expect(find.text('Pasajero: Luz Marina'), findsOneWidget);
    expect(find.text('Recoger en: Calle 5 #123'), findsOneWidget);
    expect(find.text('Destino: Aeropuerto T1'), findsOneWidget);
    expect(find.text('Estado: En curso'), findsOneWidget);
    expect(find.text('Placas: TAX-456'), findsOneWidget);
    expect(find.text('ETA: 8 min'), findsOneWidget);

    //5.- Confirmamos que el CTA principal permanezca habilitado para iniciar un nuevo viaje.
    final button = tester.widget<ElevatedButton>(find.byKey(dashboardCreateRideButtonKey));
    expect(button.onPressed, isNotNull);
  });
}
