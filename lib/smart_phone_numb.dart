import 'package:country_code_picker/country_code_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:smart_phone_numb/phone_number_lengths.dart';

class SmartPhoneNumberField extends StatefulWidget {
  const SmartPhoneNumberField({super.key});

  @override
  State<SmartPhoneNumberField> createState() => _SmartPhoneNumberFieldState();
}

class _SmartPhoneNumberFieldState extends State<SmartPhoneNumberField> {
  final TextEditingController _phoneNumberController = TextEditingController();
  CountryCode? _countryCode;
  bool _isFetchingTimezone = false;

  @override
  void initState() {
    super.initState();
    _getInitialCountryCode();
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

  String? _getCountryFromTimezone(String timezone) {
    if (timezone == 'Asia/Kolkata') return 'IN';
    if (timezone.startsWith('America/')) return 'US';
    if (timezone.startsWith('Europe/')) return 'GB';
    // Add more comprehensive mapping
    return null;
  }

  @override
  Widget build(BuildContext context) {
    int? maxLength;
    if (_countryCode != null && phoneNumberLengths.containsKey(_countryCode!.code)) {
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
              if (maxLength != null) LengthLimitingTextInputFormatter(maxLength),
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