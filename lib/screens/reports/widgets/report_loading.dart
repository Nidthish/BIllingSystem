import 'package:flutter/material.dart';

/// Skeleton loading widget shown while report data is being computed.
class ReportLoading extends StatefulWidget {
  const ReportLoading({super.key});

  @override
  State<ReportLoading> createState() => _ReportLoadingState();
}

class _ReportLoadingState extends State<ReportLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final shimmerBase = isDark ? Colors.white10 : Colors.grey.shade200;
    final shimmerHighlight = isDark ? Colors.white24 : Colors.grey.shade100;

    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // KPI card skeletons
              Row(
                children: List.generate(6, (_) => Expanded(
                  child: Container(
                    height: 80,
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    decoration: BoxDecoration(
                      color: Color.lerp(shimmerBase, shimmerHighlight, _anim.value),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                )),
              ),
              const SizedBox(height: 24),
              // Table header skeleton
              Container(
                height: 44,
                decoration: BoxDecoration(
                  color: Color.lerp(shimmerBase, shimmerHighlight, _anim.value),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                ),
              ),
              // Table row skeletons
              ...List.generate(8, (i) => Container(
                height: 40,
                decoration: BoxDecoration(
                  color: Color.lerp(shimmerBase, shimmerHighlight, i.isEven ? _anim.value : 1 - _anim.value),
                  border: Border(bottom: BorderSide(color: shimmerBase, width: 1)),
                ),
              )),
            ],
          ),
        );
      },
    );
  }
}
