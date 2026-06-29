import 'package:flutter/material.dart';
import 'package:flutter_pos/core/constants/app_strings.dart';
import 'package:flutter_pos/features/reports/presentation/pages/dashboard_page.dart';
import 'package:flutter_pos/features/products/presentation/pages/product_list_page.dart';
import 'package:flutter_pos/features/cart/presentation/pages/cashier_page.dart';
import 'package:flutter_pos/features/transactions/presentation/pages/transaction_list_page.dart';
import 'package:flutter_pos/features/settings/presentation/pages/more_page.dart';

class MainNavigationPage extends StatefulWidget {
  final String userName;
  final String userRole;

  const MainNavigationPage({
    super.key,
    required this.userName,
    required this.userRole,
  });

  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> {
  int _currentIndex = 2; // Default to Kasir (Cashier)

  final List<Widget> _pages = const [
    DashboardPage(),
    ProductListPage(),
    CashierPage(),
    TransactionListPage(),
    MorePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: AppStrings.dashboard,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2_outlined),
            activeIcon: Icon(Icons.inventory_2),
            label: AppStrings.products,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.point_of_sale_outlined),
            activeIcon: Icon(Icons.point_of_sale),
            label: AppStrings.cashier,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long_outlined),
            activeIcon: Icon(Icons.receipt_long),
            label: AppStrings.transactions,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.more_horiz_outlined),
            activeIcon: Icon(Icons.more_horiz),
            label: AppStrings.more,
          ),
        ],
      ),
    );
  }
}
