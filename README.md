# Smart Phone Number Field

A Flutter package that provides an  phone number input field with automatic country code  and number field lenth detection based on the user's timezone.
 Features

- Smart Country Detection: Automatically suggests the correct country code based on user's timezone
- Dynamic Phone Number Validation: Sets minimum and maximum phone number length limits based on the selected country
- Country Code Picker Integration: Easy-to-use country selector with flag display
- Real-time Validation: Validates phone numbers according to country-specific rules
- Support for 221+ Countries: Comprehensive database of phone number formats worldwide

 Getting Started

Add this package to your `pubspec.yaml`:

```yaml
dependencies:
  smart_phone_numb: ^0.0.1
```

Then run:
```bash
flutter pub get
```

 Usage

Import the package and use the `SmartPhoneNumberField` widget:

```dart
import 'package:flutter/material.dart';
import 'package:smart_phone_numb/smart_phone_numb.dart';

class MyForm extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          child: SmartPhoneNumberField(),
        ),
      ),
    );
  }
}
```

 How It Works

1. Automatic Detection: When the widget loads, it detects the user's timezone
2. Country Mapping: Maps the timezone to the most likely country code
3. Smart Validation: Automatically sets the correct phone number length limits
4. User Override: Users can manually select a different country if needed

Example

The widget will:
- Show a country flag and code picker
- Display a text field for phone number input
- Validate the phone number length based on the selected country
- Provide real-time feedback for invalid inputs

Supported Countries

The package includes phone number validation rules for 221+ countries, covering:
- Minimum and maximum phone number lengths
- Country-specific formatting requirements
- Major international dialing codes



 Dependencies

This package uses:
- `country_code_picker` for the country selection UI
- `flutter_timezone` for automatic timezone detection