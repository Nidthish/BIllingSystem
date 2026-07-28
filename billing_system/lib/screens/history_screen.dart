import 'package:flutter/material.dart';
import '../widgets/empty_screen_placeholder.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return EmptyScreenPlaceholder(
      icon: Icons.history_rounded,
      title: 'History',
      subtitle: 'View all past transactions and billing records.\nThis section is coming soon.',
      accentColor: const Color(0xFFFF6B6B),
    );
  }
}
