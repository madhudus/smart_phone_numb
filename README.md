# Smart Phone Number Field

A Flutter package that provides a smart phone number input field with automatic country code and number field length detection based on the user's timezone.

## Features

- **Smart Country Detection**: Automatically suggests the correct country code based on user's timezone
- **Dynamic Phone Number Validation**: Sets minimum and maximum phone number length limits based on the selected country
- **Country Code Picker Integration**: Easy-to-use country selector with flag display
- **Real-time Validation**: Validates phone numbers according to country-specific rules
- **Support for 221+ Countries**: Comprehensive database of phone number formats worldwide

## Getting Started

Add this package to your `pubspec.yaml`:

```yaml
dependencies:
  smart_phone_numb: ^0.2.4
```

Then run:

```bash
flutter pub get
```

## Usage

Import the package and use the `SmartPhoneNumberField` widget:

```dart
import 'package:smart_phone_numb/smart_phone_numb.dart';

SmartPhoneNumberField(
  defaultCountryCode: 'US',
  onChanged: (PhoneNumberData data) {
    print('Full number: ${data.fullPhoneNumber}');
    print('Country: ${data.countryCode}');
    print('Dial code: ${data.dialCode}');
    print('Number: ${data.phoneNumber}');
  },
)
```

## Parameters

| Parameter | Type | Default | Description |
|---|---|---|---|
| `defaultCountryCode` | `String` | `'US'` | Fallback country code when timezone detection fails |
| `favoriteCountries` | `List<String>` | `[]` | Country codes shown at top of the picker |
| `onChanged` | `void Function(PhoneNumberData)?` | `null` | Called when the phone number or country changes |
| `decoration` | `InputDecoration?` | `null` | Custom input decoration for the text field |
| `style` | `TextStyle?` | `null` | Text style for the phone number input |
| `enabled` | `bool` | `true` | Whether the field accepts input |
| `showCounterText` | `bool` | `false` | Whether to show the character counter |

## PhoneNumberData

The `onChanged` callback provides a `PhoneNumberData` object with:

| Property | Type | Description |
|---|---|---|
| `dialCode` | `String` | The dial code (e.g., `'+1'`) |
| `countryCode` | `String` | Two-letter ISO code (e.g., `'US'`) |
| `phoneNumber` | `String` | The entered number without country code |
| `fullPhoneNumber` | `String` | Complete number with dial code |

## How It Works

1. **Automatic Detection**: When the widget loads, it detects the user's timezone
2. **Country Mapping**: Maps the timezone to the most likely country code
3. **Smart Validation**: Automatically sets the correct phone number length limits
4. **User Override**: Users can manually select a different country if needed

## Example

```dart
class MyForm extends StatelessWidget {
  const MyForm({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          child: SmartPhoneNumberField(
            defaultCountryCode: 'DE',
            favoriteCountries: const ['+49', 'DE', '+44', 'GB'],
            decoration: const InputDecoration(
              labelText: 'Mobile Number',
              border: OutlineInputBorder(),
            ),
            onChanged: (data) {
              debugPrint('Number: ${data.fullPhoneNumber}');
            },
          ),
        ),
      ),
    );
  }
}
```

## Dependencies

This package uses:

- [`country_code_picker`](https://pub.dev/packages/country_code_picker) for the country selection UI
- [`flutter_timezone`](https://pub.dev/packages/flutter_timezone) for automatic timezone detection

## Additional Information

- **Issues & Contributions**: [GitHub Repository](https://github.com/madhudus/smart_phone_numb)
- **License**: See [LICENSE](LICENSE) file
