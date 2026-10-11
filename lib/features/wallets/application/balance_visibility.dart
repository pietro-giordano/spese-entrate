import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/clock.dart';
import '../../../data/repositories/repository_providers.dart';
import '../../../domain/models/local_preferences.dart';
import '../../settings/application/settings_providers.dart';

part 'balance_visibility.g.dart';

/// Con "sempre nascosti", dopo quanto tempo in background i saldi si nascondono di nuovo.
const hideBalancesAfterBackground = Duration(minutes: 1);

/// Testo al posto di un saldo nascosto.
const hiddenBalanceText = '€ ••••';

/// true = saldi nascosti in tutta l'app (patrimonio, gruppi, portafogli, scelta del portafoglio,
/// scheda Da/A e saldo della card in Movimenti). Gli importi dei movimenti restano visibili.
///
/// All'apertura segue "Saldi all'apertura" ([BalancesOnOpen]); poi lo cambia l'occhio in Portafogli.
@Riverpod(keepAlive: true)
class BalancesHidden extends _$BalancesHidden {
  DateTime? _backgroundSince;

  LocalPreferences get _preferences => ref.read(localPreferencesProvider).value ?? const LocalPreferences();

  DateTime _now() => ref.read(clockProvider)();

  @override
  bool build() => switch (_preferences.balancesOnOpen) {
    BalancesOnOpen.visible => false,
    BalancesOnOpen.hidden => true,
    BalancesOnOpen.remember => _preferences.balancesHidden,
  };

  /// L'occhio: mostra o nasconde e salva la scelta, che "ricorda l'ultima scelta" usa alla
  /// prossima apertura.
  Future<void> toggle() async {
    state = !state;
    final preferences = await ref.read(localPreferencesRepositoryProvider).get();
    await ref.read(localPreferencesRepositoryProvider).save(preferences.copyWith(balancesHidden: state));
  }

  /// "Saldi all'apertura" cambiato nelle Impostazioni: lo salva e ha effetto subito.
  /// Sempre visibili → li mostra, sempre nascosti → li nasconde, ricorda → lascia lo stato
  /// attuale, che diventa l'ultima scelta da ricordare.
  Future<void> setMode(BalancesOnOpen mode) async {
    state = switch (mode) {
      BalancesOnOpen.visible => false,
      BalancesOnOpen.hidden => true,
      BalancesOnOpen.remember => state,
    };
    final repository = ref.read(localPreferencesRepositoryProvider);
    final preferences = await repository.get();
    await repository.save(preferences.copyWith(balancesOnOpen: mode, balancesHidden: state));
  }

  /// L'app è andata in background: conta il primo momento, non gli eventi successivi.
  void wentToBackground() => _backgroundSince ??= _now();

  /// Con "sempre nascosti" i saldi si nascondono di nuovo dopo almeno [hideBalancesAfterBackground].
  void cameToForeground() {
    final since = _backgroundSince;
    _backgroundSince = null;
    if (since == null || _preferences.balancesOnOpen != BalancesOnOpen.hidden) return;
    if (_now().difference(since) >= hideBalancesAfterBackground) state = true;
  }
}
