import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/dashboard/dashboard_travel_history_service.dart';
import '../auth_providers.dart';

//1.- TravelHistoryController administra paginación y recarga del historial de viajes.
class TravelHistoryController
    extends AutoDisposeNotifier<AsyncValue<TravelHistoryPage>> {
  TravelHistoryController() : _currentPage = 0;

  static const int defaultPageSize = 10;

  int _currentPage;

  @override
  AsyncValue<TravelHistoryPage> build() {
    Future.microtask(() => loadPage(0));
    return const AsyncValue.loading();
  }

  //2.- loadPage recupera y publica la página solicitada preservando errores.
  Future<void> loadPage(int pageIndex) async {
    final rider = ref.read(signedInRiderProvider);
    if (rider == null) {
      state = AsyncValue.error(
        StateError('Necesitas iniciar sesión para ver tu historial.'),
        StackTrace.current,
      );
      return;
    }
    state = const AsyncValue.loading();
    final service = ref.read(dashboardTravelHistoryServiceProvider);
    try {
      final page = await service.fetchPage(
        rider,
        pageIndex: pageIndex,
        pageSize: defaultPageSize,
      );
      _currentPage = pageIndex;
      state = AsyncValue.data(page);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  //3.- nextPage avanza mientras existan páginas disponibles.
  Future<void> nextPage() async {
    final current = state.valueOrNull;
    if (current == null || !current.hasNextPage) {
      return;
    }
    await loadPage(_currentPage + 1);
  }

  //4.- previousPage retrocede evitando índices negativos.
  Future<void> previousPage() async {
    if (_currentPage == 0) {
      return;
    }
    await loadPage(_currentPage - 1);
  }

  //5.- refresh vuelve a descargar la página activa con retroalimentación inmediata.
  Future<void> refresh() async {
    await loadPage(_currentPage);
  }
}

//6.- travelHistoryControllerProvider expone el controlador a la capa de UI.
final travelHistoryControllerProvider = AutoDisposeNotifierProvider<
    TravelHistoryController, AsyncValue<TravelHistoryPage>>(TravelHistoryController.new);
