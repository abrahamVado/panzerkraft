import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ubberapp/providers/auth_providers.dart';
import 'package:ubberapp/providers/dashboard/travel_history_controller.dart';
import 'package:ubberapp/services/auth/fake_credentials.dart';
import 'package:ubberapp/services/dashboard/dashboard_travel_history_service.dart';

//1.- _StubTravelHistoryService responde con páginas predecibles para los tests.
class _StubTravelHistoryService extends DashboardTravelHistoryService {
  _StubTravelHistoryService(this.pages);

  final Map<int, TravelHistoryPage> pages;

  @override
  Future<TravelHistoryPage> fetchPage(
    RiderAccount rider, {
    required int pageIndex,
    required int pageSize,
  }) async {
    return pages[pageIndex]!;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('nextPage avanza y expone la paginación esperada', () async {
    //2.- Definimos dos páginas para validar transiciones consecutivas.
    const rider = RiderAccount(email: 'test@rider.app', name: 'Test Rider');
    final firstPage = TravelHistoryPage(
      entries: [
        TravelHistoryEntry(
          date: DateTime(2024, 1, 10),
          origin: 'Origen 1',
          destination: 'Destino 1',
          fare: 120,
          distanceKm: 8,
          durationMinutes: 15,
        ),
      ],
      pageIndex: 0,
      pageSize: 1,
      totalCount: 2,
    );
    final secondPage = TravelHistoryPage(
      entries: [
        TravelHistoryEntry(
          date: DateTime(2024, 1, 9),
          origin: 'Origen 2',
          destination: 'Destino 2',
          fare: 140,
          distanceKm: 10,
          durationMinutes: 20,
        ),
      ],
      pageIndex: 1,
      pageSize: 1,
      totalCount: 2,
    );

    final container = ProviderContainer(
      overrides: [
        signedInRiderProvider.overrideWith((ref) => StateController<RiderAccount?>(rider)),
        dashboardTravelHistoryServiceProvider
            .overrideWithValue(_StubTravelHistoryService({0: firstPage, 1: secondPage})),
      ],
    );
    addTearDown(container.dispose);

    //3.- Inicialmente el estado se encuentra en carga hasta obtener la primera página.
    final notifier = container.read(travelHistoryControllerProvider.notifier);
    await notifier.loadPage(0);
    final initialState = container.read(travelHistoryControllerProvider);
    expect(initialState.value, firstPage);

    //4.- nextPage recupera la siguiente página y la publica en el estado.
    await notifier.nextPage();
    final secondState = container.read(travelHistoryControllerProvider);
    expect(secondState.value, secondPage);
  });
}
