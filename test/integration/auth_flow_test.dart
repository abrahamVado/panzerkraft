import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mictlan_client/main.dart';
import 'package:mictlan_client/screens/auth/login_screen.dart';
import 'package:mictlan_client/screens/dashboard/dashboard_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('permite iniciar sesión y acceder al Dashboard', (tester) async {
    //1.- Montamos la app raíz que ahora delega la navegación a GoRouter.
    await tester.pumpWidget(
      const ProviderScope(
        child: MictlanApp(),
      ),
    );

    expect(find.byType(LoginScreen), findsOneWidget);

    await tester.enterText(find.byKey(loginEmailFieldKey), 'itzel.rider@example.com');
    await tester.enterText(find.byKey(loginPasswordFieldKey), 'quetzal123');
    await tester.tap(find.byKey(loginSubmitButtonKey));

    //2.- Pump extra permite que Riverpod reconstruya tras la autenticación.
    await tester.pumpAndSettle();

    //3.- Una vez autenticado debe mostrarse el dashboard protegido.
    expect(find.byType(DashboardScreen), findsOneWidget);
    expect(find.textContaining('Hola, Itzel Rider'), findsOneWidget);
  });
}
