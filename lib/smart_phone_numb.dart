import 'dart:convert';
import 'package:country_code_picker/country_code_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:smart_phone_numb/phone_number_lengths.dart';

/// A smart phone number input field widget that automatically detects
/// the user's country based on their timezone and provides validation
/// based on country-specific phone number length requirements.
///
/// This widget combines a country code picker with a phone number text field,
/// offering intelligent defaults and real-time validation.
class SmartPhoneNumberField extends StatefulWidget {
  /// Creates a [SmartPhoneNumberField] widget.
  ///
  /// The widget will automatically detect the user's timezone and suggest
  /// an appropriate country code for phone number input.
  const SmartPhoneNumberField({super.key});

  @override
  State<SmartPhoneNumberField> createState() => _SmartPhoneNumberFieldState();
}

class _SmartPhoneNumberFieldState extends State<SmartPhoneNumberField> {
  final TextEditingController _phoneNumberController = TextEditingController();
  CountryCode? _countryCode;
  bool _isFetchingTimezone = false;
  Map<String, String>? _timezoneCountryMap;

  @override
  void initState() {
    super.initState();
    _loadTimezoneMapping();
  }

  Future<void> _getInitialCountryCode() async {
    setState(() {
      _isFetchingTimezone = true;
    });

    try {
      final timezone = await FlutterTimezone.getLocalTimezone();
      final country = _getCountryFromTimezone(timezone);

      if (country != null) {
        setState(() {
          _countryCode = CountryCode.fromCountryCode(country);
        });
      }
    } catch (e) {
      // Handle errors
    } finally {
      setState(() {
        _isFetchingTimezone = false;
      });
    }
  }

  Future<void> _loadTimezoneMapping() async {
    try {
      final jsonString = await rootBundle.loadString('packages/smart_phone_numb/timezone_country_mapping.json');
      final Map<String, dynamic> jsonMap = json.decode(jsonString);
      _timezoneCountryMap = jsonMap.cast<String, String>();
      _getInitialCountryCode();
    } catch (e) {
      // Fallback to basic mapping if JSON loading fails
      _timezoneCountryMap = {
        'Asia/Kolkata': 'IN',
        'Asia/Calcutta': 'IN',
      };
      _getInitialCountryCode();
    }
  }

  String? _getCountryFromTimezone(String timezone) {
    if (_timezoneCountryMap != null) {
      // Try exact match first
      if (_timezoneCountryMap!.containsKey(timezone)) {
        return _timezoneCountryMap![timezone];
      }
      
      // Fallback patterns
      if (timezone.startsWith('America/')) return 'US';
      if (timezone.startsWith('Europe/')) return 'GB';
      if (timezone.startsWith('Asia/')) return 'IN';
    }
    
    // Default to India if no mapping found
    return 'IN';
  }

  @override
  Widget build(BuildContext context) {
    int? maxLength;
    if (_countryCode != null &&
        phoneNumberLengths.containsKey(_countryCode!.code)) {
      maxLength = phoneNumberLengths[_countryCode!.code]!['max'];
    }

    return Row(
      children: [
        if (_isFetchingTimezone)
          const CircularProgressIndicator()
        else
          CountryCodePicker(
            onChanged: (countryCode) {
              setState(() {
                _countryCode = countryCode;
                _phoneNumberController.clear();
              });
            },
            initialSelection: _countryCode?.code,
            favorite: const ['+91', 'IN'],
          ),
        Expanded(
          child: TextFormField(
            controller: _phoneNumberController,
            keyboardType: TextInputType.phone,
            maxLength: maxLength,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              if (maxLength != null)
                LengthLimitingTextInputFormatter(maxLength),
            ],
            decoration: const InputDecoration(
              labelText: 'Phone Number',
              counterText: '',
            ),
            validator: (value) {
              if (_countryCode == null || value == null || value.isEmpty) {
                return null;
              }
              final lengths = phoneNumberLengths[_countryCode!.code];
              if (lengths != null) {
                final min = lengths['min']!;
                final max = lengths['max']!;
                if (value.length < min || value.length > max) {
                  return 'Invalid phone number length for ${_countryCode!.name}';
                }
              }
              return null;
            },
          ),
        ),
      ],
    );
  }
}
