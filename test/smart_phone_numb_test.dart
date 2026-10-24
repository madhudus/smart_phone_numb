import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
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
        expect(
          min <= max,
          isTrue,
          reason: '${entry.key}: min ($min) > max ($max)',
        );
      }
    });

    test('max never exceeds E.164 limit of 15 digits', () {
      for (final entry in phoneNumberLengths.entries) {
        expect(
          entry.value['max']!,
          lessThanOrEqualTo(15),
          reason: '${entry.key} max exceeds E.164 limit',
        );
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

  group('timezoneCountryMapping', () {
    test('maps canonical IANA timezones', () {
      expect(countryCodeForTimezone('Asia/Kolkata'), 'IN');
      expect(countryCodeForTimezone('America/New_York'), 'US');
      expect(countryCodeForTimezone('Europe/Berlin'), 'DE');
      expect(countryCodeForTimezone('America/Toronto'), 'CA');
      expect(countryCodeForTimezone('Australia/Sydney'), 'AU');
    });

    test('maps legacy timezone aliases', () {
      expect(countryCodeForTimezone('Asia/Calcutta'), 'IN');
      expect(countryCodeForTimezone('America/Buenos_Aires'), 'AR');
      expect(countryCodeForTimezone('Europe/Kiev'), 'UA');
      expect(countryCodeForTimezone('US/Eastern'), 'US');
    });

    test('returns null for unknown timezones', () {
      expect(countryCodeForTimezone('Mars/Olympus_Mons'), isNull);
      expect(countryCodeForTimezone('UTC'), isNull);
    });

    test('every value is a two-letter uppercase country code', () {
      final pattern = RegExp(r'^[A-Z]{2}$');
      for (final entry in timezoneCountryMapping.entries) {
        expect(entry.value, matches(pattern), reason: entry.key);
      }
    });
  });

  group('SmartPhoneNumberField', () {
    const channel = MethodChannel('flutter_timezone');

    void mockTimezone(String? timezone) {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            if (timezone == null) {
              throw PlatformException(code: 'UNAVAILABLE');
            }
            return timezone;
          });
    }

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    Widget buildField(SmartPhoneNumberField field) {
      return MaterialApp(
        home: Scaffold(body: Form(child: field)),
      );
    }

    testWidgets('detects the country from the device timezone', (tester) async {
      mockTimezone('Asia/Kolkata');
      PhoneNumberData? data;
      await tester.pumpWidget(
        buildField(SmartPhoneNumberField(onChanged: (d) => data = d)),
      );
      await tester.pumpAndSettle();

      expect(find.text('+91'), findsOneWidget);
      expect(find.byIcon(Icons.warning), findsNothing);
      expect(data?.countryCode, 'IN');
      expect(data?.dialCode, '+91');
    });

    testWidgets('falls back to defaultCountryCode when detection fails', (
      tester,
    ) async {
      mockTimezone(null);
      await tester.pumpWidget(
        buildField(const SmartPhoneNumberField(defaultCountryCode: 'DE')),
      );
      await tester.pumpAndSettle();

      expect(find.text('+49'), findsOneWidget);
      expect(find.byIcon(Icons.warning), findsOneWidget);
    });

    testWidgets('falls back to defaultCountryCode for unknown timezones', (
      tester,
    ) async {
      mockTimezone('Etc/UTC');
      await tester.pumpWidget(
        buildField(const SmartPhoneNumberField(defaultCountryCode: 'GB')),
      );
      await tester.pumpAndSettle();

      expect(find.text('+44'), findsOneWidget);
    });

    testWidgets('falls back when timezone detection never answers', (
      tester,
    ) async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            channel,
            (call) => Completer<Object?>().future,
          );
      await tester.pumpWidget(
        buildField(const SmartPhoneNumberField(defaultCountryCode: 'FR')),
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.pump(const Duration(seconds: 5));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('+33'), findsOneWidget);
    });

    testWidgets('initialCountryCode skips timezone detection', (tester) async {
      var detectionCalls = 0;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            detectionCalls++;
            return 'America/New_York';
          });
      await tester.pumpWidget(
        buildField(const SmartPhoneNumberField(initialCountryCode: 'JP')),
      );
      await tester.pumpAndSettle();

      expect(find.text('+81'), findsOneWidget);
      expect(detectionCalls, 0);
    });

    testWidgets('reports changes once per distinct value', (tester) async {
      mockTimezone('America/New_York');
      final updates = <PhoneNumberData>[];
      await tester.pumpWidget(
        buildField(SmartPhoneNumberField(onChanged: updates.add)),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField), '5551234567');
      await tester.pump();

      expect(updates.map((d) => d.fullPhoneNumber), ['+1', '+15551234567']);
    });

    testWidgets('only accepts digits up to the country maximum', (
      tester,
    ) async {
      mockTimezone('America/New_York');
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        buildField(SmartPhoneNumberField(controller: controller)),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField), '(555) 123-4567 89');
      expect(controller.text, '5551234567');
    });

    testWidgets('validates the number length for the country', (tester) async {
      mockTimezone('America/New_York');
      await tester.pumpWidget(buildField(const SmartPhoneNumberField()));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField), '123');
      final form = tester.state<FormState>(find.byType(Form));
      expect(form.validate(), isFalse);
      await tester.pump();
      expect(find.textContaining('must be 10 digits'), findsOneWidget);

      await tester.enterText(find.byType(TextFormField), '5551234567');
      expect(form.validate(), isTrue);
    });

    testWidgets('applies custom decoration and disabled state', (tester) async {
      mockTimezone('America/New_York');
      await tester.pumpWidget(
        buildField(
          const SmartPhoneNumberField(
            enabled: false,
            decoration: InputDecoration(labelText: 'Mobile'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Mobile'), findsOneWidget);
      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.enabled, isFalse);
    });
  });
}
