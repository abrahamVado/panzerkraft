import 'dart:io';

import 'package:test/test.dart';

void main() {
  //1.- Validamos que el manifest apunte a los bitmaps en mipmap para evitar márgenes automáticos.
  test('manifest usa iconos PNG sin safe zone', () {
    //1.- Leemos el AndroidManifest.xml actual.
    final manifest = File('android/app/src/main/AndroidManifest.xml').readAsStringSync();

    //2.- Confirmamos que el atributo android:icon apunta al recurso mipmap.
    expect(manifest.contains('android:icon="@mipmap/ic_launcher"'), isTrue);

    //3.- Validamos que android:roundIcon reutiliza el mismo PNG sin un archivo alterno.
    expect(manifest.contains('android:roundIcon="@mipmap/ic_launcher"'), isTrue);
  });

  //2.- Confirmamos que cada carpeta mipmap ignora los PNG para permitir agregarlos localmente.
  test('carpetas mipmap ignoran png locales', () {
    //1.- Definimos las densidades soportadas por el proyecto.
    const densities = <String>['mdpi', 'hdpi', 'xhdpi', 'xxhdpi', 'xxxhdpi', 'anydpi-v26'];

    //2.- Recorremos cada densidad y validamos que exista el archivo .gitignore.
    for (final density in densities) {
      final gitignorePath = 'android/app/src/main/res/mipmap-$density/.gitignore';
      expect(File(gitignorePath).existsSync(), isTrue, reason: 'Falta $gitignorePath');

      //3.- Verificamos que el .gitignore efectivamente ignore los PNG añadidos manualmente.
      final gitignoreContent = File(gitignorePath).readAsStringSync();
      expect(gitignoreContent.contains('*.png'), isTrue,
          reason: 'El archivo $gitignorePath debe ignorar los PNG');
    }
  });
}
