import 'package:flutter/material.dart';
import '../widgets/empty_screen_placeholder.dart';

class AnalysisScreen extends StatelessWidget {
  const AnalysisScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return EmptyScreenPlaceholder(
      icon: Icons.bar_chart_rounded,
      title: 'Analysis',
      subtitle: 'Sales reports, insights and business analytics.\nThis section is coming soon.',
      accentColor: const Color(0xFF00C9A7),
    );
  }
}
