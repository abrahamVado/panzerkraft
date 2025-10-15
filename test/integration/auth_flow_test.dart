import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ubberapp/main.dart';
import 'package:ubberapp/screens/auth/login_screen.dart';
import 'package:ubberapp/screens/dashboard/dashboard_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('permite iniciar sesión y acceder al Dashboard', (tester) async {
    //1.- Montamos la app raíz que ahora delega la navegación a GoRouter.
    await tester.pumpWidget(
      const ProviderScope(
        child: UbberApp(),
      ),
    );

    expect(find.byType(LoginScreen), findsOneWidget);

    await tester.tap(find.byKey(loginSubmitButtonKey));

    //2.- Pump extra permite que Riverpod reconstruya tras la autenticación.
    await tester.pumpAndSettle();

    //3.- Una vez autenticado debe mostrarse el dashboard protegido.
    expect(find.byType(DashboardScreen), findsOneWidget);
    expect(find.textContaining('Hola, Itzel Rider'), findsOneWidget);
  });
}
