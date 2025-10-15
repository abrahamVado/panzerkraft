import 'package:flutter_test/flutter_test.dart';
import 'package:app/auth/auth_service.dart';

void main() {
  group('AuthService', () {
    test('extracts display name from email', () async {
      //1.- Instantiate the fake auth service used in the UI flow.
      const service = AuthService();
      //2.- Perform a sign-in with a structured email address.
      final session =
          await service.signInWithEmail('julia.fernandez@example.com');
      //3.- Expect the display name to come from the email local-part.
      expect(session.displayName, 'Julia Fernandez');
    });

    test('falls back to guest name when email has no letters', () async {
      //1.- Instantiate the service with the same deterministic behavior.
      const service = AuthService();
      //2.- Sign in with a numeric-only email to stress the parser.
      final session = await service.signInWithEmail('12345@domain.mx');
      //3.- Ensure the fallback value is consistent with the UI copy.
      expect(session.displayName, 'Guest Rider');
    });
  });
}
