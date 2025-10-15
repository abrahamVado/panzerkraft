import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ubberapp/providers/auth_providers.dart';
import 'package:ubberapp/providers/dashboard/travel_history_controller.dart';
import 'package:ubberapp/screens/dashboard/travel/travel_history_screen.dart';
import 'package:ubberapp/services/auth/fake_credentials.dart';
import 'package:ubberapp/services/dashboard/dashboard_travel_history_service.dart';

//1.- _FakeTravelHistoryService devuelve una única página controlada para las pruebas.
class _FakeTravelHistoryService extends DashboardTravelHistoryService {
  const _FakeTravelHistoryService();

  @override
  Future<TravelHistoryPage> fetchPage(
    RiderAccount rider, {
    required int pageIndex,
    required int pageSize,
  }) async {
    return TravelHistoryPage(
      entries: const [
        TravelHistoryEntry(
          date: DateTime(2024, 6, 15),
          origin: 'Base Central',
          destination: 'Aeropuerto',
          fare: 250.5,
          distanceKm: 12.3,
          durationMinutes: 28,
        ),
      ],
      pageIndex: 0,
      pageSize: pageSize,
      totalCount: 1,
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('travel history tile renders the default thumbnail asset',
      (tester) async {
    const rider = RiderAccount(email: 'tester@example.com', name: 'Tester');
    final container = ProviderContainer(overrides: [
      dashboardTravelHistoryServiceProvider
          .overrideWithValue(const _FakeTravelHistoryService()),
    ]);
    addTearDown(container.dispose);
    container.read(signedInRiderProvider.notifier).state = rider;

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: TravelHistoryScreen(),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    final thumbnailFinder = find.byKey(travelHistoryThumbnailKey);
    expect(thumbnailFinder, findsOneWidget);

    final imageWidget = tester.widget<Image>(thumbnailFinder);
    expect(imageWidget.image, isA<AssetImage>());
    final assetImage = imageWidget.image as AssetImage;
    expect(assetImage.assetName, travelHistoryThumbnailAsset);
  });
}
