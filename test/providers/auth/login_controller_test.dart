import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mictlan_client/providers/auth_providers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('acepta cualquier combinación de credenciales y crea sesión demo', () async {
    //1.- Preparamos un contenedor de Riverpod para interactuar con el LoginController.
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final controller = container.read(loginControllerProvider.notifier);
    controller.updateEmail('usuario.desconocido@ejemplo.dev');
    controller.updatePassword('123');

    //2.- submit debe resolver sin errores y publicar la sesión creada.
    await controller.submit();

    final state = container.read(loginControllerProvider);
    final signedIn = container.read(signedInRiderProvider);

    expect(state.errorMessage, isNull);
    expect(state.riderName, 'Usuario Desconocido');
    expect(signedIn, isNotNull);
    expect(signedIn!.email, 'usuario.desconocido@ejemplo.dev');
    expect(signedIn.name, 'Usuario Desconocido');
  });

  test('usa credenciales de respaldo cuando el correo está vacío', () async {
    //1.- Configuramos un nuevo contenedor para aislar el estado de la prueba previa.
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final controller = container.read(loginControllerProvider.notifier);
    controller.updateEmail('   ');
    controller.updatePassword('');

    //2.- Al enviar sin correo debemos obtener la cuenta demo predeterminada.
    await controller.submit();

    final signedIn = container.read(signedInRiderProvider);

    expect(signedIn, isNotNull);
    expect(signedIn!.email, 'guest@panzerkraft.local');
    expect(signedIn.name, 'Rider Demo');
  });
}
