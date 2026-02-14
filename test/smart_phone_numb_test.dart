import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_phone_numb/phone_number_lengths.dart';
import 'package:smart_phone_numb/smart_phone_numb.dart';

void main() {
  group('PhoneNumberData', () {
    test('fullPhoneNumber concatenates dialCode and phoneNumber', () {
      const data = PhoneNumberData(
        dialCode: '+1',
        countryCode: 'US',
        phoneNumber: '5551234567',
      );
      expect(data.fullPhoneNumber, '+15551234567');
    });

    test('fullPhoneNumber with empty phone number returns dialCode only', () {
      const data = PhoneNumberData(
        dialCode: '+44',
        countryCode: 'GB',
        phoneNumber: '',
      );
      expect(data.fullPhoneNumber, '+44');
    });

    test('equality works for identical data', () {
      const a = PhoneNumberData(
        dialCode: '+91',
        countryCode: 'IN',
        phoneNumber: '9876543210',
      );
      const b = PhoneNumberData(
        dialCode: '+91',
        countryCode: 'IN',
        phoneNumber: '9876543210',
      );
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('inequality for different data', () {
      const a = PhoneNumberData(
        dialCode: '+1',
        countryCode: 'US',
        phoneNumber: '5551234567',
      );
      const b = PhoneNumberData(
        dialCode: '+1',
        countryCode: 'US',
        phoneNumber: '5559999999',
      );
      expect(a, isNot(equals(b)));
    });

    test('toString includes all fields', () {
      const data = PhoneNumberData(
        dialCode: '+49',
        countryCode: 'DE',
        phoneNumber: '1234567',
      );
      final str = data.toString();
      expect(str, contains('+49'));
      expect(str, contains('DE'));
      expect(str, contains('1234567'));
    });
  });

  group('phoneNumberLengths', () {
    test('min is always <= max for every country', () {
      for (final entry in phoneNumberLengths.entries) {
        final min = entry.value['min']!;
        final max = entry.value['max']!;
        expect(min <= max, isTrue,
            reason: '${entry.key}: min ($min) > max ($max)');
      }
    });

    test('max never exceeds E.164 limit of 15 digits', () {
      for (final entry in phoneNumberLengths.entries) {
        expect(entry.value['max']!, lessThanOrEqualTo(15),
            reason: '${entry.key} max exceeds E.164 limit');
      }
    });

    test('contains major countries', () {
      expect(phoneNumberLengths, contains('US'));
      expect(phoneNumberLengths, contains('GB'));
      expect(phoneNumberLengths, contains('IN'));
      expect(phoneNumberLengths, contains('DE'));
      expect(phoneNumberLengths, contains('JP'));
      expect(phoneNumberLengths, contains('BR'));
    });

    test('US phone numbers are exactly 10 digits', () {
      expect(phoneNumberLengths['US']!['min'], 10);
      expect(phoneNumberLengths['US']!['max'], 10);
    });
  });

  group('SmartPhoneNumberField', () {
    testWidgets('creates widget without error', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SmartPhoneNumberField(),
          ),
        ),
      );
      expect(find.byType(SmartPhoneNumberField), findsOneWidget);
    });

    testWidgets('displays phone number input field',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SmartPhoneNumberField(),
          ),
        ),
      );
      expect(find.byType(TextFormField), findsOneWidget);
    });

    testWidgets('accepts custom default country code',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SmartPhoneNumberField(defaultCountryCode: 'DE'),
          ),
        ),
      );
      expect(find.byType(SmartPhoneNumberField), findsOneWidget);
    });

    testWidgets('accepts custom favorite countries',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SmartPhoneNumberField(
              favoriteCountries: ['+49', 'DE', '+44', 'GB'],
            ),
          ),
        ),
      );
      expect(find.byType(SmartPhoneNumberField), findsOneWidget);
    });

    testWidgets('accepts new optional parameters',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SmartPhoneNumberField(
              enabled: false,
              showCounterText: true,
              style: const TextStyle(fontSize: 18),
              decoration: const InputDecoration(labelText: 'Custom Label'),
            ),
          ),
        ),
      );
      expect(find.byType(SmartPhoneNumberField), findsOneWidget);
    });
  });
}
