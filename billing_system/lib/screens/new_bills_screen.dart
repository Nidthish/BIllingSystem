import 'package:flutter/material.dart';
import '../widgets/empty_screen_placeholder.dart';

class NewBillsScreen extends StatelessWidget {
  const NewBillsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return EmptyScreenPlaceholder(
      icon: Icons.receipt_long_rounded,
      title: 'New Bills',
      subtitle: 'Create and manage your invoices here.\nThis section is coming soon.',
      accentColor: const Color(0xFF4F8EF7),
    );
  }
}
