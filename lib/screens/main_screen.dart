import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
  bool _isSidebarVisible = true;

  final List<Widget> _screens = [
    const DashboardScreen(),
    const BillingScreen(),
    const ProductsScreen(),
    const CategoriesScreen(),
    const CustomersScreen(),
    const ReportsScreen(),
  ];

  void _toggleSidebar() {
    setState(() {
      _isSidebarVisible = !_isSidebarVisible;
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          Row(
            children: [
              // Collapsible Sidebar
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                width: _isSidebarVisible ? 195 : 0,
                child: ClipRect(
                  child: OverflowBox(
                    minWidth: 195,
                    maxWidth: 195,
                    alignment: Alignment.topLeft,
                    child: Material(
                      color: Theme.of(context).cardColor,
                      child: Column(
                        children: [
                          // Sidebar Header with Logo and Toggle Button
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                            width: double.infinity,
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color(0xFF064E3B), Color(0xFF00875A)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Image.asset(
                                    'assets/images/sk_logo.png',
                                    height: 36,
                                    width: 36,
                                    fit: BoxFit.contain,
                                    errorBuilder: (ctx, err, stack) => const Icon(Icons.store, color: Color(0xFF00875A), size: 28),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: const [
                                      Text(
                                        'MS TRADERS',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.5,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      SizedBox(height: 2),
                                      Text(
                                        'SmartBill',
                                        style: TextStyle(
                                          color: Color(0xE6FFFFFF),
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500,
                                          letterSpacing: 0.3,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.menu_open, color: Colors.white, size: 22),
                                  tooltip: 'Hide Navigation Menu',
                                  visualDensity: VisualDensity.compact,
                                  onPressed: _toggleSidebar,
                                ),
                              ],
                            ),
                          ),
                          // Nav Items
                          Expanded(
                            child: ListView(
                              padding: const EdgeInsets.symmetric(vertical: 12),
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
                          // Theme Toggle Switch
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              border: Border(top: BorderSide(color: Colors.grey.withValues(alpha: 0.2))),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Row(
                                    children: [
                                      Icon(
                                        themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                                        color: themeProvider.isDarkMode ? const Color(0xFF34D399) : const Color(0xFF00875A),
                                        size: 18,
                                      ),
                                      const SizedBox(width: 6),
                                      Flexible(
                                        child: Text(
                                          themeProvider.isDarkMode ? 'Night' : 'Light',
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
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
                ),
              ),
              // Main Screen Content
              Expanded(
                child: _screens[_selectedIndex],
              ),
            ],
          ),
          // Floating Toggle Menu Button when Sidebar is Hidden
          if (!_isSidebarVisible)
            Positioned(
              top: 10,
              left: 10,
              child: Material(
                elevation: 6,
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: const BorderSide(color: Color(0xFF00875A), width: 1.5),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: _toggleSidebar,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.menu, color: Color(0xFF00875A), size: 20),
                        SizedBox(width: 6),
                        Text(
                          'Menu',
                          style: TextStyle(
                            color: Color(0xFF00875A),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
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
