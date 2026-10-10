import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart';

import 'core/theme/app_theme.dart';
import 'core/widgets/amount_text.dart';
import 'core/widgets/component_catalog_screen.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Spese & Entrate',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
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
            for (final cents in [123456, 8990, 1111111])
              AmountText(cents, textAlign: TextAlign.right, style: textTheme.titleLarge),
            // kDebugMode è una costante: in release il compilatore elimina questo ramo.
            if (kDebugMode) ...[
              const SizedBox(height: 32),
              OutlinedButton(
                onPressed: () =>
                    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const ComponentCatalogScreen())),
                child: const Text('Catalogo componenti'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
