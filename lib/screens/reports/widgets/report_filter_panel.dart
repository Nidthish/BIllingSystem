import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../models/report_filter_model.dart';
import '../../../models/category.dart';
import '../../../models/product.dart';
import '../../../models/customer.dart';

/// Collapsible left-side ERP filter panel for Sales Analysis.
class ReportFilterPanel extends StatefulWidget {
  final ReportFilterModel filter;
  final List<Category> categories;
  final List<Product> products;
  final List<Customer> customers;
  final ValueChanged<ReportFilterModel> onFilterChanged;

  const ReportFilterPanel({
    super.key,
    required this.filter,
    required this.categories,
    required this.products,
    required this.customers,
    required this.onFilterChanged,
  });

  @override
  State<ReportFilterPanel> createState() => _ReportFilterPanelState();
}

class _ReportFilterPanelState extends State<ReportFilterPanel> {
  late ReportFilterModel _f;

  @override
  void initState() {
    super.initState();
    _f = widget.filter;
  }

  @override
  void didUpdateWidget(ReportFilterPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.filter != widget.filter) {
      setState(() => _f = widget.filter);
    }
  }

  void _update(ReportFilterModel updated) {
    setState(() => _f = updated);
    widget.onFilterChanged(updated);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2D) : Colors.white,
        border: Border(right: BorderSide(color: isDark ? Colors.white12 : Colors.grey.shade200)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _PanelTitle(label: 'Report Filters', icon: Icons.tune),
            const SizedBox(height: 12),

            // ── DATE ─────────────────────────────────────
            _FilterSection(
              title: 'Date Period',
              icon: Icons.date_range_outlined,
              child: Column(
                children: [
                  ...DatePreset.values.map((p) => _RadioTile(
                    label: p.label,
                    value: p,
                    groupValue: _f.datePreset,
                    onChanged: (v) => _update(_f.copyWith(datePreset: v, startDate: null, endDate: null)),
                  )),
                  if (_f.datePreset == DatePreset.custom) ...[
                    const SizedBox(height: 8),
                    _DateRangePicker(
                      startDate: _f.startDate,
                      endDate: _f.endDate,
                      onChanged: (s, e) => _update(_f.copyWith(datePreset: DatePreset.custom, startDate: s, endDate: e)),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 8),

            // ── GST CLASSIFICATION ───────────────────────
            _FilterSection(
              title: 'GST Classification',
              icon: Icons.receipt_long_outlined,
              child: _DropdownFilter<InvoiceGstFilter>(
                label: 'GST Filter',
                value: _f.invoiceGstFilter,
                items: const [
                  DropdownMenuItem(
                    value: InvoiceGstFilter.all,
                    child: Text('All Bills / Products', overflow: TextOverflow.ellipsis),
                  ),
                  DropdownMenuItem(
                    value: InvoiceGstFilter.gstBills,
                    child: Text('GST Bills (With GST)', overflow: TextOverflow.ellipsis),
                  ),
                  DropdownMenuItem(
                    value: InvoiceGstFilter.nonGstBills,
                    child: Text('Non-GST Bills (Without GST)', overflow: TextOverflow.ellipsis),
                  ),
                ],
                onChanged: (v) {
                  final filterVal = v ?? InvoiceGstFilter.all;
                  ProductGstFilter pGst = ProductGstFilter.all;
                  if (filterVal == InvoiceGstFilter.gstBills) pGst = ProductGstFilter.withGst;
                  if (filterVal == InvoiceGstFilter.nonGstBills) pGst = ProductGstFilter.withoutGst;
                  _update(_f.copyWith(
                    invoiceGstFilter: filterVal,
                    productGstFilter: pGst,
                  ));
                },
              ),
            ),
            const SizedBox(height: 8),

            // ── PRODUCT ───────────────────────────────────
            _FilterSection(
              title: 'Product',
              icon: Icons.inventory_2_outlined,
              child: Column(
                children: [
                  _DropdownFilter<int?>(
                    label: 'Category',
                    value: _f.categoryId,
                    items: [
                      const DropdownMenuItem(value: null, child: Text('All Categories')),
                      ...widget.categories.map((c) => DropdownMenuItem(
                        value: c.categoryId,
                        child: Text(c.categoryName, overflow: TextOverflow.ellipsis),
                      )),
                    ],
                    onChanged: (v) => _update(v == null
                        ? _f.copyWith(clearCategoryId: true, clearProductId: true)
                        : _f.copyWith(
                            categoryId: v,
                            categoryName: widget.categories.firstWhere((c) => c.categoryId == v).categoryName,
                            clearProductId: true,
                          )),
                  ),
                  const SizedBox(height: 6),
                  _DropdownFilter<int?>(
                    label: 'Product',
                    value: _f.productId,
                    items: [
                      const DropdownMenuItem(value: null, child: Text('All Products')),
                      ...((_f.categoryId != null
                          ? widget.products.where((p) => p.categoryId == _f.categoryId)
                          : widget.products.cast<Product>())
                        .map((p) => DropdownMenuItem(
                          value: p.productId,
                          child: Text(p.productName, overflow: TextOverflow.ellipsis),
                        ))),
                    ],
                    onChanged: (v) => _update(v == null
                        ? _f.copyWith(clearProductId: true)
                        : _f.copyWith(
                            productId: v,
                            productName: widget.products.firstWhere((p) => p.productId == v).productName,
                          )),
                  ),
                  const SizedBox(height: 6),
                  // Brand — Coming Soon
                  _ComingSoonField(label: 'Brand'),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // ── CUSTOMER ──────────────────────────────────
            _FilterSection(
              title: 'Customer',
              icon: Icons.people_outline,
              child: Column(
                children: [
                  _TextField(
                    label: 'Customer Name',
                    value: _f.customerName,
                    onChanged: (v) => _update(_f.copyWith(customerName: v)),
                  ),
                  const SizedBox(height: 6),
                  _TextField(
                    label: 'City / Area',
                    value: _f.city,
                    onChanged: (v) => _update(_f.copyWith(city: v)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // ── PAYMENT ───────────────────────────────────
            _FilterSection(
              title: 'Payment Method',
              icon: Icons.payment_outlined,
              child: Column(
                children: ['Cash', 'UPI', 'Card', 'Credit'].map((method) {
                  final selected = _f.paymentMethods.contains(method);
                  return _CheckboxTile(
                    label: method,
                    value: selected,
                    onChanged: (v) {
                      final methods = Set<String>.from(_f.paymentMethods);
                      v == true ? methods.add(method) : methods.remove(method);
                      _update(_f.copyWith(paymentMethods: methods));
                    },
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 8),

            // ── ANALYSIS OPTIONS ──────────────────────────
            _FilterSection(
              title: 'Analysis Columns',
              icon: Icons.table_chart_outlined,
              child: Column(
                children: [
                  _CheckboxTile(label: 'Quantity Sold', value: _f.analysisOptions.showQtySold,
                    onChanged: (v) => _update(_f.copyWith(analysisOptions: _f.analysisOptions.copyWith(showQtySold: v)))),
                  _CheckboxTile(label: 'Sales Amount', value: _f.analysisOptions.showSaleAmount,
                    onChanged: (v) => _update(_f.copyWith(analysisOptions: _f.analysisOptions.copyWith(showSaleAmount: v)))),
                  _CheckboxTile(label: 'GST Amount', value: _f.analysisOptions.showGst,
                    onChanged: (v) => _update(_f.copyWith(analysisOptions: _f.analysisOptions.copyWith(showGst: v)))),
                  _CheckboxTile(label: 'Discount', value: _f.analysisOptions.showDiscount,
                    onChanged: (v) => _update(_f.copyWith(analysisOptions: _f.analysisOptions.copyWith(showDiscount: v)))),
                  _CheckboxTile(label: 'Profit', value: _f.analysisOptions.showProfit,
                    onChanged: (v) => _update(_f.copyWith(analysisOptions: _f.analysisOptions.copyWith(showProfit: v)))),
                  _CheckboxTile(label: 'Purchase Cost', value: _f.analysisOptions.showPurchaseCost,
                    onChanged: (v) => _update(_f.copyWith(analysisOptions: _f.analysisOptions.copyWith(showPurchaseCost: v)))),
                  _CheckboxTile(label: 'Final Amount', value: _f.analysisOptions.showFinalAmount,
                    onChanged: (v) => _update(_f.copyWith(analysisOptions: _f.analysisOptions.copyWith(showFinalAmount: v)))),
                  _CheckboxTile(label: 'Avg Selling Price', value: _f.analysisOptions.showAvgSellingPrice,
                    onChanged: (v) => _update(_f.copyWith(analysisOptions: _f.analysisOptions.copyWith(showAvgSellingPrice: v)))),
                  _CheckboxTile(label: 'Avg Profit', value: _f.analysisOptions.showAvgProfit,
                    onChanged: (v) => _update(_f.copyWith(analysisOptions: _f.analysisOptions.copyWith(showAvgProfit: v)))),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // ── GROUP BY ──────────────────────────────────
            _FilterSection(
              title: 'Group By',
              icon: Icons.group_work_outlined,
              child: _DropdownFilter<GroupBy>(
                label: 'Group results by',
                value: _f.groupBy,
                items: GroupBy.values.map((g) => DropdownMenuItem(value: g, child: Text(g.label))).toList(),
                onChanged: (v) => _update(_f.copyWith(groupBy: v ?? GroupBy.product)),
              ),
            ),
            const SizedBox(height: 8),

            // ── SORT ──────────────────────────────────────
            _FilterSection(
              title: 'Sorting',
              icon: Icons.sort_outlined,
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: _DropdownFilter<SortField>(
                        label: 'Primary Sort',
                        value: _f.primarySortField,
                        items: SortField.values.map((s) => DropdownMenuItem(value: s, child: Text(s.label, overflow: TextOverflow.ellipsis))).toList(),
                        onChanged: (v) => _update(_f.copyWith(primarySortField: v ?? SortField.saleAmount)),
                      )),
                      const SizedBox(width: 6),
                      _SortDirButton(
                        ascending: _f.primarySortAsc,
                        onToggle: () => _update(_f.copyWith(primarySortAsc: !_f.primarySortAsc)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(child: _DropdownFilter<SortField>(
                        label: 'Secondary Sort',
                        value: _f.secondarySortField,
                        items: SortField.values.map((s) => DropdownMenuItem(value: s, child: Text(s.label, overflow: TextOverflow.ellipsis))).toList(),
                        onChanged: (v) => _update(_f.copyWith(secondarySortField: v ?? SortField.none)),
                      )),
                      const SizedBox(width: 6),
                      _SortDirButton(
                        ascending: _f.secondarySortAsc,
                        onToggle: () => _update(_f.copyWith(secondarySortAsc: !_f.secondarySortAsc)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Panel title
// ─────────────────────────────────────────────
class _PanelTitle extends StatelessWidget {
  final String label;
  final IconData icon;
  const _PanelTitle({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1C382B) : const Color(0xFFDCFCE7),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: primary),
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : const Color(0xFF064E3B),
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// Collapsible filter section
// ─────────────────────────────────────────────
class _FilterSection extends StatefulWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _FilterSection({required this.title, required this.icon, required this.child});

  @override
  State<_FilterSection> createState() => _FilterSectionState();
}

class _FilterSectionState extends State<_FilterSection> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFD1E7DD)),
        borderRadius: BorderRadius.circular(10),
        color: isDark ? const Color(0xFF162D22) : const Color(0xFFF0FDF4),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Icon(widget.icon, size: 18, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700,
                        fontSize: 13.5,
                        color: isDark ? Colors.white : const Color(0xFF0F2E1B),
                      ),
                    ),
                  ),
                  Icon(_expanded ? Icons.expand_less : Icons.expand_more, size: 20, color: theme.colorScheme.primary),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            child: _expanded
                ? Padding(padding: const EdgeInsets.fromLTRB(12, 0, 12, 12), child: widget.child)
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Dropdown filter
// ─────────────────────────────────────────────
class _DropdownFilter<T> extends StatelessWidget {
  final String label;
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  const _DropdownFilter({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return DropdownButtonFormField<T>(
      value: value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.inter(
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white70 : const Color(0xFF334155),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        isDense: true,
      ),
      items: items,
      onChanged: onChanged,
      style: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: isDark ? Colors.white : const Color(0xFF0F172A),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Text field filter
// ─────────────────────────────────────────────
class _TextField extends StatelessWidget {
  final String label;
  final String value;
  final ValueChanged<String> onChanged;

  const _TextField({required this.label, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextFormField(
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.inter(
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white70 : const Color(0xFF334155),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        isDense: true,
      ),
      style: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: isDark ? Colors.white : const Color(0xFF0F172A),
      ),
      onChanged: onChanged,
    );
  }
}

// ─────────────────────────────────────────────
// Checkbox tile
// ─────────────────────────────────────────────
class _CheckboxTile extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool?> onChanged;

  const _CheckboxTile({required this.label, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      height: 34,
      child: Row(
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: Checkbox(
              value: value,
              onChanged: onChanged,
              activeColor: Theme.of(context).colorScheme.primary,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: value ? FontWeight.w700 : FontWeight.w500,
                color: value
                    ? (isDark ? const Color(0xFF34D399) : const Color(0xFF00875A))
                    : (isDark ? Colors.white : const Color(0xFF0F172A)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Radio tile
// ─────────────────────────────────────────────
class _RadioTile<T> extends StatelessWidget {
  final String label;
  final T value;
  final T groupValue;
  final ValueChanged<T> onChanged;

  const _RadioTile({
    required this.label,
    required this.value,
    required this.groupValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSelected = value == groupValue;

    return SizedBox(
      height: 32,
      child: Row(
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: Radio<T>(
              value: value,
              groupValue: groupValue,
              onChanged: (v) { if (v != null) onChanged(v); },
              activeColor: Theme.of(context).colorScheme.primary,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected
                    ? (isDark ? const Color(0xFF34D399) : const Color(0xFF00875A))
                    : (isDark ? Colors.white : const Color(0xFF0F172A)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Date range picker
// ─────────────────────────────────────────────
class _DateRangePicker extends StatelessWidget {
  final DateTime? startDate;
  final DateTime? endDate;
  final void Function(DateTime?, DateTime?) onChanged;

  const _DateRangePicker({
    required this.startDate,
    required this.endDate,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              side: BorderSide(color: isDark ? Colors.white24 : const Color(0xFF00875A)),
            ),
            icon: const Icon(Icons.calendar_today, size: 14, color: Color(0xFF00875A)),
            label: Text(
              startDate != null ? DateFormat('dd/MM/yy').format(startDate!) : 'From',
              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            onPressed: () async {
              final d = await showDatePicker(
                context: context,
                initialDate: startDate ?? DateTime.now(),
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
              );
              if (d != null) onChanged(d, endDate);
            },
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              side: BorderSide(color: isDark ? Colors.white24 : const Color(0xFF00875A)),
            ),
            icon: const Icon(Icons.calendar_today, size: 14, color: Color(0xFF00875A)),
            label: Text(
              endDate != null ? DateFormat('dd/MM/yy').format(endDate!) : 'To',
              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            onPressed: () async {
              final d = await showDatePicker(
                context: context,
                initialDate: endDate ?? DateTime.now(),
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
              );
              if (d != null) onChanged(startDate, d);
            },
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// Coming-soon disabled field
// ─────────────────────────────────────────────
class _ComingSoonField extends StatelessWidget {
  final String label;
  const _ComingSoonField({required this.label});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.5,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
          color: Colors.grey.shade100,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                '$label (Coming Soon)',
                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.grey.shade700),
              ),
            ),
            const Icon(Icons.lock_outline, size: 14, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Sort direction toggle
// ─────────────────────────────────────────────
class _SortDirButton extends StatelessWidget {
  final bool ascending;
  final VoidCallback onToggle;

  const _SortDirButton({required this.ascending, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: ascending ? 'Ascending' : 'Descending',
      child: InkWell(
        onTap: onToggle,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFF00875A)),
            borderRadius: BorderRadius.circular(6),
            color: const Color(0xFFF0FDF4),
          ),
          child: Icon(
            ascending ? Icons.arrow_upward : Icons.arrow_downward,
            size: 16,
            color: const Color(0xFF00875A),
          ),
        ),
      ),
    );
  }
}
