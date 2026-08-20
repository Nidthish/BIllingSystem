import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'invoice_reports_tab.dart';
import 'sales_analysis_tab.dart';

/// Root screen for the Reports module.
/// Hosts two tabs: Invoice Reports and Sales Analysis.
class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF0B1912) : const Color(0xFFF3F4F6),
        appBar: AppBar(
          backgroundColor: isDark ? const Color(0xFF13281E) : Colors.white,
          elevation: 0,
          titleSpacing: 24,
          title: Row(
            children: [
              Image.asset(
                'assets/images/sk_logo.png',
                height: 32,
                width: 32,
                fit: BoxFit.contain,
                errorBuilder: (ctx, err, stack) => Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF00875A), Color(0xFF10B981)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.bar_chart, color: Colors.white, size: 20),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Reports & Analytics',
                style: GoogleFonts.outfit(
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF064E3B),
                ),
              ),
            ],
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(48),
            child: Container(
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: isDark ? Colors.white12 : Colors.grey.shade200,
                    width: 1,
                  ),
                ),
              ),
              child: TabBar(
                isScrollable: false,
                labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 14),
                unselectedLabelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 14),
                labelColor: const Color(0xFF00875A),
                unselectedLabelColor: isDark ? Colors.white54 : Colors.grey.shade600,
                indicatorColor: const Color(0xFF00875A),
                indicatorWeight: 3,
                indicatorSize: TabBarIndicatorSize.label,
                overlayColor: WidgetStateProperty.all(Colors.transparent),
                dividerColor: Colors.transparent,
                splashFactory: NoSplash.splashFactory,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                tabs: const [
                  Tab(
                    icon: Icon(Icons.receipt_long_outlined, size: 18),
                    text: 'Invoice Reports',
                    iconMargin: EdgeInsets.only(bottom: 2),
                  ),
                  Tab(
                    icon: Icon(Icons.analytics_outlined, size: 18),
                    text: 'Sales Analysis',
                    iconMargin: EdgeInsets.only(bottom: 2),
                  ),
                ],
              ),
            ),
          ),
        ),
        body: const Padding(
          padding: EdgeInsets.all(20),
          child: TabBarView(
            children: [
              InvoiceReportsTab(),
              SalesAnalysisTab(),
            ],
          ),
        ),
      ),
    );
  }
}
