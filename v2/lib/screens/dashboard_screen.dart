import 'package:flutter/material.dart';

import '../services/auth_service.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = AuthService.instance.currentUser;

    return Center(
      child: Text(
        'Welcome, ${user?.name ?? 'User'}\n'
        'Role: ${user?.role ?? '-'}',
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
