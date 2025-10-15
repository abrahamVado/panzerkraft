import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mictlan_client/main.dart';
import 'package:mictlan_client/screens/auth/login_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('permite iniciar sesión y acceder al HomeScreen', (tester) async {
    //1.- Iniciamos el árbol con el AuthGate para reproducir el flujo real.
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: AuthGate()),
      ),
    );

    expect(find.byType(LoginScreen), findsOneWidget);

    await tester.enterText(find.byKey(loginEmailFieldKey), 'yahualica.rider@example.com');
    await tester.enterText(find.byKey(loginPasswordFieldKey), 'obsidian!');
    await tester.tap(find.byKey(loginSubmitButtonKey));

    //2.- Pump extra permite que Riverpod reconstruya tras la autenticación.
    await tester.pump();
    await tester.pump();

    //3.- Ahora debe mostrarse la pantalla principal con su AppBar.
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.text('Mictlan Client'), findsWidgets);
  });
}
