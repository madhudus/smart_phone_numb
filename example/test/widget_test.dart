import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_phone_numb/smart_phone_numb.dart';

import 'package:example/main.dart';

void main() {
  testWidgets('renders the example phone number fields', (tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.byType(SmartPhoneNumberField), findsNWidgets(4));
    expect(find.widgetWithText(FilledButton, 'Validate'), findsOneWidget);
  });
}
