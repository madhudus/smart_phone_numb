import 'package:flutter/material.dart';
import 'package:smart_phone_numb/smart_phone_numb.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Phone Number Field Example',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  PhoneNumberData? _phoneData;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Phone Number Field'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Default configuration:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SmartPhoneNumberField(
              onChanged: (data) {
                setState(() {
                  _phoneData = data;
                });
              },
            ),
            if (_phoneData != null) ...[
              const SizedBox(height: 8),
              Text('Full number: ${_phoneData!.fullPhoneNumber}'),
              Text('Country: ${_phoneData!.countryCode}'),
            ],
            const SizedBox(height: 32),
            const Text(
              'Custom configuration (Germany default, styled):',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SmartPhoneNumberField(
              defaultCountryCode: 'DE',
              favoriteCountries: const ['+49', 'DE', '+44', 'GB', '+33', 'FR'],
              decoration: const InputDecoration(
                labelText: 'Mobile Number',
                border: OutlineInputBorder(),
              ),
              style: const TextStyle(fontSize: 18),
              showCounterText: true,
              onChanged: (data) {
                debugPrint('Custom field: ${data.fullPhoneNumber}');
              },
            ),
            const SizedBox(height: 32),
            const Text(
              'Disabled field:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const SmartPhoneNumberField(
              enabled: false,
              defaultCountryCode: 'GB',
            ),
          ],
        ),
      ),
    );
  }
}
