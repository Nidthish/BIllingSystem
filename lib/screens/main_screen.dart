import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../providers/theme_provider.dart';
import 'dashboard/dashboard_screen.dart';
import 'billing/billing_screen.dart';
import 'products/products_screen.dart';
import 'categories/categories_screen.dart';
import 'customers/customers_screen.dart';
import 'reports/reports_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const DashboardScreen(),
    const BillingScreen(),
    const ProductsScreen(),
    const CategoriesScreen(),
    const CustomersScreen(),
    const ReportsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>().settings;
    final themeProvider = context.watch<ThemeProvider>();

    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          Material(
            color: Theme.of(context).cardColor,
            child: SizedBox(
              width: 250,
              child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF064E3B), Color(0xFF00875A)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'SmartBill',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        settings?.shopName ?? 'SK Masala',
                        style: const TextStyle(
                          color: Color(0xE6FFFFFF),
                          fontSize: 13.5,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    children: [
                      _buildNavItem(0, Icons.dashboard_outlined, 'Dashboard'),
                      _buildNavItem(1, Icons.receipt_long_outlined, 'Billing'),
                      _buildNavItem(2, Icons.inventory_2_outlined, 'Products'),
                      _buildNavItem(3, Icons.category_outlined, 'Categories'),
                      _buildNavItem(4, Icons.people_outline, 'Customers'),
                      _buildNavItem(5, Icons.bar_chart_outlined, 'Reports'),
                    ],
                  ),
                ),
                // Theme Toggle Switch (Night Mode / Light Mode)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: Colors.grey.withValues(alpha: 0.2))),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                            color: themeProvider.isDarkMode ? const Color(0xFF34D399) : const Color(0xFF00875A),
                            size: 22,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            themeProvider.isDarkMode ? 'Night Mode' : 'Light Mode',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ],
                      ),
                      Switch(
                        value: themeProvider.isDarkMode,
                        activeTrackColor: const Color(0xFF34D399),
                        onChanged: (val) => themeProvider.toggleTheme(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          ),
          // Main Content
          Expanded(
            child: _screens[_selectedIndex],
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String title) {
    final isSelected = _selectedIndex == index;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryGreen = const Color(0xFF00875A);
    final mintGreen = const Color(0xFF34D399);

    return ListTile(
      leading: Icon(
        icon,
        color: isSelected
            ? (isDark ? mintGreen : primaryGreen)
            : (isDark ? Colors.white60 : Colors.grey.shade600),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected
              ? (isDark ? mintGreen : primaryGreen)
              : (isDark ? const Color(0xE6FFFFFF) : const Color(0xFF0F172A)),
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          fontSize: 14,
        ),
      ),
      selected: isSelected,
      selectedTileColor: primaryGreen.withValues(alpha: 0.12),
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
      },
    );
  }
}
