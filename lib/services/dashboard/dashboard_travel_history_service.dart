import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/fake_credentials.dart';

//1.- TravelHistoryEntry modela un viaje completado con metadatos relevantes.
class TravelHistoryEntry {
  const TravelHistoryEntry({
    required this.date,
    required this.origin,
    required this.destination,
    required this.fare,
    required this.distanceKm,
    required this.durationMinutes,
  });

  final DateTime date;
  final String origin;
  final String destination;
  final double fare;
  final double distanceKm;
  final int durationMinutes;
}

//2.- TravelHistoryPage agrupa una página paginada junto con información auxiliar.
class TravelHistoryPage {
  const TravelHistoryPage({
    required this.entries,
    required this.pageIndex,
    required this.pageSize,
    required this.totalCount,
  });

  final List<TravelHistoryEntry> entries;
  final int pageIndex;
  final int pageSize;
  final int totalCount;

  int get totalPages => (totalCount / pageSize).ceil();
  int get displayPage => pageIndex + 1;
  bool get hasPreviousPage => pageIndex > 0;
  bool get hasNextPage => displayPage < totalPages;
}

//3.- DashboardTravelHistoryService genera datos reproducibles divididos por página.
class DashboardTravelHistoryService {
  const DashboardTravelHistoryService();

  Future<TravelHistoryPage> fetchPage(
    RiderAccount rider, {
    required int pageIndex,
    required int pageSize,
  }) async {
    final totalCount = 36 + rider.email.length % 15;
    final random = Random(rider.email.hashCode + pageIndex);
    final start = pageIndex * pageSize;
    if (start >= totalCount) {
      return TravelHistoryPage(
        entries: const [],
        pageIndex: pageIndex,
        pageSize: pageSize,
        totalCount: totalCount,
      );
    }
    final endExclusive = min(start + pageSize, totalCount);
    final entries = <TravelHistoryEntry>[];
    for (var i = start; i < endExclusive; i++) {
      final dayOffset = i + 1;
      entries.add(
        TravelHistoryEntry(
          date: DateTime.now().subtract(Duration(days: dayOffset)),
          origin: 'Punto ${100 + (i % 25)}',
          destination: 'Destino ${200 + (i % 30)}',
          fare: double.parse((random.nextDouble() * 180 + 50).toStringAsFixed(2)),
          distanceKm: double.parse((random.nextDouble() * 12 + 2).toStringAsFixed(1)),
          durationMinutes: 10 + random.nextInt(25),
        ),
      );
    }
    return TravelHistoryPage(
      entries: entries,
      pageIndex: pageIndex,
      pageSize: pageSize,
      totalCount: totalCount,
    );
  }
}

//4.- dashboardTravelHistoryServiceProvider habilita overrides controlados en pruebas.
final dashboardTravelHistoryServiceProvider =
    Provider<DashboardTravelHistoryService>((ref) {
  return const DashboardTravelHistoryService();
});

