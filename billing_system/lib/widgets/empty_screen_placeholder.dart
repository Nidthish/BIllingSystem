import 'package:flutter/material.dart';

class EmptyScreenPlaceholder extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color accentColor;

  const EmptyScreenPlaceholder({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: const Color(0xFF0F1117),
      child: Column(
        children: [
          // ─── Top Bar ───
          _buildTopBar(context),

          // ─── Content ───
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Glow Icon
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: accentColor.withOpacity(0.2),
                          blurRadius: 40,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                    child: Icon(
                      icon,
                      size: 46,
                      color: accentColor,
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    subtitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF5A6080),
                      fontSize: 14,
                      height: 1.7,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 40),
                  // Coming Soon Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: accentColor.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: accentColor,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: accentColor.withOpacity(0.6),
                                blurRadius: 6,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Under Development',
                          style: TextStyle(
                            color: accentColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 28),
      decoration: const BoxDecoration(
        color: Color(0xFF13161F),
        border: Border(
          bottom: BorderSide(
            color: Color(0xFF2A2D3E),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Page Title
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
          const Spacer(),
          // Status Pill
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFF1E2130),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF2A2D3E),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: Color(0xFF00C9A7),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 7),
                const Text(
                  'System Ready',
                  style: TextStyle(
                    color: Color(0xFF8A90B0),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
