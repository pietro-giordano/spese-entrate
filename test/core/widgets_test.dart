import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spese_entrate/core/money.dart';
import 'package:spese_entrate/core/theme/app_colors.dart';
import 'package:spese_entrate/core/theme/app_theme.dart';
import 'package:spese_entrate/core/widgets/amount_text.dart';
import 'package:spese_entrate/core/widgets/app_bottom_sheet.dart';
import 'package:spese_entrate/core/widgets/app_chip.dart';
import 'package:spese_entrate/core/widgets/app_list_row.dart';
import 'package:spese_entrate/core/widgets/app_segmented.dart';
import 'package:spese_entrate/core/widgets/app_switch.dart';
import 'package:spese_entrate/core/widgets/component_catalog_screen.dart';
import 'package:spese_entrate/core/widgets/section_label.dart';

/// Monta [child] dentro un'app con il tema dell'app.
Future<void> pumpInApp(WidgetTester tester, Widget child, {ThemeData? theme}) {
  return tester.pumpWidget(
    MaterialApp(
      theme: theme ?? AppTheme.light,
      home: Scaffold(body: Center(child: child)),
    ),
  );
}

void main() {
  group('tema', () {
    test('chiaro e scuro espongono i rispettivi AppColors', () {
      expect(AppTheme.light.extension<AppColors>(), same(AppColors.light));
      expect(AppTheme.dark.extension<AppColors>(), same(AppColors.dark));
    });

    test('lerp a metà strada mescola i colori', () {
      final mid = AppColors.light.lerp(AppColors.dark, 0.5);
      expect(mid.background, Color.lerp(AppColors.light.background, AppColors.dark.background, 0.5));
    });
  });

  group('AmountText', () {
    testWidgets('spesa con segno meno e colore spesa', (tester) async {
      await pumpInApp(tester, const AmountText(6420, kind: AmountKind.expense));
      final text = tester.widget<Text>(find.text('$minusSign € 64,20'));
      expect(text.style?.color, AppColors.light.expense.text);
    });

    testWidgets('spesa non colorata usa il colore del testo', (tester) async {
      await pumpInApp(tester, const AmountText(6420, kind: AmountKind.expense, colored: false));
      final text = tester.widget<Text>(find.text('$minusSign € 64,20'));
      expect(text.style?.color, AppColors.light.text);
    });

    testWidgets('entrata con segno più', (tester) async {
      await pumpInApp(tester, const AmountText(185000, kind: AmountKind.income));
      expect(find.text('+ € 1.850,00'), findsOneWidget);
    });

    testWidgets('neutro mostra il segno solo se negativo', (tester) async {
      await pumpInApp(tester, const Column(children: [AmountText(1500), AmountText(-1500)]));
      expect(find.text('€ 15,00'), findsOneWidget);
      expect(find.text('$minusSign € 15,00'), findsOneWidget);
    });
  });

  testWidgets('AppSegmented notifica il valore toccato', (tester) async {
    String? picked;
    await pumpInApp(
      tester,
      AppSegmented<String>(
        segments: const [
          AppSegment(value: 'a', label: 'Uno'),
          AppSegment(value: 'b', label: 'Due'),
        ],
        selected: 'a',
        onChanged: (value) => picked = value,
      ),
    );
    await tester.tap(find.text('Due'));
    expect(picked, 'b');
  });

  testWidgets('AppChip ha un\'area toccabile di almeno 44 px', (tester) async {
    var taps = 0;
    await pumpInApp(tester, AppChip(label: '#casa', shape: AppChipShape.label, onTap: () => taps++));
    expect(tester.getSize(find.byType(AppChip)).height, greaterThanOrEqualTo(44));
    await tester.tap(find.byType(AppChip));
    expect(taps, 1);
  });

  group('AppSwitch', () {
    testWidgets('inverte il valore al tocco', (tester) async {
      bool? next;
      await pumpInApp(tester, AppSwitch(value: true, onChanged: (value) => next = value));
      await tester.tap(find.byType(AppSwitch));
      expect(next, isFalse);
    });

    testWidgets('disattivato non risponde', (tester) async {
      await pumpInApp(tester, const AppSwitch(value: false, onChanged: null));
      await tester.tap(find.byType(AppSwitch));
      expect(tester.takeException(), isNull);
    });
  });

  testWidgets('AppListRow mostra il chevron solo se toccabile', (tester) async {
    await pumpInApp(
      tester,
      AppListGroup(
        children: [
          AppListRow(title: 'Valuta', value: 'Euro (€)', onTap: () {}),
          const AppListRow(title: 'Sola lettura'),
        ],
      ),
    );
    expect(find.text('Euro (€)'), findsOneWidget);
    expect(find.byIcon(Icons.chevron_right_rounded), findsOneWidget);
  });

  testWidgets('SectionLabel mostra il testo in maiuscolo', (tester) async {
    await pumpInApp(tester, const SectionLabel('Categorie', trailing: '2 selezionate'));
    expect(find.text('CATEGORIE'), findsOneWidget);
    expect(find.text('2 selezionate'), findsOneWidget);
  });

  testWidgets('AppBottomSheet.show restituisce il valore scelto', (tester) async {
    String? result;
    await pumpInApp(
      tester,
      Builder(
        builder: (context) => TextButton(
          onPressed: () async {
            result = await AppBottomSheet.show<String>(
              context,
              title: 'Paga da',
              builder: (sheetContext) =>
                  TextButton(onPressed: () => Navigator.pop(sheetContext, 'Contanti'), child: const Text('Contanti')),
            );
          },
          child: const Text('Apri'),
        ),
      ),
    );
    await tester.tap(find.text('Apri'));
    await tester.pumpAndSettle();
    expect(find.text('Paga da'), findsOneWidget);

    await tester.tap(find.text('Contanti'));
    await tester.pumpAndSettle();
    expect(result, 'Contanti');
  });

  testWidgets('il catalogo si disegna in entrambi i temi su un telefono', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(MaterialApp(theme: AppTheme.light, home: const ComponentCatalogScreen()));
    expect(find.text('Catalogo componenti'), findsOneWidget);

    await tester.tap(find.text('Scuro'));
    await tester.pumpAndSettle();
    final context = tester.element(find.text('Catalogo componenti'));
    expect(Theme.of(context).brightness, Brightness.dark);

    // Scorre fino in fondo: eventuali overflow farebbero fallire il test.
    await tester.drag(find.byType(ListView), const Offset(0, -3000));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
