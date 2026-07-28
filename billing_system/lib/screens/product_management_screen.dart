import 'package:flutter/material.dart';
import '../widgets/empty_screen_placeholder.dart';

class ProductManagementScreen extends StatelessWidget {
  const ProductManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return EmptyScreenPlaceholder(
      icon: Icons.inventory_2_rounded,
      title: 'Product Management',
      subtitle: 'Add, edit, and organize your products & catalog.\nThis section is coming soon.',
      accentColor: const Color(0xFF6C63FF),
    );
  }
}
