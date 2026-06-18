import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/money_provider.dart';

class SummaryCard extends ConsumerWidget {
  const SummaryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(monthlySummaryProvider);
    final sel = ref.watch(selectedMonthProvider);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4C1D95), Color(0xFF7C3AED), Color(0xFFEC4899)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: summaryAsync.when(
          loading: () => const _CardSkeleton(),
          error: (_, __) => const Center(
            child: Text('Error loading summary',
                style: TextStyle(color: Colors.white70)),
          ),
          data: (summary) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${_monthName(sel.month)} ${sel.year}',
                      style: const TextStyle(color: Colors.white70, fontSize: 13)),
                  _MonthNav(),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                _fmt(summary.balance),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              const Text('Balance',
                  style: TextStyle(color: Colors.white60, fontSize: 12)),
              const SizedBox(height: 16),
              Row(
                children: [
                  _StatChip(
                    label: 'Income',
                    value: _fmt(summary.totalIncome),
                    icon: Icons.arrow_downward_rounded,
                    color: const Color(0xFF34D399),
                  ),
                  const SizedBox(width: 12),
                  _StatChip(
                    label: 'Expenses',
                    value: _fmt(summary.totalExpense),
                    icon: Icons.arrow_upward_rounded,
                    color: const Color(0xFFF87171),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _monthName(int month) => const [
        '',
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec'
      ][month];

  static String _fmt(double v) {
    final sign = v < 0 ? '-' : '';
    final abs = v.abs();
    if (abs >= 1000000) return '$sign₹${(abs / 1000000).toStringAsFixed(1)}M';
    if (abs >= 1000) return '$sign₹${(abs / 1000).toStringAsFixed(1)}K';
    return '$sign₹${abs.toStringAsFixed(0)}';
  }
}

class _MonthNav extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        _NavBtn(icon: Icons.chevron_left_rounded, onTap: () => _shift(ref, -1)),
        const SizedBox(width: 4),
        _NavBtn(icon: Icons.chevron_right_rounded, onTap: () => _shift(ref, 1)),
      ],
    );
  }

  void _shift(WidgetRef ref, int delta) {
    final sel = ref.read(selectedMonthProvider);
    var m = sel.month + delta;
    var y = sel.year;
    if (m < 1) {
      m = 12;
      y--;
    }
    if (m > 12) {
      m = 1;
      y++;
    }
    ref.read(selectedMonthProvider.notifier).state = SelectedMonth(y, m);
  }
}

class _NavBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _NavBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white12,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _StatChip({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white10,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style:
                          const TextStyle(color: Colors.white60, fontSize: 11)),
                  Text(value,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CardSkeleton extends StatelessWidget {
  const _CardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _shimmer(80, 16),
        const SizedBox(height: 8),
        _shimmer(150, 36),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _shimmer(double.infinity, 48)),
            const SizedBox(width: 12),
            Expanded(child: _shimmer(double.infinity, 48)),
          ],
        ),
      ],
    );
  }

  Widget _shimmer(double w, double h) => Container(
        width: w,
        height: h,
        decoration: BoxDecoration(
          color: Colors.white12,
          borderRadius: BorderRadius.circular(8),
        ),
      );
}
