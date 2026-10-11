import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spese_entrate/core/clock.dart';
import 'package:spese_entrate/data/db/app_database.dart';
import 'package:spese_entrate/data/db/database_provider.dart';
import 'package:spese_entrate/data/repositories/drift_local_preferences_repository.dart';
import 'package:spese_entrate/domain/models/local_preferences.dart';
import 'package:spese_entrate/features/settings/application/settings_providers.dart';
import 'package:spese_entrate/features/wallets/application/balance_visibility.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late AppDatabase db;
  late DateTime now;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory(), now: () => DateTime.utc(2026, 10, 11, 8));
    now = DateTime(2026, 10, 11, 9);
  });
  tearDown(() => db.close());

  /// Come all'avvio dell'app: preferenze caricate prima di leggere i saldi.
  /// Un nuovo container sullo stesso database = l'app chiusa e riaperta.
  Future<ProviderContainer> open() async {
    final container = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWithValue(db), clockProvider.overrideWithValue(() => now)],
    );
    addTearDown(container.dispose);
    container.listen(localPreferencesProvider, (_, _) {});
    await container.read(localPreferencesProvider.future);
    return container;
  }

  Future<void> setMode(BalancesOnOpen mode) async {
    final repository = DriftLocalPreferencesRepository(db);
    await repository.save((await repository.get()).copyWith(balancesOnOpen: mode));
  }

  bool hidden(ProviderContainer c) => c.read(balancesHiddenProvider);
  BalancesHidden notifier(ProviderContainer c) => c.read(balancesHiddenProvider.notifier);

  /// L'app va in background per [away] e torna in primo piano.
  void leaveFor(ProviderContainer c, Duration away) {
    notifier(c).wentToBackground();
    now = now.add(away);
    notifier(c).cameToForeground();
  }

  group('all\'apertura', () {
    test('predefinito: sempre visibili, anche se l\'ultima volta erano nascosti', () async {
      final first = await open();
      expect(hidden(first), isFalse);
      await notifier(first).toggle();
      expect(hidden(first), isTrue);

      expect(hidden(await open()), isFalse);
    });

    test('sempre nascosti: nascosti a ogni apertura, anche se l\'ultima volta erano visibili', () async {
      await setMode(BalancesOnOpen.hidden);
      final first = await open();
      expect(hidden(first), isTrue);
      await notifier(first).toggle();
      expect(hidden(first), isFalse);

      expect(hidden(await open()), isTrue);
    });

    test('ricorda l\'ultima scelta: riapre come li si era lasciati', () async {
      await setMode(BalancesOnOpen.remember);
      final first = await open();
      expect(hidden(first), isFalse);
      await notifier(first).toggle();
      expect(hidden(await open()), isTrue);

      final second = await open();
      await notifier(second).toggle();
      expect(hidden(await open()), isFalse);
    });

    test('la scelta dell\'occhio si salva in app_meta', () async {
      final container = await open();
      await notifier(container).toggle();
      final rows = {for (final row in await db.select(db.appMeta).get()) row.key: row.value};
      expect(rows[AppMetaKeys.balancesHidden], 'true');
      expect(rows[AppMetaKeys.balancesOnOpen], 'visible');
      await setMode(BalancesOnOpen.remember);
      final saved = {for (final row in await db.select(db.appMeta).get()) row.key: row.value};
      expect(saved[AppMetaKeys.balancesOnOpen], 'remember');
    });
  });

  group('ritorno in primo piano', () {
    test('sempre nascosti: si nascondono di nuovo dopo almeno 1 minuto', () async {
      await setMode(BalancesOnOpen.hidden);
      final container = await open();
      await notifier(container).toggle();

      leaveFor(container, const Duration(seconds: 59));
      expect(hidden(container), isFalse, reason: 'meno di un minuto: restano visibili');

      leaveFor(container, hideBalancesAfterBackground);
      expect(hidden(container), isTrue);
    });

    test('conta il primo momento in background, non gli eventi successivi', () async {
      await setMode(BalancesOnOpen.hidden);
      final container = await open();
      await notifier(container).toggle();

      notifier(container).wentToBackground();
      now = now.add(const Duration(seconds: 40));
      notifier(container).wentToBackground(); // hidden → paused: stesso viaggio in background
      now = now.add(const Duration(seconds: 30));
      notifier(container).cameToForeground();
      expect(hidden(container), isTrue);
    });

    test('ritorno senza essere andata in background: nessun cambiamento', () async {
      await setMode(BalancesOnOpen.hidden);
      final container = await open();
      await notifier(container).toggle();
      now = now.add(const Duration(minutes: 5));
      notifier(container).cameToForeground();
      expect(hidden(container), isFalse);
    });

    for (final mode in [BalancesOnOpen.visible, BalancesOnOpen.remember]) {
      test('${mode.name}: lo stato resta quello scelto anche dopo molto tempo', () async {
        await setMode(mode);
        final container = await open();
        leaveFor(container, const Duration(hours: 2));
        expect(hidden(container), isFalse);
        await notifier(container).toggle();
        leaveFor(container, const Duration(hours: 2));
        expect(hidden(container), isTrue);
      });
    }
  });

  group('modalità cambiata nelle Impostazioni: effetto immediato', () {
    test('sempre visibili: li mostra subito', () async {
      final container = await open();
      await notifier(container).toggle();
      await notifier(container).setMode(BalancesOnOpen.visible);
      expect(hidden(container), isFalse);
    });

    test('sempre nascosti: li nasconde subito', () async {
      final container = await open();
      await notifier(container).setMode(BalancesOnOpen.hidden);
      expect(hidden(container), isTrue);
      expect((await DriftLocalPreferencesRepository(db).get()).balancesOnOpen, BalancesOnOpen.hidden);
    });

    for (final current in [false, true]) {
      test('ricorda l\'ultima scelta: conserva lo stato corrente (${current ? 'nascosti' : 'visibili'})', () async {
        final container = await open();
        if (current) await notifier(container).toggle();
        await notifier(container).setMode(BalancesOnOpen.remember);
        expect(hidden(container), current);
        expect(hidden(await open()), current, reason: 'lo stato corrente diventa l\'ultima scelta');
      });
    }

    test('dopo «sempre nascosti» il ritorno in primo piano li nasconde di nuovo', () async {
      final container = await open();
      await notifier(container).setMode(BalancesOnOpen.hidden);
      await notifier(container).toggle();
      leaveFor(container, hideBalancesAfterBackground);
      expect(hidden(container), isTrue);
    });
  });

  group('indipendente dal blocco con biometria', () {
    for (final biometricLock in [false, true]) {
      test('blocco ${biometricLock ? 'attivo' : 'spento'}: nascosti di nuovo dopo 1 minuto', () async {
        final repository = DriftLocalPreferencesRepository(db);
        await repository.save(
          (await repository.get()).copyWith(balancesOnOpen: BalancesOnOpen.hidden, biometricLock: biometricLock),
        );
        final container = await open();
        await notifier(container).toggle();
        leaveFor(container, const Duration(seconds: 59));
        expect(hidden(container), isFalse);
        leaveFor(container, const Duration(minutes: 1));
        expect(hidden(container), isTrue);
      });
    }
  });
}
