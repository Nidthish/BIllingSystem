import 'package:flutter/material.dart';
import '../widgets/sidebar.dart';
import 'new_bills_screen.dart';
import 'product_management_screen.dart';
import 'analysis_screen.dart';
import 'history_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    NewBillsScreen(),
    ProductManagementScreen(),
    AnalysisScreen(),
    HistoryScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1117),
      body: Row(
        children: [
          // Left Sidebar
          Sidebar(
            selectedIndex: _selectedIndex,
            onItemSelected: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
          ),
          // Vertical Divider
          Container(
            width: 1,
            color: const Color(0xFF2A2D3E),
          ),
          // Main Content Area
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.03, 0),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOut,
                    )),
                    child: child,
                  ),
                );
              },
              child: KeyedSubtree(
                key: ValueKey(_selectedIndex),
                child: _screens[_selectedIndex],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
