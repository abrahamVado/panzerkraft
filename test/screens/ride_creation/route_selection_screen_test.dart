import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:mictlan_client/models/ride_route_models.dart';
import 'package:mictlan_client/providers/ride_creation_providers.dart';
import 'package:mictlan_client/screens/ride_creation/route_selection_screen.dart';
import 'package:mictlan_client/services/location/directions_service.dart';
import 'package:mictlan_client/services/location/place_autocomplete_service.dart';

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

  @override
  Future<List<RideRouteOption>> routesBetween(
    LatLng origin,
    LatLng destination,
  ) async {
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

ProviderContainer _createContainer({
  PlaceAutocompleteService? placeService,
  DirectionsService? directionsService,
}) {
  return ProviderContainer(overrides: [
    placeAutocompleteServiceProvider.overrideWithValue(
      placeService ?? FakePlaceAutocompleteService(),
    ),
    directionsServiceProvider.overrideWithValue(
      directionsService ?? FakeDirectionsService(),
    ),
  ]);
}

Widget _buildTestableScreen({
  required ProviderContainer container,
  ValueNotifier<Set<Marker>>? markersLog,
  ValueNotifier<Set<Polyline>>? polylinesLog,
}) {
  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      home: RouteSelectionScreen(
        mapBuilder: (context, markers, polylines) {
          markersLog?.value = markers;
          polylinesLog?.value = polylines;
          return const SizedBox.shrink();
        },
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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

  testWidgets('routes are rendered and selectable before enabling CTA',
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

    expect(find.byKey(const Key('route_option_0')), findsOneWidget);
    expect(find.byKey(const Key('route_option_1')), findsOneWidget);
    expect(markersLog.value.length, 2);
    expect(polylinesLog.value.isNotEmpty, isTrue);

    final startButton = find.byKey(routeSelectionStartButtonKey);
    expect(tester.widget<FilledButton>(startButton).onPressed, isNull);

    await tester.tap(find.byKey(const Key('route_option_0')));
    await tester.pump();

    expect(tester.widget<FilledButton>(startButton).onPressed, isNotNull);
  });
}
