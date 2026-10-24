## 0.3.0

* **NEW**: `initialCountryCode` parameter to start with a known country and skip timezone detection
* **NEW**: `controller` parameter to read or set the phone number from outside the widget
* **NEW**: `autovalidateMode` parameter, passed to the underlying `TextFormField`
* **NEW**: Public `timezoneCountryMapping` map and `countryCodeForTimezone()` helper, exported together with `phoneNumberLengths` from `package:smart_phone_numb/smart_phone_numb.dart`
* **IMPROVED**: Timezone mapping is now a compile-time constant instead of a JSON asset, so lookup is synchronous and no asset loading or fallback map is needed
* **IMPROVED**: Added 100+ legacy timezone aliases still reported by some devices (e.g. `Asia/Calcutta`, `Asia/Saigon`, `Europe/Kiev`, `US/Eastern`)
* **IMPROVED**: Removed the hand-written timezone if-chains, which contained timezone names that do not exist in the IANA database
* **IMPROVED**: `onChanged` is no longer called repeatedly with unchanged data (e.g. on cursor moves or when switching country on an empty field)
* **IMPROVED**: Clearer validation message for fixed-length numbers ("must be 10 digits")
* **IMPROVED**: Fixed-size loading indicator so the row does not jump while detecting the country
* **FIXED**: The field no longer stays on the loading spinner if the timezone plugin never answers (detection times out after 5 seconds)
* **FIXED**: An unknown or invalid country code no longer throws; the widget falls back to `defaultCountryCode`, then `US`
* **UPDATED**: `flutter_timezone` to `^5.1.1`
* **UPDATED**: Minimum SDK to Dart 3.8 / Flutter 3.32
* **CHORE**: Added GitHub Actions CI (format, analyze, test, pana), automated pub.dev publishing on version tags, and Dependabot

## 0.2.4

* **FIXED**: Added `mounted` guard to prevent `setState() called after dispose()` crash during async timezone detection
* **FIXED**: Removed invalid IANA timezone strings (e.g., `Europe/Hamburg`, `Europe/Florence`) that never matched
* **FIXED**: Continent-level timezone defaults now fall back to `defaultCountryCode` instead of hardcoded values
* **FIXED**: Consolidated multiple `setState` calls in `_getInitialCountryCode()` to reduce unnecessary rebuilds
* **FIXED**: `onChanged` callback now fires after initial country detection
* **FIXED**: Removed duplicate `LengthLimitingTextInputFormatter` (already enforced by `maxLength`)
* **FIXED**: Capped North Korea (KP) max phone number length from 17 to 15 (E.164 limit)
* **NEW**: Added `decoration`, `style`, `enabled`, and `showCounterText` parameters for widget customization
* **NEW**: Added `==`, `hashCode`, and `toString` to `PhoneNumberData`
* **IMPROVED**: Extracted duplicated `CountryCodePicker` into shared `_buildCountryCodePicker()` method
* **IMPROVED**: Added `Tooltip` to timezone warning icon for accessibility
* **IMPROVED**: Added `Semantics` label to loading indicator
* **IMPROVED**: Timezone JSON mapping is now cached statically across widget instances
* **IMPROVED**: Default `favoriteCountries` changed from `['+91', 'IN']` to `[]` (no regional bias)
* **IMPROVED**: Meaningful unit tests for `PhoneNumberData` and `phoneNumberLengths` data integrity
* **IMPROVED**: Updated Flutter SDK constraint from `>=1.17.0` to `>=3.10.0`
* **IMPROVED**: Cleaned up `pubspec.yaml` template comments
* **IMPROVED**: Rewritten README with parameter table and usage examples

## 0.2.3

* **NEW**: Added `PhoneNumberData` class to expose phone number state to parent widgets
* **NEW**: Added `onChanged` callback parameter for real-time phone number change notifications
* **IMPROVED**: Replaced print() debugging with proper logging using dart:developer
* **IMPROVED**: Expanded timezone fallback map from 2 to 40+ entries covering all major regions
* **FIXED**: Phone number validation for Italy (IT) and Vatican (VA) - minimum length updated from 0 to 6 digits
* **UPDATED**: flutter_timezone dependency to version 5.0.1
* **IMPROVED**: Better project organization - moved utility scripts to tools/ directory

## 0.2.2

* **UPDATED**: flutter_timezone dependency to version 5.0.0
* **FIXED**: Compatibility with flutter_timezone 5.0.0 API changes (now using TimezoneInfo object)
* **IMPROVED**: Enhanced timezone detection with support for localized timezone names

## 0.2.1

* **UPDATED**: country_code_picker dependency to version 3.4.0
* **IMPROVED**: Enhanced compatibility and stability

## 0.2.0

* **NEW**: Added configurable default country code and favorite countries
* **IMPROVED**: Enhanced error handling with visual error indicators
* **IMPROVED**: Better validation messages with specific min/max digit requirements
* **IMPROVED**: Expanded fallback timezone mapping for more accurate country detection
* **IMPROVED**: Added comprehensive test coverage for new features
* **IMPROVED**: Enhanced documentation and example app
* **REMOVED**: Country selection persistence (kept package simpler)

## 0.1.1

* **FIXED**: Code formatting to meet Dart formatter standards
* **IMPROVED**: Package now achieves perfect 160/160 pub points score

## 0.1.0

* **MAJOR IMPROVEMENT**: Added comprehensive timezone-to-country mapping with 420+ timezone entries
* **FIXED**: Default country no longer shows Afghanistan (+93), now properly detects user's country
* **ENHANCED**: Complete coverage for 247+ countries and territories via IANA timezone database
* **IMPROVED**: Robust fallback system for edge cases in timezone detection
* **ADDED**: JSON-based timezone mapping for better maintainability
* **OPTIMIZED**: Timezone detection now works accurately for users worldwide
* India users now properly get +91 instead of +93 default

## 0.0.4

* Version bump for package stability
* Ready for production use

## 0.0.3

* Minor version bump for pub.dev publishing
* Package quality improvements and optimizations

## 0.0.2

* Added comprehensive dartdoc comments to public API
* Fixed code formatting to follow Dart standards
* Updated widget tests to properly test SmartPhoneNumberField
* Improved package documentation and examples

## 0.0.1

* This is the first ever release
