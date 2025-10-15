import 'dart:io';

import 'package:test/test.dart';

void main() {
  //1.- Validamos que el vector del icono de launcher utilice un radio grande.
  test('launcher foreground maximizes safe zone', () {
    //1.- Leemos el XML vectorial del icono adaptativo.
    final xml = File(
      'android/app/src/main/res/drawable/ic_launcher_foreground.xml',
    ).readAsStringSync();

    //2.- Confirmamos que el anillo exterior inicia en 10dp (radio 44) para ocupar más área visible.
    expect(xml.contains('M54,10a44,44 0 1,0 0,88a44,44'), isTrue);

    //3.- Confirmamos que el anillo interior mantiene el grosor esperado con radio 32.
    expect(xml.contains('zm0,12a32,32 0 1,1 0,64a32,32'), isTrue);
  });
}
