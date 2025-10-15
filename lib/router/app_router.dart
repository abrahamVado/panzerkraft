import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_providers.dart';
import '../screens/auth/login_screen.dart';
import '../screens/dashboard/bank/bank_information_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/dashboard/travel/travel_history_screen.dart';
import '../screens/dashboard/trip/current_trip_details_screen.dart';
import '../screens/dashboard/trip/driver_profile_screen.dart';
import '../screens/ride_creation/auction_screen.dart';
import '../screens/ride_creation/ride_map_screen.dart';
import '../screens/ride_creation/route_selection_screen.dart';
import '../services/auth/fake_credentials.dart';
import '../services/dashboard/dashboard_current_trip_service.dart';

//1.- AppRoute enum documenta los nombres simbólicos usados en la configuración de GoRouter.
enum AppRoute {
  login,
  dashboard,
  rideMap,
  routeSelection,
  auction,
  bankInfo,
  travelHistory,
  currentTripDetails,
  driverProfile,
}

//2.- _rootNavigatorKey mantiene una referencia global para manipular el stack raíz si es necesario.
final _rootNavigatorKey = GlobalKey<NavigatorState>();

//3.- appRouterProvider construye y comparte la instancia de GoRouter sincronizada con Riverpod.
final appRouterProvider = Provider<GoRouter>((ref) {
  //4.- authListenable expone cambios de sesión a GoRouter mediante un ValueNotifier.
  final authListenable = ValueNotifier<RiderAccount?>(ref.read(signedInRiderProvider));

  //5.- Nos aseguramos de actualizar el notifier y liberarlo cuando el provider se descarte.
  ref.onDispose(authListenable.dispose);
  ref.listen(signedInRiderProvider, (_, next) {
    authListenable.value = next;
  });

  //6.- Configuramos las rutas declarativas, asignando cada pantalla del flujo solicitado.
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/dashboard',
    refreshListenable: authListenable,
    routes: [
      GoRoute(
        path: '/login',
        name: AppRoute.login.name,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/dashboard',
        name: AppRoute.dashboard.name,
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: '/dashboard/bank',
        name: AppRoute.bankInfo.name,
        builder: (context, state) => const BankInformationScreen(),
      ),
      GoRoute(
        path: '/dashboard/travel/history',
        name: AppRoute.travelHistory.name,
        builder: (context, state) => const TravelHistoryScreen(),
      ),
      GoRoute(
        path: '/dashboard/trip/details',
        name: AppRoute.currentTripDetails.name,
        builder: (context, state) {
          final trip = state.extra as DashboardCurrentTrip?;
          if (trip == null) {
            return const _MissingTripRouteScreen(label: 'detalles del viaje');
          }
          return CurrentTripDetailsScreen(trip: trip);
        },
      ),
      GoRoute(
        path: '/dashboard/trip/driver',
        name: AppRoute.driverProfile.name,
        builder: (context, state) {
          final trip = state.extra as DashboardCurrentTrip?;
          if (trip == null) {
            return const _MissingTripRouteScreen(label: 'perfil del conductor');
          }
          return DriverProfileScreen(trip: trip);
        },
      ),
      GoRoute(
        path: '/ride/map',
        name: AppRoute.rideMap.name,
        builder: (context, state) => const RideMapScreen(),
      ),
      GoRoute(
        path: '/ride/route',
        name: AppRoute.routeSelection.name,
        builder: (context, state) => const RouteSelectionScreen(),
      ),
      GoRoute(
        path: '/ride/auction',
        name: AppRoute.auction.name,
        builder: (context, state) => const AuctionScreen(),
      ),
    ],
    redirect: (context, state) {
      //7.- redirect aplica las reglas de autenticación para forzar login o dashboard según corresponda.
      final isLoggedIn = authListenable.value != null;
      final loggingIn = state.matchedLocation == '/login';
      if (!isLoggedIn) {
        return loggingIn ? null : '/login';
      }
      if (loggingIn) {
        return '/dashboard';
      }
      return null;
    },
  );
});

//8.- _MissingTripRouteScreen indica al usuario cuando la navegación carece de datos.
class _MissingTripRouteScreen extends StatelessWidget {
  const _MissingTripRouteScreen({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Viaje no disponible')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'No encontramos información para $label. Intenta desde el tablero nuevamente.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
