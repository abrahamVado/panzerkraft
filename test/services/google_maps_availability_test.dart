import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ubberapp/services/google_maps_availability.dart';

//1.- main valida la lógica que decide si Google Maps está configurado en nativo.
void main() {
  //2.- Vinculamos los canales de prueba de Flutter para permitir invocaciones de MethodChannel.
  TestWidgetsFlutterBinding.ensureInitialized();

  //3.- Restablecemos el singleton después de cada prueba para evitar fugas de estado.
  tearDown(GoogleMapsAvailability.debugReset);

  test('usa el resolvedor inyectado cuando se proporciona un override', () async {
    //4.- Reemplazamos la implementación original por una que devuelva verdadero.
    GoogleMapsAvailability.debugOverride(() async => true);

    //5.- Ejecutamos la consulta y confirmamos que responde con la bandera simulada.
    final result = await GoogleMapsAvailability.instance.isConfigured();

    expect(result, isTrue);
  });

  test('recupera el resolvedor por defecto al ejecutar debugReset', () async {
    //6.- Configuramos un handler de MethodChannel que simula una respuesta desde Android.
    const channel = MethodChannel('com.example.ubberapp/config');
    channel.setMockMethodCallHandler((MethodCall call) async {
      //6.1.- Validamos que se llame al método esperado y regresamos verdadero.
      if (call.method == 'isGoogleMapsConfigured') {
        return true;
      }
      return false;
    });

    //7.- Alteramos primero la instancia y luego restablecemos la implementación real.
    GoogleMapsAvailability.debugOverride(() async => false);
    GoogleMapsAvailability.debugReset();

    //8.- Ejecutamos la resolución real y verificamos que invoque al canal nativo simulado.
    final result = await GoogleMapsAvailability.instance.isConfigured();

    expect(result, isTrue);

    //9.- Liberamos el handler para no contaminar otras suites de prueba.
    channel.setMockMethodCallHandler(null);
  });
}
