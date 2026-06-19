import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/monthly_summary.dart';

class ExpenseBarChart extends StatelessWidget {
  final MonthlySummary summary;
  const ExpenseBarChart({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    final daysInMonth =
        DateTime(summary.year, summary.month + 1, 0).day;
    final daily = summary.dailyExpenses;

    if (daily.isEmpty) return const SizedBox.shrink();

    final maxY =
        (daily.values.reduce((a, b) => a > b ? a : b) * 1.25).ceilToDouble();

    final groups = List.generate(daysInMonth, (i) {
      final day = i + 1;
      final amount = daily[day] ?? 0.0;
      return BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: amount,
            gradient: amount > 0
                ? const LinearGradient(
                    colors: [kAccentPurple, kAccentPink],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  )
                : null,
            color: amount > 0 ? null : Colors.transparent,
            width: _barWidth(daysInMonth),
            borderRadius: BorderRadius.circular(3),
          ),
        ],
      );
    });

    final today = DateTime.now();
    final isCurrentMonth =
        today.year == summary.year && today.month == summary.month;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
      decoration: BoxDecoration(
        color: kBgSecondary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kGlassBorder, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 8),
            child: Text('Daily Spending',
                style: TextStyle(
                    color: kTextSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500)),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 120,
            child: BarChart(
              BarChartData(
                maxY: maxY,
                barGroups: groups,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxY / 3,
                  getDrawingHorizontalLine: (_) => const FlLine(
                    color: kGlassBorder,
                    strokeWidth: 0.5,
                  ),
                ),
                borderData: FlBorderData(show: false),
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => kBgTertiary,
                    tooltipPadding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    getTooltipItem: (group, _, rod, __) {
                      if (rod.toY == 0) return null;
                      return BarTooltipItem(
                        '₹${_fmt(rod.toY)}',
                        const TextStyle(
                            color: kTextPrimary,
                            fontSize: 11,
                            fontWeight: FontWeight.w600),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 20,
                      getTitlesWidget: (value, _) {
                        final day = value.toInt() + 1;
                        final isToday = isCurrentMonth &&
                            day == today.day;
                        final show = day == 1 ||
                            day == 10 ||
                            day == 20 ||
                            day == daysInMonth ||
                            isToday;
                        if (!show) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            '$day',
                            style: TextStyle(
                              color: isToday
                                  ? kAccentPurple
                                  : kTextHint,
                              fontSize: 10,
                              fontWeight: isToday
                                  ? FontWeight.w700
                                  : FontWeight.normal,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static double _barWidth(int days) {
    if (days <= 15) return 12;
    if (days <= 20) return 9;
    return 6;
  }

  static String _fmt(double v) {
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
  }
}
