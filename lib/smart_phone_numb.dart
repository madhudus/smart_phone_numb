import 'dart:convert';
import 'dart:developer';
import 'package:country_code_picker/country_code_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:smart_phone_numb/phone_number_lengths.dart';

/// Contains the current phone number data including country code and number.
class PhoneNumberData {
  /// The selected country code (e.g., '+1', '+91')
  final String dialCode;

  /// The two-letter country code (e.g., 'US', 'IN')
  final String countryCode;

  /// The phone number entered by the user (without country code)
  final String phoneNumber;

  /// The complete phone number with country code
  String get fullPhoneNumber => '$dialCode$phoneNumber';

  const PhoneNumberData({
    required this.dialCode,
    required this.countryCode,
    required this.phoneNumber,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PhoneNumberData &&
          runtimeType == other.runtimeType &&
          dialCode == other.dialCode &&
          countryCode == other.countryCode &&
          phoneNumber == other.phoneNumber;

  @override
  int get hashCode => Object.hash(dialCode, countryCode, phoneNumber);

  @override
  String toString() =>
      'PhoneNumberData(dialCode: $dialCode, countryCode: $countryCode, phoneNumber: $phoneNumber)';
}

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
  ///
  /// [defaultCountryCode] - The default country code to use if timezone detection fails
  /// [favoriteCountries] - A list of favorite country codes to show first in the picker
  /// [onChanged] - Called whenever the phone number or country code changes
  /// [decoration] - Custom input decoration for the phone number field
  /// [style] - Text style for the phone number field
  /// [enabled] - Whether the field is enabled for input
  /// [showCounterText] - Whether to show the character counter
  const SmartPhoneNumberField({
    super.key,
    this.defaultCountryCode = 'US',
    this.favoriteCountries = const [],
    this.onChanged,
    this.decoration,
    this.style,
    this.enabled = true,
    this.showCounterText = false,
  });

  /// The default country code to use if timezone detection fails
  final String defaultCountryCode;

  /// A list of favorite country codes to show first in the picker
  final List<String> favoriteCountries;

  /// Called whenever the phone number or country code changes
  final void Function(PhoneNumberData)? onChanged;

  /// Custom input decoration for the phone number field.
  /// If null, a default decoration with 'Phone Number' label is used.
  final InputDecoration? decoration;

  /// Text style for the phone number input.
  final TextStyle? style;

  /// Whether the field is enabled for input. Defaults to `true`.
  final bool enabled;

  /// Whether to show the character counter text. Defaults to `false`.
  final bool showCounterText;

  @override
  State<SmartPhoneNumberField> createState() => _SmartPhoneNumberFieldState();
}

class _SmartPhoneNumberFieldState extends State<SmartPhoneNumberField> {
  final TextEditingController _phoneNumberController = TextEditingController();
  CountryCode? _countryCode;
  bool _isFetchingTimezone = false;
  bool _hasTimezoneError = false;

  /// Cached timezone-to-country map shared across all instances.
  static Map<String, String>? _cachedTimezoneMap;

  @override
  void initState() {
    super.initState();
    _loadTimezoneMapping();
    _phoneNumberController.addListener(_notifyPhoneNumberChanged);
  }

  @override
  void dispose() {
    _phoneNumberController.removeListener(_notifyPhoneNumberChanged);
    _phoneNumberController.dispose();
    super.dispose();
  }

  /// Notifies parent widget about phone number or country code changes
  void _notifyPhoneNumberChanged() {
    if (widget.onChanged != null && _countryCode != null) {
      final data = PhoneNumberData(
        dialCode: _countryCode!.dialCode ?? '',
        countryCode: _countryCode!.code ?? '',
        phoneNumber: _phoneNumberController.text,
      );
      widget.onChanged!(data);
    }
  }

  Future<void> _getInitialCountryCode() async {
    if (!mounted) return;
    setState(() {
      _isFetchingTimezone = true;
      _hasTimezoneError = false;
    });

    try {
      final timezoneInfo = await FlutterTimezone.getLocalTimezone();
      final country = _getCountryFromTimezone(timezoneInfo.identifier);

      if (!mounted) return;
      setState(() {
        _countryCode = CountryCode.fromCountryCode(country ?? widget.defaultCountryCode);
        _isFetchingTimezone = false;
      });
    } catch (e) {
      log('Error getting timezone: $e', name: 'SmartPhoneNumberField');

      if (!mounted) return;
      setState(() {
        _hasTimezoneError = true;
        _countryCode = CountryCode.fromCountryCode(widget.defaultCountryCode);
        _isFetchingTimezone = false;
      });
    }

    _notifyPhoneNumberChanged();
  }

  Future<void> _loadTimezoneMapping() async {
    if (_cachedTimezoneMap != null) {
      _getInitialCountryCode();
      return;
    }

    try {
      final jsonString = await rootBundle.loadString(
          'packages/smart_phone_numb/timezone_country_mapping.json');
      final Map<String, dynamic> jsonMap = json.decode(jsonString);
      _cachedTimezoneMap = jsonMap.cast<String, String>();
      _getInitialCountryCode();
    } catch (e) {
      // Fallback to basic mapping if JSON loading fails
      _cachedTimezoneMap = {
        // Americas
        'America/New_York': 'US',
        'America/Chicago': 'US',
        'America/Denver': 'US',
        'America/Los_Angeles': 'US',
        'America/Toronto': 'CA',
        'America/Vancouver': 'CA',
        'America/Mexico_City': 'MX',
        'America/Sao_Paulo': 'BR',
        'America/Buenos_Aires': 'AR',
        // Europe
        'Europe/London': 'GB',
        'Europe/Paris': 'FR',
        'Europe/Berlin': 'DE',
        'Europe/Rome': 'IT',
        'Europe/Madrid': 'ES',
        'Europe/Moscow': 'RU',
        'Europe/Amsterdam': 'NL',
        'Europe/Brussels': 'BE',
        'Europe/Stockholm': 'SE',
        'Europe/Warsaw': 'PL',
        // Asia
        'Asia/Kolkata': 'IN',
        'Asia/Calcutta': 'IN',
        'Asia/Shanghai': 'CN',
        'Asia/Tokyo': 'JP',
        'Asia/Seoul': 'KR',
        'Asia/Hong_Kong': 'HK',
        'Asia/Singapore': 'SG',
        'Asia/Dubai': 'AE',
        'Asia/Bangkok': 'TH',
        'Asia/Jakarta': 'ID',
        'Asia/Manila': 'PH',
        // Oceania
        'Australia/Sydney': 'AU',
        'Australia/Melbourne': 'AU',
        'Australia/Perth': 'AU',
        'Pacific/Auckland': 'NZ',
        // Africa
        'Africa/Cairo': 'EG',
        'Africa/Johannesburg': 'ZA',
        'Africa/Lagos': 'NG',
        'Africa/Nairobi': 'KE',
      };
      _getInitialCountryCode();
    }
  }

  String? _getCountryFromTimezone(String timezone) {
    if (_cachedTimezoneMap != null) {
      // Try exact match first
      if (_cachedTimezoneMap!.containsKey(timezone)) {
        return _cachedTimezoneMap![timezone];
      }

      // Fallback patterns for better coverage
      if (timezone.startsWith('America/')) {
        if (timezone == 'America/Argentina/Buenos_Aires' ||
            timezone == 'America/Argentina/Catamarca' ||
            timezone == 'America/Argentina/Cordoba' ||
            timezone == 'America/Argentina/Jujuy' ||
            timezone == 'America/Argentina/La_Rioja' ||
            timezone == 'America/Argentina/Mendoza' ||
            timezone == 'America/Argentina/Rio_Gallegos' ||
            timezone == 'America/Argentina/Salta' ||
            timezone == 'America/Argentina/San_Juan' ||
            timezone == 'America/Argentina/San_Luis' ||
            timezone == 'America/Argentina/Tucuman' ||
            timezone == 'America/Argentina/Ushuaia') {
          return 'AR';
        }
        if (timezone == 'America/Buenos_Aires') return 'AR';
        if (timezone == 'America/Sao_Paulo' ||
            timezone == 'America/Fortaleza' ||
            timezone == 'America/Recife' ||
            timezone == 'America/Salvador' ||
            timezone == 'America/Bahia' ||
            timezone == 'America/Maceio' ||
            timezone == 'America/Campo_Grande' ||
            timezone == 'America/Cuiaba' ||
            timezone == 'America/Porto_Velho' ||
            timezone == 'America/Boa_Vista' ||
            timezone == 'America/Manaus' ||
            timezone == 'America/Eirunepe' ||
            timezone == 'America/Rio_Branco') {
          return 'BR';
        }
        if (timezone == 'America/Toronto' ||
            timezone == 'America/Vancouver' ||
            timezone == 'America/Montreal' ||
            timezone == 'America/Calgary' ||
            timezone == 'America/Edmonton' ||
            timezone == 'America/Winnipeg' ||
            timezone == 'America/Halifax' ||
            timezone == 'America/Regina' ||
            timezone == 'America/Fredericton' ||
            timezone == 'America/St_Johns') {
          return 'CA';
        }
        if (timezone == 'America/Mexico_City' ||
            timezone == 'America/Cancun' ||
            timezone == 'America/Hermosillo' ||
            timezone == 'America/Mazatlan' ||
            timezone == 'America/Chihuahua' ||
            timezone == 'America/Tijuana' ||
            timezone == 'America/Matamoros' ||
            timezone == 'America/Ojinaga' ||
            timezone == 'America/Bahia_Banderas') {
          return 'MX';
        }
        return widget.defaultCountryCode;
      }
      if (timezone.startsWith('Europe/')) {
        if (timezone == 'Europe/Paris') {
          return 'FR';
        }
        if (timezone == 'Europe/Berlin') {
          return 'DE';
        }
        if (timezone == 'Europe/Rome') {
          return 'IT';
        }
        if (timezone == 'Europe/Madrid') {
          return 'ES';
        }
        return widget.defaultCountryCode;
      }
      if (timezone.startsWith('Asia/')) {
        if (timezone == 'Asia/Tokyo') return 'JP';
        if (timezone == 'Asia/Seoul') return 'KR';
        if (timezone == 'Asia/Shanghai' ||
            timezone == 'Asia/Chongqing' ||
            timezone == 'Asia/Harbin' ||
            timezone == 'Asia/Urumqi') {
          return 'CN';
        }
        if (timezone == 'Asia/Bangkok') return 'TH';
        if (timezone == 'Asia/Jakarta' ||
            timezone == 'Asia/Surabaya' ||
            timezone == 'Asia/Medan' ||
            timezone == 'Asia/Makassar') {
          return 'ID';
        }
        if (timezone == 'Asia/Kuala_Lumpur' ||
            timezone == 'Asia/Kuching') {
          return 'MY';
        }
        return widget.defaultCountryCode;
      }
      if (timezone.startsWith('Australia/')) return 'AU';
      if (timezone.startsWith('Africa/')) {
        if (timezone == 'Africa/Cairo') return 'EG';
        if (timezone == 'Africa/Johannesburg') return 'ZA';
        if (timezone == 'Africa/Lagos') return 'NG';
        return widget.defaultCountryCode;
      }
    }

    return widget.defaultCountryCode;
  }

  Widget _buildCountryCodePicker() {
    return CountryCodePicker(
      onChanged: (countryCode) {
        setState(() {
          _countryCode = countryCode;
          _phoneNumberController.clear();
        });
        _notifyPhoneNumberChanged();
      },
      initialSelection: _countryCode?.code,
      favorite: widget.favoriteCountries,
      enabled: widget.enabled,
    );
  }

  @override
  Widget build(BuildContext context) {
    int? maxLength;
    if (_countryCode != null &&
        phoneNumberLengths.containsKey(_countryCode!.code)) {
      maxLength = phoneNumberLengths[_countryCode!.code]!['max'];
    }

    final effectiveDecoration = widget.decoration ??
        InputDecoration(
          labelText: 'Phone Number',
          counterText: widget.showCounterText ? null : '',
        );

    return Row(
      children: [
        if (_isFetchingTimezone)
          Semantics(
            label: 'Detecting country',
            child: const CircularProgressIndicator(),
          )
        else if (_hasTimezoneError)
          Stack(
            children: [
              _buildCountryCodePicker(),
              const Positioned(
                right: 0,
                top: 0,
                child: Tooltip(
                  message: 'Could not detect timezone automatically',
                  child: Icon(
                    Icons.warning,
                    color: Colors.orange,
                    size: 16,
                  ),
                ),
              ),
            ],
          )
        else
          _buildCountryCodePicker(),
        Expanded(
          child: TextFormField(
            controller: _phoneNumberController,
            keyboardType: TextInputType.phone,
            maxLength: maxLength,
            enabled: widget.enabled,
            style: widget.style,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
            ],
            decoration: effectiveDecoration,
            validator: (value) {
              if (_countryCode == null || value == null || value.isEmpty) {
                return null;
              }
              final lengths = phoneNumberLengths[_countryCode!.code];
              if (lengths != null) {
                final min = lengths['min']!;
                final max = lengths['max']!;
                if (value.length < min || value.length > max) {
                  return 'Phone number must be between $min and $max digits for ${_countryCode!.name}';
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
