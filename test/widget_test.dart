import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:spese_entrate/app.dart';

void main() {
  setUpAll(() async {
    Intl.defaultLocale = 'it_IT';
    await initializeDateFormatting('it_IT');
  });

  testWidgets('la schermata di prova usa Manrope e la localizzazione italiana', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: App()));
    await tester.pumpAndSettle();

    expect(find.text('Spese & Entrate'), findsOneWidget);

    final context = tester.element(find.byType(FontPreviewScreen));
    expect(Localizations.localeOf(context), const Locale('it', 'IT'));
    expect(Theme.of(context).textTheme.bodyMedium?.fontFamily, 'Manrope');
  });
}
