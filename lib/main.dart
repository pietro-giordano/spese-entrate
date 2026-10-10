import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

import 'app.dart';
import 'data/db/database_provider.dart';
import 'features/settings/application/settings_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Formati di date e numeri in italiano per tutto il pacchetto intl.
  Intl.defaultLocale = 'it_IT';
  await initializeDateFormatting('it_IT');

  // Apre il database prima di mostrare l'app: al primo avvio crea le tabelle,
  // il device_id e i dati iniziali.
  final container = ProviderContainer();
  await container.read(appDatabaseProvider).deviceId();

  // Impostazioni e preferenze pronte prima del primo fotogramma: tema, blocco con biometria
  // e vista predefinita sono giusti fin da subito. Gli ascoltatori le tengono caricate.
  container
    ..listen(appSettingsProvider, (_, _) {})
    ..listen(localPreferencesProvider, (_, _) {});
  await container.read(appSettingsProvider.future);
  await container.read(localPreferencesProvider.future);

  runApp(UncontrolledProviderScope(container: container, child: const App()));
}
