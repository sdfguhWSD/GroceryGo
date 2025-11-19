import 'package:flutter_test/flutter_test.dart';
import 'package:online_groceryshopping_app/main.dart';
import 'package:online_groceryshopping_app/screens/login_screen.dart';

void main() {
  testWidgets('Verify LoginScreen loads and displays initial UI',
      (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const GroceryGo());

    // Wait for the initial route (/login) to be navigated to.
    await tester.pumpAndSettle();

    // Verify that the LoginScreen is displayed.
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text('Login'),
        findsOneWidget); // Adjust 'Login' to match visible text in LoginScreen
  });
}
