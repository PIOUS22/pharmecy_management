import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import 'medicines_screen.dart';
import 'purchase_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = AuthService.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pharmacy Dashboard'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome, ${user?.name ?? 'User'}',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 5),

            Text(
              'Role: ${user?.role ?? '-'}',
              style: const TextStyle(
                fontSize: 16,
              ),
            ),

            const SizedBox(height: 25),

            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                children: [
                  _menuCard(
                    context,
                    icon: Icons.medication,
                    title: 'Medicines',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              const MedicinesScreen(),
                        ),
                      );
                    },
                  ),

                  _menuCard(
                    context,
                    icon: Icons.shopping_cart,
                    title: 'Purchase',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              const PurchaseScreen(),
                        ),
                      );
                    },
                  ),

                  _menuCard(
                    context,
                    icon: Icons.receipt_long,
                    title: 'Prescription Sales',
                    onTap: () {
                      // Prescription screen
                      // will be connected later.
                    },
                  ),

                  _menuCard(
                    context,
                    icon: Icons.money_off,
                    title: 'Expenses',
                    onTap: () {
                      // Expense screen
                      // will be connected later.
                    },
                  ),

                  _menuCard(
                    context,
                    icon: Icons.business,
                    title: 'Suppliers',
                    onTap: () {
                      // Supplier screen
                      // will be connected later.
                    },
                  ),

                  _menuCard(
                    context,
                    icon: Icons.bar_chart,
                    title: 'Reports',
                    onTap: () {
                      // Reports screen
                      // will be connected later.
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _menuCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius:
            BorderRadius.circular(12),
        child: Padding(
          padding:
              const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment:
                MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 42,
              ),

              const SizedBox(height: 10),

              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
