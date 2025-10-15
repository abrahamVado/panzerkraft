# Taxi Demo Setup Guide

This guide centralizes the configuration steps that keep the taxi demo predictable across environments.
Use it together with the root project README when preparing a workstation or a CI runner.

## Google Maps API keys

1. Create API keys with Maps SDK for Android, Maps SDK for iOS, Places API, and Directions API enabled.
2. **Android build time configuration**
   - Set `MAPS_API_KEY` inside `android/local.properties` so Gradle can expand `${MAPS_API_KEY}` from the manifest.
   - Alternatively export it just for the Flutter command invocation: `MAPS_API_KEY=your-key flutter run`.
3. **iOS build time configuration**
   - Edit `ios/Runner/AppDelegate.swift` (or `AppDelegate.m` on Obj-C) and follow the plugin instructions to call `GMSServices.provideAPIKey`.
   - Confirm the `GoogleMaps` dependency exists in `ios/Podfile.lock` after a successful `pod install`.
4. **Runtime configuration**
   - The widgets consult `AppConfig.googleMapsApiKey`, which reads the `GOOGLE_MAPS_API_KEY` Dart define.
   - Pass it while running or testing:
     ```bash
     flutter run \\
       --dart-define=GOOGLE_MAPS_API_KEY=your-key \\
       --dart-define=BACKEND_BASE_URL=https://demo-backend.local
     ```
   - Replicate the same defines inside CI or integration test scripts so mocked map experiences stay enabled.

## Manage the fake credential list

1. Locate `lib/services/auth/fake_credentials.dart`. The list under `fakeCredentialStoreProvider` is the single source of truth.
2. Each credential stores the normalized email and a SHA-256 password hash. Generate hashes with one of the following options:
   - macOS/Linux: `echo -n 'plainPassword' | shasum -a 256`.
   - OpenSSL (all platforms): `echo -n 'plainPassword' | openssl dgst -sha256`.
   - Dart snippet (inside the repo so it reuses the `crypto` dependency):
     ```bash
     dart run bin/hash_password.dart
     ```
     Create the file on the fly when needed:
     ```bash
     cat <<'DART' > bin/hash_password.dart
     import 'dart:convert';
     import 'dart:io';
     import 'package:crypto/crypto.dart';

     void main(List<String> args) {
       //1.- password elige el argumento o solicita la entrada estándar.
       final password = args.isNotEmpty ? args.first : (stdin.readLineSync() ?? '');
       //2.- hash aplica SHA-256 al texto plano.
       final hash = sha256.convert(utf8.encode(password)).toString();
       //3.- Imprime la cadena hexadecimal para pegarla en fake_credentials.dart.
       print(hash);
     }
     DART
     ```
     Then execute `dart run bin/hash_password.dart "plainPassword"`, copy the hash, and delete the helper when done.
3. Populate the rider name automatically via `FakeCredential.riderName`. The UI capitalizes the email prefix, so new emails should follow the same convention (`name.lastname@example.com`).
4. Keep widget and service tests aligned with the credential list so CI keeps covering successful and failing authentication flows.

## Configure controllable mock services

1. Both `DashboardMetricsService` and `DashboardCurrentTripService` derive deterministic data from the rider email hash.
2. Override them in integration tests or demos through Riverpod providers. Example:
   ```dart
   final scope = ProviderScope(
     overrides: [
       dashboardMetricsServiceProvider.overrideWithValue(
         const DashboardMetricsService(),
       ),
       dashboardCurrentTripServiceProvider.overrideWithValue(
         const DashboardCurrentTripService(),
       ),
     ],
     child: const MyApp(),
   );
   ```
3. For scenario-specific values create lightweight fakes that implement the same public API:
   ```dart
   class FixedTripService extends DashboardCurrentTripService {
     //1.- extendemos para reutilizar la firma pública.
     @override
     Future<DashboardCurrentTrip?> fetchCurrentTrip(RiderAccount rider) async {
       //2.- devolvemos un viaje fijo o null según la prueba necesaria.
       return const DashboardCurrentTrip(
         passengerName: 'Pasajero Demo',
         pickupAddress: 'Terminal 1',
         dropoffAddress: 'Terminal 2',
         status: 'En curso',
         vehiclePlate: 'TAX-321',
         etaMinutes: 4,
       );
     }
   }
   ```
4. Inject the fake with `dashboardCurrentTripServiceProvider.overrideWithValue(FixedTripService())` to drive storybook scenarios or widget tests.
5. When new mock services appear, document their providers inside this guide to keep overrides straightforward.
