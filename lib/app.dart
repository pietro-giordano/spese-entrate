import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Spese & Entrate',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(fontFamily: 'Manrope'),
      locale: const Locale('it', 'IT'),
      supportedLocales: const [Locale('it', 'IT')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: const FontPreviewScreen(),
    );
  }
}

/// Schermata di prova temporanea: verifica font Manrope e formati italiani.
class FontPreviewScreen extends StatelessWidget {
  const FontPreviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final currency = NumberFormat.currency(locale: 'it_IT', symbol: '€');
    final today = DateFormat.yMMMMEEEEd().format(DateTime.now());

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text('Spese & Entrate', style: textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text(today, style: textTheme.bodyLarge),
            const SizedBox(height: 24),
            for (final weight in [FontWeight.w400, FontWeight.w500, FontWeight.w600, FontWeight.w700, FontWeight.w800])
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  'Manrope ${weight.value} — Portafogli e movimenti',
                  style: textTheme.titleMedium?.copyWith(fontWeight: weight),
                ),
              ),
            const SizedBox(height: 24),
            for (final amount in [1234.56, 89.9, 11111.11])
              Text(
                currency.format(amount),
                textAlign: TextAlign.right,
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
