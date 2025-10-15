import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart';

import 'package:mictlan_client/providers/ride_creation_providers.dart';
import 'package:mictlan_client/screens/ride_creation/ride_map_screen.dart';
import 'package:mictlan_client/services/location/ride_location_service.dart';

class _FakeGoogleMapsFlutterPlatform extends FakeGoogleMapsFlutterPlatform {}

class _DeniedLocationService extends RideLocationService {
  const _DeniedLocationService();

  @override
  Future<RideLocationResult> fetchCurrentLocation() async {
    return const RideLocationResult(status: RideLocationStatus.permissionsDenied);
  }
}

class _SuccessLocationService extends RideLocationService {
  const _SuccessLocationService(this.position);

  final LatLng position;

  @override
  Future<RideLocationResult> fetchCurrentLocation() async {
    return RideLocationResult(status: RideLocationStatus.success, position: position);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    //1.- Reemplazamos la plataforma de Google Maps para evitar dependencias nativas en pruebas.
    GoogleMapsFlutterPlatform.instance = _FakeGoogleMapsFlutterPlatform();
  });

  testWidgets('muestra el mensaje cuando los permisos son denegados', (tester) async {
    final container = ProviderContainer(
      overrides: [
        rideLocationServiceProvider.overrideWithValue(const _DeniedLocationService()),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: RideMapScreen()),
      ),
    );

    await tester.pumpAndSettle();

    //2.- Al denegar permisos mostramos la advertencia apropiada en la UI.
    expect(
      find.descendant(
        of: find.byKey(rideMapPermissionMessageKey),
        matching: find.text('Necesitamos permisos de ubicación para centrar el mapa en ti.'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('persistimos el modo de viaje seleccionado', (tester) async {
    final container = ProviderContainer(
      overrides: [
        rideLocationServiceProvider.overrideWithValue(
          const _SuccessLocationService(LatLng(19.4, -99.1)),
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: RideMapScreen()),
      ),
    );

    await tester.pumpAndSettle();

    //3.- Abrimos el menú flotante y elegimos crear un viaje para otra persona.
    await tester.tap(find.byKey(rideMapMenuButtonKey));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(rideMapModeForOtherKey));
    await tester.pumpAndSettle();

    expect(container.read(rideCreationModeProvider), RideCreationMode.forOther);
  });
}
