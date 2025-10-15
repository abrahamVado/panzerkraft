import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart';

import 'package:mictlan_client/main.dart';
import 'package:mictlan_client/models/ride_route_models.dart';
import 'package:mictlan_client/providers/auction/auction_controller.dart';
import 'package:mictlan_client/providers/ride_creation_providers.dart';
import 'package:mictlan_client/screens/auth/login_screen.dart';
import 'package:mictlan_client/screens/dashboard/dashboard_screen.dart';
import 'package:mictlan_client/screens/ride_creation/auction_screen.dart';
import 'package:mictlan_client/screens/ride_creation/ride_map_screen.dart';
import 'package:mictlan_client/screens/ride_creation/route_selection_screen.dart';
import 'package:mictlan_client/services/auction/bid_generator.dart';
import 'package:mictlan_client/services/location/directions_service.dart';
import 'package:mictlan_client/services/location/place_autocomplete_service.dart';
import 'package:mictlan_client/services/location/ride_location_service.dart';

class _FakeGoogleMapsFlutterPlatform extends FakeGoogleMapsFlutterPlatform {}

class _TestRideLocationService extends RideLocationService {
  const _TestRideLocationService();

  @override
  Future<RideLocationResult> fetchCurrentLocation() async {
    //1.- Forzamos éxito inmediato para centrar el mapa sin depender del GPS real.
    return const RideLocationResult(
      status: RideLocationStatus.success,
      position: LatLng(19.4, -99.13),
    );
  }
}

class _TestPlaceAutocompleteService extends PlaceAutocompleteService {
  _TestPlaceAutocompleteService() : super(apiKey: 'integration');

  final Map<String, RideWaypoint> _catalog = {
    'origin': RideWaypoint(
      placeId: 'origin',
      description: 'Alpha Base',
      location: const LatLng(19.41, -99.12),
    ),
    'destination': RideWaypoint(
      placeId: 'destination',
      description: 'Beta Station',
      location: const LatLng(19.45, -99.11),
    ),
  };

  @override
  Future<List<PlaceSuggestion>> search(String query) async {
    //2.- Respondemos sugerencias en memoria filtrando por descripción.
    return _catalog.values
        .where(
          (waypoint) =>
              waypoint.description.toLowerCase().contains(query.toLowerCase()),
        )
        .map(
          (waypoint) => PlaceSuggestion(
            description: waypoint.description,
            placeId: waypoint.placeId,
          ),
        )
        .toList();
  }

  @override
  Future<RideWaypoint?> resolveSuggestion(PlaceSuggestion suggestion) async {
    //3.- map lookup entrega coordenadas determinísticas para la prueba.
    return _catalog[suggestion.placeId];
  }
}

class _TestDirectionsService extends DirectionsService {
  _TestDirectionsService() : super(apiKey: 'integration');

  @override
  Future<List<RideRouteOption>> routesBetween(
    LatLng origin,
    LatLng destination,
  ) async {
    //4.- Devolvemos rutas predecibles para simplificar las aserciones.
    return const [
      RideRouteOption(
        id: 'fastest',
        polyline: '_p~iF~ps|U_ulLnnqC_mqNvxq`@',
        distanceMeters: 1200,
        durationSeconds: 600,
        summary: 'Fastest',
      ),
      RideRouteOption(
        id: 'scenic',
        polyline: '_ulLnnqC_mqNvxq`@_p~iF~ps|U',
        distanceMeters: 1500,
        durationSeconds: 780,
        summary: 'Scenic',
      ),
    ];
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    //5.- Sustituimos la plataforma de Google Maps para evitar dependencias nativas en tests.
    GoogleMapsFlutterPlatform.instance = _FakeGoogleMapsFlutterPlatform();
  });

  testWidgets('permite completar el flujo de taxi hasta la subasta', (
    tester,
  ) async {
    //6.- Configuramos overrides para simular servicios externos y temporizadores.
    final container = ProviderContainer(
      overrides: [
        rideLocationServiceProvider.overrideWithValue(
          const _TestRideLocationService(),
        ),
        placeAutocompleteServiceProvider.overrideWithValue(
          _TestPlaceAutocompleteService(),
        ),
        directionsServiceProvider.overrideWithValue(_TestDirectionsService()),
        auctionTimingConfigProvider.overrideWithValue(
          AuctionTimingConfig(
            tickInterval: Duration(milliseconds: 100),
            minCountdown: Duration(milliseconds: 400),
            maxCountdown: Duration(milliseconds: 400),
          ),
        ),
        auctionTickerProvider.overrideWithValue(
          (interval) =>
              Stream.periodic(interval, (count) => interval * (count + 1)),
        ),
        bidGeneratorProvider.overrideWithValue(
          BidGenerator(random: Random(4), spread: 0.05),
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MictlanApp(),
      ),
    );
    await tester.pumpAndSettle();

    //7.- Iniciamos sesión con credenciales válidas para desbloquear el dashboard.
    await tester.enterText(
      find.byKey(loginEmailFieldKey),
      'itzel.rider@example.com',
    );
    await tester.enterText(find.byKey(loginPasswordFieldKey), 'quetzal123');
    await tester.tap(find.byKey(loginSubmitButtonKey));
    await tester.pumpAndSettle();

    expect(find.byType(DashboardScreen), findsOneWidget);

    //8.- Lanzamos el CTA principal y elegimos crear el viaje para nosotros mismos.
    await tester.tap(find.byKey(dashboardCreateRideButtonKey));
    await tester.pumpAndSettle();

    expect(find.byType(RideMapScreen), findsOneWidget);

    await tester.tap(find.byKey(rideMapMenuButtonKey));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(rideMapModeForSelfKey));
    await tester.pumpAndSettle();

    //9.- Completamos el formulario de ruta usando las sugerencias simuladas.
    expect(find.byType(RouteSelectionScreen), findsOneWidget);

    await tester.enterText(find.byKey(routeSelectionOriginFieldKey), 'Alpha');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text('Alpha Base'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(routeSelectionDestinationFieldKey),
      'Beta',
    );
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text('Beta Station'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byKey(const Key('route_option_0')), findsOneWidget);
    await tester.tap(find.byKey(const Key('route_option_0')));
    await tester.pump();

    final startButton = find.byKey(routeSelectionStartButtonKey);
    expect(tester.widget<FilledButton>(startButton).onPressed, isNotNull);

    await tester.tap(startButton);
    await tester.pumpAndSettle();

    //10.- En la pantalla de subasta seleccionamos una oferta y verificamos el conteo regresivo.
    expect(find.byType(AuctionScreen), findsOneWidget);
    await tester.tap(find.byType(Card).first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Buscando conductor...'), findsOneWidget);
    expect(find.textContaining('Oferta elegida'), findsOneWidget);
  });
}
