import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/sales_analysis_provider.dart';
import '../../providers/settings_provider.dart';
import '../../utils/reports_pdf_generator.dart';
import '../../utils/reports_excel_generator.dart';
import 'widgets/report_filter_panel.dart';
import 'widgets/analysis_table.dart';
import 'widgets/report_summary_cards.dart';
import 'widgets/report_loading.dart';

class SalesAnalysisTab extends StatefulWidget {
  const SalesAnalysisTab({super.key});

  @override
  State<SalesAnalysisTab> createState() => _SalesAnalysisTabState();
}

class _SalesAnalysisTabState extends State<SalesAnalysisTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SalesAnalysisProvider>().loadData();
    });
  }

  Future<void> _printReport() async {
    final provider = context.read<SalesAnalysisProvider>();
    final settings = context.read<SettingsProvider>().settings;
    if (settings == null) return;
    try {
      await ReportsPdfGenerator.printSalesAnalysis(
        rows: provider.analysisRows,
        summary: provider.summary,
        filter: provider.filter,
        settings: settings,
        generatedBy: 'Admin',
      );
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Print error: $e')));
    }
  }

  Future<void> _exportPdf() async {
    final provider = context.read<SalesAnalysisProvider>();
    final settings = context.read<SettingsProvider>().settings;
    if (settings == null) return;
    try {
      final path = await ReportsPdfGenerator.exportSalesAnalysisPdf(
        rows: provider.analysisRows,
        summary: provider.summary,
        filter: provider.filter,
        settings: settings,
        generatedBy: 'Admin',
      );
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('PDF saved: $path')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _exportExcel() async {
    final provider = context.read<SalesAnalysisProvider>();
    try {
      final path = await ReportsExcelGenerator.exportAnalysisToExcel(
        rows: provider.analysisRows,
        filter: provider.filter,
        summary: provider.summary,
      );
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Excel saved: $path')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _showSaveTemplateDialog() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Save Report Template'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Template Name',
            hintText: 'e.g. Monthly GST Report',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              if (ctrl.text.trim().isEmpty) return;
              await context.read<SalesAnalysisProvider>().saveTemplate(ctrl.text.trim());
              if (ctx.mounted) Navigator.pop(ctx);
              if (mounted) ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Template "${ctrl.text.trim()}" saved!')),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showLoadTemplateDialog() {
    final provider = context.read<SalesAnalysisProvider>();
    if (provider.savedTemplates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No saved templates yet.')),
      );
      return;
    }
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Load Report Template'),
        content: SizedBox(
          width: 400,
          child: ListView(
            shrinkWrap: true,
            children: provider.savedTemplates.map((t) => ListTile(
              leading: const Icon(Icons.bookmark_outline),
              title: Text(t.name),
              subtitle: Text('Saved ${t.savedAt.day}/${t.savedAt.month}/${t.savedAt.year}'),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () {
                  provider.deleteTemplate(t.name);
                  Navigator.pop(ctx);
                },
              ),
              onTap: () {
                provider.loadTemplate(t);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Loaded: ${t.name}')));
              },
            )).toList(),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SalesAnalysisProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) return const ReportLoading();

        return Row(
          children: [
            // ── Left Filter Panel ──────────────────────────
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: provider.filterPanelExpanded ? 270 : 0,
              clipBehavior: Clip.antiAlias,
              decoration: const BoxDecoration(),
              child: provider.filterPanelExpanded
                  ? ReportFilterPanel(
                      filter: provider.pendingFilter,
                      categories: provider.allCategories,
                      products: provider.allProducts,
                      customers: provider.allCustomers,
                      onFilterChanged: provider.updatePendingFilter,
                    )
                  : const SizedBox.shrink(),
            ),

            // ── Main Content Area ──────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top action bar
                  _AnalysisToolbar(
                    provider: provider,
                    onApply: provider.applyFilters,
                    onClear: provider.clearFilters,
                    onRefresh: provider.refresh,
                    onPrint: _printReport,
                    onExportPdf: _exportPdf,
                    onExportExcel: _exportExcel,
                    onSaveTemplate: _showSaveTemplateDialog,
                    onLoadTemplate: _showLoadTemplateDialog,
                  ),
                  const SizedBox(height: 12),

                  // KPI summary cards
                  ReportSummaryCards.forAnalysis(provider.summary),
                  const SizedBox(height: 12),

                  // Results row count + pagination
                  _AnalysisTableToolbar(provider: provider),
                  const SizedBox(height: 8),

                  // Analysis table
                  Expanded(
                    child: provider.isApplying
                        ? const ReportLoading()
                        : AnalysisTable(
                            rows: provider.pagedRows,
                            summary: provider.summary,
                            options: provider.filter.analysisOptions,
                            groupBy: provider.filter.groupBy,
                            onClearFilters: provider.clearFilters,
                          ),
                  ),

                  // Pagination
                  if (provider.totalPages > 1)
                    _AnalysisPagination(provider: provider),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

// ─────────────────────────────────────────────
// Analysis Toolbar
// ─────────────────────────────────────────────
class _AnalysisToolbar extends StatelessWidget {
  final SalesAnalysisProvider provider;
  final Future<void> Function() onApply;
  final VoidCallback onClear;
  final Future<void> Function() onRefresh;
  final VoidCallback onPrint;
  final VoidCallback onExportPdf;
  final VoidCallback onExportExcel;
  final VoidCallback onSaveTemplate;
  final VoidCallback onLoadTemplate;

  const _AnalysisToolbar({
    required this.provider,
    required this.onApply,
    required this.onClear,
    required this.onRefresh,
    required this.onPrint,
    required this.onExportPdf,
    required this.onExportExcel,
    required this.onSaveTemplate,
    required this.onLoadTemplate,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2D) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade200),
      ),
      child: Row(
        children: [
          // Toggle panel
          Tooltip(
            message: provider.filterPanelExpanded ? 'Collapse Filters' : 'Expand Filters',
            child: IconButton(
              icon: Icon(
                provider.filterPanelExpanded ? Icons.menu_open : Icons.menu,
                color: theme.colorScheme.primary,
              ),
              onPressed: provider.toggleFilterPanel,
            ),
          ),
          const SizedBox(width: 4),
          // Active filters badge
          if (provider.filter.hasActiveFilters)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(children: [
                Icon(Icons.filter_alt, size: 12, color: theme.colorScheme.primary),
                const SizedBox(width: 4),
                Text('Filters Active', style: TextStyle(fontSize: 11, color: theme.colorScheme.primary, fontWeight: FontWeight.w600)),
              ]),
            ),
          const SizedBox(width: 8),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              reverse: true,
              child: Row(
                children: [
                  _ToolbarBtn(icon: Icons.bookmark_border, label: 'Save Template', onTap: onSaveTemplate, outline: true),
                  const SizedBox(width: 6),
                  _ToolbarBtn(icon: Icons.bookmarks_outlined, label: 'Templates', onTap: onLoadTemplate, outline: true),
                  const SizedBox(width: 10),
                  _ToolbarBtn(icon: Icons.filter_list_off, label: 'Clear', onTap: onClear, outline: true),
                  const SizedBox(width: 6),
                  _ToolbarBtn(icon: Icons.refresh, label: 'Refresh', onTap: () async => await onRefresh(), outline: true),
                  const SizedBox(width: 10),
                  _ToolbarBtn(icon: Icons.print, label: 'Print', onTap: onPrint, color: theme.colorScheme.primary),
                  const SizedBox(width: 6),
                  _ToolbarBtn(icon: Icons.picture_as_pdf, label: 'PDF', onTap: onExportPdf, color: Colors.red.shade700),
                  const SizedBox(width: 6),
                  _ToolbarBtn(icon: Icons.table_chart, label: 'Excel', onTap: onExportExcel, color: Colors.green.shade700),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Primary Apply button
          FilledButton.icon(
            icon: provider.isApplying
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.play_arrow, size: 18),
            label: Text(provider.isApplying ? 'Applying...' : 'Apply Filters',
              style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
            onPressed: provider.isApplying ? null : () => onApply(),
            style: FilledButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }
}

class _ToolbarBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool outline;
  final Color? color;

  const _ToolbarBtn({
    required this.icon,
    required this.label,
    required this.onTap,
    this.outline = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final resolvedColor = color ?? theme.colorScheme.primary;

    if (outline) {
      return OutlinedButton.icon(
        icon: Icon(icon, size: 15, color: isDark ? const Color(0xFF34D399) : const Color(0xFF00875A)),
        label: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          side: BorderSide(color: isDark ? const Color(0xFF34D399) : const Color(0xFF00875A)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          backgroundColor: isDark ? const Color(0xFF13281E) : Colors.transparent,
        ),
      );
    }
    return ElevatedButton.icon(
      icon: Icon(icon, size: 15, color: Colors.white),
      label: Text(
        label,
        style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white),
      ),
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: resolvedColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: 1,
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Table toolbar
// ─────────────────────────────────────────────
class _AnalysisTableToolbar extends StatelessWidget {
  final SalesAnalysisProvider provider;
  const _AnalysisTableToolbar({required this.provider});

  @override
  Widget build(BuildContext context) {
    final dateRange = provider.filter.effectiveDateRange;
    final fmt = DateFormat('dd MMM yy');
    return Row(
      children: [
        Text('${provider.analysisRows.length} rows  •  ${fmt.format(dateRange.$1)} – ${fmt.format(dateRange.$2)}',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
        const Spacer(),
        if (provider.totalPages > 1)
          Text('Page ${provider.currentPage + 1} / ${provider.totalPages}',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// Analysis pagination
// ─────────────────────────────────────────────
class _AnalysisPagination extends StatelessWidget {
  final SalesAnalysisProvider provider;
  const _AnalysisPagination({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(icon: const Icon(Icons.first_page), onPressed: provider.currentPage > 0 ? () => provider.goToPage(0) : null),
          IconButton(icon: const Icon(Icons.chevron_left), onPressed: provider.currentPage > 0 ? provider.prevPage : null),
          Text('${provider.currentPage + 1} / ${provider.totalPages}',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          IconButton(icon: const Icon(Icons.chevron_right), onPressed: provider.currentPage < provider.totalPages - 1 ? provider.nextPage : null),
          IconButton(icon: const Icon(Icons.last_page), onPressed: provider.currentPage < provider.totalPages - 1 ? () => provider.goToPage(provider.totalPages - 1) : null),
        ],
      ),
    );
  }
}
