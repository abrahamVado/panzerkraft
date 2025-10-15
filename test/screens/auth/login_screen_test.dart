import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ubberapp/providers/auth_providers.dart';
import 'package:ubberapp/screens/auth/login_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('crea una sesión demo al presionar el botón principal', (tester) async {
    //1.- Montamos la pantalla y presionamos el CTA demo para generar credenciales.
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: LoginScreen()),
      ),
    );

    await tester.tap(find.byKey(loginSubmitButtonKey));
    await tester.pump();

    //2.- Debe aparecer la tarjeta de bienvenida con el correo generado dinámicamente.
    expect(find.textContaining('Bienvenido'), findsOneWidget);
    expect(find.textContaining('Sesión creada como'), findsOneWidget);

    final context = tester.element(find.byType(LoginScreen));
    final container = ProviderScope.containerOf(context);
    //3.- Confirmamos que el provider global conserva al rider autenticado con dominio ubberapp.
    expect(container.read(signedInRiderProvider)?.email, endsWith('@ubberapp.local'));
  });
}
