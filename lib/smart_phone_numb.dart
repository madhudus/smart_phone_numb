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
  const SmartPhoneNumberField({
    super.key,
    this.defaultCountryCode = 'US',
    this.favoriteCountries = const ['+91', 'IN'],
    this.onChanged,
  });

  /// The default country code to use if timezone detection fails
  final String defaultCountryCode;

  /// A list of favorite country codes to show first in the picker
  final List<String> favoriteCountries;

  /// Called whenever the phone number or country code changes
  final void Function(PhoneNumberData)? onChanged;

  @override
  State<SmartPhoneNumberField> createState() => _SmartPhoneNumberFieldState();
}

class _SmartPhoneNumberFieldState extends State<SmartPhoneNumberField> {
  final TextEditingController _phoneNumberController = TextEditingController();
  CountryCode? _countryCode;
  bool _isFetchingTimezone = false;
  bool _hasTimezoneError = false;
  Map<String, String>? _timezoneCountryMap;

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
    setState(() {
      _isFetchingTimezone = true;
      _hasTimezoneError = false;
    });

    try {
      final timezoneInfo = await FlutterTimezone.getLocalTimezone();
      final country = _getCountryFromTimezone(timezoneInfo.identifier);

      if (country != null) {
        setState(() {
          _countryCode = CountryCode.fromCountryCode(country);
        });
      }
    } catch (e) {
      // Log the error for debugging
      log('Error getting timezone: $e', name: 'SmartPhoneNumberField');

      setState(() {
        _hasTimezoneError = true;
        // Set a default country code as fallback
        _countryCode = CountryCode.fromCountryCode(widget.defaultCountryCode);
      });
    } finally {
      setState(() {
        _isFetchingTimezone = false;
      });
    }
  }

  Future<void> _loadTimezoneMapping() async {
    try {
      final jsonString = await rootBundle.loadString(
          'packages/smart_phone_numb/timezone_country_mapping.json');
      final Map<String, dynamic> jsonMap = json.decode(jsonString);
      _timezoneCountryMap = jsonMap.cast<String, String>();
      _getInitialCountryCode();
    } catch (e) {
      // Fallback to basic mapping if JSON loading fails
      // Includes major timezones from different regions
      _timezoneCountryMap = {
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
    if (_timezoneCountryMap != null) {
      // Try exact match first
      if (_timezoneCountryMap!.containsKey(timezone)) {
        return _timezoneCountryMap![timezone];
      }

      // Fallback patterns for better coverage
      if (timezone.startsWith('America/')) {
        // Most American timezones map to US, but there are some exceptions
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
          return 'AR'; // Argentina
        }
        if (timezone == 'America/Buenos_Aires') return 'AR'; // Argentina
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
          return 'BR'; // Brazil
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
          return 'CA'; // Canada
        }
        if (timezone == 'America/Mexico_City' ||
            timezone == 'America/Guadalajara' ||
            timezone == 'America/Monterrey' ||
            timezone == 'America/Cancun' ||
            timezone == 'America/Hermosillo' ||
            timezone == 'America/Mazatlan' ||
            timezone == 'America/Chihuahua' ||
            timezone == 'America/Tijuana' ||
            timezone == 'America/Matamoros' ||
            timezone == 'America/Ojinaga' ||
            timezone == 'America/Bahia_Banderas') {
          return 'MX'; // Mexico
        }
        return 'US'; // Default for other American timezones
      }
      if (timezone.startsWith('Europe/')) {
        if (timezone == 'Europe/Paris' ||
            timezone == 'Europe/Marseille' ||
            timezone == 'Europe/Lyon' ||
            timezone == 'Europe/Toulouse' ||
            timezone == 'Europe/Nice' ||
            timezone == 'Europe/Nantes' ||
            timezone == 'Europe/Strasbourg' ||
            timezone == 'Europe/Montpellier' ||
            timezone == 'Europe/Bordeaux' ||
            timezone == 'Europe/Lille' ||
            timezone == 'Europe/Rennes' ||
            timezone == 'Europe/Reims' ||
            timezone == 'Europe/Le_Havre' ||
            timezone == 'Europe/Saint-Etienne' ||
            timezone == 'Europe/Toulon') {
          return 'FR'; // France
        }
        if (timezone == 'Europe/Berlin' ||
            timezone == 'Europe/Hamburg' ||
            timezone == 'Europe/Munich' ||
            timezone == 'Europe/Cologne' ||
            timezone == 'Europe/Frankfurt' ||
            timezone == 'Europe/Stuttgart' ||
            timezone == 'Europe/Dusseldorf' ||
            timezone == 'Europe/Leipzig' ||
            timezone == 'Europe/Dortmund' ||
            timezone == 'Europe/Essen' ||
            timezone == 'Europe/Bremen' ||
            timezone == 'Europe/Dresden' ||
            timezone == 'Europe/Hanover' ||
            timezone == 'Europe/Nuremberg' ||
            timezone == 'Europe/Duisburg') {
          return 'DE'; // Germany
        }
        if (timezone == 'Europe/Rome' ||
            timezone == 'Europe/Milan' ||
            timezone == 'Europe/Naples' ||
            timezone == 'Europe/Turin' ||
            timezone == 'Europe/Palermo' ||
            timezone == 'Europe/Genoa' ||
            timezone == 'Europe/Bologna' ||
            timezone == 'Europe/Florence' ||
            timezone == 'Europe/Bari' ||
            timezone == 'Europe/Catania' ||
            timezone == 'Europe/Venice' ||
            timezone == 'Europe/Verona' ||
            timezone == 'Europe/Messina' ||
            timezone == 'Europe/Padua' ||
            timezone == 'Europe/Trieste') {
          return 'IT'; // Italy
        }
        if (timezone == 'Europe/Madrid' ||
            timezone == 'Europe/Barcelona' ||
            timezone == 'Europe/Valencia' ||
            timezone == 'Europe/Seville' ||
            timezone == 'Europe/Zaragoza' ||
            timezone == 'Europe/Malaga' ||
            timezone == 'Europe/Murcia' ||
            timezone == 'Europe/Palma' ||
            timezone == 'Europe/Bilbao' ||
            timezone == 'Europe/Alicante' ||
            timezone == 'Europe/Cordoba') {
          return 'ES'; // Spain
        }
        return 'GB'; // Default for other European timezones
      }
      if (timezone.startsWith('Asia/')) {
        if (timezone == 'Asia/Tokyo') return 'JP'; // Japan
        if (timezone == 'Asia/Seoul') return 'KR'; // South Korea
        if (timezone == 'Asia/Shanghai' ||
            timezone == 'Asia/Chongqing' ||
            timezone == 'Asia/Harbin' ||
            timezone == 'Asia/Urumqi') {
          return 'CN'; // China
        }
        if (timezone == 'Asia/Bangkok') return 'TH'; // Thailand
        if (timezone == 'Asia/Jakarta' ||
            timezone == 'Asia/Surabaya' ||
            timezone == 'Asia/Medan' ||
            timezone == 'Asia/Makassar' ||
            timezone == 'Asia/Denpasar') {
          return 'ID'; // Indonesia
        }
        if (timezone == 'Asia/Kuala_Lumpur' ||
            timezone == 'Asia/Kuching') {
          return 'MY'; // Malaysia
        }
        return 'IN'; // Default for other Asian timezones
      }
      if (timezone.startsWith('Australia/')) return 'AU'; // Australia
      if (timezone.startsWith('Africa/')) {
        if (timezone == 'Africa/Cairo') return 'EG'; // Egypt
        if (timezone == 'Africa/Johannesburg') return 'ZA'; // South Africa
        if (timezone == 'Africa/Lagos') return 'NG'; // Nigeria
        return 'KE'; // Default for other African timezones (Kenya)
      }
    }

    // Default to US if no mapping found
    return widget.defaultCountryCode;
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
        else if (_hasTimezoneError)
          Stack(
            children: [
              CountryCodePicker(
                onChanged: (countryCode) {
                  setState(() {
                    _countryCode = countryCode;
                    _phoneNumberController.clear();
                  });
                  _notifyPhoneNumberChanged();
                },
                initialSelection: _countryCode?.code,
                favorite: widget.favoriteCountries,
              ),
              const Positioned(
                right: 0,
                top: 0,
                child: Icon(
                  Icons.warning,
                  color: Colors.orange,
                  size: 16,
                ),
              ),
            ],
          )
        else
          CountryCodePicker(
            onChanged: (countryCode) {
              setState(() {
                _countryCode = countryCode;
                _phoneNumberController.clear();
              });
              _notifyPhoneNumberChanged();
            },
            initialSelection: _countryCode?.code,
            favorite: widget.favoriteCountries,
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
