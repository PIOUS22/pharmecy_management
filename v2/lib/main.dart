import 'package:flutter/material.dart';

import 'database/app_database.dart';
import 'screens/login_screen.dart';
import 'services/auth_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await AppDatabase.instance.database;

  await AuthService.instance.initialize();

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
      home: const LoginScreen(),
    );
  }
}
