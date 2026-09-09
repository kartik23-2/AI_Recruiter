import 'package:ai_recruiter/shared/widgets/gradient_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GradientButton Widget Tests', () {
    testWidgets('renders button label when not loading', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GradientButton(
              onPressed: () {},
              isLoading: false,
              label: 'Submit Application',
            ),
          ),
        ),
      );

      expect(find.text('Submit Application'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('renders CircularProgressIndicator when isLoading is true', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GradientButton(
              onPressed: () {},
              isLoading: true,
              label: 'Submit Application',
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Submit Application'), findsNothing);
    });

    testWidgets('triggers onPressed callback when tapped', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GradientButton(
              onPressed: () {
                tapped = true;
              },
              isLoading: false,
              label: 'Tap Me',
            ),
          ),
        ),
      );

      await tester.tap(find.text('Tap Me'));
      await tester.pump();

      expect(tapped, isTrue);
    });
  });
}
