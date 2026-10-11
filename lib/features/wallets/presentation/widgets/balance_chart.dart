import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/dates.dart';
import '../../../../core/money.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';

/// Linea del saldo a fine mese (ultimi 6 mesi) nella card del dettaglio portafoglio.
class BalanceChart extends StatelessWidget {
  const BalanceChart({super.key, required this.points, required this.color});

  final List<({LocalDate date, int balanceCents})> points;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final months = DateFormat('MMM', 'it_IT');
    final values = points.map((p) => p.balanceCents.toDouble()).toList();
    final min = values.reduce((a, b) => a < b ? a : b);
    final max = values.reduce((a, b) => a > b ? a : b);
    // Margine sopra e sotto; se il saldo non cambia mai la linea resta a metà.
    final padding = max == min ? (max.abs() / 10).clamp(100.0, double.infinity) : (max - min) * 0.15;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, AppSpacing.lg, 14, AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: colors.border),
        borderRadius: BorderRadius.circular(AppRadius.cardLarge),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Andamento del saldo · ultimi 6 mesi', style: textTheme.labelMedium?.copyWith(color: colors.textMuted)),
          const SizedBox(height: AppSpacing.md),
          Semantics(
            label:
                'Andamento del saldo negli ultimi sei mesi: '
                'da ${formatCents(points.first.balanceCents)} a ${formatCents(points.last.balanceCents)}',
            excludeSemantics: true,
            child: SizedBox(
              height: 140,
              child: LineChart(
                LineChartData(
                  minX: 0,
                  maxX: (points.length - 1).toDouble(),
                  minY: min - padding,
                  maxY: max + padding,
                  lineTouchData: const LineTouchData(enabled: false),
                  borderData: FlBorderData(show: false),
                  gridData: FlGridData(
                    drawVerticalLine: false,
                    horizontalInterval: (max - min + 2 * padding) / 2,
                    getDrawingHorizontalLine: (_) => FlLine(color: colors.divider, strokeWidth: 1),
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(),
                    rightTitles: const AxisTitles(),
                    topTitles: const AxisTitles(),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 1,
                        reservedSize: 24,
                        getTitlesWidget: (value, meta) => SideTitleWidget(
                          meta: meta,
                          child: Text(
                            months.format(points[value.toInt()].date.toDateTime()),
                            style: textTheme.labelSmall?.copyWith(fontSize: 10, color: colors.textMuted),
                          ),
                        ),
                      ),
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: [for (final (i, value) in values.indexed) FlSpot(i.toDouble(), value)],
                      color: color,
                      barWidth: 3,
                      isCurved: false,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
