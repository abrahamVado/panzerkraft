import 'dart:io';

import 'package:test/test.dart';

import 'package:ubberapp/config/branding_config.dart';

void main() {
  //1.- Garantizamos que el manifest delegue los iconos al drawable común gestionado desde Flutter.
  test('manifest utiliza el PNG replicado en mipmap para icono cuadrado y redondo', () {
    //1.- Leemos el AndroidManifest.xml actual.
    final manifest = File('android/app/src/main/AndroidManifest.xml').readAsStringSync();

    //2.- Confirmamos que android:icon depende del PNG copiado a mipmap/app_icon.
    expect(manifest.contains('android:icon="@mipmap/app_icon"'), isTrue);

    //3.- Validamos que android:roundIcon comparte el mismo recurso para mantener consistencia.
    expect(manifest.contains('android:roundIcon="@mipmap/app_icon"'), isTrue);

    //4.- Comprobamos que el archivo ya no referencia vectores auxiliares en drawable.
    expect(manifest.contains('@drawable/app_icon'), isFalse);
  });

  //2.- Verificamos que BrandingConfig exponga el icono que se muestra en la aplicación.
  test('androidIconSource apunta al asset configurable', () {
    //1.- Obtenemos la ruta del icono declarada en la configuración centralizada.
    final iconSource = BrandingConfig.androidIconSource;

    //2.- Afirmamos que la ruta no esté vacía y apunte al directorio de assets esperado.
    expect(iconSource.isNotEmpty, isTrue);
    expect(iconSource, startsWith('assets/icon/'));

    //3.- Validamos que el recurso termine en PNG para garantizar compatibilidad con Android.
    expect(iconSource.toLowerCase().endsWith('.png'), isTrue);
  });
}
