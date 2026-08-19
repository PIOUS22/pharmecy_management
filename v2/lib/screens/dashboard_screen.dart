import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import 'login_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  Future<void> logout(
    BuildContext context,
  ) async {
    AuthService.instance.logout();

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => const LoginScreen(),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user =
        AuthService.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Pharmacy Dashboard',
        ),
        actions: [
          IconButton(
            onPressed: () => logout(context),
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Center(
        child: Text(
          'Welcome, ${user?.name ?? 'User'}\n'
          'Role: ${user?.role ?? '-'}',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
