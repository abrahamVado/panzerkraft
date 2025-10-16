import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ubberapp/providers/auth_providers.dart';
import 'package:ubberapp/screens/auth/login_screen.dart' as login_screen;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('crea una sesión demo al presionar el botón principal', (tester) async {
    //1.- Montamos la pantalla y presionamos el CTA demo para generar credenciales.
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: login_screen.LoginScreen()),
      ),
    );

    await tester.tap(find.byKey(login_screen.loginSubmitButtonKey));
    await tester.pump();

    //2.- Debe aparecer la tarjeta de bienvenida con el correo generado dinámicamente.
    expect(find.textContaining('Bienvenido'), findsOneWidget);
    expect(find.textContaining('Sesión creada como'), findsOneWidget);

    final context = tester.element(find.byType(login_screen.LoginScreen));
    final container = ProviderScope.containerOf(context);
    //3.- Confirmamos que el provider global conserva al rider autenticado con dominio ubberapp.
    expect(container.read(signedInRiderProvider)?.email, endsWith('@ubberapp.local'));
  });

  testWidgets('el placeholder se ajusta a contenedores pequeños sin overflow', (tester) async {
    //1.- Montamos el placeholder dentro de un recuadro idéntico al del error reportado.
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              height: 60,
              width: 60,
              child: login_screen.createBrandingPlaceholderForTesting('Logotipo en espera'),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    //2.- Confirmamos que no hay excepciones y que el contenido respeta el límite disponible.
    expect(tester.takeException(), isNull);
    final semanticsFinder = find.bySemanticsLabel('Logotipo en espera');
    expect(semanticsFinder, findsOneWidget);
    final renderBox = tester.renderObject<RenderBox>(semanticsFinder);
    expect(renderBox.size.height <= 60, isTrue);
  });
}
