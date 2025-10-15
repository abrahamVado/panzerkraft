import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mictlan_client/providers/auth_providers.dart';
import 'package:mictlan_client/screens/auth/login_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('muestra el saludo cuando las credenciales son válidas', (tester) async {
    //1.- Montamos la pantalla en un MaterialApp para acceso a temas y navegación.
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: LoginScreen()),
      ),
    );

    await tester.enterText(find.byKey(loginEmailFieldKey), 'itzel.rider@example.com');
    await tester.enterText(find.byKey(loginPasswordFieldKey), 'quetzal123');
    await tester.tap(find.byKey(loginSubmitButtonKey));
    await tester.pump();

    //2.- Verificamos el mensaje de bienvenida con el nombre derivado del correo.
    expect(find.textContaining('Bienvenido, Itzel Rider'), findsOneWidget);

    final context = tester.element(find.byType(LoginScreen));
    final container = ProviderScope.containerOf(context);
    //3.- Confirmamos que el provider global conserva al rider autenticado.
    expect(container.read(signedInRiderProvider)?.email, 'itzel.rider@example.com');
  });

  testWidgets('muestra error cuando las credenciales no coinciden', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: LoginScreen()),
      ),
    );

    await tester.enterText(find.byKey(loginEmailFieldKey), 'itzel.rider@example.com');
    await tester.enterText(find.byKey(loginPasswordFieldKey), 'clave-erronea');
    await tester.tap(find.byKey(loginSubmitButtonKey));
    await tester.pump();

    //4.- Debe aparecer el mensaje de error y el provider mantenerse vacío.
    expect(find.text('No pudimos verificar tus credenciales.'), findsOneWidget);
    final context = tester.element(find.byType(LoginScreen));
    final container = ProviderScope.containerOf(context);
    expect(container.read(signedInRiderProvider), isNull);
  });
}
