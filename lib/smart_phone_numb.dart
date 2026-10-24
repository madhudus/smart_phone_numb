import 'dart:developer';

import 'package:country_code_picker/country_code_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:smart_phone_numb/phone_number_lengths.dart';
import 'package:smart_phone_numb/timezone_country_mapping.dart';

export 'package:smart_phone_numb/phone_number_lengths.dart';
export 'package:smart_phone_numb/timezone_country_mapping.dart';

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

  /// Creates a [PhoneNumberData] from its parts.
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
  /// [initialCountryCode] - A country code to start with, skipping timezone detection
  /// [favoriteCountries] - A list of favorite country codes to show first in the picker
  /// [onChanged] - Called whenever the phone number or country code changes
  /// [controller] - Controls the text of the phone number field
  /// [decoration] - Custom input decoration for the phone number field
  /// [style] - Text style for the phone number field
  /// [enabled] - Whether the field is enabled for input
  /// [showCounterText] - Whether to show the character counter
  /// [autovalidateMode] - When the phone number field validates itself
  const SmartPhoneNumberField({
    super.key,
    this.defaultCountryCode = 'US',
    this.initialCountryCode,
    this.favoriteCountries = const [],
    this.onChanged,
    this.controller,
    this.decoration,
    this.style,
    this.enabled = true,
    this.showCounterText = false,
    this.autovalidateMode,
  });

  /// The default country code to use if timezone detection fails
  final String defaultCountryCode;

  /// A two-letter country code (e.g. `'IN'`) to start with.
  ///
  /// When set, timezone detection is skipped. Useful when editing a phone
  /// number whose country is already known.
  final String? initialCountryCode;

  /// A list of favorite country codes to show first in the picker
  final List<String> favoriteCountries;

  /// Called whenever the phone number or country code changes
  final void Function(PhoneNumberData)? onChanged;

  /// Controls the text of the phone number field (without the dial code).
  ///
  /// If null, the widget creates and manages its own controller.
  final TextEditingController? controller;

  /// Custom input decoration for the phone number field.
  /// If null, a default decoration with 'Phone Number' label is used.
  final InputDecoration? decoration;

  /// Text style for the phone number input.
  final TextStyle? style;

  /// Whether the field is enabled for input. Defaults to `true`.
  final bool enabled;

  /// Whether to show the character counter text. Defaults to `false`.
  final bool showCounterText;

  /// When the phone number field validates itself.
  ///
  /// If null, the enclosing [Form]'s mode is used.
  final AutovalidateMode? autovalidateMode;

  @override
  State<SmartPhoneNumberField> createState() => _SmartPhoneNumberFieldState();
}

class _SmartPhoneNumberFieldState extends State<SmartPhoneNumberField> {
  static const _timezoneDetectionTimeout = Duration(seconds: 5);

  TextEditingController? _internalController;
  CountryCode? _countryCode;
  bool _isFetchingTimezone = false;
  bool _hasTimezoneError = false;
  PhoneNumberData? _lastNotifiedData;

  TextEditingController get _phoneNumberController =>
      widget.controller ?? (_internalController ??= TextEditingController());

  @override
  void initState() {
    super.initState();
    _phoneNumberController.addListener(_notifyPhoneNumberChanged);

    final initialCountry = _tryCountryCode(widget.initialCountryCode);
    if (initialCountry != null) {
      _countryCode = initialCountry;
      // Defer so a parent calling setState in onChanged is not mid-build.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _notifyPhoneNumberChanged();
      });
    } else {
      _isFetchingTimezone = true;
      _getInitialCountryCode();
    }
  }

  @override
  void didUpdateWidget(SmartPhoneNumberField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      (oldWidget.controller ?? _internalController)?.removeListener(
        _notifyPhoneNumberChanged,
      );
      if (widget.controller != null) {
        _internalController?.dispose();
        _internalController = null;
      }
      _phoneNumberController.addListener(_notifyPhoneNumberChanged);
    }
  }

  @override
  void dispose() {
    _phoneNumberController.removeListener(_notifyPhoneNumberChanged);
    _internalController?.dispose();
    super.dispose();
  }

  /// Returns the [CountryCode] for a two-letter [code], or `null` if the
  /// code is missing or unknown to the country picker.
  static CountryCode? _tryCountryCode(String? code) {
    if (code == null || code.isEmpty) return null;
    try {
      return CountryCode.fromCountryCode(code.toUpperCase());
    } catch (_) {
      return null;
    }
  }

  /// Notifies parent widget about phone number or country code changes
  void _notifyPhoneNumberChanged() {
    if (widget.onChanged == null || _countryCode == null) return;
    final data = PhoneNumberData(
      dialCode: _countryCode!.dialCode ?? '',
      countryCode: _countryCode!.code ?? '',
      phoneNumber: _phoneNumberController.text,
    );
    // The controller also notifies on cursor and selection changes.
    if (data == _lastNotifiedData) return;
    _lastNotifiedData = data;
    widget.onChanged!(data);
  }

  Future<void> _getInitialCountryCode() async {
    CountryCode? detected;
    try {
      // Never leave the picker hidden behind a spinner if the platform
      // implementation does not answer.
      final timezoneInfo = await FlutterTimezone.getLocalTimezone().timeout(
        _timezoneDetectionTimeout,
      );
      detected = _tryCountryCode(
        countryCodeForTimezone(timezoneInfo.identifier),
      );
    } catch (e) {
      log('Error getting timezone: $e', name: 'SmartPhoneNumberField');
    }

    if (!mounted) return;
    setState(() {
      _hasTimezoneError = detected == null;
      _countryCode =
          detected ??
          _tryCountryCode(widget.defaultCountryCode) ??
          _tryCountryCode('US');
      _isFetchingTimezone = false;
    });

    _notifyPhoneNumberChanged();
  }

  Widget _buildCountryCodePicker() {
    return CountryCodePicker(
      onChanged: (countryCode) {
        setState(() {
          _countryCode = countryCode;
        });
        // Clearing the text notifies the listener with the new country.
        if (_phoneNumberController.text.isEmpty) {
          _notifyPhoneNumberChanged();
        } else {
          _phoneNumberController.clear();
        }
      },
      initialSelection: _countryCode?.code,
      favorite: widget.favoriteCountries,
      enabled: widget.enabled,
    );
  }

  String? _validate(String? value) {
    if (_countryCode == null || value == null || value.isEmpty) {
      return null;
    }
    final lengths = phoneNumberLengths[_countryCode!.code];
    if (lengths != null) {
      final min = lengths['min']!;
      final max = lengths['max']!;
      if (value.length < min || value.length > max) {
        final digits = min == max ? '$min' : 'between $min and $max';
        return 'Phone number must be $digits digits for ${_countryCode!.name}';
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final maxLength = phoneNumberLengths[_countryCode?.code]?['max'];

    final effectiveDecoration =
        widget.decoration ??
        InputDecoration(
          labelText: 'Phone Number',
          counterText: widget.showCounterText ? null : '',
        );

    return Row(
      children: [
        if (_isFetchingTimezone)
          Semantics(
            label: 'Detecting country',
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox.square(
                dimension: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
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
                  child: Icon(Icons.warning, color: Colors.orange, size: 16),
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
            autovalidateMode: widget.autovalidateMode,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: effectiveDecoration,
            validator: _validate,
          ),
        ),
      ],
    );
  }
}
