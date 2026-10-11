import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/clock.dart';
import '../../../data/device/biometric_auth.dart';
import 'settings_providers.dart';

part 'app_lock.g.dart';

/// Dopo quanto tempo in background l'app si blocca di nuovo.
const lockAfterBackground = Duration(minutes: 1);

/// Stato del blocco con biometria: true = schermata di sblocco visibile.
///
/// Si blocca all'apertura e quando l'app torna in primo piano dopo almeno [lockAfterBackground],
/// se l'utente ha attivato il blocco nelle impostazioni.
@Riverpod(keepAlive: true)
class AppLock extends _$AppLock {
  DateTime? _backgroundSince;

  bool get _enabled => ref.read(localPreferencesProvider).value?.biometricLock ?? false;

  DateTime _now() => ref.read(clockProvider)();

  @override
  bool build() => _enabled;

  /// L'app è andata in background: conta il primo momento, non gli eventi successivi.
  void wentToBackground() => _backgroundSince ??= _now();

  void cameToForeground() {
    final since = _backgroundSince;
    _backgroundSince = null;
    if (since == null || !_enabled) return;
    if (_now().difference(since) >= lockAfterBackground) state = true;
  }

  /// Chiede la biometria; sblocca se riesce.
  Future<bool> unlock() async {
    final ok = await ref.read(biometricAuthProvider).authenticate('Sblocca Finanze');
    if (ok) state = false;
    return ok;
  }

  /// Quando l'utente disattiva il blocco.
  void release() => state = false;
}
