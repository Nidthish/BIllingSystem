import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Professional ERP-style empty state widget displayed when no report data is found.
class ReportEmptyState extends StatelessWidget {
  final VoidCallback? onClearFilters;
  final String title;
  final String subtitle;

  const ReportEmptyState({
    super.key,
    this.onClearFilters,
    this.title = 'No Records Found',
    this.subtitle = 'Try adjusting your filters or expanding the date range.',
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.assessment_outlined,
              size: 56,
              color: theme.colorScheme.primary.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white38 : Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),
          if (onClearFilters != null)
            FilledButton.icon(
              onPressed: onClearFilters,
              icon: const Icon(Icons.filter_list_off),
              label: const Text('Clear All Filters'),
              style: FilledButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
        ],
      ),
    );
  }
}
