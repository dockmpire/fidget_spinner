import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fidget_spinner/main.dart';
import 'package:fidget_spinner/widgets/spinner_fidget.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Initialize SharedPreferences for testing
    SharedPreferences.setMockInitialValues({});
    
    // Build our app and trigger a frame.
    await tester.pumpWidget(const FormFreshFidgetApp());

    // Verify that our spinner is present
    expect(find.byType(SpinnerFidget), findsOneWidget);
  });
}
