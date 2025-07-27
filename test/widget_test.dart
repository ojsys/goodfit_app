// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:goodfit_app/main.dart';

void main() {
  testWidgets('A Good Fit app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const AGoodFitApp());

    // Verify that the splash screen loads with the app title components
    expect(find.text('A'), findsOneWidget);
    expect(find.text('Good'), findsOneWidget);
    expect(find.text('Fit'), findsOneWidget);
    expect(find.text('Find Your Fitness Tribe'), findsOneWidget);
    expect(find.text('Get Started'), findsOneWidget);
    expect(find.text('Sign Up'), findsOneWidget);
  });
}
