import 'package:test/test.dart';

import 'package:mictlan_client/services/auth/fake_credentials.dart';

void main() {
  group('FakeCredentialStore', () {
    test('authenticate devuelve la cuenta cuando el correo se normaliza', () {
      //1.- Definimos una credencial idéntica a la lista por defecto.
      const credential = FakeCredential(
        email: 'itzel.rider@example.com',
        passwordHash:
            '3e13adf022bf21a6a5af0711fd308250d608591bfee81d3252c450461a76f327',
      );
      final store = FakeCredentialStore(const [credential]);

      //2.- Solicitamos autenticación usando mayúsculas y espacios extra.
      final account = store.authenticate(
        '  Itzel.Rider@Example.com  ',
        'quetzal123',
      );

      //3.- El almacén debe devolver el RiderAccount con el nombre generado.
      expect(account, isNotNull);
      expect(account!.email, 'itzel.rider@example.com');
      expect(account.name, 'Itzel Rider');
    });

    test('authenticate regresa null para contraseñas erróneas', () {
      //1.- Creamos el almacén con la misma credencial conocida.
      final store = FakeCredentialStore(const [
        FakeCredential(
          email: 'itzel.rider@example.com',
          passwordHash:
              '3e13adf022bf21a6a5af0711fd308250d608591bfee81d3252c450461a76f327',
        ),
      ]);

      //2.- Intentamos ingresar con contraseña incorrecta.
      final account = store.authenticate(
        'itzel.rider@example.com',
        'clave-erronea',
      );

      //3.- Sin coincidencia, debe retornar null.
      expect(account, isNull);
    });

    test('allowedRiders expone los nombres derivados del correo', () {
      //1.- Agregamos dos credenciales para validar el formateo de nombres.
      final store = FakeCredentialStore(const [
        FakeCredential(
          email: 'itzel.rider@example.com',
          passwordHash:
              '3e13adf022bf21a6a5af0711fd308250d608591bfee81d3252c450461a76f327',
        ),
        FakeCredential(
          email: 'yahualica.super_driver@example.com',
          passwordHash:
              '5831be2394a3329adcab17a3e30ac57e87eb2bf50fcaf60c0af1dd335d5acb55',
        ),
      ]);

      //2.- Obtenemos la lista de riders permitidos.
      final allowed = store.allowedRiders;

      //3.- Validamos que los nombres capitalicen cada segmento del correo.
      expect(allowed, hasLength(2));
      expect(allowed.first.name, 'Itzel Rider');
      expect(allowed.last.name, 'Yahualica Super Driver');
    });
  });
}
