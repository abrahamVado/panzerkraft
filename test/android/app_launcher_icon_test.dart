import 'dart:io';

import 'package:test/test.dart';

void main() {
  //1.- Validamos que exista documentación en texto para generar los PNG del launcher en cada mipmap.
  group('Android launcher icon', () {
    //2.- Cada densidad debe contener un placeholder .txt indicando cómo generar ic_launcher.png.
    test('includes text placeholders for every density', () {
      const densities = [
        'mipmap-mdpi',
        'mipmap-hdpi',
        'mipmap-xhdpi',
        'mipmap-xxhdpi',
        'mipmap-xxxhdpi',
      ];
      //3.- Recorremos las densidades confirmando la existencia del recurso empaquetado.
      for (final density in densities) {
        final basePath = 'android/app/src/main/res/' '$density/';
        final square = File('${basePath}ic_launcher.txt');
        final round = File('${basePath}ic_launcher_round.txt');

        expect(
          square.existsSync(),
          isTrue,
          reason: 'Missing launcher placeholder for $density',
        );

        expect(
          round.existsSync(),
          isTrue,
          reason: 'Missing round launcher placeholder for $density',
        );
      }
    });
  });
}
