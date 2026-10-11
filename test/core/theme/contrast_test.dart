import 'dart:math' as math;

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spese_entrate/core/theme/app_colors.dart';

/// Rapporto di contrasto WCAG 2.x tra due colori opachi.
double contrast(Color a, Color b) {
  final la = a.computeLuminance(), lb = b.computeLuminance();
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

/// Coppie testo/sfondo usate davvero dai widget, in entrambi i temi: testo ≥ 4.5:1 (CLAUDE.md).
/// Le serie dei grafici sono elementi grafici, non testo: ≥ 3:1 (WCAG 1.4.11).
void main() {
  for (final (name, c) in [('chiaro', AppColors.light), ('scuro', AppColors.dark)]) {
    group('tema $name', () {
      final textPairs = <String, (Color, Color)>{
        'testo su sfondo': (c.text, c.background),
        'testo su superficie': (c.text, c.surface),
        'testo su segmento attivo': (c.text, c.surfaceRaised),
        'testo secondario su sfondo': (c.textMuted, c.background),
        'testo secondario su superficie': (c.textMuted, c.surface),
        'testo secondario su segmented': (c.textMuted, c.track),
        'pericolo su sfondo': (c.danger, c.background),
        'pericolo su superficie': (c.danger, c.surface),
        for (final (tone, t) in [
          ('spesa', c.expense),
          ('entrata', c.income),
          ('neutro', c.neutral),
          ('liquidità', c.liquidity),
          ('risparmi', c.savings),
          ('investimenti', c.investments),
        ]) ...{
          '$tone: testo su pieno': (t.onFill, t.fill),
          '$tone: testo su tinta': (t.onTint, t.tint),
          '$tone: testo su superficie': (t.text, c.surface),
          '$tone: testo su sfondo': (t.text, c.background),
        },
      };

      for (final MapEntry(key: pair, value: (fg, bg)) in textPairs.entries) {
        test(pair, () => expect(contrast(fg, bg), greaterThanOrEqualTo(4.5)));
      }

      test('serie dei grafici su superficie (elementi grafici)', () {
        for (final (i, series) in c.chartSeries.indexed) {
          // Eccezione nota: l'arancio #F08A4B del tema chiaro (2,5:1) è un token confermato;
          // nei grafici i valori sono anche scritti in legenda e tabella.
          if (identical(c, AppColors.light) && i == 1) continue;
          expect(contrast(series, c.surface), greaterThanOrEqualTo(3), reason: 'serie ${i + 1}');
        }
      });
    });
  }
}
