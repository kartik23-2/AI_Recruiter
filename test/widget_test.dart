import 'package:ai_recruiter/shared/widgets/gradient_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App smoke test', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: GradientButton(
            onPressed: null,
            isLoading: false,
            label: 'Disabled Button',
          ),
        ),
      ),
    );

    expect(find.text('Disabled Button'), findsOneWidget);
  });
}

