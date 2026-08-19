import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import 'dashboard_screen.dart';
import 'expenses_screen.dart';
import 'login_screen.dart';
import 'medicines_screen.dart';
import 'prescription_screen.dart';
import 'purchase_screen.dart';
import 'reports_screen.dart';
import 'supplier_screen.dart';
import 'user_management_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int selectedIndex = 0;

  late final List<Widget> pages = [
    const DashboardScreen(),
    const MedicinesScreen(),
    const PrescriptionScreen(),
    const PurchaseScreen(),
    const SupplierScreen(),
    const ExpensesScreen(),
    const ReportsScreen(),
  ];

  String get pageTitle {
    switch (selectedIndex) {
      case 0:
        return 'Dashboard';
      case 1:
        return 'Medicine';
      case 2:
        return 'Prescription Sale';
      case 3:
        return 'Purchase';
      case 4:
        return 'Suppliers';
      case 5:
        return 'Expenses';
      case 6:
        return 'Reports';
      default:
        return 'Pharmacy Management';
    }
  }

  Future<void> logout() async {
    AuthService.instance.logout();

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => const LoginScreen(),
      ),
      (route) => false,
    );
  }

  void openUserManagement() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const UserManagementScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text(pageTitle),
      ),
      drawer: Drawer(
        child: SafeArea(
          child: Column(
            children: [
              UserAccountsDrawerHeader(
                accountName: Text(
                  user?.name ?? 'User',
                ),
                accountEmail: Text(
                  '${user?.username ?? ''} • ${user?.role ?? ''}',
                ),
                currentAccountPicture: const CircleAvatar(
                  child: Icon(Icons.person),
                ),
              ),

              drawerItem(
                icon: Icons.dashboard,
                title: 'Dashboard',
                index: 0,
              ),

              drawerItem(
                icon: Icons.medication,
                title: 'Medicine',
                index: 1,
              ),

              drawerItem(
                icon: Icons.receipt_long,
                title: 'Prescription Sale',
                index: 2,
              ),

              drawerItem(
                icon: Icons.inventory_2,
                title: 'Purchase',
                index: 3,
              ),

              drawerItem(
                icon: Icons.business,
                title: 'Suppliers',
                index: 4,
              ),

              drawerItem(
                icon: Icons.money_off,
                title: 'Expenses',
                index: 5,
              ),

              drawerItem(
                icon: Icons.analytics,
                title: 'Reports',
                index: 6,
              ),

              if (user?.isAdmin == true)
                ListTile(
                  leading: const Icon(Icons.people),
                  title: const Text('User Management'),
                  onTap: () {
                    Navigator.pop(context);
                    openUserManagement();
                  },
                ),

              const Spacer(),

              const Divider(),

              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Logout'),
                onTap: logout,
              ),
            ],
          ),
        ),
      ),
      body: IndexedStack(
        index: selectedIndex,
        children: pages,
      ),
    );
  }

  Widget drawerItem({
    required IconData icon,
    required String title,
    required int index,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      selected: selectedIndex == index,
      onTap: () {
        setState(() {
          selectedIndex = index;
        });

        Navigator.pop(context);
      },
    );
  }
}
