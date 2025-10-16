import 'package:flutter_test/flutter_test.dart';
import 'package:panzerkraft_demo/main.dart';

void main() {
  //1.- Verifica que la aplicación construye la pantalla principal sin errores.
  testWidgets('DemoHomeScreen renders', (tester) async {
    await tester.pumpWidget(const DemoShowcaseApp());
    expect(find.text('Panzerkraft Demo Ready'), findsOneWidget);
  });
}
