import 'package:flutter/material.dart';

class Sidebar extends StatefulWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;

  const Sidebar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  @override
  State<Sidebar> createState() => _SidebarState();
}

class _SidebarState extends State<Sidebar> {
  int? _hoveredIndex;

  final List<_NavItem> _items = const [
    _NavItem(
      icon: Icons.receipt_long_rounded,
      label: 'New Bills',
      subtitle: 'Create invoices',
    ),
    _NavItem(
      icon: Icons.inventory_2_rounded,
      label: 'Product Management',
      subtitle: 'Manage products',
    ),
    _NavItem(
      icon: Icons.bar_chart_rounded,
      label: 'Analysis',
      subtitle: 'Reports & insights',
    ),
    _NavItem(
      icon: Icons.history_rounded,
      label: 'History',
      subtitle: 'Past transactions',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 270,
      height: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFF13161F),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF13161F),
            Color(0xFF0F1117),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── App Header ───
          _buildHeader(),

          const SizedBox(height: 8),

          // ─── Divider ───
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    const Color(0xFF2A2D3E),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // ─── Nav Label ───
          Padding(
            padding: const EdgeInsets.only(left: 24, bottom: 8),
            child: Text(
              'NAVIGATION',
              style: TextStyle(
                color: const Color(0xFF4A5073),
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.8,
              ),
            ),
          ),

          // ─── Nav Items ───
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _items.length,
              itemBuilder: (context, index) {
                return _buildNavItem(index);
              },
            ),
          ),

          // ─── Footer ───
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
      child: Row(
        children: [
          // App Icon
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF4F8EF7),
                  Color(0xFF6C63FF),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF4F8EF7).withOpacity(0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.receipt_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          // App Title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'BillPro',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
                Text(
                  'v1.0  •  Enterprise Desktop',
                  style: TextStyle(
                    color: const Color(0xFF5A6080),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index) {
    final item = _items[index];
    final isSelected = widget.selectedIndex == index;
    final isHovered = _hoveredIndex == index;

    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredIndex = index),
      onExit: (_) => setState(() => _hoveredIndex = null),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => widget.onItemSelected(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          margin: const EdgeInsets.symmetric(vertical: 3),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: isSelected
                ? const Color(0xFF4F8EF7).withOpacity(0.15)
                : isHovered
                    ? const Color(0xFFFFFFFF).withOpacity(0.04)
                    : Colors.transparent,
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF4F8EF7).withOpacity(0.4)
                  : Colors.transparent,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              // Selected Indicator + Icon container
              Stack(
                alignment: Alignment.center,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color(0xFF4F8EF7),
                                Color(0xFF6C63FF),
                              ],
                            )
                          : null,
                      color: isSelected
                          ? null
                          : isHovered
                              ? const Color(0xFF2A2D3E)
                              : const Color(0xFF1E2130),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color:
                                    const Color(0xFF4F8EF7).withOpacity(0.35),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ]
                          : null,
                    ),
                    child: Icon(
                      item.icon,
                      size: 20,
                      color: isSelected
                          ? Colors.white
                          : isHovered
                              ? const Color(0xFF8A90B0)
                              : const Color(0xFF5A6080),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 14),
              // Label + Subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.label,
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : isHovered
                                ? const Color(0xFFCDD0E0)
                                : const Color(0xFF8A90B0),
                        fontSize: 13.5,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w500,
                        letterSpacing: 0.1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.subtitle,
                      style: TextStyle(
                        color: isSelected
                            ? const Color(0xFF4F8EF7).withOpacity(0.8)
                            : const Color(0xFF3D4060),
                        fontSize: 10.5,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              // Active arrow
              if (isSelected)
                Icon(
                  Icons.chevron_right_rounded,
                  color: const Color(0xFF4F8EF7),
                  size: 18,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1D27),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF2A2D3E),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF4F8EF7), Color(0xFF6C63FF)],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Center(
              child: Text(
                'A',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Admin',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 12.5,
                  ),
                ),
                Text(
                  'Administrator',
                  style: TextStyle(
                    color: const Color(0xFF5A6080),
                    fontSize: 10.5,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.settings_rounded,
            color: const Color(0xFF4A5073),
            size: 18,
          ),
        ],
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  final String subtitle;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.subtitle,
  });
}
