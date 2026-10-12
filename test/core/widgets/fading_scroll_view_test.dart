import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spese_entrate/core/widgets/fading_scroll_view.dart';

void main() {
  /// Area alta 300 px con un contenuto alto [contentHeight]. Restituisce una funzione per
  /// cambiare l'altezza del contenuto senza scorrere (come espandere "Tutte").
  Future<void Function(double)> pump(WidgetTester tester, double contentHeight) async {
    var height = contentHeight;
    late StateSetter rebuild;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              height: 300,
              child: StatefulBuilder(
                builder: (context, setState) {
                  rebuild = setState;
                  return FadingScrollView(children: [SizedBox(height: height)]);
                },
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return (double value) => rebuild(() => height = value);
  }

  FadingScrollViewState state(WidgetTester tester) => tester.state(find.byType(FadingScrollView));

  testWidgets('contenuto che sta nell\'area: nessuna sfumatura', (tester) async {
    await pump(tester, 200);
    expect((state(tester).fadeTop, state(tester).fadeBottom), (false, false));
  });

  testWidgets('contenuto più alto: sfumatura in basso; in fondo sparisce in basso e compare in alto', (tester) async {
    await pump(tester, 1000);
    expect((state(tester).fadeTop, state(tester).fadeBottom), (false, true));

    await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -300));
    await tester.pumpAndSettle();
    expect((state(tester).fadeTop, state(tester).fadeBottom), (true, true), reason: 'a metà: entrambe');

    await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -2000));
    await tester.pumpAndSettle();
    expect((state(tester).fadeTop, state(tester).fadeBottom), (true, false));
  });

  testWidgets('il contenuto cresce senza scorrere (es. "Tutte"): compare la sfumatura in basso', (tester) async {
    final setContentHeight = await pump(tester, 200);
    expect(state(tester).fadeBottom, isFalse);
    setContentHeight(900);
    await tester.pumpAndSettle();
    expect((state(tester).fadeTop, state(tester).fadeBottom), (false, true));
  });

  testWidgets('trasparenza, non colore: ShaderMask con dstIn e 20 px sull\'altezza reale', (tester) async {
    await pump(tester, 1000);
    final mask = tester.widget<ShaderMask>(find.byType(ShaderMask));
    expect(mask.blendMode, BlendMode.dstIn);
    final shader = mask.shaderCallback(const Rect.fromLTWH(0, 0, 100, 300));
    expect(shader, isA<Shader>());
  });
}
