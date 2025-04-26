import 'package:flutter_test/flutter_test.dart';
// Import your sign_in_screen.dart instead of main.dart if that's where the widget is
import 'package:graduation_project/main.dart';

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Build the SignInScreen and trigger a frame.
    await tester.pumpWidget(const SignInScreen());

    // Verify that something specific to SignInScreen is found.
    expect(find.text('Sign In'), findsOneWidget);
    expect(find.text('0'), findsNothing);

    // If you have a button or icon in SignInScreen, you can tap it here.
    // Example: await tester.tap(find.byIcon(Icons.add));
    // await tester.pump();

    // Then verify something changed.
  });
}
