import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:ubberapp/models/ride_route_models.dart';
import 'package:ubberapp/providers/ride_creation_providers.dart';
import 'package:ubberapp/screens/ride_creation/route_selection_screen.dart';
import 'package:ubberapp/services/location/directions_service.dart';
import 'package:ubberapp/services/location/place_autocomplete_service.dart';
import 'package:ubberapp/services/location/ride_location_service.dart';

//1.- FakePlaceAutocompleteService devuelve datos determinísticos sin tocar la red real.
class FakePlaceAutocompleteService extends PlaceAutocompleteService {
  FakePlaceAutocompleteService()
      : super(
          apiKey: 'fake',
        );

  final Map<String, RideWaypoint> _waypoints = {
    'origin': RideWaypoint(
      placeId: 'origin',
      description: 'Alpha Base',
      location: const LatLng(19.0, -99.0),
    ),
    'destination': RideWaypoint(
      placeId: 'destination',
      description: 'Beta Station',
      location: const LatLng(19.1, -99.1),
    ),
  };

  @override
  Future<List<PlaceSuggestion>> search(String query) async {
    return _waypoints.values
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
    return _waypoints[suggestion.placeId];
  }
}

//2.- FakeDirectionsService proporciona rutas predefinidas para validar el renderizado.
class FakeDirectionsService extends DirectionsService {
  FakeDirectionsService()
      : super(
          apiKey: 'fake',
        );

  LatLng? lastOrigin;
  LatLng? lastDestination;

  @override
  Future<List<RideRouteOption>> routesBetween(
    LatLng origin,
    LatLng destination,
  ) async {
    lastOrigin = origin;
    lastDestination = destination;
    return [
      const RideRouteOption(
        id: 'primary',
        polyline: '_p~iF~ps|U_ulLnnqC_mqNvxq`@',
        distanceMeters: 1200,
        durationSeconds: 600,
        summary: 'Fastest',
      ),
      const RideRouteOption(
        id: 'scenic',
        polyline: '_ulLnnqC_mqNvxq`@_p~iF~ps|U',
        distanceMeters: 1500,
        durationSeconds: 780,
        summary: 'Scenic',
      ),
    ];
  }
}

//3.- FakeRideLocationService evita dependencias de geolocalización durante las pruebas.
class FakeRideLocationService extends RideLocationService {
  FakeRideLocationService({RideLocationResult? result})
      : _result = result ??
            const RideLocationResult(
              status: RideLocationStatus.success,
              position: LatLng(19.05, -99.05),
            ),
        super();

  final RideLocationResult _result;

  @override
  Future<RideLocationResult> fetchCurrentLocation() async => _result;
}

ProviderContainer _createContainer({
  PlaceAutocompleteService? placeService,
  DirectionsService? directionsService,
  RideLocationService? locationService,
}) {
  return ProviderContainer(overrides: [
    placeAutocompleteServiceProvider.overrideWithValue(
      placeService ?? FakePlaceAutocompleteService(),
    ),
    directionsServiceProvider.overrideWithValue(
      directionsService ?? FakeDirectionsService(),
    ),
    rideLocationServiceProvider.overrideWithValue(
      locationService ?? FakeRideLocationService(),
    ),
  ]);
}

Widget _buildTestableScreen({
  required ProviderContainer container,
  ValueNotifier<Set<Marker>>? markersLog,
  ValueNotifier<Set<Polyline>>? polylinesLog,
  ValueNotifier<void Function(LatLng position)?>? onMapTapLog,
}) {
  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      home: RouteSelectionScreen(
        mapBuilder: (context, markers, polylines, onTap) {
          markersLog?.value = markers;
          polylinesLog?.value = polylines;
          onMapTapLog?.value = onTap;
          return const SizedBox.shrink();
        },
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('map location error message matches RideLocationStatus cases', () {
    //1.- Verificamos que cada estado se traduzca al texto mostrado en SnackBar.
    expect(
      _mapLocationErrorMessage(RideLocationStatus.permissionsDenied),
      'We need location permissions to use your current position.',
    );
    expect(
      _mapLocationErrorMessage(RideLocationStatus.servicesDisabled),
      'Enable GPS services to use your current location.',
    );
    expect(
      _mapLocationErrorMessage(RideLocationStatus.failure),
      'We could not determine your current location.',
    );
    expect(
      _mapLocationErrorMessage(RideLocationStatus.success),
      'Location resolved successfully.',
    );
  });

  testWidgets('form validation surfaces errors when fields are empty',
      (tester) async {
    final container = _createContainer();
    await tester.pumpWidget(_buildTestableScreen(container: container));

    final formFinder = find.byType(Form);
    final formState = tester.state<FormState>(formFinder);
    expect(formState.validate(), isFalse);
    await tester.pumpAndSettle();

    expect(find.text('Select an origin'), findsOneWidget);
    expect(find.text('Select a destination'), findsOneWidget);
  });

  testWidgets('routes render summary and CTA enables automatically',
      (tester) async {
    final container = _createContainer();
    final markersLog = ValueNotifier<Set<Marker>>({});
    final polylinesLog = ValueNotifier<Set<Polyline>>({});

    await tester.pumpWidget(
      _buildTestableScreen(
        container: container,
        markersLog: markersLog,
        polylinesLog: polylinesLog,
      ),
    );

    await tester.enterText(find.byKey(routeSelectionOriginFieldKey), 'Alpha');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text('Alpha Base'));
    await tester.pumpAndSettle();

    await tester.enterText(
        find.byKey(routeSelectionDestinationFieldKey), 'Beta');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text('Beta Station'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    final calculateButton = find.byKey(routeSelectionCalculateButtonKey);
    expect(calculateButton, findsOneWidget);

    await tester.tap(calculateButton);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byKey(const Key('route_option_0')), findsOneWidget);
    expect(find.byKey(const Key('route_option_1')), findsOneWidget);
    expect(markersLog.value.length, 2);
    expect(polylinesLog.value.isNotEmpty, isTrue);

    final startButton = find.byKey(routeSelectionStartButtonKey);
    expect(tester.widget<FilledButton>(startButton).onPressed, isNotNull);
    expect(find.textContaining('Viaje estimado'), findsOneWidget);
    expect(find.textContaining('Ruta: Fastest'), findsOneWidget);

    await tester.tap(find.byKey(const Key('route_option_1')));
    await tester.pump();

    expect(find.textContaining('Ruta: Scenic'), findsOneWidget);
  });

  testWidgets('selected route polyline stands out with accent styling',
      (tester) async {
    final container = _createContainer();
    final polylinesLog = ValueNotifier<Set<Polyline>>({});

    await tester.pumpWidget(
      _buildTestableScreen(
        container: container,
        polylinesLog: polylinesLog,
      ),
    );

    await tester.enterText(find.byKey(routeSelectionOriginFieldKey), 'Alpha');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text('Alpha Base'));
    await tester.pumpAndSettle();

    await tester.enterText(
        find.byKey(routeSelectionDestinationFieldKey), 'Beta');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text('Beta Station'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    final calculateButton = find.byKey(routeSelectionCalculateButtonKey);
    expect(calculateButton, findsOneWidget);

    await tester.tap(calculateButton);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(polylinesLog.value, isNotEmpty);
    final selectedPolyline = polylinesLog.value.firstWhere(
      (polyline) => polyline.width == 6,
      orElse: () => throw StateError('No highlighted polyline found'),
    );
    expect(selectedPolyline.color, Colors.blueAccent);
    expect(selectedPolyline.zIndex, 1);
  });

  testWidgets('demo button fills origin, destination and triggers directions',
      (tester) async {
    final directions = FakeDirectionsService();
    final container = _createContainer(directionsService: directions);

    await tester.pumpWidget(_buildTestableScreen(container: container));

    await tester.tap(find.byKey(routeSelectionUseDemoButtonKey));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Mexico City Historic Center'), findsOneWidget);
    expect(find.text('Teotihuacán Archaeological Site'), findsOneWidget);
    expect(
      directions.lastOrigin,
      const LatLng(19.4326, -99.1332),
    );
    expect(
      directions.lastDestination,
      const LatLng(19.7008, -98.8456),
    );
    expect(find.byKey(const Key('route_option_0')), findsOneWidget);
    expect(find.byKey(const Key('route_option_1')), findsOneWidget);
  });

  testWidgets('calculate button uses current location when origin missing',
      (tester) async {
    final locationResult = const RideLocationResult(
      status: RideLocationStatus.success,
      position: LatLng(19.25, -99.25),
    );
    final locationService = FakeRideLocationService(result: locationResult);
    final directions = FakeDirectionsService();
    final markersLog = ValueNotifier<Set<Marker>>({});
    final container = _createContainer(
      directionsService: directions,
      locationService: locationService,
    );

    await tester.pumpWidget(
      _buildTestableScreen(
        container: container,
        markersLog: markersLog,
      ),
    );

    await tester.enterText(
      find.byKey(routeSelectionDestinationFieldKey),
      'Beta',
    );
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text('Beta Station'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    await tester.tap(find.byKey(routeSelectionCalculateButtonKey));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.textContaining('Origen seleccionado'), findsOneWidget);
    expect(directions.lastOrigin, locationResult.position);
    expect(directions.lastDestination, const LatLng(19.1, -99.1));
    expect(
      markersLog.value.any((marker) => marker.markerId.value == 'origin'),
      isTrue,
    );
  });

  testWidgets('tocar el mapa llena el origen y el destino según el foco',
      (tester) async {
    final container = _createContainer();
    final mapTapLog = ValueNotifier<void Function(LatLng)?>(null);

    await tester.pumpWidget(
      _buildTestableScreen(
        container: container,
        onMapTapLog: mapTapLog,
      ),
    );

    expect(mapTapLog.value, isNotNull);

    mapTapLog.value!(const LatLng(19.2, -99.2));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Origen seleccionado'),
      findsOneWidget,
    );

    mapTapLog.value!(const LatLng(19.3, -99.3));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Destino seleccionado'),
      findsOneWidget,
    );
  });
}
