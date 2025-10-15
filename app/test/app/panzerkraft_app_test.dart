import 'package:flutter_test/flutter_test.dart';
import 'package:panzerkraft/app.dart';

void main() {
  testWidgets('PanzerkraftApp shows the authentication flow by default', (tester) async {
    //1.- Render the root widget so providers and routes are ready for interaction.
    await tester.pumpWidget(const PanzerkraftApp());
    //2.- Let inherited widgets settle before evaluating the visible UI.
    await tester.pumpAndSettle();
    //3.- Assert that the authentication welcome text is visible for logged-out users.
    expect(find.text('Welcome back to Panzerkraft'), findsOneWidget);
  });
}
