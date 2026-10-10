import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/money.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../domain/services/comparison.dart';

/// Colore di ciascun periodo confrontato (i tre del mockup: blu, arancio, verde acqua).
Color seriesColor(BuildContext context, int index) {
  final colors = context.colors;
  return switch (index) {
    0 => colors.income.text,
    1 => const Color(0xFFF08A4B),
    _ => colors.savings.text,
  };
}

/// Una riga del confronto: un valore per ogni periodo, nello stesso ordine.
class CompareRow {
  const CompareRow({
    required this.name,
    required this.shortName,
    required this.values,
    this.higherIsBetter = false,
    this.isTotal = false,
  });

  final String name;

  /// Nome breve per l'asse del grafico a barre ("Trasp.").
  final String shortName;
  final List<int> values;

  /// Per le entrate e il saldo aumentare è positivo; per le spese no.
  final bool higherIsBetter;
  final bool isTotal;
}

/// Abbrevia un nome per le etichette sotto le barre: prima parola, al massimo 6 lettere.
String shortCategoryName(String name) {
  final first = name.split(' ').first;
  return first.length > 6 ? '${first.substring(0, 5)}.' : first;
}

String _wholeEuros(int cents) {
  final euros = (cents.abs() + 50) ~/ 100;
  final text = NumberFormat('#,##0', 'it_IT').format(euros);
  return cents < 0 ? '$minusSign$text' : text;
}

/// Passo "tondo" (1, 2 o 5 per una potenza di 10) per dividere [span] in circa [steps] parti.
double niceStep(double span, {int steps = 3}) {
  if (span <= 0) return 1;
  final raw = span / steps;
  final magnitude = math.pow(10, (math.log(raw) / math.ln10).floor()).toDouble();
  final normalized = raw / magnitude;
  final nice = normalized <= 1 ? 1 : (normalized <= 2 ? 2 : (normalized <= 5 ? 5 : 10));
  return nice * magnitude;
}

/// Etichetta compatta per l'asse: 600, 1,2k, 18k.
String _compact(double euros) {
  if (euros.abs() < 1000) return euros.round().toString();
  return '${NumberFormat('0.#', 'it_IT').format(euros / 1000)}k';
}

/// Barre raggruppate: una per periodo in ogni riga.
class CompareBarChart extends StatelessWidget {
  const CompareBarChart({super.key, required this.rows});

  final List<CompareRow> rows;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final values = [for (final row in rows) ...row.values.map((v) => v / 100)];
    final maxY = values.fold(0.0, math.max);
    final minY = values.fold(0.0, math.min);
    final periods = rows.isEmpty ? 0 : rows.first.values.length;

    return SizedBox(
      height: 190,
      child: BarChart(
        BarChartData(
          maxY: maxY == 0 ? 1 : maxY * 1.1,
          minY: minY < 0 ? minY * 1.1 : 0,
          alignment: BarChartAlignment.spaceAround,
          barTouchData: BarTouchData(enabled: false),
          borderData: FlBorderData(
            show: true,
            border: Border(bottom: BorderSide(color: colors.borderStrong)),
          ),
          gridData: const FlGridData(show: false),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(),
            rightTitles: const AxisTitles(),
            topTitles: const AxisTitles(),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 24,
                getTitlesWidget: (value, meta) => SideTitleWidget(
                  meta: meta,
                  child: Text(
                    rows[value.toInt()].shortName,
                    style: textTheme.labelSmall?.copyWith(fontSize: 11, color: colors.neutral.onTint),
                  ),
                ),
              ),
            ),
          ),
          barGroups: [
            for (final (i, row) in rows.indexed)
              BarChartGroupData(
                x: i,
                barsSpace: 2,
                barRods: [
                  for (var p = 0; p < periods; p++)
                    BarChartRodData(
                      toY: row.values[p] / 100,
                      color: seriesColor(context, p),
                      width: 11,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

/// Linee del valore cumulato giorno per giorno, una per periodo.
class CompareLineChart extends StatelessWidget {
  const CompareLineChart({super.key, required this.series});

  /// Per ogni periodo, il cumulato in centesimi (un elemento per giorno).
  final List<List<int>> series;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final days = series.fold(1, (longest, s) => math.max(longest, s.length));
    final all = [for (final s in series) ...s.map((v) => v / 100)];
    // Scala con valori tondi: minimo e massimo sono multipli del passo, così le etichette non si accavallano.
    final rawMin = all.fold(0.0, math.min);
    final rawMax = all.fold(0.0, math.max);
    final step = niceStep(rawMax - rawMin);
    final minY = (rawMin / step).floorToDouble() * step;
    final maxY = math.max((rawMax / step).ceilToDouble() * step, minY + step);
    final labelStyle = textTheme.labelSmall?.copyWith(fontSize: 10, color: colors.textMuted);

    return SizedBox(
      height: 200,
      child: LineChart(
        LineChartData(
          minX: 1,
          maxX: days.toDouble(),
          minY: minY,
          maxY: maxY,
          lineTouchData: const LineTouchData(enabled: false),
          borderData: FlBorderData(show: false),
          gridData: FlGridData(
            drawVerticalLine: false,
            horizontalInterval: step,
            getDrawingHorizontalLine: (_) => FlLine(color: colors.divider, strokeWidth: 1),
          ),
          titlesData: FlTitlesData(
            rightTitles: const AxisTitles(),
            topTitles: const AxisTitles(),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 34,
                interval: step,
                getTitlesWidget: (value, meta) => SideTitleWidget(
                  meta: meta,
                  child: Text(_compact(value), style: labelStyle),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 22,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  final day = value.toInt();
                  // Solo inizio, metà e fine: 1, 15, 31 per un mese.
                  final show = day == 1 || day == days || (days > 20 && day == 15);
                  return show
                      ? SideTitleWidget(
                          meta: meta,
                          child: Text('$day', style: labelStyle),
                        )
                      : const SizedBox.shrink();
                },
              ),
            ),
          ),
          lineBarsData: [
            // Il primo periodo per ultimo, così la sua linea resta sopra le altre.
            for (final (i, values) in series.indexed.toList().reversed)
              LineChartBarData(
                spots: [for (final (day, cents) in values.indexed) FlSpot(day + 1.0, cents / 100)],
                color: seriesColor(context, i),
                barWidth: i == 0 ? 3 : 2.5,
                isStrokeCapRound: true,
                dotData: const FlDotData(show: false),
              ),
          ],
        ),
      ),
    );
  }
}

/// Tabella: una colonna per periodo e la variazione del primo rispetto al secondo.
class CompareTable extends StatelessWidget {
  const CompareTable({super.key, required this.firstColumn, required this.periodLabels, required this.rows});

  final String firstColumn;
  final List<String> periodLabels;
  final List<CompareRow> rows;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final showDelta = periodLabels.length >= 2;
    const tabular = [FontFeature.tabularFigures()];
    final headerStyle = textTheme.labelSmall?.copyWith(
      fontSize: 11,
      color: colors.textMuted,
      fontWeight: FontWeight.w800,
      letterSpacing: 0.5,
    );

    Widget cell(Widget child, {int flex = 10}) => Expanded(flex: flex, child: child);

    Widget row({required List<Widget> cells, Color? background, bool top = true}) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: background,
        border: top ? Border(top: BorderSide(color: colors.divider)) : null,
      ),
      child: Row(children: cells),
    );

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: colors.border),
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Column(
        children: [
          row(
            top: false,
            background: colors.neutral.tint.withValues(alpha: 0.5),
            cells: [
              cell(Text(firstColumn.toUpperCase(), style: headerStyle), flex: 14),
              for (final (i, label) in periodLabels.indexed)
                cell(
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: seriesColor(context, i),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(label.toUpperCase(), textAlign: TextAlign.right, maxLines: 1, style: headerStyle),
                      ),
                    ],
                  ),
                ),
              if (showDelta) cell(Text('Δ', textAlign: TextAlign.right, style: headerStyle), flex: 9),
            ],
          ),
          for (final data in rows)
            row(
              cells: [
                cell(
                  Text(
                    data.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.labelMedium?.copyWith(
                      fontWeight: data.isTotal ? FontWeight.w800 : FontWeight.w600,
                    ),
                  ),
                  flex: 14,
                ),
                for (final value in data.values)
                  cell(
                    Text(
                      _wholeEuros(value),
                      textAlign: TextAlign.right,
                      style: textTheme.labelMedium?.copyWith(
                        fontWeight: data.isTotal ? FontWeight.w800 : FontWeight.w600,
                        fontFeatures: tabular,
                      ),
                    ),
                  ),
                if (showDelta) cell(_Delta(row: data), flex: 9),
              ],
            ),
        ],
      ),
    );
  }
}

class _Delta extends StatelessWidget {
  const _Delta({required this.row});

  final CompareRow row;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final change = percentChange(row.values[0], row.values[1]);
    final String text;
    final Color color;
    if (change == null) {
      text = '—';
      color = colors.textMuted;
    } else if (change.abs() < 0.0005) {
      text = '0,0%';
      color = colors.textMuted;
    } else {
      final sign = change > 0 ? '+' : minusSign;
      text = '$sign${NumberFormat('0.0', 'it_IT').format(change.abs() * 100)}%';
      final good = (change > 0) == row.higherIsBetter;
      color = good ? colors.income.text : colors.danger;
    }
    return Text(
      text,
      textAlign: TextAlign.right,
      style: Theme.of(context).textTheme.labelMedium
          ?.copyWith(fontWeight: FontWeight.w800, color: color, fontFeatures: const [FontFeature.tabularFigures()]),
    );
  }
}
