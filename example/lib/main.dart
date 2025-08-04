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

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Phone Number Field'),
      ),
      body: const Padding(
        padding: EdgeInsets.all(16.0),
        child: SmartPhoneNumberField(),
      ),
    );
  }
}
