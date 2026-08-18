import 'package:flutter/material.dart';

void main() {
  runApp(const PharmacyV2App());
}

class PharmacyV2App extends StatelessWidget {
  const PharmacyV2App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Pharmacy Management V2',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.green,
      ),
      home: const Scaffold(
        body: Center(
          child: Text(
            'Pharmacy Management V2',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
