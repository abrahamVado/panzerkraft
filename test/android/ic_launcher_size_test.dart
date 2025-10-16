import 'dart:io';

import 'package:test/test.dart';

void main() {
  //1.- Validamos que el vector del icono de launcher utilice un radio grande.
  test('launcher foreground elimina el espacio seguro', () {
    //1.- Leemos el XML vectorial del icono adaptativo.
    final xml = File(
      'android/app/src/main/res/drawable/ic_launcher_foreground.xml',
    ).readAsStringSync();

    //2.- Confirmamos que el vector ocupa el viewport completo con radio 54 sin márgenes.
    expect(xml.contains('M54,0a54,54 0 1,0 0,108a54,54'), isTrue);
  });
}
