import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_phone_numb/smart_phone_numb.dart';

void main() {
  group('SmartPhoneNumberField', () {
    testWidgets('should create widget without error', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SmartPhoneNumberField(),
          ),
        ),
      );

      expect(find.byType(SmartPhoneNumberField), findsOneWidget);
    });

    testWidgets('should display phone number input field', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SmartPhoneNumberField(),
          ),
        ),
      );

      expect(find.byType(TextFormField), findsOneWidget);
    });
  });
}
