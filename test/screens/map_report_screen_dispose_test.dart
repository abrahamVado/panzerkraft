import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

import 'package:ubberapp/screens/map_report_screen.dart';
import 'package:ubberapp/services/api.dart';
import 'package:ubberapp/services/folio_repository.dart';
import 'package:ubberapp/services/google_maps_availability.dart';
import 'package:ubberapp/services/location_service.dart';
import 'package:ubberapp/services/session_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    //1.- Forzamos que Google Maps aparezca disponible en pruebas.
    GoogleMapsAvailability.debugOverride(() async => true);
  });

  tearDown(() {
    //2.- Restauramos la implementación real tras cada escenario.
    GoogleMapsAvailability.debugReset();
  });

  testWidgets('Map controller is disposed when screen unmounts', (tester) async {
    //3.- Preparamos dependencias simuladas para evitar canales nativos.
    final session = _FakeSessionService();
    final repository = _FakeFolioRepository(session);
    final api = ApiService(
      client: _FakeHttpClient(),
      session: session,
      folios: repository,
    );
    final location = LocationService(
      isServiceEnabled: () async => false,
      checkPermission: () async => LocationPermission.denied,
      requestPermission: () async => LocationPermission.denied,
      getCurrentPosition: (_) async => throw StateError('unused'),
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: MapReportScreen(
            api: api,
            session: session,
            folios: repository,
            location: location,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    //4.- Inyectamos un eliminador de prueba y desmontamos el widget.
    final state = tester.state(find.byType(MapReportScreen));
    var disposed = false;
    (state as dynamic).registerMapDisposer(() async {
      disposed = true;
    });

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();

    //5.- Confirmamos que la rutina personalizada se ejecutó.
    expect(disposed, isTrue);
  });
}

class _FakeHttpClient extends http.BaseClient {
  //6.- Retornamos respuestas en memoria para las rutas usadas durante la inicialización.
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    if (request.method == 'GET' && request.url.path.endsWith('/incident-types')) {
      final body = jsonEncode([
        {
          'id': 'test',
          'name': 'Test',
          'emoji': '🧪',
          'reportType': 'test',
        }
      ]);
      return http.StreamedResponse(
        Stream<List<int>>.value(utf8.encode(body)),
        200,
      );
    }
    if (request.method == 'POST' && request.url.path.endsWith('/reports')) {
      final body = jsonEncode({
        'folio': 'ABC-123',
        'status': 'new',
        'createdAt': DateTime.now().toIso8601String(),
      });
      return http.StreamedResponse(
        Stream<List<int>>.value(utf8.encode(body)),
        200,
      );
    }
    return http.StreamedResponse(Stream<List<int>>.empty(), 404);
  }
}

class _FakeSessionService extends SessionService {
  _FakeSessionService()
      : super(
          client: _FakeHttpClient(),
          storage: InMemoryTokenStorage(),
          clock: () => DateTime.now(),
        );

  //7.- Ninguna prueba requiere sesión válida, por lo que devolvemos valores nulos.
  @override
  Future<SessionToken?> currentToken() async => null;

  @override
  Future<bool> hasValidToken() async => false;

  @override
  Future<String?> currentPhone() async => null;
}

class _FakeFolioRepository extends FolioRepository {
  _FakeFolioRepository(SessionService session)
      : super(storage: InMemoryFolioStorage(), session: session);

  //8.- No persistimos folios durante la prueba, solo regresamos colecciones vacías.
  @override
  Future<List<FolioEntry>> loadForCurrentSession() async => const [];

  @override
  Future<void> saveForCurrentSession(FolioEntry entry) async {}
}
