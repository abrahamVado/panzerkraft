import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'auth/auth_controller.dart';
import 'auth/auth_screen.dart';
import 'auth/auth_service.dart';
import 'dashboard/dashboard_screen.dart';
import 'travel/travel_controller.dart';
import 'travel/travel_screen.dart';
import 'travel/auction_manager.dart';
import 'services/location_service.dart';

class PanzerkraftApp extends StatelessWidget {
  const PanzerkraftApp({super.key});

  @override
  Widget build(BuildContext context) {
    //1.- Wire top-level controllers so authentication and travel logic are available.
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthController>(
          create: (_) => AuthController(service: AuthService()),
        ),
        ChangeNotifierProvider<TravelController>(
          create: (_) => TravelController(
            locationService: LocationService(),
            auctionManager: RideAuctionManager(),
          ),
        ),
      ],
      //2.- Build the MaterialApp that defines routing and theming.
      child: MaterialApp(
        title: 'Panzerkraft Mobility',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
          useMaterial3: true,
        ),
        routes: {
          '/': (_) => const AuthGate(),
          TravelScreen.routeName: (_) => const TravelScreen(),
        },
      ),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    //1.- Listen to authentication status so we can show login or dashboard.
    return Consumer<AuthController>(
      builder: (context, auth, _) {
        //2.- Redirect unauthenticated users to the sign-in screen.
        if (!auth.isAuthenticated) {
          return AuthScreen(onSignedIn: auth.signInWithEmail);
        }
        //3.- Send authenticated users straight to the dashboard.
        return DashboardScreen(
          displayName: auth.displayName,
          onLogout: auth.signOut,
        );
      },
    );
  }
}
