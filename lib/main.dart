import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

import 'app.dart';
import 'data/db/database_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Formati di date e numeri in italiano per tutto il pacchetto intl.
  Intl.defaultLocale = 'it_IT';
  await initializeDateFormatting('it_IT');

  // Apre il database prima di mostrare l'app: al primo avvio crea le tabelle,
  // il device_id e i dati iniziali.
  final container = ProviderContainer();
  await container.read(appDatabaseProvider).deviceId();

  runApp(UncontrolledProviderScope(container: container, child: const App()));
}
