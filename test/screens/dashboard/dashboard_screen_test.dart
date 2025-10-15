import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ubberapp/providers/auth_providers.dart';
import 'package:ubberapp/screens/dashboard/dashboard_screen.dart';
import 'package:ubberapp/services/auth/fake_credentials.dart';
import 'package:ubberapp/services/dashboard/dashboard_current_trip_service.dart';
import 'package:ubberapp/services/dashboard/dashboard_metrics_service.dart';

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
      amount: 180.50,
      durationMinutes: 22,
      distanceKm: 11.5,
      vehicleModel: 'Sedán Confort',
      driverName: 'Conductor Rider',
      driverRating: 4.9,
      driverExperienceYears: 6,
      driverPhone: '+52 55 5555 0000',
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
    expect(find.text('Banco Uno'), findsOneWidget);
    expect(find.text('itzel.rider@example.com'), findsOneWidget);
    expect(find.textContaining('Has completado 24 viajes'), findsOneWidget);
    expect(find.text('Ingresos semanales'), findsOneWidget);
    expect(find.text('\$1520.50'), findsOneWidget);
    expect(find.text('Ingresos mensuales'), findsOneWidget);
    expect(find.text('\$6400.75'), findsOneWidget);
    expect(find.text('97.0% de viajes aceptados'), findsOneWidget);
    expect(find.text('Bienvenido, Itzel Rider'), findsOneWidget);

    //4.- Revisamos que la sección de viaje en curso muestre el resumen esperado.
    expect(find.text('Pasajero: Luz Marina'), findsOneWidget);
    expect(find.text('Recoger en: Calle 5 #123'), findsOneWidget);
    expect(find.text('Destino: Aeropuerto T1'), findsOneWidget);
    expect(find.text('Estado: En curso'), findsOneWidget);
    expect(find.text('Placas: TAX-456'), findsOneWidget);
    expect(find.text('ETA: 8 min'), findsOneWidget);
    expect(find.text('Monto estimado: 180.50 MXN'), findsOneWidget);
    expect(find.text('Duración estimada: 22 min'), findsOneWidget);
    expect(find.text('Distancia estimada: 11.5 km'), findsOneWidget);
    expect(find.text('Anticipa viajes'), findsOneWidget);
    expect(find.text('Soporte 24/7'), findsOneWidget);

    //5.- Confirmamos que el CTA principal permanezca habilitado para iniciar un nuevo viaje.
    final button = tester.widget<FilledButton>(find.byKey(dashboardCreateRideButtonKey));
    expect(button.onPressed, isNotNull);

    //6.- Validamos que el botón de alerta esté disponible cuando existe un viaje aceptado.
    final panicButton = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Alerta').first,
    );
    expect(panicButton.onPressed, isNotNull);
  });

  testWidgets('deshabilita el botón de pánico sin viaje aceptado', (tester) async {
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

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          signedInRiderProvider.overrideWith((ref) => StateController<RiderAccount?>(rider)),
          dashboardMetricsProvider.overrideWith((ref) => Future.value(metrics)),
          dashboardCurrentTripProvider.overrideWith((ref) => Future.value(null)),
        ],
        child: const MaterialApp(home: DashboardScreen()),
      ),
    );

    await tester.pumpAndSettle();

    //7.- Corroboramos que el resumen refleje la indisponibilidad del botón.
    expect(find.text('Sin viaje aceptado'), findsOneWidget);
    final panicButton = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Alerta').first,
    );
    expect(panicButton.onPressed, isNull);
  });
}
